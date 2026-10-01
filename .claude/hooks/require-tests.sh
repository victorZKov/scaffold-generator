#!/bin/bash
# Hook: Enforce "Tested" invariant — production code in test-required layers must have a sibling test
# Source: Gartner governance → Tested invariant (generation checkpoint)
# Strategy: when a file is written under a known production layer, warn (not block) if no
# corresponding test file exists. Set REQUIRE_TESTS_STRICT=1 to escalate to a hard block.

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

# Skip non-source artifacts
case "$FILE_PATH" in
    *.md|*.json|*.yml|*.yaml|*.tf|*.sh|*.gitignore|*template*) exit 0 ;;
    */tests/*|*/test/*|*/__tests__/*|*.test.*|*.spec.*|*Tests*|*Test.cs) exit 0 ;;
esac

# Match production layers we care about
case "$FILE_PATH" in
    *.Domain/*|*.Application/*|*.Infrastructure/*|*.Api/*)
        LAYER="dotnet" ;;
    */src/features/*|*/src/services/*|*/src/lib/*)
        LAYER="frontend" ;;
    *)
        exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")
STEM="${BASENAME%.*}"

# Look for a matching test file in nearby test directories
FOUND=0
case "$LAYER" in
    dotnet)
        if find . -type f \( -name "${STEM}Tests.cs" -o -name "${STEM}Test.cs" \) 2>/dev/null | grep -q .; then
            FOUND=1
        fi
        ;;
    frontend)
        if find . -type f \( -name "${STEM}.test.*" -o -name "${STEM}.spec.*" \) 2>/dev/null | grep -q .; then
            FOUND=1
        fi
        ;;
esac

if [ "$FOUND" = "0" ]; then
    MSG="Tested invariant: $FILE_PATH has no sibling test (${STEM}Tests / ${STEM}.test.*). Create one before considering this artifact done. Coverage target: 75%+."
    if [ "${REQUIRE_TESTS_STRICT:-0}" = "1" ]; then
        echo "Blocked: $MSG" >&2
        exit 2
    else
        echo "Warning: $MSG" >&2
        exit 0
    fi
fi

exit 0
