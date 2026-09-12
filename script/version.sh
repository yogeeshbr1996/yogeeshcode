#!/usr/bin/env bash
# YogeeshCode version + release manager
# Usage:
#   script/version.sh              -> show current version
#   script/version.sh bump patch   -> 1.18.30 -> 1.18.40
#   script/version.sh bump minor   -> 1.18.30 -> 1.19.0
#   script/version.sh bump major   -> 1.18.30 -> 2.0.0
#   script/version.sh set 2.5.0    -> set explicit version
#
# Releases only happen when YOU decide. Same version can be re-released (override).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

get_version() {
  node -p "require('./packages/opencode/package.json').version"
}

set_version() {
  local ver="$1"
  if ! echo "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: invalid semver: $ver" >&2; exit 1
  fi
  for pkg in packages/opencode/package.json packages/desktop/package.json sdks/vscode/package.json; do
    [ -f "$pkg" ] || continue
    node -e "const fs=require('fs');const p='$pkg';const j=JSON.parse(fs.readFileSync(p));j.version='$ver';fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n')"
    echo "  $pkg -> $ver"
  done
}

bump_version() {
  local bump="$1"
  local cur=$(get_version)
  local major=$(echo "$cur" | cut -d. -f1)
  local minor=$(echo "$cur" | cut -d. -f2)
  local patch=$(echo "$cur" | cut -d. -f3)
  case "$bump" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 10)) ;;
    *) echo "ERROR: unknown bump: $bump" >&2; exit 1 ;;
  esac
  set_version "${major}.${minor}.${patch}"
}

case "${1:-show}" in
  show) get_version ;;
  bump) bump_version "${2:-patch}" ;;
  set) set_version "$2" ;;
  *) echo "usage: script/version.sh [show|bump patch|minor|major|set X.Y.Z]" >&2; exit 1 ;;
esac