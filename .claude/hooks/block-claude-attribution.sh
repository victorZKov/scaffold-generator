#!/bin/bash
# Hook: Block Claude/AI attribution in git commits
# Source: Governance → "NEVER add Co-Authored-By: Claude or any AI attribution"

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

if echo "$COMMAND" | grep -qE '\bgit\s+commit\b'; then
    if echo "$COMMAND" | grep -qiE 'co-authored-by'; then
        echo "Blocked: Never add Co-Authored-By attributions to commits. Commits are authored by the user only." >&2
        exit 2
    fi
fi

exit 0
