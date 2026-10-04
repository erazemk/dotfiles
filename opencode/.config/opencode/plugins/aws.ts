import type { Plugin } from "@opencode-ai/plugin"
import type { AgentPartInput, FilePartInput, SubtaskPartInput, TextPartInput } from "@opencode-ai/sdk"

const expiredSsoSession =
    /AWS credential provider failed: (?:The SSO session token associated with profile=[^\s]+ was not found or is invalid\.|Token is expired\.)/

export const aws: Plugin = async ({ $, client }) => {
    const messages = new Map<
        string,
        {
            messageID: string
            agent: string
            model: { providerID: string; modelID: string }
            parts: Array<TextPartInput | FilePartInput | AgentPartInput | SubtaskPartInput>
        }
    >()
    const retrying = new Set<string>()
    let login: Promise<boolean> | undefined

    return {
        "chat.message": async (_input, output) => {
            messages.set(output.message.sessionID, {
                messageID: output.message.id,
                agent: output.message.agent,
                model: output.message.model,
                parts: output.parts.flatMap((part) => {
                    switch (part.type) {
                        case "text":
                            return [{ ...part, type: "text" }]
                        case "file":
                            return [{ ...part, type: "file" }]
                        case "agent":
                            return [{ ...part, type: "agent" }]
                        case "subtask":
                            return [{ ...part, type: "subtask" }]
                        default:
                            return []
                    }
                }),
            })
        },
        event: async ({ event }) => {
            if (event.type === "session.idle") {
                if (!retrying.has(event.properties.sessionID)) messages.delete(event.properties.sessionID)
                return
            }

            if (event.type !== "session.error" || !event.properties.sessionID) return

            const error = event.properties.error
            const message =
                error instanceof Error ? error.message : typeof error === "string" ? error : (JSON.stringify(error) ?? "")
            const match = expiredSsoSession.exec(message)
            if (!match) return

            const retry = messages.get(event.properties.sessionID)
            if (!retry || retrying.has(retry.messageID)) return

            retrying.add(retry.messageID)

            if (!login) {
                login = (async () => {
                    try {
                        await client.app.log({
                            body: {
                                service: "aws",
                                level: "info",
                                message: "AWS SSO session expired; opening login flow",
                            },
                        })

                        const result = await $`aws sso login`.quiet().nothrow()
                        await client.app.log({
                            body: {
                                service: "aws",
                                level: result.exitCode === 0 ? "info" : "error",
                                message:
                                    result.exitCode === 0
                                        ? "AWS SSO login completed"
                                        : `AWS SSO login failed: ${result.stderr.toString().trim()}`,
                            },
                        })

                        return result.exitCode === 0
                    } catch (error) {
                        void client.app
                            .log({
                                body: {
                                    service: "aws",
                                    level: "error",
                                    message: `Could not start AWS SSO login: ${String(error)}`,
                                },
                            })
                            .catch(() => { })
                        return false
                    }
                })().finally(() => {
                    login = undefined
                })
            }

            const loginAttempt = login
            void (async () => {
                let retried = false
                try {
                    if (!(await loginAttempt)) return

                    await client.session.promptAsync({
                        path: { id: event.properties.sessionID! },
                        body: retry,
                    })
                    retried = true
                    await client.app.log({
                        body: {
                            service: "aws",
                            level: "info",
                            message: "AWS SSO login completed; retrying the failed message",
                        },
                    })
                } catch (error) {
                    void client.app
                        .log({
                            body: {
                                service: "aws",
                                level: "error",
                                message: `Could not retry the failed message: ${String(error)}`,
                            },
                        })
                        .catch(() => { })
                } finally {
                    retrying.delete(retry.messageID)
                    if (!retried) messages.delete(event.properties.sessionID!)
                }
            })()
        },
    }
}
