/** @jsxImportSource @opentui/solid */
import { createSignal } from "solid-js"
import type { SessionStatus } from "@opencode-ai/sdk/v2"
import type { TuiPlugin, TuiPluginModule, TuiSlotPlugin } from "@opencode-ai/plugin/tui"

type Session = {
  id: string
  parentID?: string
  agent?: string
  title: string
  time: {
    created: number
  }
}

const active = (status: SessionStatus | undefined) => status?.type === "busy" || status?.type === "retry"

const subtree = (sessions: ReadonlyMap<string, Session>, root: string) => {
  const ids = new Set([root])
  let changed = true

  while (changed) {
    changed = false
    for (const session of sessions.values()) {
      if (!session.parentID || !ids.has(session.parentID) || ids.has(session.id)) continue
      ids.add(session.id)
      changed = true
    }
  }

  return ids
}

const tui: TuiPlugin = async (api) => {
  const sessions = new Map<string, Session>()
  const statuses = new Map<string, SessionStatus>()
  const [revision, setRevision] = createSignal(0)
  const refresh = () => setRevision((value) => value + 1)

  api.event.on("session.created", (event) => {
    const session = event.properties.info
    sessions.set(session.id, session)
    refresh()
  })
  api.event.on("session.updated", (event) => {
    const session = event.properties.info
    sessions.set(session.id, session)
    refresh()
  })
  api.event.on("session.deleted", (event) => {
    sessions.delete(event.properties.sessionID)
    statuses.delete(event.properties.sessionID)
    refresh()
  })
  api.event.on("session.status", (event) => {
    statuses.set(event.properties.sessionID, event.properties.status)
    refresh()
  })
  api.event.on("session.idle", (event) => {
    statuses.set(event.properties.sessionID, { type: "idle" })
    refresh()
  })

  void (async () => {
    const listed = await api.client.session.list({ directory: api.state.path.directory, limit: 100 })
    if (api.lifecycle.signal.aborted) return

    for (const session of listed.data ?? []) sessions.set(session.id, session)
    refresh()
  })()

  const slot: TuiSlotPlugin = {
    order: 350,
    slots: {
      sidebar_content(ctx, { session_id }) {
        revision()
        const descendants = subtree(sessions, session_id)
        const children = [...sessions.values()]
          .filter(
            (session) =>
              session.id !== session_id &&
              descendants.has(session.id) &&
              active(statuses.get(session.id) ?? api.state.session.status(session.id)),
          )
          .sort((left, right) => left.time.created - right.time.created)

        if (children.length === 0) return null

        return (
          <box flexDirection="column">
            <text fg={ctx.theme.current.text}>
              <b>Subagents</b>
            </text>
            {children.map((session) => {
              const title = session.title.replace(/\s+\(@[^)]*\)\s*$/, "")

              return (
                <box flexDirection="row" gap={1}>
                  <text flexShrink={0} fg={ctx.theme.current.success}>
                    •
                  </text>
                  <text fg={ctx.theme.current.text} wrapMode="word">
                    <span style={{ fg: ctx.theme.current.text }}>{session.agent ?? "subagent"}</span>{" "}
                    <span style={{ fg: ctx.theme.current.textMuted }}>{title}</span>
                  </text>
                </box>
              )
            })}
          </box>
        )
      },
    },
  }

  api.slots.register(slot)
}

export default {
  id: "subagents",
  tui,
} satisfies TuiPluginModule & { id: string }
