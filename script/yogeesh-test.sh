#!/usr/bin/env bash
# ============================================================
# YogeeshCode Release Smoke Test - run before EVERY release.
#   exit 0 = all green, exit 1 = something broke.
#
# Usage:
#   script/yogeesh-test.sh                 # full check (fast, no network for models)
#   script/yogeesh-test.sh --network       # also verify models.dev + Ollama endpoints
#   script/yogeesh-test.sh --quick         # only core checks (config, CLI, tests)
# ============================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0; FAIL=0; SKIP=0
declare -a FAILURES=()

ok()   { PASS=$((PASS+1)); echo "  \033[32m✔\033[0m $1"; }
bad()  { FAIL=$((FAIL+1)); FAILURES+=("$1"); echo "  \033[31m✘\033[0m $1"; }
skip(){ SKIP=$((SKIP+1)); echo "  \033[33m-\033[0m $1 (skipped)"; }

section() { echo ""; echo "\033[1;36m━━━ $1 ━━━\033[0m"; }

QUICK=0; NET=0
for a in "$@"; do [[ "$a" == "--quick" ]] && QUICK=1; [[ "$a" == "--network" ]] && NET=1; done

# ------------------------------------------------------------
section "1. Config & branding"
if node -e "JSON.parse(require('fs').readFileSync('yogeeshcode.json.example','utf8'))"; then
  ok "yogeeshcode.json.example is valid JSON"
else
  bad "yogeeshcode.json.example is NOT valid JSON"
fi

CPROV=$(node -e "const c=JSON.parse(require('fs').readFileSync('yogeeshcode.json.example','utf8')); console.log(Object.keys(c.provider||{}).length)")
CRANK=$(node -e "const c=JSON.parse(require('fs').readFileSync('yogeeshcode.json.example','utf8')); console.log((c.yogeeshcode?.model_ranker?.order||[]).length)")
[ "$CPROV" -ge 12 ] && ok "config has $CPROV providers (>=12)" || bad "config providers=$CPROV (<12)"
[ "$CRANK" -ge 20 ] && ok "config ranked chain has $CRANK models (>=20)" || bad "config ranked count=$CRANK (<20)"

# brand check - no leaked upstream name in shipped config
if grep -q 'opencode.json' yogeeshcode.json.example; then
  bad "config still references opencode.json"
else
  ok "no upstream opencode.json leak in config"
fi

# ------------------------------------------------------------
section "2. Permission autopilot defaults"
node -e "const c=JSON.parse(require('fs').readFileSync('yogeeshcode.json.example','utf8')); const p=c.permission; if(p['edit']!=='allow'||p['read']!=='allow') process.exit(1)"
if [ $? -eq 0 ]; then ok "read/edit auto-approve present"; else bad "read/edit auto-approve missing"; fi
if grep -qF '"rm -rf*": "deny"' yogeeshcode.json.example; then ok "risky rm -rf denied"; else bad "rm -rf deny rule missing"; fi
if grep -qF '"sudo *": "deny"' yogeeshcode.json.example; then ok "sudo denied"; else bad "sudo deny rule missing"; fi

# ------------------------------------------------------------
section "3. CLI boots"
VER=$(bun run --cwd packages/opencode src/index.ts --version 2>&1 | tail -n 1)
if echo "$VER" | grep -qi 'yogeeshcode'; then
  ok "CLI version: $VER"
else
  bad "CLI version output wrong: $VER"
fi
if bun run --cwd packages/opencode src/index.ts --help 2>&1 | grep -q 'yogeeshcode'; then
  ok "CLI help renders"
else
  bad "CLI help missing brand"
fi

# ------------------------------------------------------------
section "4. Unit tests"
if [ "$QUICK" -eq 1 ]; then
  skip "full bun test (use without --quick)"
else
  if (cd packages/opencode && bun test test/export-format.test.ts 2>&1 | grep -q '0 fail'); then
    ok "export-format tests pass (txt/html/pdf)"
  else
    bad "export-format tests FAILED"
  fi
fi

