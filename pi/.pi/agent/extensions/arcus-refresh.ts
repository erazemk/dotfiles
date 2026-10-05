/** Refresh Arcus's catalog in the background at interactive Pi session startup. */
import { homedir } from "node:os";
import { join } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

interface RefreshResult {
  status: "changed" | "unchanged" | "busy" | "error";
  added?: string[];
  updated?: string[];
  removed?: string[];
}

export default function (pi: ExtensionAPI) {
  let controller: AbortController | undefined;

  async function refresh(ctx: ExtensionContext, signal: AbortSignal) {
    try {
      const result = await pi.exec(
        join(homedir(), ".pi", "agent", "bin", "update-arcus-models"),
        ["--json"],
        { signal, timeout: 45_000 },
      );
      if (signal.aborted || !ctx.hasUI) return;
      if (result.code !== 0 || result.killed) {
        ctx.ui.notify(
          "Arcus catalog check failed; existing models kept. Check network and Keychain access.",
          "warning",
        );
        return;
      }
      const summary: RefreshResult = JSON.parse(result.stdout);
      if (summary.status === "error") {
        ctx.ui.notify(
          "Arcus catalog check failed; existing models kept.",
          "warning",
        );
        return;
      }
      if (summary.status !== "changed") return;

      const changes: string[] = [];
      for (const kind of ["added", "updated", "removed"] as const) {
        const models = summary[kind] ?? [];
        if (!models.length) continue;
        const names = models.slice(0, 6).join(", ");
        const remaining =
          models.length > 6 ? `, +${models.length - 6} more` : "";
        changes.push(`${models.length} ${kind}: ${names}${remaining}`);
      }
      ctx.ui.notify(
        `Arcus catalog updated.\n${changes.join("\n") || "Provider configuration updated."}\nOpen /model to reload. Your active model is unchanged.`,
        "info",
      );
    } catch {
      if (!signal.aborted && ctx.hasUI) {
        ctx.ui.notify(
          "Arcus catalog check failed; existing models kept.",
          "warning",
        );
      }
    }
  }

  pi.on("session_start", (_event, ctx) => {
    controller?.abort();
    controller = undefined;
    if (ctx.mode !== "tui") return;
    controller = new AbortController();
    // Deliberately don't return/await this promise: startup must not wait for I/O.
    void refresh(ctx, controller.signal);
  });

  pi.on("session_shutdown", () => {
    controller?.abort();
    controller = undefined;
  });
}
