# YogeeshCode Upstream Merge Strategy

How to merge new `sst/opencode` releases **without losing any of your changes**.

## Version Scheme

Two independent version tracks (so base and yours never collide):

| Track | Where | Example |
|---|---|---|
| **YogeeshCode** (yours) | `package.json` -> `yogeeshcode.version` | `1.0.0`, `1.1.0`, `2.0.0` |
| **Base OpenCode** | `packages/opencode/package.json` -> `version` | `1.18.30`, `1.19.0` |

`script/version.sh` shows both:
```bash
script/version.sh              # YogeeshCode 1.0.0 / Base 1.18.30
script/version.sh bump patch   # bump YOUR version: 1.0.0 -> 1.0.1
script/version.sh bump base patch  # bump BASE version: 1.18.30 -> 1.18.40
```

`--version` output shows both:
```
$ yogeeshcode --version
YogeeshCode 1.0.0 (base OpenCode 1.18.30)
```

## How merges work (3 layers)

### Layer 1: `.gitattributes` auto-resolution (trivial conflicts)
All branded/customized files are tagged `merge=ours` in `.gitattributes`. When
both you and upstream modify the same file, git **automatically keeps YOUR
version** — no manual resolution needed.

Files covered: branding (logo, README, global.ts), config (paths, config.ts),
all YogeeshCode features (retry, fallthrough, model-registry, export-format),
build scripts, VSCode extension, desktop, lockfiles.

### Layer 2: `script/yogeesh-merge.sh` (rebase with auto-conflict handling)
When upstream makes deeper changes that conflict with your patches:
```bash
script/yogeesh-merge.sh --check       # preview what would change
ls conflicted_files.txt                # list of files that need attention
script/yogeesh-merge.sh                # rebase + auto-resolve trivial conflicts
./conflicted_files.txt                 # manually fix remaining files
git rebase --continue                  # finish
```

The script:
1. Stashes your uncommitted work
2. Fetches upstream/dev
3. Starts rebase onto upstream/dev
4. For each conflict:
   - If the file is in `.gitattributes` `merge=ours` → auto-resolve with YOUR version
   - If the conflict is in a source file you've modified (processor.ts, prompt.ts, etc.) → auto-resolve by applying YOUR changes on top of the new upstream base
   - Otherwise → pause and let you resolve manually
5. After rebase: runs `bun install` to update lockfiles

### Layer 3: Manual patch re-application (rare structural changes)
If upstream restructures a file you've patched (e.g., processor.ts gets split
into multiple files):
```bash
# Find your patch
git log --oneline --all -- packages/opencode/src/session/processor.ts

# Extract your changes as a patch
git show <commit> -- packages/opencode/src/session/processor.ts > /tmp/my.patch

# After rebase, re-apply manually
git apply --3way /tmp/my.patch
# or manually copy your logic into the new file structure
```

## Step-by-step: when sst/opencode releases a new version

```bash
# 1. Check what's new
script/yogeesh-merge.sh --check

# 2. See which files you've customized (that upstream also touched)
git diff --name-only upstream/dev...HEAD

# 3. Do the rebase (auto-resolves trivial conflicts)
script/yogeesh-merge.sh

# 4. Fix any remaining conflicts manually
vim <conflicted files>
git add -A && git rebase --continue

# 5. Update the BASE version to match new upstream
script/version.sh set base 1.19.0   # <-- new upstream version

# 6. Bump YOUR version (since you merged new upstream)
script/version.sh bump minor        # 1.0.0 -> 1.1.0

# 7. Verify everything builds
bun install
bun run typecheck
bun run --cwd packages/opencode src/index.ts --version
# Should show: YogeeshCode 1.1.0 (base OpenCode 119.0)

# 8. Run tests
bun test

# 9. Commit + tag + release
script/release.sh --publish
```

## Files you OWN (never take upstream version)

These are listed in `.gitattributes` with `merge=ours`:
- All `script/` files
- `packages/core/src/global.ts`, `flag/flag.ts`, `installation/yogeesh-version.ts`
- `packages/opencode/bin/yogeeshcode`
- `packages/opencode/src/config/paths.ts`, `config/config.ts`
- `packages/tui/src/logo.ts`
- All YogeeshCode feature files (retry, fallthrough, model-registry, export, etc.)
- `sdks/vscode/*` (entire VSCode extension)
- `packages/desktop/*` (entire Desktop app)
- `README.md`, `UPSTREAM_MERGE.md`, `.gitattributes`, `.gitignore`
- All lockfiles (bun.lock)

## Files you WANT from upstream (auto-merge)

- `packages/opencode/src/cli/cmd/run/` — new CLI commands
- `packages/opencode/src/provider/provider.ts` — new providers
- `packages/opencode/src/session/summary.ts` — summary improvements
- `packages/app/*`, `packages/web/*` — new web UI
- `packages/opencode/script/generate.ts` — model data generation
- Dependencies in workspace package.json files (not root)

## Tracking your custom patches

Each YogeeshCode feature is in its own file or clearly marked with comments:

```typescript
// YogeeshCode: ranked free-model fallthrough
// YogeeshCode: rate-limit fallthrough with cooldowns
// YogeeshCode: model registry auto-refresh
```

To find ALL your changes vs upstream:
```bash
git log --oneline --all -- 'packages/opencode/src/session/retry.ts'   'packages/opencode/src/session/model-fallthrough.ts'   'packages/opencode/src/session/export-format.ts'   'packages/opencode/src/session/processor.ts'   'packages/opencode/src/session/prompt.ts'   'packages/opencode/src/provider/model-registry.ts'   'packages/opencode/src/cli/cmd/registry.ts'
```

## Emergency: undo a bad merge

```bash
# Abort in-progress rebase
git rebase --abort

# Reset to before merge attempt
git reset --hard origin/yogeeshcode-rebrand

# Or go back to a specific good commit
git reset --hard <good-commit-sha>
git push --force-with-lease origin yogeeshcode-rebrand
```
