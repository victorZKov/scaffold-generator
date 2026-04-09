#!/bin/bash
# Hook: Stamp every generated artifact into a provenance ledger
# Source: Gartner governance → Auditable invariant + provenance completeness metric
# Fires PostToolUse on Write/Edit/MultiEdit. Append-only JSONL ledger under .claude/provenance/.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

[ -z "$FILE_PATH" ] && exit 0

LEDGER_DIR=".claude/provenance"
mkdir -p "$LEDGER_DIR" 2>/dev/null || exit 0

LEDGER="$LEDGER_DIR/$(date -u +%Y-%m).jsonl"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
HASH=""
[ -f "$FILE_PATH" ] && HASH=$(shasum -a 256 "$FILE_PATH" 2>/dev/null | awk '{print $1}')

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
