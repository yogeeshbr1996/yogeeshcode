#!/usr/bin/env bash
# YogeeshCode local build — mirrors upstream's GitHub Actions, runs locally.
# No GitHub required. Builds, versions, and bundles everything you can ship.
#
# Upstream flow (publish.yml / publish-vscode.yml):
#   1. version.ts  -> bumps package.json + tags
#   2. build.ts    -> native binaries for linux/darwin/win32 (arm64+x64+musl+baseline)
#   3. vsce package -> .vsix extension
#   4. desktop     -> electron dmg/exe/deb/rpm/AppImage
#   5. npm publish + gh release upload
#
# This script does steps 1-4 locally. Usage:
#   script/yogeesh-build.sh [cli|vscode|desktop|all] [--single]
#
# Outputs:
#   release/yogeeshcode-<ver>-<os>-<arch>.tar.gz   (CLI native binary)
#   release/yogeeshcode-<ver>.vsix                 (VS Code / Cursor / Windsurf)
#   release/yogeeshcode-<ver>-<os>-<arch>.dmg      (Desktop, optional)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-all}"
[[ "$TARGET" == "--single" ]] && TARGET="all"
RELEASE_DIR="$ROOT/release"
VERSION="$(node -p "require('./package.json').version")"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in arm64|aarch64) ARCH="arm64" ;; x86_64|amd64) ARCH="x64" ;; esac

echo "=========================================="
echo " YogeeshCode build"
echo "  version : $VERSION"
echo "  host    : $OS-$ARCH"
echo "  target  : $TARGET"
echo "=========================================="
mkdir -p "$RELEASE_DIR"

build_cli() {
  echo ""
  echo "━━━ [1/3] Building CLI native binary ━━━"
  local single_flag=""
  for arg in "$@"; do [[ "$arg" == "--single" ]] && single_flag="--single"; done

  cd packages/opencode
  if [ -n "$single_flag" ]; then
    echo "  → --single: current platform only (fast)"
    bun run script/build.ts --single 2>&1 | tail -n 20
  else
    echo "  → full multi-platform build (several minutes)"
    bun run script/build.ts 2>&1 | tail -n 30
  fi
  cd "$ROOT"

  local count=0
  for pkg_dir in packages/opencode/dist/*/; do
    [ -d "$pkg_dir/bin" ] || continue
    local pkg_name="$(basename "$pkg_dir")"
    local new_name="${pkg_name/opencode/yogeeshcode}"
    local archive
    if echo "$pkg_name" | grep -q "linux"; then
      archive="$RELEASE_DIR/${new_name}.tar.gz"
      (cd "$pkg_dir/bin" && tar -czf "$archive" ./*)
    else
      archive="$RELEASE_DIR/${new_name}.zip"
      (cd "$pkg_dir/bin" && zip -rq "$archive" ./*)
    fi
    echo "  ✓ $archive"
    count=$((count + 1))
    ln -sf "$(basename "$archive")" "$RELEASE_DIR/yogeeshcode-latest-$(echo "$new_name" | sed 's/^yogeeshcode-//').$(echo "$archive" | sed 's/.*\.//')"
  done

  if [ "$count" -eq 0 ]; then
    echo "  !! No binary packages found. Retrying with --single..."
    cd packages/opencode && bun run script/build.ts --single && cd "$ROOT"
    build_cli --single
    return
  fi
  echo "  → $count artifact(s) in $RELEASE_DIR/"
}

build_vscode() {
  echo ""
  echo "━━━ [2/3] Building VS Code extension ━━━"
  cd sdks/vscode
  echo "  → typecheck..."
  ./node_modules/.bin/tsc --noEmit 2>&1 | tail -n 5 || npx --yes tsc --noEmit 2>&1 | tail -n 5
  echo "  → esbuild..."
  node esbuild.js --production 2>&1 | tail -n 5
  echo "  → packaging .vsix..."
  npx --yes @vscode/vsce package --no-dependencies 2>&1 | tail -n 5
  cd "$ROOT"

  local vsix="$(ls -t sdks/vscode/*.vsix 2>/dev/null | head -n 1)"
  if [ -z "$vsix" ]; then
    echo "  !! .vsix not found (check sdks/vscode/package.json publisher+name)"
    return 1
  fi
  local dest="$RELEASE_DIR/yogeeshcode-${VERSION}.vsix"
  cp "$vsix" "$dest"
  ln -sf "$(basename "$dest")" "$RELEASE_DIR/yogeeshcode-latest.vsix"
  echo "  ✓ $dest"
  echo "  → Install: code --install-extension $dest"
}

build_desktop() {
  echo ""
  echo "━━━ [3/3] Building Desktop app ━━━"
  echo "  NOTE: Desktop needs the CLI node dist bundled. Skipped by default."
  echo "  To build: cd packages/desktop && bun install && bun run package:mac"
  echo "  Then copy: cp packages/desktop/dist/*.dmg $RELEASE_DIR/"
  if [ -d packages/desktop ]; then
    cd packages/desktop
    if grep -q "package:mac" package.json 2>/dev/null; then
      echo "  → Found package:mac script, attempting build..."
      bun install >/dev/null 2>&1 || true
      if bun run package:mac 2>&1 | tail -n 10; then
        cd "$ROOT"
        for f in packages/desktop/dist/*.{dmg,exe,zip,AppImage,deb,rpm} packages/desktop/dist/*.app.tar.gz; do
          [ -f "$f" ] || continue
          cp "$f" "$RELEASE_DIR/"
          echo "  ✓ $(basename "$f")"
        done
      else
        cd "$ROOT"
        echo "  !! Desktop build failed. Skipped."
      fi
    fi
  fi
}

case "$TARGET" in
  cli)     build_cli "$@" ;;
  vscode)  build_vscode ;;
  desktop) build_desktop ;;
  all|"")  build_cli "$@" && build_vscode && build_desktop ;;
  *) echo "usage: script/yogeesh-build.sh [cli|vscode|desktop|all]" >&2; exit 1 ;;
esac

echo ""
echo "=========================================="
echo " YogeeshCode build complete"
echo "  version : $VERSION"
echo "  artifacts in $RELEASE_DIR/:"
ls -lh "$RELEASE_DIR" 2>/dev/null | tail -n 20 | sed 's/^/    /'
echo ""
echo " Quick install:"
echo "   CLI   : script/yogeesh-install.sh cli    → ~/.local/bin/yogeeshcode"
echo "   VSCode: script/yogeesh-install.sh vscode → code --install-extension"
echo "   All   : script/yogeesh-install.sh"
echo "=========================================="