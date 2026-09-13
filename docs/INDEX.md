# YogeeshCode Documentation

> Complete reference for the YogeeshCode fork — a free-model-first AI coding agent forked from [sst/opencode](https://github.com/sst/opencode) (MIT).

## Quick Start

```bash
# Build current platform
script/yogeesh-build.sh

# Install from release
bash release/install.sh

# Run
yogeeshcode --help
```

## Docs Index

| Document | What it covers |
|---|---|
| **[IMPLEMENTATION.md](./IMPLEMENTATION.md)** | Every feature we added: rebrand, export, rate-limit fallthrough, model ranker, permissions, build system |
| **[FREE_MODELS.md](./FREE_MODELS.md)** | All 50+ free models: sources, context windows, rate limits, auth requirements |
| **[PERMISSIONS.md](./PERMISSIONS.md)** | Autopilot permission system: auto-approve, deny, ask rules |
| **[RELEASE_WORKFLOW.md](./RELEASE_WORKFLOW.md)** | Versioning, building, releasing, installers |
| **[UPSTREAM_SYNC.md](./UPSTREAM_SYNC.md)** | How to merge upstream sst/opencode updates without losing our changes |

## Repo Structure

```
yogeeshcode/
├── script/
│   ├── yogeesh-build.sh      # Build CLI + VSIX + installer → release/
│   ├── yogeesh-install.sh    # One-click installer (auto-detect OS/arch)
│   ├── version.sh            # Semver manager (show/bump/set)
│   ├── release.sh            # Release manager (dry-run/publish/override)
│   ├── yogeesh-sync.sh       # Upstream sync helper
│   └── yogeesh-test.sh       # Automated test suite (30 checks)
├── release/                   # Build artifacts (gitignored, force-added)
├── docs/                      # This documentation
├── packages/
│   ├── opencode/              # Core CLI + TUI (our main changes here)
│   ├── tui/                   # Terminal UI (model tier badges, permission dialogs)
│   ├── desktop/               # Electron desktop app (BETA)
│   ├── core/                  # Shared core (global app name, flags)
│   └── app/                   # Web app
├── sdks/vscode/               # VS Code/Cursor/Windsurf extension
└── yogeeshcode.json.example   # Default config (free-model-first)
```

## Key Design Decisions

1. **Free-model-first**: Default config has 50+ free models, 12 providers. Paid is opt-in only.
2. **Never-stop fallthrough**: On 429/5xx, auto-rotates ranked list with cooldowns. Max 100 attempts.
3. **Permission autopilot**: Edits + safe terminal auto-approved. Risky (`rm -rf`, `sudo`) denied. Medium asks.
4. **Semver releases**: `script/version.sh` manages versions. `script/release.sh` builds + tags + publishes.
5. **One-click install**: `release/install.sh` auto-detects OS/arch, installs CLI + VSIX.
6. **Internal imports kept**: `@opencode-ai/*` imports NOT renamed (7000+ refs). Only user-visible surface rebranded.

## Git Branches

- `yogeeshcode-rebrand` — our main branch (all changes)
- `dev` — upstream tracking (read-only, rebase target)

## Commits (newest first)

| Commit | Description |
|---|---|
| `1d03a24e4e` | Release v1.0.0: darwin-arm64 + VSIX + installer |
| `55d5349a2d` | Fix scriptName branding, 30/30 tests pass |
| `055a01589c` | Free cloud-only, models.dev + Zen integrated, autopilot permissions |
| `33dad1dd48` | All free models (50+, 12 providers) |
| `fbc70eed1b` | Semver versioning + release manager |
| `d122d61c9a` | Release folder + free-model-first config |
| `53bab978ef` | Build + install scripts |
| `99724ba0bc` | Export txt/html/pdf, rate-limit fallthrough |
| `ac2cf35471` | Rebrand: yogeeshcode binary + ~/.yogeeshcode + VSCode ext |
