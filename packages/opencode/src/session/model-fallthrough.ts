// YogeeshCode: ranked free-model fallthrough.
// Never stops on rate limits - cycles ranked list with cooldowns + escalating backoff.
// Sources (all FREE, cost input=0 output=0):
//   1. opencode/* (OpenCode Zen) - from models.dev catalog, needs `yogeeshcode auth login`
//      (device OAuth). Verified live: 31 FREE Zen models incl. big-pickle,
//      grok-code, nemotron-3-ultra-free (1M ctx), qwen3.6-plus-free, minimax,
//      deepseek-v4-flash-free - all tool_call=true (agentic-capable).
//   2. gemini-free/* - Google AI Studio free tier (API key).
//   3. glm-free/* - Zhipu GLM free flagship (API key).
//   4. openrouter-free/* - OpenRouter :free endpoints ($0, API key).
//   5. groq-free/* - Groq free tier (API key).
//   6. pollinations-noauth/* - zero-auth keyless fallback (config-defined provider).
// NOTE: `provider.getModel()` resolves every entry through the models.dev
// catalog (ModelsDev service -> auto-refresh every 60 min). If models.dev
// DEPRECATES/removes a model id, getModel fails for it and the fallthrough
// loop in prompt.ts skips to the next ranked entry automatically - so the
// agent never breaks, it just moves down the chain. Keep this list in sync
// with `yogeeshcode.json.example -> yogeeshcode.model_ranker.order`.
// To force-refresh the catalog: `yogeeshcode models --refresh` or
// `yogeeshcode registry force`.
export type ModelRef = { providerID: string; modelID: string }
export function parseModelRef(ref: string): ModelRef | undefined {
  const idx = ref.indexOf("/")
  if (idx <= 0) return undefined
  return { providerID: ref.slice(0, idx), modelID: ref.slice(idx + 1) }
}
export const DEFAULT_RANKED_FREE_MODELS: string[] = [
  // Tier 1: OpenCode Zen FREE (models.dev, tool_call=true, cost 0/0).
  // big-pickle = default agent model. Order: flagship -> 1M-ctx giants -> coders.
  "opencode/big-pickle",
  "opencode/nemotron-3-ultra-free",
  "opencode/longcat-2.0-free",
  "opencode/mimo-v2-pro-free",
  "opencode/grok-code",
  "opencode/qwen3.6-plus-free",
  "opencode/minimax-m2.1-free",
  "opencode/deepseek-v4-flash-free",
  "opencode/glm-5-free",
  "opencode/kimi-k2.5-free",
  "opencode/ling-3.0-flash-free",
  "opencode/muse-spark-1.3-contributor-free",
  // Tier 2: free-tier with API key (config-defined providers).
  "pollinations-noauth/openai",
  "gemini-free/gemini-2.5-flash",
  "glm-free/glm-4.5-flash",
  "openrouter-free/nex-agi/nex-n2.5-pro:free",
  "openrouter-free/nex-agi/nex-n2.5-mini:free",
  "openrouter-free/qwen/qwen3-coder:free",
  "openrouter-free/deepseek/deepseek-chat:free",
  "openrouter-free/meta-llama/llama-3.3-70b-instruct:free",
  "groq-free/llama-3.3-70b-versatile",
  "groq-free/qwen-qwq-32b",
  "deepinfra/meta-llama/Llama-3.3-70B-Instruct",
  "deepinfra/Qwen/Qwen2.5-Coder-32B-Instruct",
  "novita/meta-llama/llama-3.3-70b-instruct",
  "sambanova/Meta-Llama-3.3-70B-Instruct",
  "sambanova/Qwen2.5-Coder-32B-Instruct",
  "poe/gpt-4o-mini",
  "poe/claude-3-5-haiku",
  "watsonx/meta-llama/llama-3-3-70b-instruct",
  "vertex-ai/gemini-2.5-flash",
  "together/meta-llama/Llama-3.3-70B-Instruct-Turbo",
  "together/Qwen/Qwen2.5-Coder-32B-Instruct",
  "huggingface/Qwen/Qwen2.5-Coder-32B-Instruct",
  "huggingface/deepseek-ai/DeepSeek-R1-Distill-Llama-70B",
  "huggingface/meta-llama/Llama-3.1-70B-Instruct",
  "fireworks/accounts/fireworks/models/llama-v3p1-70b-instruct",
  "fireworks/accounts/fireworks/models/qwen2p5-coder-32b-instruct",
  "nvidia/meta/llama-3.1-70b-instruct",
  "nvidia/qwen/qwen2.5-coder-32b-instruct",
  "friendli/meta-llama-3.1-70b-instruct",
  "predibase/meta-llama/llama-3.1-70b-instruct",
  "cortex/gpt-4o-mini",
  "cortex/claude-3.5-haiku",
  "ollama/qwen2.5-coder:14b",
  "ollama/qwen3-coder:30b",
]
export function rankedFreeModels(config: any): string[] {
  const order = config?.yogeeshcode?.model_ranker?.order
  const base =
    Array.isArray(order) && order.length > 0 ? order.filter((x: unknown) => typeof x === "string") : DEFAULT_RANKED_FREE_MODELS
  // YogeeshCode: quota-pool expansion. Users can clone a free-tier provider
  // under multiple ids sharing one baseURL, each with its OWN key:
  //   "openrouter-free-2": { baseURL: https://openrouter.ai/api/v1, apiKey: KEY2 ... }
  // If any ranked entry points at the SAME underlying model through a
  // different provider id, expand it: try model on key-1, then key-2...
  // before moving to the next model. This is how one model gets N x quota.
  const keyring = config?.yogeeshcode?.keyring
  if (!keyring || typeof keyring !== "object") return base
  const out: string[] = []
  for (const ref of base) {
    out.push(ref)
    const parsed = parseModelRef(ref)
    if (!parsed) continue
    const clones: unknown = (keyring as Record<string, unknown>)[parsed.providerID]
    if (!Array.isArray(clones)) continue
    for (const clone of clones) {
      if (typeof clone === "string" && clone.length > 0 && clone !== parsed.providerID) {
        out.push(`${clone}/${parsed.modelID}`)
      }
    }
  }
  return out
}
