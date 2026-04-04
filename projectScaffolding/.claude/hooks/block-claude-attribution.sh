#!/bin/bash
# Hook: Block Claude/AI attribution in git commits
# Source: Governance → "NEVER add Co-Authored-By: Claude or any AI attribution"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qE '\bgit\s+commit\b'; then
    if echo "$COMMAND" | grep -qiE 'co-authored-by'; then
        echo "Blocked: Never add Co-Authored-By attributions to commits. Commits are authored by the user only." >&2
        exit 2
    fi
fi

exit 0
