#!/bin/bash
# Hook: Block terraform apply — all deployments go through pipelines
# Source: Governance → "NEVER run terraform apply"

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

if echo "$COMMAND" | grep -qE '\bterraform\s+apply\b'; then
    echo "Blocked: terraform apply is not allowed. All deployments must go through CI/CD pipelines. Use 'terraform plan' for validation only." >&2
    exit 2
fi

exit 0
