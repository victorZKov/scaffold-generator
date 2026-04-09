#!/bin/bash
# Hook: Run tfsec + checkov on each .tf file written/edited
# Source: context/governance.md → Secure invariant for IaC (generation checkpoint)
# Best-effort: only blocks if the tool is installed AND finds HIGH/CRITICAL issues.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
[[ "$FILE_PATH" != *.tf ]] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

DIR=$(dirname "$FILE_PATH")
FAIL=0
MSG=""

if command -v tfsec >/dev/null 2>&1; then
    if ! OUT=$(tfsec --minimum-severity HIGH --no-color --soft-fail=false "$DIR" 2>&1); then
        FAIL=1
        MSG="$MSG\n[tfsec]\n$OUT"
    fi
fi

if command -v checkov >/dev/null 2>&1; then
    if ! OUT=$(checkov -f "$FILE_PATH" --quiet --compact --framework terraform 2>&1); then
        FAIL=1
        MSG="$MSG\n[checkov]\n$OUT"
    fi
fi

if [ "$FAIL" = "1" ]; then
    echo -e "Terraform policy violation in $FILE_PATH:$MSG\n\nFix the HIGH/CRITICAL findings and re-write. Do NOT bypass — this is the Secure invariant at the generation checkpoint." >&2
    exit 2
fi

exit 0
