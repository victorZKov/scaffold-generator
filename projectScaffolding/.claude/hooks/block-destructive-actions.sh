#!/bin/bash
# Hook: Block destructive az CLI and rm -rf commands
# Source: Governance → "Never modify or destroy shared infrastructure"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block destructive az CLI (allow read-only and az pipelines)
if echo "$COMMAND" | grep -qE '\baz\s+'; then
    if echo "$COMMAND" | grep -qE '\baz\s+pipelines?\s+'; then
        exit 0
    fi
    if echo "$COMMAND" | grep -qE '\b(create|delete|update|start|stop|restart|purge|remove|set)\b'; then
        echo "Blocked: Destructive az CLI commands are not allowed. Only read-only operations (list, show, get) are permitted. All changes go through Terraform and CI/CD pipelines." >&2
        exit 2
    fi
fi

# Block rm -rf
if echo "$COMMAND" | grep -qE '\brm\s+.*-[a-zA-Z]*r[a-zA-Z]*f|rm\s+.*-[a-zA-Z]*f[a-zA-Z]*r'; then
    echo "Blocked: rm -rf is not allowed without explicit user authorization. Confirm the target path with the user first." >&2
    exit 2
fi

exit 0
