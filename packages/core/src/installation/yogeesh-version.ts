// YogeeshCode version tracking.
// `yogeeshcode.version` is set at build time from root package.json's yogeeshcode.version field.
// This is INDEPENDENT from upstream OpenCode's OPENCODE_VERSION.
import { createRequire } from "module"

declare global {
  const YOGEESH_VERSION: string
}

export const YogeeshVersion = typeof YOGEESH_VERSION === "string" ? YOGEESH_VERSION : "local"

// Base OpenCode version: injected at build time. In dev (bun run src/index.ts),
// fall back to reading packages/opencode/package.json so `--version` is never "unknown".
function devBaseVersion(): string {
  try {
    // packages/core/src/installation/ -> packages/opencode/package.json
    const require = createRequire(import.meta.url)
    return require("../../../opencode/package.json").version as string
  } catch {
    return "unknown"
  }
}

export const YogeeshBaseVersion = typeof OPENCODE_VERSION === "string" ? OPENCODE_VERSION : devBaseVersion()

export function yogeeshVersionInfo(): string {
  if (YogeeshVersion === "local") {
    return `YogeeshCode local (base OpenCode ${YogeeshBaseVersion})`
  }
  return `YogeeshCode ${YogeeshVersion} (base OpenCode ${YogeeshBaseVersion})`
}
