#!/bin/bash
# Hook: Block git push — user must push manually or give explicit permission
# Source: Governance → "NEVER git push without explicit user approval"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qE '\bgit\s+push\b'; then
    echo "Blocked: git push is not allowed. The user must push manually or explicitly approve the push." >&2
    exit 2
fi

exit 0
