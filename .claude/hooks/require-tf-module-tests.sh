#!/bin/bash
# Hook: Every Terraform module under modules/ must have a tests/ directory with .tftest.hcl
# Source: context/governance.md → Tested invariant for IaC
# Warning by default; set REQUIRE_TF_TESTS_STRICT=1 to escalate to a hard block.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# --- Cross-platform support (added for Windows; no-op on macOS/Linux) -------
# lib/platform.sh detects the OS. On Windows (Git Bash) it strips the "\r" that
# jq.exe adds and converts C:\ backslash paths to forward slashes, so the checks
# below work unchanged. On macOS/Linux these calls return their input as-is.
# If lib/platform.sh is missing, the hook falls back to the original behaviour.
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$HOOK_DIR/lib/platform.sh" ]; then
    . "$HOOK_DIR/lib/platform.sh"
    FILE_PATH=$(normalize_path "$FILE_PATH")
fi
# ---------------------------------------------------------------------------

[ -z "$FILE_PATH" ] && exit 0
[[ "$FILE_PATH" != *.tf ]] && exit 0

# Only fire for files inside modules/<name>/...
case "$FILE_PATH" in
    *modules/*) ;;
    *) exit 0 ;;
esac

# Test files themselves are fine
[[ "$FILE_PATH" == *.tftest.hcl ]] && exit 0
[[ "$FILE_PATH" == *tests/* ]] && exit 0

# Resolve module root: everything up to and including modules/<name>
MOD_ROOT=$(echo "$FILE_PATH" | sed -E 's|(.*/modules/[^/]+).*|\1|')
[ -z "$MOD_ROOT" ] && exit 0
[ "$MOD_ROOT" = "$FILE_PATH" ] && exit 0

if ! find "$MOD_ROOT/tests" -name "*.tftest.hcl" 2>/dev/null | grep -q .; then
    MOD_NAME=$(basename "$MOD_ROOT")
    MSG="Module '$MOD_NAME' has no tests under $MOD_ROOT/tests/*.tftest.hcl. Required by the Tested invariant for IaC."
    if [ "${REQUIRE_TF_TESTS_STRICT:-0}" = "1" ]; then
        echo "Blocked: $MSG" >&2
        exit 2
    else
        echo "Warning: $MSG" >&2
        exit 0
    fi
fi

exit 0
