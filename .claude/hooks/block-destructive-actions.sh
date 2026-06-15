#!/bin/bash
# Hook: Block destructive az CLI and rm -rf commands
# Source: Governance → "Never modify or destroy shared infrastructure"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block destructive az CLI commands.
# Rationale: cloud INFRASTRUCTURE changes must go through Terraform + CI/CD. But Azure DevOps
# project/repo/board management (az devops / az boards / az repos) and pipelines are project
# administration, NOT infrastructure — they are allowed. A `delete` is still blocked everywhere,
# even within the allowed groups, to prevent removing a project/repo/board by accident.
if echo "$COMMAND" | grep -qE '\baz\s+'; then
    # Hard block: any az ... delete (highest priority, no exceptions via the allow-list).
    if echo "$COMMAND" | grep -qE '\b(delete|purge)\b'; then
        echo "Blocked: 'az ... delete/purge' is not allowed. Destructive removals must be done deliberately by the user, never by the agent." >&2
        exit 2
    fi
    # Allow-list: project/work-item/repo administration and pipelines (not infrastructure).
    if echo "$COMMAND" | grep -qE '\baz\s+(devops|boards|repos|pipelines?)\s+'; then
        exit 0
    fi
    # Everything else destructive on az (typically infrastructure) stays blocked.
    if echo "$COMMAND" | grep -qE '\b(create|update|start|stop|restart|remove|set)\b'; then
        echo "Blocked: Destructive az CLI commands are not allowed. Only read-only operations (list, show, get) are permitted for cloud resources. Infrastructure changes go through Terraform and CI/CD pipelines. (Azure DevOps admin via 'az devops/boards/repos' is allowed; 'delete' is never allowed.)" >&2
        exit 2
    fi
fi

# Block rm -rf
if echo "$COMMAND" | grep -qE '\brm\s+.*-[a-zA-Z]*r[a-zA-Z]*f|rm\s+.*-[a-zA-Z]*f[a-zA-Z]*r'; then
    echo "Blocked: rm -rf is not allowed without explicit user authorization. Confirm the target path with the user first." >&2
    exit 2
fi

exit 0
