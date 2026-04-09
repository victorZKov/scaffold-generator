# OIDC Federated Credentials — Setup Guide
# Source: context/governance.md → no long-lived secrets in CI
# {{PROJECT_NAME}}

This document shows how to wire **OIDC federated workload identity** between {{GIT_PLATFORM}} and {{CLOUD}} so the governance pipeline never stores long-lived service-principal secrets.

---

## Why OIDC

- No SP secret in repo, no rotation burden, no leak risk
- Each pipeline run gets a short-lived token bound to the repo + branch + workflow
- Auditable: cloud audit logs show the originating workflow run
- Required by the **Auditable** invariant

---

## {{IF_AZURE}} Azure + GitHub Actions

### One-time Azure setup

```bash
# 1. Create the app registration
az ad app create --display-name "{{PROJECT_NAME}}-github-oidc"
APP_ID=$(az ad app list --display-name "{{PROJECT_NAME}}-github-oidc" --query "[0].appId" -o tsv)

# 2. Create service principal
az ad sp create --id "$APP_ID"
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)

# 3. Grant Contributor (or scoped role) on the target subscription/resource group
az role assignment create \
  --role Contributor \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/{{SUBSCRIPTION_ID}}/resourceGroups/{{RG_NAME}}"

# 4. Add federated credential — branch-scoped
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:{{ORG}}/{{REPO}}:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# 5. Add federated credential — pull_request
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:{{ORG}}/{{REPO}}:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'

# 6. Add federated credential — environment-scoped (production approvals)
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-env-prod",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:{{ORG}}/{{REPO}}:environment:production",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

### GitHub repo secrets to configure

Only **non-secret** identifiers — no client secret:

| Secret name              | Value             |
|--------------------------|-------------------|
| `AZURE_CLIENT_ID`        | `$APP_ID`         |
| `AZURE_TENANT_ID`        | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID`  | `{{SUBSCRIPTION_ID}}` |

### Workflow snippet (already in `governance.terraform.github.template.yml`)

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: azure/login@v2
    with:
      client-id:       ${{ secrets.AZURE_CLIENT_ID }}
      tenant-id:       ${{ secrets.AZURE_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## {{/IF_AZURE}}

## {{IF_AWS}} AWS + GitHub Actions

```bash
# 1. Create the OIDC provider (one-time per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Create the IAM role with trust policy bound to repo + branch
cat > trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::{{AWS_ACCOUNT_ID}}:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike":   { "token.actions.githubusercontent.com:sub": "repo:{{ORG}}/{{REPO}}:*" }
    }
  }]
}
EOF

aws iam create-role \
  --role-name "{{PROJECT_NAME}}-github-oidc" \
  --assume-role-policy-document file://trust.json

aws iam attach-role-policy \
  --role-name "{{PROJECT_NAME}}-github-oidc" \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess  # scope down in real use
```

### Workflow snippet

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::{{AWS_ACCOUNT_ID}}:role/{{PROJECT_NAME}}-github-oidc
      aws-region: {{AWS_REGION}}
```

## {{/IF_AWS}}

## {{IF_ADO}} Azure + Azure DevOps (Workload Identity Federation)

ADO ≥ Sprint 232 supports federated identities natively in Service Connections.

```bash
# 1. Create app registration (same as GitHub flow)
az ad app create --display-name "{{PROJECT_NAME}}-ado-oidc"

# 2. In Azure DevOps:
#    Project Settings → Service connections → New → Azure Resource Manager
#    Authentication method: Workload Identity federation (automatic)
#    ADO will create the federated credential against your tenant.

# 3. Reference in pipeline as:
#    azureSubscription: "{{PROJECT_NAME}}-azure-oidc"
```

## {{/IF_ADO}}

---

## Verification

After setup, run a no-op pipeline (PR with a single comment change) and confirm:

1. Pipeline log shows successful login WITHOUT a client secret env var
2. Cloud audit log shows the principal as the federated identity, not a static SP
3. `terraform plan` succeeds against the target subscription/account

If any step fails: check the federated credential `subject` matches your repo/branch/environment exactly — that is the most common error.
