#!/usr/bin/env bash
# YogeeshCode version + release manager
#
# TWO independent version tracks:
#   yogeeshcode.version  — YOUR product version (root package.json -> yogeeshcode.version)
#   <base> version       — upstream OpenCode base (packages/opencode/package.json -> version)
#
# This way you can bump YOUR version without touching the base, and when upstream
# releases a new version, the base updates independently.
#
# Usage:
#   script/version.sh                      -> show both versions
#   script/version.sh bump patch           -> 1.0.0 -> 1.0.1  (YOUR version)
#   script/version.sh bump minor           -> 1.0.0 -> 1.1.0
#   script/version.sh bump major           -> 1.0.0 -> 2.0.0
#   script/version.sh bump base patch      -> bump base version
#   script/version.sh set 2.5.0            -> set YOUR version explicitly
#   script/version.sh set base 1.19.0      -> set base version explicitly
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Read versions from package.json files
# yogeeshcode.version lives in root package.json
get_yogeesh_version() {
  node -p "require('./package.json').yogeeshcode?.version || '0.0.0'"
}
# Base OpenCode version lives in packages/opencode/package.json
get_base_version() {
  node -p "require('./packages/opencode/package.json').version"
}

# Set YOUR version (root package.json -> yogeeshcode.version)
set_yogeesh_version() {
  local ver="$1"
  if ! echo "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: invalid semver: $ver" >&2; exit 1
  fi
  node -e "const fs=require('fs');const p='./package.json';const j=JSON.parse(fs.readFileSync(p));j.yogeeshcode.version='$ver';fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n')"
  echo "  package.json yogeeshcode.version -> $ver"
}

# Set BASE version (packages/opencode/package.json -> version)
set_base_version() {
  local ver="$1"
  if ! echo "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: invalid semver: $ver" >&2; exit 1
  fi
  node -e "const fs=require('fs');const p='./packages/opencode/package.json';const j=JSON.parse(fs.readFileSync(p));j.version='$ver';fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n')"
  echo "  packages/opencode/package.json version -> $ver"
}

bump_yogeesh() {
  local bump="$1"
  local cur=$(get_yogeesh_version)
  local major=$(echo "$cur" | cut -d. -f1)
  local minor=$(echo "$cur" | cut -d. -f2)
  local patch=$(echo "$cur" | cut -d. -f3)
  case "$bump" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
    *) echo "ERROR: unknown bump: $bump" >&2; exit 1 ;;
  esac
  set_yogeesh_version "${major}.${minor}.${patch}"
}

bump_base() {
  local bump="$1"
  local cur=$(get_base_version)
  local major=$(echo "$cur" | cut -d. -f1)
  local minor=$(echo "$cur" | cut -d. -f2)
  local patch=$(echo "$cur" | cut -d. -f3)
  case "$bump" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 10)) ;;
    *) echo "ERROR: unknown bump: $bump" >&2; exit 1 ;;
  esac
  set_base_version "${major}.${minor}.${patch}"
}

show_versions() {
  echo "YogeeshCode version : $(get_yogeesh_version)"
  echo "Base OpenCode      : $(get_base_version)"
}

case "${1:-show}" in
  show) show_versions ;;
  bump)
    case "${2:-}" in
      base) bump_base "${3:-patch}" ;;
      *)    bump_yogeesh "${2:-patch}" ;;
    esac
    show_versions
    ;;
  set)
    case "${2:-}" in
      base) set_base_version "$3" ;;
      *)    set_yogeesh_version "$2" ;;
    esac
    show_versions
    ;;
  *) echo "usage: script/version.sh [show|bump patch|minor|major|base patch|set X.Y.Z|set base X.Y.Z]" >&2; exit 1 ;;
esac