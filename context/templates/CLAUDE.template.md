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
- **Always ask before any design decision** — never assume
- **Always ask before any destructive action** — never rm -rf unconfirmed paths

*(Add new guardrails as mistakes happen. Keep this under 15 items.)*

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
