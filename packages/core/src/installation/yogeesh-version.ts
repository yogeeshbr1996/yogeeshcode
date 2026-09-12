// YogeeshCode version tracking.
// `yogeeshcode.version` is set at build time from root package.json's yogeeshcode.version field.
// This is INDEPENDENT from upstream OpenCode's OPENCODE_VERSION.
declare global {
  const YOGEESH_VERSION: string
}

export const YogeeshVersion = typeof YOGEESH_VERSION === "string" ? YOGEESH_VERSION : "local"
export const YogeeshBaseVersion = typeof OPENCODE_VERSION === "string" ? OPENCODE_VERSION : "unknown"

export function yogeeshVersionInfo(): string {
  if (YogeeshVersion === "local") {
    return `YogeeshCode local (base OpenCode ${YogeeshBaseVersion})`
  }
  return `YogeeshCode ${YogeeshVersion} (base OpenCode ${YogeeshBaseVersion})`
}
