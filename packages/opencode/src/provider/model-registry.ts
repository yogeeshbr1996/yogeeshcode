export interface YogModelInfo {
  providerID: string
  modelID: string
  label: string
  context: number
}

export interface YogRegistryEntry extends YogModelInfo {
  source: string
  fetchedAt: number
}

export interface YogRegistrySnapshot {
  lastRefresh: number
  autoRefreshMs: number
  models: YogRegistryEntry[]
}

const DEFAULT_AUTO_REFRESH_MS = 12 * 60 * 60 * 1000
const CACHE_DIR = (): string => {
  try {
    const { Global } = require("@opencode-ai/core/global") as typeof import("@opencode-ai/core/global")
    return Global.Path.data
  } catch {
    return "~/.yogeeshcode"
  }
}

const REMOTE_URLS: Array<{ providerID: string; url: string }> = [
  { providerID: "openrouter-free", url: "https://openrouter.ai/api/v1/models" },
  { providerID: "groq-free", url: "https://api.groq.com/openai/v1/models" },
  { providerID: "ollama", url: "http://localhost:11434/api/tags" },
  { providerID: "gemini-free", url: "https://generativelanguage.googleapis.com/v1beta/models" },
  { providerID: "huggingface", url: "https://api-inference.huggingface.co/framework/text-generation-inference" },
  { providerID: "deepseek-direct", url: "https://api.deepseek.com/v1/models" },
  { providerID: "mistral-direct", url: "https://api.mistral.ai/v1/models" },
  { providerID: "cloudflare", url: "https://api.cloudflare.com/client/v4/accounts/-/ai/models/v1" },
  { providerID: "cerebras", url: "https://api.cerebras.ai/v1/models" },
  { providerID: "perplexity", url: "https://api.perplexity.ai/models" },
]

export function formatRelative(ts: number): string {
  if (!ts) return "never"
  const diff = Date.now() - ts
  const sec = Math.floor(diff / 1000)
  if (sec < 60) return `${sec}s ago`
  const min = Math.floor(sec / 60)
  if (min < 60) return `${min}m ago`
  const hr = Math.floor(min / 60)
  if (hr < 24) return `${hr}h ${min % 60}m ago`
  const day = Math.floor(hr / 24)
  return `${day}d ${hr % 24}h ago`
}

export function defaultSnapshot(): YogRegistrySnapshot {
  return { lastRefresh: 0, autoRefreshMs: DEFAULT_AUTO_REFRESH_MS, models: [] }
}

export function shouldAutoRefresh(snap: YogRegistrySnapshot): boolean {
  if (!snap.lastRefresh) return true
  return Date.now() - snap.lastRefresh >= snap.autoRefreshMs
}

