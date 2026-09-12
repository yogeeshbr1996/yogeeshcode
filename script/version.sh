#!/usr/bin/env bash
# YogeeshCode version manager
#
# VERSION SCHEME:
#   OpenCode version: 1.18.30 (base upstream)
#   YogeeshCode version: 1.18.30.N (N = our patch number)
#
# Examples:
#   OpenCode 1.2.2 -> YogeeshCode 1.2.2.1, 1.2.2.2, 1.2.2.3 ...
#   OpenCode 1.18.30 -> YogeeshCode 1.18.30.1, 1.18.30.2 ...
#
# Usage:
#   script/version.sh                    # show both versions
#   script/version.sh bump               # increment our patch (1.18.30.1 -> 1.18.30.2)
#   script/version.sh bump major         # bump OpenCode major, reset patch (1.18.30 -> 2.0.0, YogeeshCode 2.0.0.1)
#   script/version.sh bump minor         # bump OpenCode minor, reset patch
#   script/version.sh bump patch         # bump OpenCode patch, reset our patch
#   script/version.sh set-base 1.19.0    # set new base OpenCode version (after upstream merge)
#   script/version.sh set 1.18.30.5      # set explicit YogeeshCode version

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$ROOT/package.json"
BASE_PKG="$ROOT/packages/opencode/package.json"

grep_version() { node -p "require('$1').version" 2>/dev/null; }
# YogeeshCode version lives at package.json -> yogeeshcode.version (4-part: base.ourpatch)
yogeesh_version() { node -p "require('$PKG').yogeeshcode?.version || ''" 2>/dev/null; }

BASE_VERSION="$(grep_version "$BASE_PKG")"
YOGEESH_VERSION="$(yogeesh_version)"

# Parse our 4-part version: BASE.MYPATCH
MYPATCH="1"
if [[ "$YOGEESH_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  MYPATCH="${BASH_REMATCH[4]}"
elif [[ "$YOGEESH_VERSION" =~ ^${BASE_VERSION}\.(.+)$ ]]; then
  MYPATCH="${BASH_REMATCH[1]}"
fi

show() {
  echo "OpenCode (base):  $BASE_VERSION"
  echo "YogeeshCode:      $YOGEESH_VERSION"
  echo "  (base + patch .$MYPATCH)"
}

set_version() {
  local new_ver="$1"
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('$PKG','utf8'));
    pkg.yogeeshcode = pkg.yogeeshcode || {};
    pkg.yogeeshcode.version = '$new_ver';
    fs.writeFileSync('$PKG', JSON.stringify(pkg, null, 2) + '\n');
  "
  echo "Set YogeeshCode version: $new_ver"
}

case "${1:-show}" in
  show) show ;;
  bump)
    MYPATCH=$((MYPATCH + 1))
    set_version "${BASE_VERSION}.${MYPATCH}"
    ;;
  patch)
    # bump OpenCode patch, reset our patch
    IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"
    PATCH=$((PATCH + 1))
    set_version "${MAJOR}.${MINOR}.${PATCH}.1"
    ;;
  minor)
    IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"
    MINOR=$((MINOR + 1)); PATCH=0
    set_version "${MAJOR}.${MINOR}.${PATCH}.1"
    ;;
  major)
    IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"
    MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
    set_version "${MAJOR}.${MINOR}.${PATCH}.1"
    ;;
  set-base)
    base_ver="$2"
    IFS='.' read -r MAJOR MINOR PATCH <<< "$base_ver"
    MAJOR="${MAJOR:-0}"; MINOR="${MINOR:-0}"; PATCH="${PATCH:-0}"
    # Also update the base package.json
    node -e "
      const fs = require('fs');
      const bpkg = JSON.parse(fs.readFileSync('$BASE_PKG','utf8'));
      bpkg.version = '$base_ver';
      fs.writeFileSync('$BASE_PKG', JSON.stringify(bpkg, null, 2) + '
');
    "
    set_version "${base_ver}.1"
    echo "Updated base OpenCode version to $base_ver"
    ;;
  set) set_version "$2" ;;
  *)
    echo "Usage: script/version.sh [show|bump|patch|minor|major|set-base X.Y.Z|set X.Y.Z.N]" >&2
    exit 1
    ;;
esac
