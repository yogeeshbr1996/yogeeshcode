# Upstream merge (sync from sst/opencode)

SST ships most features on their `dev` branch. Since YogeeshCode keeps almost
all upstream file paths intact and only touches a handful of branded files,
merging upstream is cheap.

## One-time setup (already done by helper script)

```bash
git remote add upstream https://github.com/sst/opencode.git
git fetch upstream
```

## Sync (safe recipe)

```bash
# 0) fresh state only - commit or stash your WIP first
git checkout yogeeshcode-rebrand

# 1) pull latest upstream
git fetch upstream

# 2) replay upstream onto our branch
git rebase upstream/dev
#    OR squash-merge style instead:
#    git merge upstream/dev --no-edit

# 3) resolve conflicts - ONLY in upstream-touched files.
#    Our branded files (rarely touched upstream) may conflict on:
#    - README.md            -> keep YogeeshCode branding
#    - package.json         -> keep "name": "yogeeshcode"
#    - packages/core/src/global.ts        (dir name)
#    - packages/opencode/bin/yogeeshcode  (ours only)
#    - sdks/vscode/package.json + src/extension.ts (brands)
#    - packages/opencode/src/session/retry.ts      (fallthrough)
#    - packages/opencode/src/session/model-fallthrough.ts (ours only)
#    Never take "theirs" blindly on those; that reverts branding.

# 4) reinstall + verify
bun install
bun run --cwd packages/opencode src/index.ts --version
cd packages/opencode && bun test test/export-format.test.ts

# 5) push
git push
```

## Script

```bash
# fetch upstream + report how far behind we are
script/yogeesh-sync.sh --check

# fetch + rebase ours onto upstream/dev (keeps history linear)
script/yogeesh-sync.sh --rebase
```

> Tip: keep our branded deltas in as FEW files as possible so future merges
> stay trivial. Review `git diff upstream/dev...yogeeshcode-rebrand --stat`
> after each sync.