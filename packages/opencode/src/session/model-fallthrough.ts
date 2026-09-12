// YogeeshCode: ranked free-model fallthrough.
// Never stops on rate limits - cycles ranked list with cooldowns + escalating backoff.
export type ModelRef = { providerID: string; modelID: string }
export function parseModelRef(ref: string): ModelRef | undefined {
  const idx = ref.indexOf("/")
  if (idx <= 0) return undefined
  return { providerID: ref.slice(0, idx), modelID: ref.slice(idx + 1) }
}
export const DEFAULT_RANKED_FREE_MODELS: string[] = [
  "openrouter-free/nex-agi/nex-n2.5-pro:free",
  "openrouter-free/z-ai/glm-4.5-air:free",
  "openrouter-free/qwen/qwen3-coder:free",
  "openrouter-free/deepseek/deepseek-chat:free",
  "openrouter-free/moonshotai/kimi-k2:free",
  "groq-free/llama-3.3-70b-versatile",
  "ollama/qwen2.5-coder:14b",
]
export function rankedFreeModels(config: any): string[] {
  const order = config?.yogeeshcode?.model_ranker?.order
  if (Array.isArray(order) && order.length > 0) return order.filter((x: unknown) => typeof x === "string")
  return DEFAULT_RANKED_FREE_MODELS
}
