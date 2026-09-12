#!/usr/bin/env bash
# YogeeshCode helper: sync from upstream sst/opencode (dev).
# Usage:
#   script/yogeesh-sync.sh --check    # fetch upstream + report drift
#   script/yogeesh-sync.sh --rebase   # fetch + rebase current branch onto upstream/dev
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

REMOTE_URL=${YOGEESH_UPSTREAM_URL:-https://github.com/sst/opencode.git}
BRANCH=$(git branch --show-current)

if ! git remote | grep -q "^upstream$"; then
  echo "[sync] adding upstream remote -> $REMOTE_URL"
  git remote add upstream "$REMOTE_URL"
fi

echo "[sync] fetching upstream..."
git fetch upstream

case "${1:---check}" in
  --check)
    echo "[sync] branch: $BRANCH"
    echo "[sync] behind upstream/dev by:"
    git rev-list --left-right --count upstream/dev...HEAD
    echo "[sync] files we changed vs upstream (branding surface):"
    git diff --stat upstream/dev...HEAD
    ;;
  --rebase)
    echo "[sync] rebasing $BRANCH onto upstream/dev..."
    git rebase upstream/dev
    echo "[sync] DONE. Next: bun install && bun run --cwd packages/opencode src/index.ts --version"
    ;;
  *)
    echo "usage: $0 [--check|--rebase]" >&2
    exit 1
    ;;
esac