#!/bin/bash
# Hook: Enforce code-quality invariants on each file written/edited
# Source: Gartner governance → Functional + Tested invariants (generation checkpoint)
# Fires PostToolUse on Write/Edit. Best-effort: only runs tools if available.
# Non-blocking for unknown file types; blocks on hard failures of installed linters.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

EXT="${FILE_PATH##*.}"
FAIL=0
MSG=""

run_check() {
    local tool=$1; shift
    if command -v "$tool" >/dev/null 2>&1; then
        if ! OUT=$("$@" 2>&1); then
            FAIL=1
            MSG="$MSG\n[$tool] $OUT"
        fi
    fi
}

case "$EXT" in
    ts|tsx|js|jsx)
        run_check eslint eslint --no-error-on-unmatched-pattern "$FILE_PATH"
        ;;
    py)
        run_check ruff ruff check "$FILE_PATH"
        ;;
    cs)
        # dotnet format is heavy; only verify whitespace on the single file's project if fast mode set
        if command -v dotnet >/dev/null 2>&1 && [ "${ENFORCE_DOTNET_FORMAT:-0}" = "1" ]; then
            PROJ=$(find "$(dirname "$FILE_PATH")" -maxdepth 4 -name "*.csproj" | head -1)
            [ -n "$PROJ" ] && run_check dotnet dotnet format "$PROJ" --include "$FILE_PATH" --verify-no-changes
        fi
        ;;
    tf)
        run_check terraform terraform fmt -check "$FILE_PATH"
        ;;
    sh)
        run_check shellcheck shellcheck "$FILE_PATH"
        ;;
    json)
        run_check jq jq empty "$FILE_PATH"
        ;;
    yml|yaml)
        run_check yamllint yamllint "$FILE_PATH"
        ;;
esac

if [ "$FAIL" = "1" ]; then
    echo -e "Invariant check failed for $FILE_PATH:$MSG\n\nFix the issues and re-write the file. Do NOT bypass — Gartner governance requires the 'Functional' invariant to pass at the generation checkpoint." >&2
    exit 2
fi

exit 0
