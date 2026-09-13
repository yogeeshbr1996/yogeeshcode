// YogeeshCode: model-tier visibility rules.
// Tier 1 (FREE, zero-auth): always shown. Providers whose name marks them as
// "no key"/"zero auth"/"pollinations" or the built-in `opencode` Zen catalog
// never require stored credentials to appear.
// Tier 2 (FREE TIER, auth needed): shown ONLY after the user connects that
// provider (API key / OAuth / env). Toggled on automatically by
// `sync.data.provider_next.connected`.
// Tier 3 (PAID): never shown unless the user explicitly opts in via
// `yogeeshcode.paid_models.allow_paid: true` in the global config
// (~/.yogeeshcode/yogeeshcode.json), AND the provider is connected.
// Cost heuristic: cost.input > 0 / cost.output > 0 means paid tokens.
export const YOG_FREE_ALWAYS_VISIBLE_PROVIDER_IDS = new Set(["opencode", "pollinations-noauth"])

export type YogSyncModel = {
  cost?: { input?: number; output?: number }
  limit?: { context?: number; input?: number; output?: number }
  status?: string
}

export type YogTier = "free" | "free-tier" | "paid"

export function yogTierOf(providerID: string, model?: YogSyncModel): YogTier {
  if (YOG_FREE_ALWAYS_VISIBLE_PROVIDER_IDS.has(providerID)) return "free"
  const input = model?.cost?.input ?? 0
  const output = model?.cost?.output ?? 0
  if (input > 0 || output > 0) return "paid"
  // Cost-free catalog entries from other providers still need their auth.
  return "free-tier"
}

export function yogModelVisible(
  providerID: string,
  model: YogSyncModel | undefined,
  opts: { connected?: boolean; allowPaid?: boolean } = {},
): boolean {
  const tier = yogTierOf(providerID, model)
  if (tier === "free") return true
  if (tier === "paid") return (opts.connected ?? false) && (opts.allowPaid ?? false)
  return opts.connected ?? false
}

// YogeeshCode: compact token-budget footer for the picker.
// Format: "FREE 1M | out 32K" - ctx = window size, out = per-call generation cap.
// Tokens are the #1 lever for coding: bigger ctx = whole repo in memory,
// bigger out = full files generated without truncation.
export function yogTokens(n?: number): string {
  if (n === undefined || n === null || Number.isNaN(n)) return "?"
  if (n >= 1000000) return `${(n / 1000000).toFixed(n % 1000000 === 0 ? 0 : 1)}M`
  if (n >= 1000) return `${Math.round(n / 1000)}K`
  return `${n}`
}

export function yogFooter(providerID: string, model?: YogSyncModel): string {
  const tier = yogTierOf(providerID, model)
  const tag = tier === "free" ? "FREE" : tier === "free-tier" ? "FREE-TIER" : "PAID"
  return `${tag} ${yogTokens(model?.limit?.context)} | out ${yogTokens(model?.limit?.output)}`
}