export async function fetchProviderModels(providerID: string, apiKey?: string): Promise<YogRegistryEntry[]> {
  try {
    const urlMap: Record<string, () => Promise<YogRegistryEntry[]>> = {
      "openrouter-free": async () => {
        const u = new URL("https://openrouter.ai/api/v1/models")
        const res = await fetch(u.toString())
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of j.data ?? []) {
          if (!m.id || !m.pricing || Number(m.pricing.completion) > 0 || Number(m.pricing.prompt) > 0) continue
          out.push({
            providerID, modelID: m.id,
            label: (m.name ?? m.id),
            context: m.context_length ?? 8192, source: "openrouter", fetchedAt: now,
          })
        }
        return out
      },
      "groq-free": async () => {
        const res = await fetch("https://api.groq.com/openai/v1/models", { headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {} })
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of j.data ?? []) {
          out.push({ providerID, modelID: m.id, label: m.owned_by ?? m.id, context: 131072, source: "groq", fetchedAt: now })
        }
        return out
      },
      "ollama": async () => {
        try {
          const res = await fetch("http://localhost:11434/api/tags")
          if (!res.ok) return []
          const j = await res.json() as any
          const out: YogRegistryEntry[] = []
          const now = Date.now()
          for (const m of j.models ?? []) {
            out.push({ providerID, modelID: m.name, label: m.name, context: 32768, source: "ollama", fetchedAt: now })
          }
          return out
        } catch { return [] }
      },
      "gemini-free": async () => {
        const res = await fetch("https://generativelanguage.googleapis.com/v1beta/models" + (apiKey ? `?key=${apiKey}` : ""))
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of j.models ?? []) {
          if (!m.name) continue
          const id = m.name.replace(/^models\//, "")
          out.push({ providerID, modelID: id, label: m.displayName ?? id, context: m.inputTokenLimit ?? 1000000, source: "gemini", fetchedAt: now })
        }
        return out
      },
      "deepseek-direct": async () => {
        const res = await fetch("https://api.deepseek.com/v1/models", { headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {} })
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of j.data ?? []) {
          out.push({ providerID, modelID: m.id, label: m.id, context: 128000, source: "deepseek", fetchedAt: now })
        }
        return out
      },
      "mistral-direct": async () => {
        const res = await fetch("https://api.mistral.ai/v1/models", { headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {} })
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of j.data ?? []) {
          out.push({ providerID, modelID: m.id, label: m.id, context: 32768, source: "mistral", fetchedAt: now })
        }
        return out
      },
      "huggingface": async () => {
        const res = await fetch("https://api-inference.huggingface.co/framework/text-generation-inference", { headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {} })
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of (Array.isArray(j) ? j : []) as any[]) {
          if (!m.modelId) continue
          out.push({ providerID, modelID: m.modelId, label: m.modelId, context: 131072, source: "huggingface", fetchedAt: now })
        }
        return out
      },
      "cloudflare": async () => {
        const res = await fetch("https://api.cloudflare.com/client/v4/accounts/-/ai/models/v1", { headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {} })
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of (j.result ?? []) as any[]) {
          if (!m.name) continue
          out.push({ providerID, modelID: m.name, label: m.name, context: 131072, source: "cloudflare", fetchedAt: now })
        }
        return out
      },
      "cerebras": async () => {
        const res = await fetch("https://api.cerebras.ai/v1/models", { headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {} })
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of (j.data ?? []) as any[]) {
          if (!m.id) continue
          out.push({ providerID, modelID: m.id, label: m.id, context: 8192, source: "cerebras", fetchedAt: now })
        }
        return out
      },
      "perplexity": async () => {
        const res = await fetch("https://api.perplexity.ai/models", { headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {} })
        if (!res.ok) return []
        const j = await res.json() as any
        const out: YogRegistryEntry[] = []
        const now = Date.now()
        for (const m of (j.data ?? j.models ?? []) as any[]) {
          if (!m.id && !m.name) continue
          out.push({ providerID, modelID: m.id ?? m.name, label: m.id ?? m.name, context: 131072, source: "perplexity", fetchedAt: now })
        }
        return out
      },
    }
    const fn = urlMap[providerID]
    if (!fn) return []
    return await fn()
  } catch {
    return []
  }
}

export async function refreshAllProviders(apiKeys: Record<string, string> = {}): Promise<YogRegistrySnapshot> {
  const results = await Promise.all(REMOTE_URLS.map((r) => fetchProviderModels(r.providerID, apiKeys[r.providerID])))
  const models = results.flat()
  return { lastRefresh: Date.now(), autoRefreshMs: DEFAULT_AUTO_REFRESH_MS, models }
}

export function getCachedSnapshot(): YogRegistrySnapshot {
  try {
    const fs = require("fs") as typeof import("fs")
    const path = require("path") as typeof import("path")
    const dir = CACHE_DIR().replace(/^~/, require("os").homedir())
    const f = path.join(dir, "model-registry.json")
    if (!fs.existsSync(f)) return defaultSnapshot()
    const raw = fs.readFileSync(f, "utf8")
    return JSON.parse(raw) as YogRegistrySnapshot
  } catch {
    return defaultSnapshot()
  }
}

export function saveSnapshot(snap: YogRegistrySnapshot): void {
  try {
    const fs = require("fs") as typeof import("fs")
    const path = require("path") as typeof import("path")
    const dir = CACHE_DIR().replace(/^~/, require("os").homedir())
    fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(path.join(dir, "model-registry.json"), JSON.stringify(snap, null, 2))
  } catch {}
}

export async function getOrRefresh(apiKeys: Record<string, string> = {}, force = false, autoRefreshMs?: number): Promise<YogRegistrySnapshot> {
  const cached = getCachedSnapshot()
  const effective = autoRefreshMs ? { ...cached, autoRefreshMs } : cached
  if (!force && !shouldAutoRefresh(effective)) return cached
  const fresh = await refreshAllProviders(apiKeys)
  if (fresh.models.length > 0) saveSnapshot({ ...fresh, autoRefreshMs: autoRefreshMs ?? fresh.autoRefreshMs })
  else saveSnapshot({ ...cached, lastRefresh: Date.now() })
  return fresh.models.length > 0 ? { ...fresh, autoRefreshMs: autoRefreshMs ?? fresh.autoRefreshMs } : cached
}
