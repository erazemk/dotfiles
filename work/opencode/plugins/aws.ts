import type { Plugin } from "@opencode-ai/plugin"

const expiredSsoSession =
  /AWS credential provider failed: (?:The SSO session token associated with profile=[^\s]+ was not found or is invalid\.|Token is expired\.)/

export const aws: Plugin = async ({ $, client }) => {
  let login: Promise<void> | undefined

  return {
    event: async ({ event }) => {
      if (event.type !== "session.error") return

      const error = event.properties.error
      const message =
        error instanceof Error ? error.message : typeof error === "string" ? error : (JSON.stringify(error) ?? "")
      const match = expiredSsoSession.exec(message)
      if (!match) return

      if (login) return

      login = (async () => {
        try {
          await client.app.log({
            body: {
              service: "aws",
              level: "info",
              message: "AWS SSO session expired; opening login flow",
            },
          })

          const result = await $`aws sso login`.nothrow()
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
        } catch (error) {
          void client.app
            .log({
              body: {
                service: "aws",
                level: "error",
                message: `Could not start AWS SSO login: ${String(error)}`,
              },
            })
            .catch(() => {})
        }
      })().finally(() => {
        login = undefined
      })

      void login
    },
  }
}
