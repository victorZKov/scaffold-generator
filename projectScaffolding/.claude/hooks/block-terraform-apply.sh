#!/bin/bash
# Hook: Block terraform apply — all deployments go through pipelines
# Source: Governance → "NEVER run terraform apply"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qE '\bterraform\s+apply\b'; then
    echo "Blocked: terraform apply is not allowed. All deployments must go through CI/CD pipelines. Use 'terraform plan' for validation only." >&2
    exit 2
fi

exit 0
