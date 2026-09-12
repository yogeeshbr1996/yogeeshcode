#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
TARGET="${1:-all}"
LOCAL_BIN="$HOME/.local/bin"
install_cli() {
  echo 'Installing CLI binary'
  mkdir -p "$LOCAL_BIN"
  local rel="$ROOT/release"
  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  local arch="$(uname -m)"
  case "$arch" in arm64|aarch64) arch="arm64" ;; x86_64|amd64) arch="x64" ;; esac
  local native="$(ls "$rel"/yogeeshcode-*-"$os"-"$arch".{tar.gz,zip} 2>/dev/null | grep -v latest | head -n 1)"
  if [ -n "$native" ]; then
    local tmp="$(mktemp -d)"
    if [[ "$native" == *.tar.gz ]]; then tar -xzf "$native" -C "$tmp"; else unzip -q "$native" -d "$tmp"; fi
    install -m 0755 "$tmp"/* "$LOCAL_BIN/yogeeshcode"
    rm -rf "$tmp"
    echo "  installed native binary"
  else
    echo "  no native binary, creating dev launcher"
    printf '#!/usr/bin/env bash\nexec bun run "$ROOT/packages/opencode/src/index.ts" "$@"\n' > "$LOCAL_BIN/yogeeshcode"
    chmod +x "$LOCAL_BIN/yogeeshcode"
    echo "  installed dev launcher"
  fi
}
install_vscode() {
  echo 'Installing VS Code extension'
  local vsix="$(ls -t "$ROOT"/sdks/vscode/yogeeshcode-*.vsix 2>/dev/null | head -n 1)"
  if [ -z "$vsix" ]; then echo "  no .vsix found"; return 1; fi
  local code_cmd=""
  for c in code code-insiders code-oss codium cursor windsurf; do command -v "$c" &>/dev/null && { code_cmd="$c"; break; }; done
  if [ -z "$code_cmd" ]; then echo "  no code CLI found"; return 0; fi
  "$code_cmd" --install-extension "$vsix" --force
  echo "  installed via $code_cmd"
}
case "$TARGET" in cli) install_cli ;; vscode) install_vscode ;; all|"") install_cli && install_vscode ;; *) echo "usage: $0 [cli|vscode|all]" >&2; exit 1 ;; esac
echo 'Done.'
