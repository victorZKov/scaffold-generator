#!/bin/bash
# governance-report.sh — Compute the Gartner success metrics for a generated project
# Source: context/governance.md → Success Measures
# Usage: ./tools/governance-report.sh [project-path]
#   Defaults to current directory.
# Outputs: human-readable summary + JSON (if --json passed) covering:
#   - 7-invariant first-pass rate proxy
#   - Provenance completeness
#   - Governance bypass attempts (from .claude/provenance + git log)
#   - Coverage status
#   - Pending/missing test files

set -e
ROOT="${1:-.}"
[ "$1" = "--json" ] && { ROOT="."; JSON=1; }
[ "$2" = "--json" ] && JSON=1

cd "$ROOT"

# ─── Provenance ledger stats ──────────────────────────────────────────
LEDGER_DIR=".claude/provenance"
TOTAL_GENERATED=0
UNIQUE_FILES=0
SESSIONS=0
if [ -d "$LEDGER_DIR" ]; then
    TOTAL_GENERATED=$(cat "$LEDGER_DIR"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
    UNIQUE_FILES=$(cat "$LEDGER_DIR"/*.jsonl 2>/dev/null | jq -r '.file' 2>/dev/null | sort -u | wc -l | tr -d ' ')
    SESSIONS=$(cat "$LEDGER_DIR"/*.jsonl 2>/dev/null | jq -r '.session' 2>/dev/null | sort -u | wc -l | tr -d ' ')
fi

# ─── Provenance completeness: % of tracked source files in the ledger ─
TRACKED=$(git ls-files 2>/dev/null | grep -E '\.(cs|ts|tsx|js|jsx|py|tf|sh)$' | wc -l | tr -d ' ')
COVERED=0
if [ "$TRACKED" -gt 0 ] && [ -d "$LEDGER_DIR" ]; then
    PWD_ABS=$(pwd)
    LEDGER_FILES=$(cat "$LEDGER_DIR"/*.jsonl 2>/dev/null | jq -r '.file' 2>/dev/null \
        | sed "s|^${PWD_ABS}/||" | sort -u)
    while IFS= read -r f; do
        if echo "$LEDGER_FILES" | grep -qxF "$f"; then
            COVERED=$((COVERED + 1))
        fi
    done < <(git ls-files | grep -E '\.(cs|ts|tsx|js|jsx|py|tf|sh)$')
fi
PROV_PCT=0
[ "$TRACKED" -gt 0 ] && PROV_PCT=$(awk -v c="$COVERED" -v t="$TRACKED" 'BEGIN{printf "%.1f", (c/t)*100}')

# ─── Governance bypass attempts (look for --no-verify, skip markers) ──
BYPASS=$(git log --all --oneline 2>/dev/null | grep -cE '(--no-verify|skip[- ]hooks?|bypass)' || true)
BYPASS=${BYPASS:-0}

# ─── Test/source pairing (Tested invariant proxy) ─────────────────────
SRC_FILES=$(find . -type f \( -name "*.cs" -o -name "*.ts" -o -name "*.tsx" \) \
    -not -path "*/node_modules/*" -not -path "*/bin/*" -not -path "*/obj/*" \
    -not -name "*.test.*" -not -name "*.spec.*" -not -name "*Tests.cs" -not -name "*Test.cs" 2>/dev/null | wc -l | tr -d ' ')
TEST_FILES=$(find . -type f \( -name "*Tests.cs" -o -name "*Test.cs" -o -name "*.test.*" -o -name "*.spec.*" \) \
    -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
TEST_RATIO=0
[ "$SRC_FILES" -gt 0 ] && TEST_RATIO=$(awk -v t="$TEST_FILES" -v s="$SRC_FILES" 'BEGIN{printf "%.1f", (t/s)*100}')

# ─── Modules without tests (Terraform) ────────────────────────────────
TF_MODULES=$(find modules -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
TF_MODULES_TESTED=0
if [ "$TF_MODULES" -gt 0 ]; then
    for d in modules/*/; do
        if find "$d/tests" -name "*.tftest.hcl" 2>/dev/null | grep -q .; then
            TF_MODULES_TESTED=$((TF_MODULES_TESTED + 1))
        fi
    done
fi

# ─── Output ───────────────────────────────────────────────────────────
if [ "${JSON:-0}" = "1" ]; then
    jq -nc \
        --arg gen "$TOTAL_GENERATED" --arg uniq "$UNIQUE_FILES" --arg sess "$SESSIONS" \
        --arg tracked "$TRACKED" --arg covered "$COVERED" --arg prov "$PROV_PCT" \
        --arg bypass "$BYPASS" --arg src "$SRC_FILES" --arg tst "$TEST_FILES" --arg ratio "$TEST_RATIO" \
        --arg tfm "$TF_MODULES" --arg tfmt "$TF_MODULES_TESTED" \
        '{
            provenance: {generated_events:$gen|tonumber, unique_files:$uniq|tonumber, sessions:$sess|tonumber,
                         tracked_source_files:$tracked|tonumber, covered:$covered|tonumber, completeness_pct:$prov|tonumber},
            bypass_attempts:$bypass|tonumber,
            tested_invariant: {source_files:$src|tonumber, test_files:$tst|tonumber, pairing_pct:$ratio|tonumber},
            terraform: {modules:$tfm|tonumber, modules_with_tests:$tfmt|tonumber}
        }'
    exit 0
fi

cat <<EOF
╔════════════════════════════════════════════════════════════════╗
║              GOVERNANCE REPORT — $(basename "$(pwd)")
║              $(date -u +%Y-%m-%dT%H:%M:%SZ)
╚════════════════════════════════════════════════════════════════╝

PROVENANCE LEDGER (Auditable invariant)
  Generation events:        $TOTAL_GENERATED
  Unique files generated:   $UNIQUE_FILES
  Distinct sessions:        $SESSIONS
  Tracked source files:     $TRACKED
  Covered by ledger:        $COVERED  ($PROV_PCT%)
  Target:                   100%

GOVERNANCE BYPASS (target: 0)
  Suspicious commits:       $BYPASS

TESTED INVARIANT (proxy: src↔test pairing)
  Source files:             $SRC_FILES
  Test files:               $TEST_FILES
  Pairing ratio:            $TEST_RATIO%

TERRAFORM MODULES (Tested invariant for IaC)
  Modules:                  $TF_MODULES
  With tests/*.tftest.hcl:  $TF_MODULES_TESTED

EOF

# Exit non-zero if any red flag
RED=0
[ "$BYPASS" -gt 0 ] && RED=1
awk -v p="$PROV_PCT" 'BEGIN{exit !(p+0 < 80)}' && [ "$TRACKED" -gt 0 ] && RED=1
[ "$TF_MODULES" -gt 0 ] && [ "$TF_MODULES_TESTED" -lt "$TF_MODULES" ] && RED=1

if [ "$RED" = "1" ]; then
    echo "STATUS: ❌ Governance debt detected. Review the metrics above." >&2
    exit 1
fi
echo "STATUS: ✅ All governance metrics within target."
