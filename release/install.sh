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
# Normalize OS name for archive lookup (uname returns Darwin/Linux)
OS_LOWER="$(echo "$OS" | tr '[:upper:]' '[:lower:]')"
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
