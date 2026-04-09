#!/bin/bash
# Hook: Enforce mandatory tags on Terraform resources
# Source: context/governance.md → Auditable + FinOps invariants
# Required tags read from .claude/tf-required-tags (one per line) or env REQUIRED_TF_TAGS
# (comma-separated). Defaults: cost-center, owner, environment, data-classification.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

[ -z "$CONTENT" ] && exit 0
[[ "$FILE_PATH" != *.tf ]] && exit 0

# Skip files that don't declare resources (variables.tf, outputs.tf, versions.tf, locals.tf)
case "$(basename "$FILE_PATH")" in
    variables.tf|outputs.tf|versions.tf|providers.tf|locals.tf|data.tf) exit 0 ;;
esac

# Only check files with at least one taggable resource block
if ! echo "$CONTENT" | grep -E -q '^resource[[:space:]]+"(azurerm_|aws_|google_)'; then
    exit 0
fi

# Load required tags
if [ -f .claude/tf-required-tags ]; then
    REQUIRED=$(tr '\n' ',' < .claude/tf-required-tags | sed 's/,$//')
else
    REQUIRED="${REQUIRED_TF_TAGS:-cost-center,owner,environment,data-classification}"
fi

MISSING=""
IFS=',' read -ra TAGS <<< "$REQUIRED"
for tag in "${TAGS[@]}"; do
    tag=$(echo "$tag" | xargs)
    if ! echo "$CONTENT" | grep -E -q "\"$tag\"[[:space:]]*=|$(echo "$tag" | tr '-' '_')[[:space:]]*="; then
        MISSING="$MISSING $tag"
    fi
done

if [ -n "$MISSING" ]; then
    echo "Blocked: $FILE_PATH declares taggable resources but is missing required tag(s):$MISSING" >&2
    echo "Add them to the resource's 'tags = {}' block (or merge with var.common_tags). Required set: $REQUIRED" >&2
    exit 2
fi

exit 0
