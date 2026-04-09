# CLAUDE.md — {{ProjectName}}

## Project Overview

**{{ProjectName}}** — {{description}}

- **Backend:** .NET {{dotnetVersion}} Web API (Clean Architecture)
- **Frontend:** {{frontendFramework}} + TypeScript + {{uiLibrary}} (pnpm only)
- **Infrastructure:** {{cloud}} ({{infraDetails}})
- **Database:** {{database}}
- **Auth:** {{authType}}
- **Local dev:** {{localDev}}

---

## CRITICAL: Never Sign Commits as Claude

- **NEVER** add `Co-Authored-By: Claude` or any AI attribution to commits
- **NEVER** mention Claude, AI, or any assistant in commit messages
- Commits are authored by the user only

---

## CRITICAL: Issue Governance

**Every piece of work MUST be tracked in a GitHub Issue before any code is written.**

### Required Fields

1. **Title** — Clear, actionable
2. **Labels** — At minimum: `layer:*`, `type:*`, `priority:*`
3. **Milestone** — Which delivery phase
4. **Acceptance criteria** — What "done" looks like

### Branch Naming

`issue/<number>-<short-description>`

### Workflow

1. Check if a GitHub Issue exists. If not, create one first.
2. Assign yourself, move to "In Progress".
3. Branch from `main`: `git checkout -b issue/<number>-<short-desc>`
4. Work. Commit frequently with conventional commits (`feat:`, `fix:`, `docs:`, `test:`)
5. PR references the issue: `Closes #<number>`
6. Never push without explicit user authorization.

---

## Architecture: Clean Architecture (Onion)

```
{{ProjectName}}.Domain          → Entities, Value Objects, Domain Events (zero dependencies)
{{ProjectName}}.Application     → Use Cases, CQRS, Interfaces, DTOs, Validation
{{ProjectName}}.Infrastructure  → EF Core, External services, Repos implementation
{{ProjectName}}.Api             → Controllers, Middleware, DI (entry point)
{{ProjectName}}.Tests           → Unit + Integration tests
```

### Modules

{{modules}}

---

## Clean Code Rules

1. **Meaningful names** — Reveal intent. No abbreviations unless universal.
2. **Small functions** — Each method does ONE thing.
3. **Single Responsibility** — Each class has one reason to change.
4. **Dependency Inversion** — Depend on abstractions (interfaces), not concretions.
5. **No magic numbers/strings** — Use constants or configuration.
6. **Guard clauses** — Fail fast. Don't nest.
7. **Immutable where possible** — `record` types for DTOs, `readonly` fields.
8. **Explicit error handling** — Custom exceptions for domain errors. Never swallow.
9. **No God classes** — If a class exceeds ~200 lines, split it.
10. **Tests prove behavior** — Every public method has a test. Tests read like documentation.

---

## Testing Requirements

- **Minimum 75% code coverage** (CI fails below this threshold)
- **Target: 80%+**
- Unit tests: Domain + Application layers (all public methods)
- Integration tests: API endpoints, DB interactions (Testcontainers)
- Architecture tests: NetArchTest to enforce layer dependencies
- Test naming: `Should_ReturnUser_When_ValidIdProvided`
- Frameworks: xUnit, Moq, FluentAssertions, Testcontainers

---

## Naming Conventions (.NET)

| Element | Convention | Example |
|---------|-----------|---------|
| Interface | `I` prefix + PascalCase | `IUserRepository` |
| Class | PascalCase | `UserService` |
| Method | PascalCase verb | `CreateUser` |
| Property | PascalCase | `CreatedAt` |
| Private field | `_camelCase` | `_repository` |
| Parameter | camelCase | `userId` |
| Constant | PascalCase | `MaxRetryCount` |
| DTO | `Dto` suffix | `UserDto` |
| Command | `Command` suffix | `CreateUserCommand` |
| Query | `Query` suffix | `GetUserByIdQuery` |

---

## Supply Chain Security (pnpm enforced)

### pnpm is mandatory — npm and yarn are forbidden

- **NEVER use `npm install`, `npm run`, `npm ci`** — always `pnpm install`, `pnpm run`, `pnpm exec`
- **NEVER use `npx`** for project scripts — use `pnpm exec` or `pnpm dlx` instead
- **NEVER use `yarn`** — pnpm is the only allowed package manager
- The `block-npm.sh` hook enforces this automatically

### Dependency pinning

- **Never use `^` or `~`** in dependency version specifiers — always pin exact versions
- Use `pnpm add <package> --save-exact` (or `-E`) to ensure exact pinning
- **Always commit `pnpm-lock.yaml`** — never delete it or add it to `.gitignore`

### Deterministic installs

