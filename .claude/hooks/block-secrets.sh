#!/bin/bash
# Hook: Block writing secrets/credentials to files
# Source: Gartner governance → "Secure" invariant (pre-write secret detection)
# Fires on Write/Edit. Inspects content for common secret patterns.

INPUT=$(cat)
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$CONTENT" ] && exit 0

# Skip the hook files themselves and obvious template/example paths
case "$FILE_PATH" in
    */hooks/*|*template*|*.example|*.sample) exit 0 ;;
esac

# Pattern set: AWS keys, GitHub PATs, Azure keys, generic API keys, private keys, JWTs in source
PATTERNS=(
    'AKIA[0-9A-Z]{16}'                          # AWS Access Key
    'aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{40}'
    'ghp_[A-Za-z0-9]{36}'                       # GitHub PAT
    'github_pat_[A-Za-z0-9_]{82}'
    'xox[baprs]-[A-Za-z0-9-]{10,}'              # Slack tokens
    '-----BEGIN (RSA |EC |OPENSSH |DSA |)PRIVATE KEY-----'
    'AccountKey=[A-Za-z0-9+/=]{40,}'            # Azure storage
    'DefaultEndpointsProtocol=https;AccountName='
    '(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*["\x27][^"\x27]{6,}["\x27]'
    '(api[_-]?key|apikey|secret)[[:space:]]*[:=][[:space:]]*["\x27][A-Za-z0-9_\-]{16,}["\x27]'
)

for p in "${PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -E -q "$p"; then
        echo "Blocked: Potential secret detected matching pattern /$p/ in $FILE_PATH. Use a secret manager (Key Vault, .env.local gitignored, GitHub Secrets) — never commit credentials. If this is a false positive, refactor to use a placeholder." >&2
        exit 2
    fi
done

exit 0
