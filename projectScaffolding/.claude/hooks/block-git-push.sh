#!/bin/bash
# Hook: Block git push — user must push manually or give explicit permission
# Source: Governance → "NEVER git push without explicit user approval"

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

if echo "$COMMAND" | grep -qE '\bgit\s+push\b'; then
    echo "Blocked: git push is not allowed. The user must push manually or explicitly approve the push." >&2
    exit 2
fi

exit 0
