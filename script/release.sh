#!/usr/bin/env bash
# YogeeshCode release — build, tag, and publish to GitHub Releases.
# Only runs when YOU explicitly call it.
#
# Usage:
#   script/release.sh                  # build + create draft release (no publish)
#   script/release.sh --publish        # build + publish to GitHub Releases
#   script/release.sh --override       # allow re-releasing same version (force)
#   script/release.sh --dry-run        # build only, no tag, no publish
#
# Version comes from script/version.sh (semver in package.json).
# Override same version: moves tag v<VERSION> to current commit.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PUBLISH=false
OVERRIDE=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --publish) PUBLISH=true ;;
    --override) OVERRIDE=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "unknown flag: $arg" >&2; exit 1 ;;
  esac
done

VERSION="$(script/version.sh show)"
TAG="v${VERSION}"
echo "=========================================="
echo " YogeeshCode release"
echo "  version : $VERSION"
echo "  tag     : $TAG"
echo "  publish : $PUBLISH"
echo "  override: $OVERRIDE"
echo "  dry-run : $DRY_RUN"
echo "=========================================="

# Check git status
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "ERROR: uncommitted changes. Commit first." >&2
  git status --short
  exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
  if $OVERRIDE; then
    echo "  Tag $TAG exists. Deleting (override)..."
    git tag -d "$TAG" 2>/dev/null || true
    git push origin ":refs/tags/$TAG" 2>/dev/null || true
  else
    echo "ERROR: tag $TAG already exists. Bump version first or use --override." >&2
    exit 1
  fi
fi

# Build
echo ""
echo "--- Building artifacts ---"
script/yogeesh-build.sh

if $DRY_RUN; then
  echo ""
  echo "--- DRY RUN complete ---"
  echo "  release/ artifacts built, no tag, no publish"
  ls -lh release/ 2>/dev/null | tail -n 20
  exit 0
fi

# Generate release notes
RELEASE_NOTES="release/RELEASE_NOTES.md"
cat > "$RELEASE_NOTES" <<EOF
# YogeeshCode v${VERSION}

## Install
\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/yogeeshbr1996/yogeeshcode/yogeeshcode-rebrand/release/install.sh | bash
\`\`\`

## Free models (default config)
- Gemini Flash (free tier) — planner
- OpenRouter :free — Nex Pro, GLM 4.5 Air, Qwen3 Coder, DeepSeek, Kimi K2
- Groq free — Llama 70B, Qwen 32B
- Ollama local — qwen2.5-coder

## What's new
$(git log --oneline --no-walk --format="- %s" HEAD 2>/dev/null || echo "- release $VERSION")

## Artifacts
- CLI: yogeeshcode-${VERSION}-<os>-<arch>.tar.gz
- VS Code ext: yogeeshcode-${VERSION}.vsix
EOF

# Commit release notes + version
git add -A
git commit -m "Release v${VERSION}" --allow-empty

# Create tag
git tag -a "$TAG" -m "YogeeshCode v${VERSION}"

# Push
git push origin yogeeshcode-rebrand
git push origin "$TAG"

if $PUBLISH; then
  echo ""
  echo "--- Publishing to GitHub Releases ---"
  if gh release view "$TAG" >/dev/null 2>&1; then
    # Release exists — upload with override
    gh release upload "$TAG" release/* --clobber
  else
    gh release create "$TAG" release/* \
      --title "YogeeshCode v${VERSION}" \
      --notes-file "$RELEASE_NOTES"
  fi
  echo "  Published: https://github.com/yogeeshbr1996/yogeeshcode/releases/tag/$TAG"
fi

echo ""
echo "=========================================="
echo " Release v${VERSION} complete"
echo "=========================================="