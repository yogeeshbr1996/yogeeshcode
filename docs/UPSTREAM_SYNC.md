# Upstream Sync

How to merge updates from [sst/opencode](https://github.com/sst/opencode) without losing our changes.

## Setup

```bash
# Add upstream remote (one-time)
git remote add upstream https://github.com/sst/opencode.git

# Fetch upstream
git fetch upstream
```

## Check Drift

```bash
script/yogeesh-sync.sh --check
```

Shows:
- Commits ahead/behind upstream
- Files that differ (branding check)

## Rebase

```bash
script/yogeesh-sync.sh --rebase
```

Fetches upstream and rebases our `yogeeshcode-rebrand` branch onto `upstream/dev`.

## Conflict Resolution

When rebasing, conflicts may arise. Here's how to resolve:

### Keep OURS (our branding)

```bash
git checkout --ours README.md package.json packages/core/src/global.ts packages/core/src/flag/flag.ts packages/opencode/src/config/paths.ts packages/opencode/bin/yogeeshcode packages/tui/src/logo.ts sdks/vscode/package.json sdks/vscode/src/extension.ts yogeeshcode.json.example script/yogeesh-*.sh docs/*.md
```

### Keep THEIRS (upstream code)

```bash
git checkout --theirs packages/opencode/src/session/*.ts packages/opencode/src/provider/*.ts packages/opencode/src/cli/*.ts packages/tui/src/**/*.tsx packages/core/src/**/*.ts sdks/vscode/src/**/*.ts
```

### After resolving

```bash
git add -A
git rebase --continue
```

## Files That Always Conflict

These files are our branding — always keep ours:

| File | Why |
|---|---|
| `README.md` | Our fork notice |
| `package.json` (root) | Our name `yogeeshcode` |
| `packages/core/src/global.ts` | `app: "yogeeshcode"` |
| `packages/core/src/flag/flag.ts` | `YOGEESHCODE_CONFIG_DIR` |
| `packages/opencode/src/config/paths.ts` | `.yogeeshcode` dir |
| `packages/opencode/bin/yogeeshcode` | Our launcher |
| `packages/tui/src/logo.ts` | Our logo |
| `sdks/vscode/package.json` | Our publisher |
| `sdks/vscode/src/extension.ts` | Our terminal name |
| `yogeeshcode.json.example` | Our free-model config |
| `script/yogeesh-*.sh` | Our scripts |
| `docs/*.md` | Our docs |
| `UPSTREAM_MERGE.md` | Our playbook |

## Automation

The sync script handles most of this:

```bash
# Check only
script/yogeesh-sync.sh --check

# Full rebase with auto-conflict-resolution for branding files
script/yogeesh-sync.sh --rebase
```
