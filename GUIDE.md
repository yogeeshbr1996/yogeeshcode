# YogeeshCode — Free-Model-First AI Coding Assistant

> A free-model-first AI coding assistant — forked from [sst/opencode](https://github.com/sst/opencode) (MIT).
> Rebranded as **YogeeshCode**. 25 providers, 132 free models, zero cost.

## What is YogeeshCode?

YogeeshCode is an IDE/CLI that uses **only free AI models** for coding. It auto-rotates between 132+ free models when rate limits hit, so you never pay and never stop.

Built from the official OpenCode codebase with:
- Free-model-first ranking (never picks paid unless you force it)
- Rate-limit fallthrough with cooldowns + escalating backoff
- Conversation export (txt / html / pdf)
- Auto-refreshing model registry (12h default)
- Bulletproof upstream merge strategy
- Version scheme: OpenCode `1.18.30` → YogeeshCode `1.18.30.1`

## Version Scheme

| OpenCode (base) | YogeeshCode | Meaning |
|---|---|---|
| `1.2.2` | `1.2.2.1` | First patch on OpenCode 1.2.2 |
| `1.2.2` | `1.2.2.2` | Second patch on OpenCode 1.2.2 |
| `1.18.30` | `1.18.30.1` | First patch on OpenCode 1.18.30 |

```bash
script/version.sh                  # show both versions
script/version.sh bump             # 1.18.30.1 -> 1.18.30.2 (increment our patch)
script/version.sh bump patch       # bump OpenCode patch, reset our patch
script/version.sh bump minor       # bump OpenCode minor, reset our patch
script/version.sh bump major       # bump OpenCode major, reset our patch
script/version.sh set-base 1.19.0  # set new base OpenCode version (after upstream merge)
script/version.sh set 1.18.30.5    # set explicit YogeeshCode version
```

## Build & Release

```bash
# Build current platform + VSIX into release/
script/yogeesh-build.sh

# Build ALL platforms (darwin/linux x64+arm64, windows x64+arm64)
script/yogeesh-build.sh --full

# Build specific target
script/yogeesh-build.sh cli
script/yogeesh-build.sh vscode
script/yogeesh-build.sh desktop

# Install from release/
bash release/install.sh

# One-liner from GitHub
curl -fsSL https://raw.githubusercontent.com/yogeeshbr1996/yogeeshcode/yogeeshcode-rebrand/release/install.sh | bash
```

### Release workflow
```bash
script/release.sh --dry-run    # build only, no tag
script/release.sh             # build + tag + push (draft)
script/release.sh --publish   # build + tag + publish to GitHub Releases
script/release.sh --override --publish  # re-release same version (force)
```

## Configuration

Copy the example config:
```bash
cp yogeeshcode.json.example ~/.yogeeshcode/yogeeshcode.json
```

Then set your API keys:
```bash
export OPENROUTER_API_KEY="..."
export GEMINI_API_KEY="..."
export GROQ_API_KEY="..."
export DEEPSEEK_API_KEY="..."
export MISTRAL_API_KEY="..."
export TOGETHER_API_KEY="..."
export HF_API_KEY="..."
export CF_API_KEY="..."
export CEREBRAS_API_KEY="..."
export PERPLEXITY_API_KEY="..."
```

Or run `ollama serve` for local-only (unlimited, free).

## Free Models (132 models, 25 providers)

| Provider | Models | Best for |
|---|---|---|
| **Gemini free** | 2.5 Flash, 2.0 Flash, 2.5 Pro | Planner (1M ctx) |
| **OpenRouter free** | Nex N2.5 Pro/Mini, Qwen3 Coder, DeepSeek V3/R1, Llama 3.3/3.1-405B, Qwen3 235B, Mistral, Phi-3, Claude 3.5 Haiku | Agentic coding, reasoning |
| **Groq free** | Llama 3.3 70B, QwQ 32B, Llama 3.1 70B/8B | Fast executor |
| **DeepInfra** | Llama 3.3/3.1 70B, Qwen2.5 Coder 32B, DeepSeek R1, Phi-3 | Open models |
| **Novita** | Llama 3.3/3.1 70B, Qwen2.5 Coder, DeepSeek R1 | Fast coding |
| **SambaNova** | Llama 3.3/3.1 70B, Qwen2.5 Coder, DeepSeek R1 | Fast |
| **Poe** | GPT-4o Mini, Claude 3.5 Haiku, Llama 3.1, Qwen2.5 Coder, DeepSeek R1 | Multi-model |
| **watsonx (IBM)** | Llama 3.3/3.1 70B, Granite 3 8B/2B | Enterprise |
| **Vertex AI** | Gemini 2.5 Flash, 2.0 Flash ($300 credit) | Google Cloud |
| **Together** | Llama 3.3 70B Turbo, Qwen2.5 Coder, DeepSeek R1 | Fast coding |
| **HuggingFace** | Llama 3.1 70B/8B, Qwen2.5 Coder 32B, DeepSeek R1, Phi-3, Gemma 2 27B | Open models |
| **Fireworks** | Llama 3.1 70B, Qwen2.5 Coder 32B, DeepSeek R1 | Fast |
| **NVIDIA** | Llama 3.1 70B, Qwen2.5 Coder 32B, DeepSeek R1, Mistral Large | Hardware |
| **Cohere** | Command R+, R, R7B, Aya Expanse 32B | Reasoning |
| **Lepton** | Llama 3.1 70B, Qwen2.5 Coder, DeepSeek R1 | Fast |
| **Friendli** | Llama 3.1 70B/8B, Qwen2.5 Coder | Fast |
| **Predibase** | Llama 3.1 70B, Qwen2.5 Coder | Fast |
| **Baseten** | Llama 3.1/3.3 70B | Inference |
| **Cortex** | GPT-4o Mini, Claude 3.5 Haiku, Llama 3.1 | Edge |
| **DeepSeek direct** | V3, R1 | Reasoning |
| **Mistral direct** | 7B, Mixtral 8x7B | Small/fast |
| **Cloudflare** | Llama 3.1 8B, Llama 3.3 70B, Qwen 1.5 14B, Mistral 7B | Edge |
| **Cerebras** | Llama 3.1 70B/8B | Very fast |
| **Perplexity** | Llama 3.1 Sonar Large/Small | Online search |
| **Ollama (local)** | Qwen2.5/3 Coder, DeepSeek R1, Llama 3.3/3.1, CodeLlama, GPT-OSS | Local unlimited |

### Ranking Order
Auto-rotates on 429 rate limits: `Gemini → Nex Pro → Nex Mini → Qwen3 Coder → DeepSeek → Llama 70B → Groq → DeepInfra → Novita → SambaNova → Poe → watsonx → Vertex → Together → HuggingFace → Fireworks → NVIDIA → Cohere → Lepton → Friendli → Predibase → Baseten → Cortex → DeepSeek direct → Mistral → Cloudflare → Cerebras → Perplexity → Ollama local`

## Model Registry (Auto-Refresh)

```bash
yogeeshcode registry              # status: last refresh, next due, count
yogeeshcode registry refresh      # auto-refresh (if 12h elapsed)
yogeeshcode registry force        # force refresh NOW (ignores interval)
yogeeshcode registry list         # show all cached free models
```

Settings in `~/.yogeeshcode/yogeeshcode.json`:
```json
{
  "yogeeshcode": {
    "auto_refresh_min": 720,
    "free_models_only": true,
    "max_attempts": 200,
    "cooldown_ms": 60000
  }
}
```

## Conversation Export

```bash
yogeeshcode export <session> --format txt|html|pdf [--out file]
```

- `txt` = clean transcript
- `html` = styled chat (prints to PDF from browser)
- `pdf` = minimal valid PDF writer
- `json` = full data (default)

## Rate-Limit Fallthrough

Never stops on rate limits:
- Per-model **cooldown** (60s default) — a 429/5xx model gets a timeout before retry
- **Escalating backoff** — retry-after → 2^n exponential → 120s cap
- **Ranked rotation** → next model in the free list
- **max_attempts: 200** — keeps trying all 132 models before giving up

## Upstream Merge (New OpenCode Releases)

When `sst/opencode` releases a new version:

```bash
# One command to merge upstream changes
script/yogeesh-sync.sh --rebase

# Review what changed
script/yogeesh-sync.sh --check

# Bump your version to reflect new base
script/version.sh bump patch   # or minor/major

# Rebuild release
script/yogeesh-build.sh

# Push
git push origin yogeeshcode-rebrand
```

### How it works
- `.gitattributes` marks branded files as `merge=ours` — Git keeps YOUR version automatically
- Your commits are **replayed on top** of whatever upstream just released
- Conflicts only in files NOT marked `merge=ours` — auto-resolved

### Files protected from upstream merge
```
README.md
package.json
packages/core/src/global.ts
packages/tui/src/logo.ts
yogeeshcode.json.example
sdks/vscode/package.json
UPSTREAM_MERGE.md
script/version.sh
script/yogeesh-sync.sh
```

## Project Structure

```
yogeeshcode/
├── package.json                    # Root config (YogeeshCode version)
├── packages/
│   ├── opencode/               # CLI/TUI (OpenCode base version)
│   ─── tui/                    # Terminal UI
│   ─── core/                   # Core utilities
│   ─── desktop/                # Desktop app (Electron)
│   ─── app/                    # Web app
│   ─── install/                # Installer scripts
│   ─── plugin/                 # Plugin system
│   ─── sdk/                    # SDK
│   ─── validate/               # Validation
├── sdks/vscode/                   # VS Code extension
├── script/                      # Build scripts
│   ├── version.sh            # Version manager
│   ├── release.sh            # Release manager
│   ├── yogeesh-build.sh      # Build all platforms
│   ├── yogeesh-install.sh    # Install from release/
│   ─── yogeesh-sync.sh       # Upstream merge helper
├── yogeeshcode.json.example      # Free-model config
├── UPSTREAM_MERGE.md             # Merge strategy details
├── GUIDE.md                      # This file
└── release/                      # Build output (gitignored)
```

## Commands Reference

```bash
# Basic
yogeeshcode --version             # Show version
yogeeshcode --help                # Show help
yogeeshcode run "prompt"           # Run a prompt
yogeeshcode                       # Interactive TUI

# Models
yogeeshcode models                # List available models
yogeeshcode model <name>          # Switch model

# Registry
yogeeshcode registry status       # Last refresh, next due, count
yogeeshcode registry refresh      # Auto-refresh (if 12h elapsed)
yogeeshcode registry force        # Force refresh NOW
yogeeshcode registry list         # Show all cached models

# Export
yogeeshcode export <session> --format txt|html|pdf

# VS Code
# Cmd+Esc = split terminal with YogeeshCode
# Cmd+Shift+Esc = new session
# Cmd+Opt+K = insert @File#L37-42

# Desktop
cd packages/desktop && bun run package:mac
```

## License

MIT — forked from [sst/opencode](https://github.com/sst/opencode). Not affiliated with OpenCode.

## Links

- Repo: https://github.com/yogeeshbr1996/yogeeshcode
- Branch: `yogeeshcode-rebrand`
- Upstream: https://github.com/sst/opencode
