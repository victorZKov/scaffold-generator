#!/bin/bash
# Hook: Enforce pnpm — block npm usage
# Source: Governance → "NEVER use npm — always use pnpm"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

SANITIZED=$(echo "$COMMAND" | sed 's/pnpm/__PNPM__/g')

if echo "$SANITIZED" | grep -qw "npm"; then
    echo "Blocked: Use pnpm instead of npm. All frontend operations require pnpm (install, run, build, test)." >&2
    exit 2
fi

exit 0
