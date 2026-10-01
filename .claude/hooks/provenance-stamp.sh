#!/bin/bash
# Hook: Stamp every generated artifact into a provenance ledger
# Source: Gartner governance → Auditable invariant + provenance completeness metric
# Fires PostToolUse on Write/Edit/MultiEdit. Append-only JSONL ledger under .claude/provenance/.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# --- Cross-platform support (added for Windows; no-op on macOS/Linux) -------
# lib/platform.sh detects the OS. On Windows (Git Bash) it strips the "\r" that
# jq.exe adds and converts C:\ backslash paths to forward slashes, so the checks
# below work unchanged. On macOS/Linux these calls return their input as-is.
# If lib/platform.sh is missing, the hook falls back to the original behaviour.
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$HOOK_DIR/lib/platform.sh" ]; then
    . "$HOOK_DIR/lib/platform.sh"
    TOOL=$(normalize_text "$TOOL")
    FILE_PATH=$(normalize_path "$FILE_PATH")
    SESSION=$(normalize_text "$SESSION")
fi
# ---------------------------------------------------------------------------

[ -z "$FILE_PATH" ] && exit 0

LEDGER_DIR=".claude/provenance"
mkdir -p "$LEDGER_DIR" 2>/dev/null || exit 0

LEDGER="$LEDGER_DIR/$(date -u +%Y-%m).jsonl"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
HASH=""
# Windows: Git Bash has no `shasum`. sha256_file (lib/platform.sh) still uses
# shasum when present (macOS/Linux, the original behaviour) and falls back to
# sha256sum otherwise. Original line, used when lib/platform.sh is missing:
#   [ -f "$FILE_PATH" ] && HASH=$(shasum -a 256 "$FILE_PATH" 2>/dev/null | awk '{print $1}')
if command -v sha256_file >/dev/null 2>&1; then
    [ -f "$FILE_PATH" ] && HASH=$(sha256_file "$FILE_PATH")
else
    [ -f "$FILE_PATH" ] && HASH=$(shasum -a 256 "$FILE_PATH" 2>/dev/null | awk '{print $1}')
fi

jq -nc \
    --arg ts "$TS" \
    --arg session "$SESSION" \
    --arg tool "$TOOL" \
    --arg file "$FILE_PATH" \
    --arg hash "$HASH" \
    --arg model "${CLAUDE_MODEL:-unknown}" \
    '{ts:$ts, session:$session, tool:$tool, file:$file, sha256:$hash, model:$model}' \
    >> "$LEDGER" 2>/dev/null || true

exit 0
