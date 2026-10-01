#!/bin/bash
# Hook: Block destructive az CLI and rm -rf commands
# Source: Governance → "Never modify or destroy shared infrastructure"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# --- Cross-platform support (added for Windows; no-op on macOS/Linux) -------
# lib/platform.sh detects the OS. On Windows (Git Bash) it strips the "\r" that
# jq.exe adds and converts C:\ backslash paths to forward slashes, so the checks
# below work unchanged. On macOS/Linux these calls return their input as-is.
# If lib/platform.sh is missing, the hook falls back to the original behaviour.
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$HOOK_DIR/lib/platform.sh" ]; then
    . "$HOOK_DIR/lib/platform.sh"
    COMMAND=$(normalize_text "$COMMAND")
fi
# ---------------------------------------------------------------------------

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
