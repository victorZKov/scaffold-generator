#!/bin/bash
# Hook: Block obvious public-exposure patterns in Terraform before they hit disk
# Source: context/governance.md → Secure invariant (highest-cost IaC failure mode)
# Catches the patterns that cause data breaches: open CIDRs, public storage,
# disabled encryption, public network access flags.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

[ -z "$CONTENT" ] && exit 0
[[ "$FILE_PATH" != *.tf ]] && exit 0

# Allow opt-out per file via comment marker
if echo "$CONTENT" | grep -q "# tf-public-exposure: allow"; then
    exit 0
fi

declare -a PATTERNS=(
    '0\.0\.0\.0/0'                                      "Open CIDR (0.0.0.0/0). Restrict to known ranges or use private endpoints."
    '"::/0"'                                            "Open IPv6 CIDR (::/0)."
    'public_network_access_enabled[[:space:]]*=[[:space:]]*true'  "public_network_access_enabled = true. Use private endpoints."
    'allow_blob_public_access[[:space:]]*=[[:space:]]*true'       "allow_blob_public_access = true. Storage must be private."
    'enable_https_traffic_only[[:space:]]*=[[:space:]]*false'     "enable_https_traffic_only = false. HTTPS-only is mandatory."
    'min_tls_version[[:space:]]*=[[:space:]]*"TLS1_0"'           "min_tls_version TLS1_0 is deprecated. Use TLS1_2 minimum."
    'min_tls_version[[:space:]]*=[[:space:]]*"TLS1_1"'           "min_tls_version TLS1_1 is deprecated. Use TLS1_2 minimum."
    'encryption[[:space:]]*=[[:space:]]*false'                    "encryption = false. Encryption-at-rest is mandatory."
    'storage_encrypted[[:space:]]*=[[:space:]]*false'             "storage_encrypted = false."
    'publicly_accessible[[:space:]]*=[[:space:]]*true'            "publicly_accessible = true (RDS/database)."
    'skip_final_snapshot[[:space:]]*=[[:space:]]*true'            "skip_final_snapshot = true. Production data must be snapshotted."
    'force_destroy[[:space:]]*=[[:space:]]*true'                  "force_destroy = true. Review carefully — irreversible."
    'block_public_acls[[:space:]]*=[[:space:]]*false'             "S3 block_public_acls = false."
    'block_public_policy[[:space:]]*=[[:space:]]*false'           "S3 block_public_policy = false."
    'ignore_public_acls[[:space:]]*=[[:space:]]*false'            "S3 ignore_public_acls = false."
    'restrict_public_buckets[[:space:]]*=[[:space:]]*false'       "S3 restrict_public_buckets = false."
)

i=0
while [ $i -lt ${#PATTERNS[@]} ]; do
    P="${PATTERNS[$i]}"
    R="${PATTERNS[$((i+1))]}"
    if echo "$CONTENT" | grep -E -q "$P"; then
        echo "Blocked: $FILE_PATH — $R" >&2
        echo "If this is intentional and reviewed, add a line comment '# tf-public-exposure: allow' at the top of the file." >&2
        exit 2
    fi
    i=$((i+2))
done

exit 0
