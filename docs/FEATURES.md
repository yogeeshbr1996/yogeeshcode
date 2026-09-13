# YogeeshCode Features

Complete feature reference for the YogeeshCode AI coding agent.

## Table of Contents

1. [What is YogeeshCode](#what-is-yogeeshcode)
2. [Free Model System](#free-model-system)
3. [Rate Limit Fallthrough](#rate-limit-fallthrough)
4. [Permission Autopilot](#permission-autopilot)
5. [Conversation Export](#conversation-export)
6. [Build and Release](#build-and-release)
7. [Version Management](#version-management)
8. [Upstream Sync](#upstream-sync)
9. [VS Code Extension](#vs-code-extension)
10. [Desktop App](#desktop-app)

---

## What is YogeeshCode

YogeeshCode is a fork of [OpenCode](https://github.com/sst/opencode) (MIT license), a terminal-based AI coding agent. It adds free-model-first design, rate limit fallthrough, permission autopilot, conversation export, one-click installer, and semver versioning.

---

## Free Model System

### Architecture

User prompt goes to primary model (Gemini Flash free). On rate limit (429), model ranker rotates to next in list. Cycle continues forever, local model is last resort (unlimited).

### Model Ranking

Models ranked by coding quality (based on Aider polyglot, SWE-bench benchmarks):

| Rank | Model | Context | Best For |
|------|-------|---------|----------|
| 1 | Gemini 2.5 Flash (free) | 1M | Planning, large codebases |
| 2 | Nex N2.5 Pro :free | 262K | Agentic coding |
| 3 | Nex N2.5 Mini :free | 262K | Fast agentic |
| 4 | Qwen3 Coder :free | 128K | Code edits and diffs |
| 5 | DeepSeek Chat :free | 128K | Execution |
| 6 | Llama 3.3 70B :free | 80K | General coding |
| 7+ | Groq, DeepSeek direct, Mistral, HF, Cloudflare, Together, Cerebras, Perplexity, GitHub Models, NVIDIA NIM, Zhipu GLM-4-Flash | varies | Fallback |
| last | Ollama local | varies | Unlimited fallback |


---

## Rate Limit Fallthrough

When a model returns 429, 401, 403, or 5xx: mark cooldown on failing model, walk ranked list skipping cooled-down models, pick next healthy model, swap streamInput.model, retry. If all are cooling down, wait with escalating backoff and retry. With max_attempts=100, it cycles until one works.

Status bar shows: "Free tier rate limited - rotating models, attempt N/100 -> next-model"

---

## Permission Autopilot

Auto-approved: read, edit, glob, grep, LSP, web fetch/search, task, safe terminal (ls, cat, git status, git diff, npm, bun, node, tsc, eslint, python3, cargo, go, make, cp, mv).

Denied: rm -rf, rm -fr, sudo, chmod 777, ssh, git reset --hard, git clean -fd, git push --force, format, mkfs, dd, kill -9.

---

## Conversation Export

yogeeshcode export session --format txt|html|pdf|json [--out file]

txt = plain transcript. html = styled chat (print to PDF in browser). pdf = minimal valid PDF writer (no deps). json = full structured data (default).

---

## Build and Release

script/yogeesh-build.sh builds current platform plus VSIX into release/. script/yogeesh-build.sh --full builds all platforms (darwin/linux/win, arm64+x64).

Release folder: yogeeshcode-ver-darwin-arm64.zip, linux-x64.tar.gz, windows-x64.zip, .vsix, install.sh, version.txt.

One-click install: curl -fsSL https://raw.githubusercontent.com/yogeeshbr1996/yogeeshcode/yogeeshcode-rebrand/release/install.sh | bash

Installs to ~/.local/bin/yogeeshcode, auto-installs VSIX if code/cursor/codium/windsurf CLI is on PATH.

---

## Version Management

script/version.sh shows current. bump patch/minor/major increments. set X.Y.Z sets explicit. Updates both package.json files and creates git tag.

---

## Upstream Sync

script/yogeesh-sync.sh --check shows drift plus branding diff. --rebase fetches upstream and rebases onto it. See UPSTREAM_MERGE.md for conflict playbook.

---

## VS Code Extension

code --install-extension release/yogeeshcode-ver.vsix. Keybindings: Cmd+Esc opens split terminal, Cmd+Shift+Esc new session, Cmd+Opt+K inserts @File#L for selection.

---

## Desktop App

cd packages/desktop && bun install && bun run package:mac. Outputs to packages/desktop/dist/*.dmg.

---

## Test Automation

script/yogeesh-test.sh full (30 checks). --quick skips slow unit tests. --network also hits models.dev live.

Checks: config valid JSON, permission autopilot rules, CLI boots, unit tests, export command wired, VSCode ext branded, shell scripts syntax, models.dev sanity, version plus release managers dry-run.

Ask: git push, git rebase, kill, docker, curl POST/PUT/DELETE, wget write, brew install, npm install -g, pip install, everything else.

CLI: yogeeshcode --auto approves all except denies. yogeeshcode --no-auto asks for everything. TUI: Ctrl+P toggles mode.

Backoff: attempts 1-5 immediate, 6+ exponential (2^n, cap 120s). Cooldown models skipped. When cooldown expires, model becomes available again.
### Provider Categories

**No auth required (truly free):** Pollinations (keyless, unlimited).

**Free tier (auth via yogeeshcode auth login, device OAuth):** OpenCode Zen (31 free models from models.dev), Gemini (AI Studio), OpenRouter :free, Groq, DeepSeek direct, Mistral, HuggingFace, Cloudflare Workers AI, Together AI, Cerebras, Perplexity, GitHub Models, NVIDIA NIM, Zhipu GLM-4-Flash.

**Paid (opt-in only):** Any model can be added manually in config.

### Configuration

Set yogeeshcode.free_models_only to true to show only free models. Set model_ranker.auto to true to auto-rotate on rate limits. Set cooldown_ms for retry wait time. Set max_attempts for retry cap (100 = effectively never).