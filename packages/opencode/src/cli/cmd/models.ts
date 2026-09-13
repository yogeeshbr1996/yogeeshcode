import { EOL } from "os"
import { Effect } from "effect"
import { ModelsDev } from "@opencode-ai/core/models-dev"
import { effectCmd, fail } from "../effect-cmd"
import { UI } from "../ui"
import { ProviderV2 } from "@opencode-ai/core/provider"

export const ModelsCommand = effectCmd({
  command: "models [provider]",
  describe: "list all available models",
  builder: (yargs) =>
    yargs
      .positional("provider", {
        describe: "provider ID to filter models by",
        type: "string",
        array: false,
      })
      .option("verbose", {
        describe: "use more verbose model output (includes metadata like costs)",
        type: "boolean",
      })
      .option("refresh", {
        describe: "refresh the models cache from models.dev",
        type: "boolean",
      })
      .option("tier", {
        describe: "filter by YogeeshCode tier: free (zero-auth) | free-tier (auth added) | paid (opt-in via yogeeshcode.paid_models.allow_paid) | all",
        type: "string",
        choices: ["free", "free-tier", "paid", "all"],
      }),
  handler: Effect.fn("Cli.models")(function* (args) {
    const { Provider } = yield* Effect.promise(() => import("@/provider/provider"))
    if (args.refresh) {
      yield* ModelsDev.Service.use((s) => s.refresh(true))
      UI.println(UI.Style.TEXT_SUCCESS_BOLD + "Models cache refreshed" + UI.Style.TEXT_NORMAL)
    }

    // YogeeshCode tier visibility: default shows FREE (zero-auth) + connected
    // FREE TIER only. --tier=all reveals everything; paid stays hidden unless
    // yogeeshcode.paid_models.allow_paid is true AND provider connected.
    const { Config } = yield* Effect.promise(() => import("@/config/config"))
    const { Auth } = yield* Effect.promise(() => import("@/auth"))
    let allowPaid = false
    let connectedIDs = new Set<string>()
    try {
      const cfgSvc = yield* Config.Service
      const cfg: any = yield* cfgSvc.get()
      allowPaid = cfg?.yogeeshcode?.paid_models?.allow_paid === true
    } catch {}
    try {
      const authSvc = yield* Auth.Service
      const all = yield* authSvc.all().pipe(Effect.orDie)
      connectedIDs = new Set(Object.keys(all))
      const envs = process.env
      for (const [k, v] of Object.entries(envs)) {
        if (v && v.length > 4 && /API_KEY|APIKEY|_TOKEN$/.test(k)) {
          // env-keyed providers unlock on use; CLI tier filter relies on stored creds
        }
      }
    } catch {}

    const tierOf = (providerID: string, cost?: { input?: number; output?: number }) => {
      if (providerID === "opencode" || providerID === "pollinations-noauth") return "free" as const
      if ((cost?.input ?? 0) > 0 || (cost?.output ?? 0) > 0) return "paid" as const
      return "free-tier" as const
    }
    const tierArg = (args.tier as string | undefined) ?? "default"
    const visible = (providerID: string, cost?: { input?: number; output?: number }) => {
      const tier = tierOf(providerID, cost)
      if (tierArg === "all") return true
      if (tierArg !== "default") return tier === tierArg
      if (tier === "free") return true
      if (tier === "paid") return allowPaid && connectedIDs.has(providerID)
      return connectedIDs.has(providerID)
    }

    const header = (providerID: string, cost?: { input?: number; output?: number }) => {
      if (tierArg !== "default" && tierArg !== "all") return ""
      const tier = tierOf(providerID, cost)
      return tier === "free" ? "  [FREE]" : tier === "free-tier" ? "  [FREE TIER - needs auth]" : "  [PAID]"
    }

    const provider = yield* Provider.Service
    const providers = yield* provider.list()

    const print = (providerID: ProviderV2.ID, verbose?: boolean) => {
      const p = providers[providerID]
      const sorted = Object.entries(p.models).sort(([a], [b]) => a.localeCompare(b))
      let shown = 0
      for (const [modelID, model] of sorted) {
        if (!visible(String(providerID), (model as any)?.cost)) continue
        shown++
        process.stdout.write(`${providerID}/${modelID}${header(String(providerID), (model as any)?.cost)}`)
        process.stdout.write(EOL)
        if (verbose) {
          process.stdout.write(JSON.stringify(model, null, 2))
          process.stdout.write(EOL)
        }
      }
      return shown
    }

    if (args.provider) {
      const providerID = ProviderV2.ID.make(args.provider)
      if (!providers[providerID]) return yield* fail(`Provider not found: ${args.provider}`)
      const shown = print(providerID, args.verbose)
      if (shown === 0)
        UI.println(
          UI.Style.TEXT_DIM +
            "  (hidden: add this provider's auth to unlock free-tier, or set yogeeshcode.paid_models.allow_paid for paid)" +
            UI.Style.TEXT_NORMAL,
        )
      return
    }

    const ids = Object.keys(providers).sort((a, b) => {
      const aIsOpencode = a.startsWith("opencode")
      const bIsOpencode = b.startsWith("opencode")
      if (aIsOpencode && !bIsOpencode) return -1
      if (!aIsOpencode && bIsOpencode) return 1
      return a.localeCompare(b)
    })

    let total = 0
    for (const providerID of ids) total += print(ProviderV2.ID.make(providerID), args.verbose) ?? 0
    UI.println("")
    UI.println(
      UI.Style.TEXT_DIM +
        `  Showing ${total} model(s). Tier: FREE always visible; FREE TIER appears after 'yogeeshcode auth login <provider>'; PAID needs yogeeshcode.paid_models.allow_paid=true. Use --tier=all to see everything.` +
        UI.Style.TEXT_NORMAL,
    )
  }),
})
