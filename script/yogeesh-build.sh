#!/usr/bin/env bash
# YogeeshCode local build - produces release/ folder with ALL platform installers.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
TARGET="${1:-all}"
RELEASE_DIR="$ROOT/release"
VERSION="$(node -p "require('./packages/opencode/package.json').version")"
OS="$(uname -s | tr '[:upper:' '[:lower:')"
ARCH="$(uname -m)"
case "$ARCH" in arm64|aarch64) ARCH="arm64" ;; x86_64|amd64) ARCH="x64" ;; esac
echo "=========================================="
echo " YogeeshCode build -> $RELEASE_DIR/"
echo "  version : $VERSION"
echo "  host    : $OS-$ARCH"
echo "=========================================="
mkdir -p "$RELEASE_DIR"

build_cli() {
  echo ""
  echo "--- [1/3] CLI native binary ---"
  local single_flag="--single"
  for arg in "$@"; do [[ "$arg" == "--full" ]] && single_flag=""; done
  cd packages/opencode
  if [ -n "$single_flag" ]; then
    echo "  -> current platform only (fast, use --full for all)"
    bun run script/build.ts --single 2>&1 | tail -n 20
  else
    echo "  -> full multi-platform build (several minutes)"
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
    echo "  OK $archive"
    count=$((count + 1))
    local short="$(echo "$new_name" | sed 's/^yogeeshcode-//')"
    rm -f "$RELEASE_DIR/yogeeshcode-latest-$short.tar.gz" "$RELEASE_DIR/yogeeshcode-latest-$short.zip"
    ln -sf "$(basename "$archive")" "$RELEASE_DIR/yogeeshcode-latest-$short.$(echo "$archive" | sed 's/.*\.//')"
  done
  if [ "$count" -eq 0 ]; then
    echo "  !! No artifacts found. Retrying --single..."
    cd packages/opencode && bun run script/build.ts --single && cd "$ROOT"
    build_cli
    return
  fi
  echo "  -> $count artifact(s)"
}

build_vscode() {
  echo ""
  echo "--- [2/3] VS Code extension ---"
  cd sdks/vscode
  ./node_modules/.bin/tsc --noEmit 2>&1 | tail -n 3 || npx --yes tsc --noEmit 2>&1 | tail -n 3
  node esbuild.js --production 2>&1 | tail -n 3
  npx --yes @vscode/vsce package --no-dependencies 2>&1 | tail -n 3
  cd "$ROOT"
  local vsix="$(ls -t sdks/vscode/*.vsix 2>/dev/null | head -n 1)"
  if [ -z "$vsix" ]; then echo "  !! .vsix not found"; return 1; fi
  local dest="$RELEASE_DIR/yogeeshcode-${VERSION}.vsix"
  cp "$vsix" "$dest"
  ln -sf "$(basename "$dest")" "$RELEASE_DIR/yogeeshcode-latest.vsix"
  echo "  OK $dest"
}

build_desktop() {
  echo ""
  echo "--- [3/3] Desktop app (optional) ---"
  echo "  -> cd packages/desktop && bun install && bun run package:mac"
  echo "  -> then cp packages/desktop/dist/*.dmg $RELEASE_DIR/"
}

write_release_installer() {
  echo ""
  echo "--- Writing release/install.sh ---"
  cat > "$RELEASE_DIR/install.sh" <<'INSTALLER'
#!/usr/bin/env bash
# YogeeshCode one-click installer - auto-detects OS + architecture.
set -euo pipefail
VER="$(cd "$(dirname "$0")" && cat version.txt)"
OS="$(uname -s | tr '[:upper:' '[:lower:')"
ARCH="$(uname -m)"
case "$ARCH" in arm64|aarch64) ARCH="arm64" ;; x86_64|amd64) ARCH="x64" ;; esac
case "$OS" in
  darwin|linux) ARCHIVE="yogeeshcode-${VER}-${OS}-${ARCH}.tar.gz" ;;
  mingw*|msys*|cygwin*) ARCHIVE="yogeeshcode-${VER}-windows-${ARCH}.zip" ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac
DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
echo "YogeeshCode installer"
echo "  version : $VER"
echo "  os      : $OS-$ARCH"
if [ -f "$DIR/$ARCHIVE" ]; then
  echo "  -> installing from local"
  TMP="$(mktemp -d)"
  if [[ "$ARCHIVE" == *.tar.gz ]]; then tar -xzf "$DIR/$ARCHIVE" -C "$TMP"; else unzip -q "$DIR/$ARCHIVE" -d "$TMP"; fi
  install -m 0755 "$TMP"/yogeeshcode "$LOCAL_BIN/yogeeshcode" 2>/dev/null || install -m 0755 "$TMP"/opencode "$LOCAL_BIN/yogeeshcode" 2>/dev/null || install -m 0755 "$TMP"/* "$LOCAL_BIN/" 2>/dev/null || true
  rm -rf "$TMP"
else
  echo "  -> downloading from GitHub..."
  URL="https://github.com/yogeeshbr1996/yogeeshcode/releases/download/v${VER}/${ARCHIVE}"
  TMP="$(mktemp -d)"
  curl -fsSL "$URL" -o "$TMP/$ARCHIVE"
  (cd "$TMP" && tar -xzf "$ARCHIVE" 2>/dev/null || unzip -q "$ARCHIVE")
  install -m 0755 "$TMP"/yogeeshcode "$LOCAL_BIN/yogeeshcode" 2>/dev/null || install -m 0755 "$TMP"/opencode "$LOCAL_BIN/yogeeshcode" 2>/dev/null || true
  rm -rf "$TMP"
fi
case ":$PATH:" in *":$LOCAL_BIN:") ;; *) echo "  WARNING: Add $LOCAL_BIN to PATH" ;; esac
VSCODE="$(ls "$DIR"/yogeeshcode-*.vsix 2>/dev/null | head -n 1)"
if [ -n "$VSCODE" ]; then
  for c in code code-insiders codium cursor windsurf; do
    command -v "$c" &>/dev/null && { "$c" --install-extension "$VSCODE" --force 2>/dev/null && echo "  OK VS Code ext via $c"; break; }
  done
fi
echo "Done. Run: yogeeshcode --help"
INSTALLER
  chmod +x "$RELEASE_DIR/install.sh"
  echo "$VERSION" > "$RELEASE_DIR/version.txt"
  echo "  OK release/install.sh + version.txt"
}

for arg in "$@"; do
  case "$arg" in
    cli) build_cli ;;
    vscode) build_vscode ;;
    desktop) build_desktop ;;
    all) build_cli; build_vscode; build_desktop ;;
  esac
done
[[ $# -eq 0 ]] && { build_cli; build_vscode; build_desktop; }
write_release_installer

echo ""
echo "=========================================="
echo " YogeeshCode build complete -> $RELEASE_DIR/"
echo "  version : $VERSION"
ls -lh "$RELEASE_DIR" 2>/dev/null | tail -n 20 | sed 's/^/    /'
echo ""
echo " Install:  bash release/install.sh"
echo " One-liner: curl -fsSL https://raw.githubusercontent.com/yogeeshbr1996/yogeeshcode/yogeeshcode-rebrand/release/install.sh | bash"
echo "=========================================="
