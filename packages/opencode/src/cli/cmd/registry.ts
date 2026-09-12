import { EOL } from "os"
import { Effect } from "effect"
import { effectCmd, fail } from "../effect-cmd"
import { UI } from "../ui"
import {
  getCachedSnapshot,
  getOrRefresh,
  formatRelative,
  shouldAutoRefresh,
  type YogRegistrySnapshot,
} from "@/provider/model-registry"

export const RegistryCommand = effectCmd({
  command: "registry [action]",
  describe: "view / refresh YogeeshCode free-model registry",
  builder: (yargs) =>
    yargs
      .positional("action", {
        describe: "status (default) | refresh | force | list",
        type: "string",
        default: "status",
      }),
  handler: Effect.fn("Cli.registry")(function* (args) {
    const action = (args.action as string) ?? "status"
    const apiKeyRecord: Record<string, string> = {}
    try {
      const { Config } = yield* Effect.promise(() => import("@/config/config"))
      const c: any = yield* Config.get()
      for (const pid of Object.keys(c?.provider ?? {})) {
        const prov = c.provider[pid] as any
        const ak = prov?.options?.apiKey
        if (typeof ak === "string" && ak.startsWith("{") && ak.endsWith("}")) {
          const envKey = ak.slice(1, -1).replace(/^env:/, "")
          apiKeyRecord[pid] = process.env[envKey] ?? ""
        } else if (typeof ak === "string" && ak.length > 8) {
          apiKeyRecord[pid] = ak
        }
      }
    } catch {}

    if (action === "status") {
      const snap = getCachedSnapshot()
      const cfgMin = 720
      const arMin = Math.round((snap.autoRefreshMs ?? cfgMin * 60000) / 60000)
      UI.println("")
      UI.println(UI.Style.TEXT_HIGHLIGHT_BOLD + "YogeeshCode Free-Model Registry" + UI.Style.TEXT_NORMAL)
      UI.println("")
      UI.println("  Last refresh : " + formatRelative(snap.lastRefresh))
      UI.println("  Auto-refresh : every " + arMin + " minutes (default 720 = 12h)")
      UI.println("  Models cached: " + snap.models.length)
      UI.println("  Next refresh : " + (shouldAutoRefresh(snap) ? "due now" : formatRelative(snap.lastRefresh + snap.autoRefreshMs)))
      UI.println("")
      UI.println("  Commands:")
      UI.println("    yogeeshcode registry refresh   - auto refresh (respects 12h interval)")
      UI.println("    yogeeshcode registry force     - force refresh NOW (ignores interval)")
      UI.println("    yogeeshcode registry list      - list all cached free models")
      UI.println("")
      return
    }

    if (action === "refresh" || action === "force") {
      const force = action === "force"
      UI.println(
        (force ? "Force-refreshing" : "Refreshing") + " free-model registry..."
      )
      const arMin = 720
      const snap = yield* Effect.promise(() => getOrRefresh(apiKeyRecord, force, arMin * 60 * 1000))
      UI.println("")
      UI.println(" Done. " + snap.models.length + " free models cached.")
      UI.println("  Last refresh: " + formatRelative(snap.lastRefresh))
      return
    }

    if (action === "list") {
      const snap = getCachedSnapshot()
      UI.println("")
      UI.println("Cached Free Models (" + snap.models.length + ")")
      UI.println("")
      let prev = ""
      for (const m of snap.models) {
        if (m.providerID !== prev) {
          prev = m.providerID
          UI.println("  " + m.providerID)
        }
        UI.println("    " + m.modelID + " (" + m.label + ") - " + m.context + " ctx")
      }
      UI.println("")
      UI.println("  Last refresh: " + formatRelative(snap.lastRefresh))
      return
    }

    return yield* fail("Unknown registry action: " + action)
  }),
})
