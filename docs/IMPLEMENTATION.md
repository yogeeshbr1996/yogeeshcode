# Implementation Details

Technical deep-dive into every feature we added to the YogeeshCode fork.

## Commit History

| Commit | Description |
|---|---|
| `ac2cf35471` | Rebrand: `yogeeshcode` binary, `~/.yogeeshcode`, VSCode ext, TUI logo |
| `99724ba0bc` | Export txt/html/pdf, rate-limit fallthrough (cooldowns, max 100 attempts) |
| `53bab978ef` | Build + install scripts |
| `d122d61c9a` | Release folder + free-model-first config |
| `fbc70eed1b` | Semver versioning + release manager (dry-run, publish, override) |
| `33dad1dd48` | All free models (50+, 12 providers, Gemini-first ranking) |
| `055a01589c` | Free cloud-only, models.dev + OpenCode Zen integrated, autopilot permissions |
| `55d5349a2d` | Fix scriptName branding, 30/30 tests pass |
| `1d03a24e4e` | Release v1.0.0: darwin-arm64 + VSIX + installer |

## Table of Contents

1. [Rebrand](#rebrand)
2. [Free Model System](#free-model-system)
3. [Rate Limit Fallthrough](#rate-limit-fallthrough)
4. [Permission Autopilot](#permission-autopilot)
5. [Conversation Export](#conversation-export)
6. [Build System](#build-system)
7. [Version Management](#version-management)
8. [Upstream Sync](#upstream-sync)

---

## Rebrand

### What changed

| File | Change |
|---|---|
| `package.json` | `name: "opencode"` -> `"yogeeshcode"` |
| `packages/core/src/global.ts` | `app: "opencode"` -> `"yogeeshcode"` |
| `packages/opencode/bin/opencode` | Added `yogeeshcode` launcher |
| `packages/opencode/package.json` | `bin: { opencode, yogeeshcode }` |
| `packages/opencode/src/config/paths.ts` | Supports `.yogeeshcode` + `.opencode` fallback |
| `packages/core/src/flag/flag.ts` | `YOGEESHCODE_CONFIG_DIR` env first |
| `sdks/vscode/package.json` | `publisher: yogeesh`, `displayName: YogeeshCode` |
| `sdks/vscode/src/extension.ts` | `TERMINAL_NAME: yogeeshcode` |
| `packages/tui/src/logo.ts` | New block logo art |

### What NOT changed (kept upstream)

- All `@opencode-ai/*` internal imports (7000+ refs)
- All upstream feature code (LSP, MCP, agents, etc.)
- MIT LICENSE file

---

## Free Model System

### Architecture

```
Config (yogeeshcode.json)
  -> provider: { gemini-free, openrouter-free, ... }
  -> yogeeshcode.model_ranker.order: [rank1, rank2, ...]
  -> yogeeshcode.free_models_only: true

At runtime:
  prompt.ts -> provider.getModel(primary)
             -> if missing, walk rankedFreeModels() list
             -> skip cooled-down, pick first healthy
             -> auto-swap before processing

  processor.ts -> on 429/5xx -> mark cooldown
               -> pick next from ranked list
               -> swap streamInput.model
               -> retry (max 100 attempts)
```

### Files

| File | Role |
|---|---|
| `yogeeshcode.json.example` | Default config with 50+ free models |
| `packages/opencode/src/session/model-fallthrough.ts` | Ranked list + parser |
| `packages/opencode/src/session/prompt.ts` | Primary model fallback |
| `packages/opencode/src/session/processor.ts` | Runtime rotation on retry |
| `packages/opencode/src/session/retry.ts` | Cooldown + backoff state |

---

## Rate Limit Fallthrough

### retry.ts

```typescript
// Cooldown map: "provider/model" -> timestamp
const cooldowns = new Map<string, number>()

// Configure max attempts (default 100)
yogeeshConfigureFallthrough(maxAttempts?)

// Mark model on cooldown (default 60s)
yogeeshMarkCooldown(providerID, modelID, cooldownMs)

// Check remaining cooldown
yogeeshCooldownRemaining(providerID, modelID): number
```

### processor.ts retry flow

1. Stream fails with 429/401/403/5xx
2. Mark current model on cooldown
3. Call `yogeeshPickNextRef()` to find next healthy model
4. If found: swap `streamInput.model`, retry
5. If all cooling: escalating backoff (2^n, cap 120s)
6. After backoff, cooldowns may have expired, retry
7. Repeat up to `max_attempts` (100)

### Backoff schedule

| Attempt | Delay |
|---|---|
| 1-5 | immediate |
| 6 | 2s |
| 7 | 4s |
| 8 | 8s |
| 9 | 16s |
| 10 | 32s |
| 11 | 64s |
| 12+ | 120s cap |

---

## Permission Autopilot

### Config schema

```json
{
  "permission": {
    "edit": "allow",
    "bash": "ask",
    "bash_allowlist": ["ls", "cat", "git status", "npm run", "bun run", "node", "python3", "cargo", "go", "make", "cp", "mv"],
    "bash_denylist": ["rm -rf", "sudo", "chmod 777", "git reset --hard", "git push --force"]
  }
}
```

### Resolution order

1. If command in denylist -> DENY (even with --auto)
2. If command in allowlist -> ALLOW
3. If mode is --auto -> ALLOW
4. If mode is --no-auto -> ASK
5. Default -> ASK

---

## Conversation Export

### export-format.ts

Zero-dependency formatters:
- `formatTxt(messages)` -> plain transcript
- `formatHtml(messages)` -> styled HTML (print to PDF in browser)
- `formatPdf(messages)` -> minimal valid PDF (Helvetica, paginated)

### CLI

```bash
yogeeshcode export <session> --format txt|html|pdf|json [--out file]
```

Default is `json` (backwards compatible). New formats: `txt`, `html`, `pdf`.

---

## Build System

### script/yogeesh-build.sh

1. Build CLI native binary via `bun run script/build.ts`
2. Package as `.zip` (darwin/win) or `.tar.gz` (linux)
3. Build VSIX via `npx @vscode/vsce package`
4. Write `release/install.sh` (one-click installer)
5. Write `release/version.txt`

### script/yogeesh-install.sh

Auto-detects OS + arch:
- darwin/linux -> `.tar.gz`
- windows -> `.zip`

Extracts to `~/.local/bin/yogeeshcode`, installs VSIX if code/cursor on PATH.

---

## Version Management

### script/version.sh

```bash
script/version.sh              # show current
script/version.sh bump patch   # 1.0.0 -> 1.0.1
script/version.sh bump minor   # 1.0.0 -> 1.1.0
script/version.sh bump major   # 1.0.0 -> 2.0.0
script/version.sh set 2.0.0    # explicit
```

Updates both `package.json` files + creates git tag.

### script/release.sh

```bash
script/release.sh --dry-run                # build only
script/release.sh                          # build + tag + push
script/release.sh --publish                # build + tag + GitHub release
script/release.sh --override --publish     # re-release same version
```

---

## Upstream Sync

### script/yogeesh-sync.sh

```bash
script/yogeesh-sync.sh --check     # show drift + branding diff
script/yogeesh-sync.sh --rebase    # fetch upstream + rebase onto it
```

### Conflict playbook

When rebasing onto upstream, keep "ours" on these files:
- `README.md`, `package.json` (root)
- `packages/core/src/global.ts`
- `packages/core/src/flag/flag.ts`
- `packages/opencode/src/config/paths.ts`
- `packages/opencode/bin/yogeeshcode`
- `packages/tui/src/logo.ts`
- `sdks/vscode/package.json`
- `sdks/vscode/src/extension.ts`
- `yogeeshcode.json.example`
- All `script/yogeesh-*.sh`
- All `docs/*.md`

See `UPSTREAM_MERGE.md` for full details.