- **Use `pnpm install --frozen-lockfile`** in CI and all automated scripts
- Install scripts are disabled by default — if a dependency requires a build step, it must be explicitly approved
- **Do not run blind upgrade commands** (`npm update`, `npx npm-check-updates`, `pnpm update --latest`) — review each update individually

### Verification

- When adding a dependency, verify it on [npmjs.com](https://www.npmjs.com) before installing
- Prefer well-maintained packages with verified publishers and provenance
- Do not add git-based or tarball URL dependencies unless explicitly approved
- **Do not store secrets in plain text** in `.env` files committed to version control

---

## Guardrails

- Always use **pnpm** — never npm
- **NEVER git push** without explicit user authorization
- **NEVER terraform apply** — all deployments go through pipelines
- **NEVER commit as Claude** — no AI attribution in commits
- **NEVER --no-verify** — fix the hook, don't skip it
- **NEVER destructive az CLI** — only read-only (list, show, get)
- **NEVER write secrets** to source — use Key Vault / GitHub Secrets / .env.local (gitignored)
- **NEVER expose Terraform resources publicly** — no `0.0.0.0/0`, no `allow_blob_public_access = true`, no `public_network_access_enabled = true`
- **NEVER omit mandatory tags** on cloud resources — `cost-center`, `owner`, `environment`, `data-classification`
- **NEVER hand-edit AI-generated code that failed an invariant** — reject and regenerate (preserves provenance)
- **Always ask before any design decision** — never assume
- **Always ask before any destructive action** — never rm -rf unconfirmed paths

*(Add new guardrails as mistakes happen. Keep this under 15 items.)*

---

## Governance — Gartner 7 Invariants

This project enforces the seven behavioral invariants at three checkpoints. See `context/governance.md` for the full spec.

| Invariant | Enforced by |
|-----------|-------------|
| Functional | analyzers, linters, `enforce-invariants.sh` hook, CI build |
| Tested | `require-tests.sh` hook, ≥75% coverage gate in CI |
| Secure | `block-secrets.sh`, `block-tf-public-exposure.sh`, gitleaks, tfsec, checkov, CodeQL |
| Scalable | architecture review, SonarCloud rules |
| Performant | NFR-driven benchmarks in CI |
| Observable | OpenTelemetry from day one (see `docs/observability.md`) |
| Auditable | `provenance-stamp.sh` hook, conventional commits, SBOM (syft), signed artifacts |

**Hooks active in this project** (see `.claude/hooks/`):

| Hook | Phase | Purpose |
|------|-------|---------|
| `block-npm.sh` | PreToolUse Bash | Enforce pnpm |
| `block-git-push.sh` | PreToolUse Bash | Block unauthorized push |
| `block-terraform-apply.sh` | PreToolUse Bash | Apply only via pipeline |
| `block-no-verify.sh` | PreToolUse Bash | Forbid hook bypass |
| `block-destructive-actions.sh` | PreToolUse Bash | Block rm -rf, az delete |
| `block-claude-attribution.sh` | PreToolUse Bash | No AI authorship in commits |
| `block-secrets.sh` | PreToolUse Write/Edit | Detect AWS/GH/Azure/PEM secrets |
| `block-tf-public-exposure.sh` | PreToolUse Write/Edit | Block public CIDRs, public storage, weak TLS |
| `require-tf-tags.sh` | PreToolUse Write/Edit | Mandatory tags on every taggable resource |
| `enforce-invariants.sh` | PostToolUse Write/Edit | Lint/format on each file written |
| `require-tests.sh` | PostToolUse Write/Edit | Warn/block when prod code lacks a sibling test |
| `enforce-tf-policy.sh` | PostToolUse Write/Edit | tfsec + checkov on .tf files |
| `require-tf-module-tests.sh` | PostToolUse Write/Edit | Every TF module needs `tests/*.tftest.hcl` |
| `provenance-stamp.sh` | PostToolUse Write/Edit | Append to `.claude/provenance/*.jsonl` |

**Reporting**: `./tools/governance-report.sh` prints the success metrics (provenance completeness, bypass attempts, src↔test pairing, TF module coverage). Runs in CI as a soft gate.

---

## File Structure

```
{{projectName}}/
├── CLAUDE.md                  ← This file
├── .gitignore
├── README.md
├── .claude/
│   ├── settings.json          ← Hooks configuration
│   └── hooks/                 ← Governance hook scripts
├── goals/
│   └── manifest.md
├── context/
├── tools/
│   └── manifest.md
├── src/
│   ├── backend/
│   │   └── webapi/            ← .NET solution
│   └── frontend/              ← {{frontendFramework}} application
├── infrastructure/            ← Terraform modules
└── .github/
    └── workflows/             ← CI/CD pipelines
```

---

## Environments

| Environment | Purpose | Branch |
|-------------|---------|--------|
{{environmentsTable}}

---

## Local Development

{{localDevInstructions}}