# ------------------------------------------------------------
section "5. Feature presence (static contract check)"
check_in() { # file pattern label
  if grep -qE "$2" "$1" 2>/dev/null; then ok "$3 wired"; else bad "$3 MISSING in $1"; fi
}
check_in packages/opencode/src/session/model-fallthrough.ts 'opencode/big-pickle' "Zen big-pickle ranked #1"
check_in packages/opencode/src/session/model-fallthrough.ts 'muse-spark-1.3(-contributor)?-free' "1M ctx Zen models ranked"
check_in packages/opencode/src/session/model-fallthrough.ts 'keyring' "keyring quota-pool logic"
check_in packages/opencode/src/session/retry.ts 'yogeeshShouldFallthrough' "rate-limit fallthrough detector"
check_in packages/opencode/src/session/retry.ts 'yogeeshMarkCooldown' "cooldown logic"
check_in packages/opencode/src/session/processor.ts 'rotating models' "model rotation status text"
check_in packages/opencode/src/cli/cmd/models.ts '"tier"' "models --tier filter"
check_in packages/opencode/src/cli/cmd/models.ts '"biggest"' "models --biggest token sort"
check_in packages/opencode/src/cli/cmd/export.ts 'pdf' "export pdf format"
check_in packages/tui/src/util/yogeesh-model-tiers.ts 'yogTierOf' "TUI tier logic"
check_in packages/tui/src/util/yogeesh-model-tiers.ts 'yogFooter' "TUI token-budget footer"

# ------------------------------------------------------------
section "6. VSCode extension"
VSCODE_JSON=$(node -e "const p=JSON.parse(require('fs').readFileSync('sdks/vscode/package.json','utf8')); console.log(p.name+':'+p.publisher)")
if [ "$VSCODE_JSON" == "yogeeshcode:yogeesh" ]; then ok "VS Code ext branded: $VSCODE_JSON"; else bad "VS Code ext name/publisher: $VSCODE_JSON"; fi
if ls sdks/vscode/*.vsix &>/dev/null; then ok "VSIX artifact present"; else skip "VSIX not built (run script/yogeesh-build.sh vscode)"; fi

# ------------------------------------------------------------
section "7. Shell scripts syntax"
for s in script/yogeesh-build.sh script/yogeesh-install.sh script/version.sh script/release.sh script/yogeesh-sync.sh; do
  if bash -n "$s" 2>/dev/null; then ok "$s syntax"; else bad "$s BROKEN syntax"; fi
done

# ------------------------------------------------------------
section "8. models.dev sanity (network)"
if [ "$NET" -eq 1 ]; then
  COUNT=$(curl -s --max-time 20 https://models.dev/api.json 2>/dev/null | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{const j=JSON.parse(d);const op=j.opencode?.models||{};const free=Object.values(op).filter(m=>(m.cost?.input||0)===0&&(m.cost?.output||0)===0);console.log(free.length)}catch(e){console.log('ERR')}})")
  if [ "$COUNT" != "ERR" ] && [ "$COUNT" -ge 20 ]; then ok "models.dev Zen FREE models: $COUNT (>=20)"; else bad "models.dev check failed/unexpected: $COUNT"; fi
else
  skip "models.dev network (use --network)"
fi

# ------------------------------------------------------------
section "9. Version & release managers dry-run"
V=$(bash script/version.sh show 2>/dev/null | tail -n 1 || echo "")
if [ -n "$V" ]; then ok "version.sh works: $V"; else bad "version.sh failed"; fi
if [ "$QUICK" -eq 0 ]; then
  if bash -n script/release.sh 2>/dev/null; then ok "release.sh syntax"; else bad "release.sh syntax"; fi
fi

# ------------------------------------------------------------
echo ""
echo "=========================================="
echo " YogeeshCode smoke test"
echo "   PASS: $PASS   FAIL: $FAIL   SKIP: $SKIP"
if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo " FAILURES:"
  for f in "${FAILURES[@]}"; do echo "   - $f"; done
  echo "=========================================="
  exit 1
fi
echo "   \033[32mALL GREEN - safe to release\033[0m"
echo "=========================================="
exit 0
