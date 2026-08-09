import { mkdir, readFile, rename, unlink, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, join } from "node:path"
import type { Plugin } from "@opencode-ai/plugin"

const gatewayURL = "https://ai-gateway.dev.devrev-eng.ai/v1/model/info"
const requestTimeoutMs = 10_000
const snapshotPath = join(homedir(), ".local", "state", "opencode", "arcus-model-monitor.json")

type JSONValue = null | boolean | number | string | JSONValue[] | { [key: string]: JSONValue }

type ModelSnapshot = {
  name: string
  id: string
  configuration: JSONValue
}

type Snapshot = {
  capturedAt: string
  models: Record<string, ModelSnapshot>
}

let refreshing: Promise<void> | undefined

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

function normalize(value: unknown): JSONValue | undefined {
  if (value === null || typeof value === "boolean" || typeof value === "number" || typeof value === "string") {
    return value
  }

  if (Array.isArray(value)) {
    const normalized = value.map(normalize)
    if (normalized.some((item) => item === undefined)) return undefined
    return normalized as JSONValue[]
  }

  if (!isRecord(value)) return undefined

  const normalized: Record<string, JSONValue> = {}
  for (const key of Object.keys(value).sort()) {
    const item = normalize(value[key])
    if (item === undefined) return undefined
    normalized[key] = item
  }
  return normalized
}

function equal(left: JSONValue, right: JSONValue): boolean {
  return JSON.stringify(left) === JSON.stringify(right)
}

function validSnapshot(value: unknown): value is Snapshot {
  if (!isRecord(value) || typeof value.capturedAt !== "string" || !isRecord(value.models)) {
    return false
  }

  return Object.entries(value.models).every(([name, model]) => {
    return (
      typeof name === "string" &&
      isRecord(model) &&
      typeof model.name === "string" &&
      typeof model.id === "string" &&
      normalize(model.configuration) !== undefined
    )
  })
}

function parseModels(value: unknown): Record<string, ModelSnapshot> | undefined {
  if (!isRecord(value) || !Array.isArray(value.data) || value.data.length === 0) return undefined

  const parsed: ModelSnapshot[] = []
  for (const entry of value.data) {
    if (!isRecord(entry) || typeof entry.model_name !== "string" || entry.model_name.length === 0) return undefined
    if (!isRecord(entry.litellm_params) || typeof entry.litellm_params.model !== "string" || entry.litellm_params.model.length === 0) {
      return undefined
    }

    const modelInfo = isRecord(entry.model_info) ? entry.model_info : undefined
    if (!modelInfo) return undefined

    const capabilities: Record<string, JSONValue> = {}
    for (const [key, value] of Object.entries(modelInfo)) {
      const normalized = normalize(value)
      if (key.startsWith("supports_") && normalized !== undefined) capabilities[key] = normalized
    }
    const supportedOpenAIParams = Array.isArray(modelInfo.supported_openai_params)
      ? [...modelInfo.supported_openai_params].sort()
      : modelInfo.supported_openai_params
    const configuration = normalize({
      modelName: entry.model_name,
      modelID: entry.litellm_params.model,
      maxTokens: modelInfo.max_tokens,
      maxInputTokens: modelInfo.max_input_tokens,
      maxOutputTokens: modelInfo.max_output_tokens,
      mode: modelInfo.mode,
      capabilities,
      supportedOpenAIParams,
    })
    if (configuration === undefined) return undefined

    const model: ModelSnapshot = {
      name: entry.model_name,
      id: entry.litellm_params.model,
      configuration,
    }
    parsed.push(model)
  }

  const models: Record<string, ModelSnapshot> = {}
  for (const model of parsed.sort((left, right) => (left.name < right.name ? -1 : left.name > right.name ? 1 : 0))) {
    const previous = models[model.name]
    if (previous && !equal(normalize(previous)!, normalize(model)!)) return undefined
    models[model.name] = model
  }
  return models
}

async function readSnapshot(): Promise<Snapshot | undefined> {
  try {
    const value: unknown = JSON.parse(await readFile(snapshotPath, "utf8"))
    return validSnapshot(value) ? value : undefined
  } catch (error) {
    if (isRecord(error) && error.code === "ENOENT") return undefined
    console.warn("Arcus model monitor could not read its snapshot")
    return undefined
  }
}

async function writeSnapshot(snapshot: Snapshot): Promise<void> {
  await mkdir(dirname(snapshotPath), { recursive: true })
  const temporaryPath = `${snapshotPath}.${process.pid}.tmp`
  await writeFile(temporaryPath, `${JSON.stringify(snapshot)}\n`, { mode: 0o600 })
  try {
    await rename(temporaryPath, snapshotPath)
  } catch (error) {
    await unlink(temporaryPath).catch(() => {})
    throw error
  }
}

async function token(signal: AbortSignal): Promise<string | undefined> {
  const process = Bun.spawn(["security", "find-generic-password", "-a", "devrev", "-s", "arcus-token", "-w"], {
    stdout: "pipe",
    stderr: "ignore",
  })
  const abort = () => process.kill()
  signal.addEventListener("abort", abort, { once: true })

  try {
    if ((await process.exited) !== 0) return undefined
    const value = (await new Response(process.stdout).text()).trim()
    return value || undefined
  } finally {
    signal.removeEventListener("abort", abort)
  }
}

const plugin: Plugin = async ({ client }) => {
  const refresh = async () => {
    const signal = AbortSignal.timeout(requestTimeoutMs)
    const apiToken = await token(signal)
    if (!apiToken || signal.aborted) return

    const response = await fetch(gatewayURL, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${apiToken}`,
      },
      signal,
    })
    if (!response.ok) return

    const models = parseModels(await response.json())
    if (!models) return

    const current: Snapshot = {
      capturedAt: new Date().toISOString(),
      models,
    }
    const cached = await readSnapshot()
    if (!cached) {
      await writeSnapshot(current)
      return
    }

    let changed = false
    for (const name of Object.keys(models).filter((name) => !cached.models[name]).sort()) {
      const model = models[name]
      changed = true
      await client.tui.showToast({
        body: {
          title: "Arcus model added",
          message: `Name: ${model.name}\nID: ${model.id}`,
          variant: "success",
          duration: 2_000,
        },
      })
    }

    for (const name of Object.keys(cached.models).filter((name) => !models[name]).sort()) {
      const model = cached.models[name]
      changed = true
      await client.tui.showToast({
        body: {
          title: "Arcus model removed",
          message: `Name: ${model.name}\nID: ${model.id}`,
          variant: "error",
          duration: 2_000,
        },
      })
    }

    for (const name of Object.keys(models).filter((name) => cached.models[name]).sort()) {
      const previous = cached.models[name]
      const model = models[name]
      if (model.id === previous.id && equal(model.configuration, previous.configuration)) continue
      changed = true
      await client.tui.showToast({
        body: {
          title: "Arcus model updated",
          message: `Name: ${model.name}\nID: ${model.id}`,
          variant: "warning",
          duration: 2_000,
        },
      })
    }

    if (!changed) {
      await client.tui.showToast({
        body: {
          title: "No Arcus update",
          message: "No models were added, removed, or updated.",
          variant: "info",
          duration: 2_000,
        },
      })
    }

    await writeSnapshot(current)
  }

  const startRefresh = () => {
    if (refreshing) return
    refreshing = refresh()
      .catch((error) => {
        console.warn("Arcus model monitor refresh failed", error instanceof Error ? error.message : error)
      })
      .finally(() => {
        refreshing = undefined
      })
  }

  startRefresh()

  return {}
}

export default plugin
