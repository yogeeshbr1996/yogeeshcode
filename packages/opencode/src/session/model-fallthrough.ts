// YogeeshCode: ranked free-model fallthrough.
// Never stops on rate limits - cycles ranked list with cooldowns + escalating backoff.
export type ModelRef = { providerID: string; modelID: string }
export function parseModelRef(ref: string): ModelRef | undefined {
  const idx = ref.indexOf("/")
  if (idx <= 0) return undefined
  return { providerID: ref.slice(0, idx), modelID: ref.slice(idx + 1) }
}
export const DEFAULT_RANKED_FREE_MODELS: string[] = [
  "pollinations-noauth/openai",
  "opencode/big-pickle",
  "gemini-free/gemini-2.5-flash",
  "opencode/grok-code",
  "opencode/nemotron-3-ultra-free",
  "opencode/qwen3.6-plus-free",
  "opencode/minimax-m2.1-free",
  "opencode/deepseek-v4-flash-free",
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
  if (Array.isArray(order) && order.length > 0) return order.filter((x: unknown) => typeof x === "string")
  return DEFAULT_RANKED_FREE_MODELS
}
