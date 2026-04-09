# Goal: Project Scaffolding via Interview

## Trigger

User opens this project and asks to create/scaffold/start a new project.

## Pre-conditions

- None. This is the starting point.

## Language

This file is the single source of truth, written in English. Claude MUST deliver the interview in the user's language:

1. **Detect language** from the user's first message (e.g. Spanish, English, French, etc.)
2. **Conduct the entire interview** — questions, options, examples, summary, and confirmation prompt — in that detected language.
3. **If the user switches language** mid-interview, follow their lead and switch too.
4. The confirmation keyword adapts to the language: "SÍ" (ES), "YES" (EN), or the equivalent affirmative in the detected language.

Everything below is written in English for maintainability. Claude translates at delivery time.

## Process

### Phase 0: Announce Intent

Tell the user (in their language):
> "I'm going to ask you a series of questions to generate your project scaffolding deterministically. I won't generate any files until we've answered all the questions. Please answer with as much detail as possible — I won't make assumptions."

Then begin Phase 1.

---

### Phase 1: Project Identity

Ask each question individually, wait for the answer before proceeding.

**Q1 — Project name**
> What is the project name? (PascalCase, e.g. `QuantumApi`, `DxPortal`, `SiroApp`)
- Used for: .NET namespaces, solution name, display name
- Derived automatically: kebab-case for repo/folder (e.g. `quantum-api`)

**Q2 — Project description**
> Describe the project in 1-2 sentences. What does it do and for whom?

---

### Phase 2: Requirements

This phase captures the project's architecture and requirements upfront. The user can paste as much or as little as they have — but encourage detail.

**Q3 — Architecture description**
> Describe the desired architecture of the project. You can be as detailed as you want:
> - What components does it have? (frontend, backend, APIs, workers, etc.)
> - How do they communicate with each other?
> - Are there external services or integrations?
>
> If you already have a diagram or document, paste it here.

**Q4 — Functional requirements**
> Paste or describe the functional requirements of the project.
> They can be user stories, use cases, or a list of features.
>
> Example:
> - As a user, I can register and log in
> - As an admin, I can manage users and roles
> - The system sends email notifications

**Q5 — Non-functional requirements**
> Paste or describe the non-functional requirements.
> Include: performance, availability, security, scalability, compliance, etc.
>
> Example:
> - 99.9% availability
> - Latency < 200ms at P95
> - GDPR compliance
> - Support for 10,000 concurrent users

---

### Phase 3: Project Type

**Q6 — Project type** (show options, wait for selection — multiple selections allowed)
> What type of project is this? You can choose more than one option (e.g. `1,2` or `1,3,5`).
>
> 1. **Web Frontend** — React/Vite, Next.js, etc.
> 2. **Backend / API** — .NET, Node.js, etc.
> 3. **Mobile** — React Native, .NET MAUI, Flutter
> 4. **Infrastructure** — Terraform, Pulumi
> 5. **Database** — Schema + migrations only
> 6. **Worker / Background service** — Jobs, queues, async processing
>
> **Common combinations:**
> - `1,2,4,5` = Full mono-repo (web + API + infra + DB) — most common
> - `2,5` = Backend + DB (no frontend)
> - `1` = Frontend only
> - `3,2,5` = Mobile + API + DB

Based on answer, proceed to Phase 4 with appropriate conditional questions.

---

### Phase 4: Tech Stack

Ask only the questions relevant to the selected project types from Phase 3.

**If includes Web Frontend (option 1):**

> Q7a — Frontend framework?
> 1. React + Vite (recommended)
> 2. Next.js

> Q7b — UI library?
> 1. shadcn/ui + Tailwind CSS (recommended)
> 2. MUI
> 3. No library (Tailwind only)

**If includes Backend / API (option 2):**

> Q7c — Backend technology?
> 1. .NET 10 (recommended)
> 2. .NET 9
> 3. .NET 8
> 4. Node.js + Express/Fastify

> Q7d — Database?
> 1. PostgreSQL (recommended)
> 2. SQL Server / Azure SQL
> 3. MongoDB
> 4. No database

**If includes Mobile (option 3):**

> Q7e — Mobile framework?
> 1. React Native + Expo
> 2. .NET MAUI
> 3. Flutter

> Q7f — Target platforms?
> 1. iOS + Android (both)
> 2. iOS only
> 3. Android only

**If includes Infrastructure (option 4):**

> Q7g — IaC tool?
> 1. Terraform (recommended)
> 2. Pulumi
> 3. Bicep (Azure only)

**If full mono-repo (frontend + backend selected):**

> Q7h — Local dev orchestration?
> 1. .NET Aspire (recommended)
> 2. docker-compose
> 3. Both

---

### Phase 5: Infrastructure & Auth

**Q8 — Authentication** (only if backend, API, or mobile selected)
> How do users authenticate?
> 1. Azure AD / Entra ID (OpenID Connect)
> 2. Local JWT (own identity server)
> 3. Auth0 / third-party provider
> 4. No authentication (internal/private API)

**Q9 — Cloud infrastructure** (only if infrastructure selected or full mono-repo)
> Which cloud does it deploy to?
> 1. Azure (AKS, Container Apps, Azure SQL, etc.)
> 2. AWS (ECS, RDS, etc.)
> 3. GCP (Cloud Run, Cloud SQL, etc.)
> 4. No cloud infra (local/generic k8s only)

**Q10 — Environments**
> What environments do you need?
> 1. dev + staging + prod (standard)
> 2. dev + prod
> 3. dev only (MVP/POC)
> 4. Custom (specify which ones)

---

### Phase 6: DevOps & Governance

**Q11 — Git platform**
> Where will the source code be hosted?
> 1. GitHub
> 2. GitLab
> 3. Azure DevOps Repos

**Q12 — Organization / group**
> What is the name of the organization, group, or project where the repository will be published?
> - GitHub: organization or user (e.g. `mycompany`)
> - GitLab: group (e.g. `mycompany/platform`)
> - Azure DevOps: organization/project (e.g. `mycompany/MyProject`)

**Q13 — CI/CD**
> How is it built and deployed?
> 1. GitHub Actions (recommended if GitHub)
> 2. GitLab CI/CD (recommended if GitLab)
> 3. Azure DevOps Pipelines (recommended if ADO)
> 4. Combination (specify)

**Q14 — Issue tracking & project management**
> Where do you want to manage issues and project work?
> 1. GitHub Issues + Projects (recommended if GitHub)
> 2. Azure DevOps Boards + Work Items
> 3. GitLab Issues + Boards
> 4. Jira
> 5. Linear
> 6. Don't create issues automatically
>
> If you choose a supported option (1, 2, or 3), when generating the project I'll create the initial issues/work items automatically based on the modules and requirements you defined.

**Q15 — AI development methodology**
> Do you want to apply any of these methodologies to structure work with AI?
>
> 1. **ATLAS + GOTCHA + SDD** (recommended) — Combines architectural thinking (ATLAS), structured prompts (GOTCHA), and spec-driven development (SDD). [More info](https://blog.victorz.cloud/blog/article-09-sdd-comparison)
>    - **ATLAS:** Architect → Trace → Link → Assemble → Stress-test
>    - **GOTCHA:** Goals → Orchestration → Tools → Context → Heuristics → Args
>    - **SDD:** Specify → Plan → Execute (specs as primary artifacts)
> 2. **GOTCHA only** — Just the structured prompt framework (already included by default in scaffolding)
> 3. **No additional methodology** — Just the basic scaffolding with CLAUDE.md
>
> If you choose option 1, the project will include:
> - `specs/` — SDD specification directory (user stories, acceptance criteria)
> - `atlas/` — ATLAS checklists per feature/component
> - Full GOTCHA framework in `goals/`, `context/`, `tools/`
> - Issue template following the flow: User Story (SDD) → ATLAS Checklist → GOTCHA Prompt → Task Breakdown → Code

---

### Phase 6.5: Governance (Gartner 7-invariant model)

Reference: `context/governance.md`. Ask each question individually.

**Q15a — Adopt the Gartner 7-invariant governance model?**
> The model enforces Functional, Tested, Secure, Scalable, Performant, Observable and Auditable invariants at three checkpoints (generation hooks, pre-commit, CI/CD). Recommended for any project that will reach production.
> 1. Yes — full model (hooks + pre-commit + CI/CD gates + provenance ledger)
> 2. Minimal — only generation hooks and pre-commit (no CI/CD gates yet)
> 3. No — keep current basic governance only

**Q15b — Reasoning-based security scanning?** (only if Q15a = 1 or 2)
> Augment SAST/DAST with Claude Code Security (data-flow + business-logic analysis). Pilot recommended on a non-critical app first.
> 1. Yes — integrate from day one
> 2. Pilot only (manual trigger)
> 3. No

**Q15c — Route Claude Code traffic via a corporate LLM Gateway?**
> Provides unified auth, usage tracking, cost controls, audit logging.
> - If Yes: provide the gateway base URL (becomes `ANTHROPIC_BASE_URL` in managed settings).
> - If No: skip.

**Q15d — OpenTelemetry export endpoint?** (only if Q15a = 1)
> Required for the "Observable" invariant. Provide:
> - OTLP endpoint (e.g. `https://otel.mycompany.internal`) or `none`
> - Cost-center / team tag (e.g. `team=platform,costcenter=eng-001`)

**Q15e — MCP server allowlist for this project?**
> Comma-separated list of MCP servers the agents in this project may use, or `none` for full lockdown, or `inherit` to use global config.

**Q15f — WebFetch domain allowlist?**
> Comma-separated trusted domains for agent web access, or `none` for no internet, or `unrestricted` (not recommended).

**Q15h–Q15o — Terraform/IaC governance** (ONLY if Q6 includes option 4 Infrastructure)

> **Q15h — Required tags** (mandatory on every taggable resource)
> Provide comma-separated list, or accept default: `cost-center,owner,environment,data-classification`
> Written to `.claude/tf-required-tags` and enforced by `require-tf-tags.sh` + OPA policy.

> **Q15i — Allowed cloud regions** (whitelist)
> Comma-separated (e.g. `westeurope,northeurope`). Used in `policy/allowed_regions.rego` for data-residency enforcement.

> **Q15j — Terraform state backend**
> 1. azurerm (storage account + blob lock)
> 2. s3 (bucket + DynamoDB lock)
> 3. gcs
> 4. terraform cloud / HCP
> 5. local (POC only — not for production)

> **Q15k — Blast-radius / state segmentation**
> 1. one-state-per-env (dev/stg/prod) — small projects
> 2. one-state-per-stack-per-env (network/data/compute × dev/stg/prod) — recommended
> 3. monolithic single state — discouraged

> **Q15l — Private module registry?**
> URL of the private Terraform module registry (e.g. `app.terraform.io/myorg`, ADO Artifacts feed, GitLab module registry), or `none` to use only local `modules/` paths.

> **Q15m — Drift detection schedule**
> 1. daily (cron in CI/CD against prod state)
> 2. weekly
> 3. on-demand only
> 4. off

> **Q15n — Cost guardrails (Infracost)**
> Monthly $ delta threshold above which a PR is blocked (e.g. `500`), or `off` to only report.

> **Q15o — OIDC federated cloud auth?**
> 1. Yes — generate workload-identity federation config (no SP secrets in repo)
> 2. No — use long-lived secrets (discouraged)

**Q15g — Provenance level?** (only if Q15a = 1 or 2)
> 1. Basic — file → session ledger (`.claude/provenance/*.jsonl`)
> 2. Full — basic + prompt hashes + model version + decision chain
> 3. Off

---

### Phase 7: Modules

**Q16 — Application modules**
> List the main modules or sections of the application. Examples: `Auth`, `Users`, `Dashboard`, `Reports`, `Notifications`, `Admin`.
>
> Write them separated by commas. These will be the base modules created in backend and frontend.

---

### Phase 8: Output

**Q17 — Output directory**
> Where do you want to generate the project? Provide the absolute path.
> (e.g. `/Users/victorzaragoza/Documents/Dev/k/mynewproject`)
>
> IMPORTANT: Never use a relative path. Confirm the path exists or will be created.

---

### Phase 9: Confirmation

Before generating ANY file, present a full summary **in the user's language**:

```
PROJECT SUMMARY
===============
Name:           {ProjectName}
Description:    {description}

REQUIREMENTS
------------
Architecture:   {architectureSummary} (summary of what the user described)
Functional:     {functionalReqCount} requirements captured
Non-functional: {nonFunctionalReqCount} requirements captured

PROJECT TYPE
------------
Components:     {selectedTypes} (e.g. Web Frontend + Backend/API + Infrastructure + DB)

STACK
-----
Frontend:       {frontendFramework} + {uiLibrary}
Backend:        {backendTech} (Clean Architecture)
Mobile:         {mobileFramework} — {mobilePlatforms}
Database:       {database}
IaC:            {iacTool}
Local dev:      {localDev}

INFRASTRUCTURE
--------------
Auth:           {authType}
Cloud:          {cloud}
Environments:   {environments}

DEVOPS & GOVERNANCE
-------------------
Git platform:   {gitPlatform}
Organization:   {orgName}
Repo:           {orgName}/{project-name-kebab}
CI/CD:          {cicd}
Issue tracking: {issueTracking}
AI methodology: {methodology}

GARTNER GOVERNANCE
------------------
7-invariant model: {full | minimal | off}
Reasoning security:{yes | pilot | no}
LLM Gateway:       {url | none}
OpenTelemetry:     {endpoint | none} (tags: {tags})
MCP allowlist:     {list | none | inherit}
WebFetch allowlist:{domains | none | unrestricted}
Provenance:        {basic | full | off}

# Only show this block if Q6 includes Infrastructure (Terraform):
TERRAFORM GOVERNANCE
--------------------
Required tags:     {Q15h list}
Allowed regions:   {Q15i list}
State backend:     {Q15j}
Segmentation:      {Q15k}
Module registry:   {Q15l | none}
Drift detection:   {Q15m}
Cost guardrail:    {Q15n $/PR | off}
OIDC auth:         {yes | no}

MODULES
-------
{module1}, {module2}, ...

OUTPUT
------
Directory:      {outputPath}

Is everything correct? Answer YES to generate, or indicate what to change.
```

Only proceed after explicit affirmative confirmation (YES / SÍ / equivalent).

---

### Phase 10: Generation

Generate files in this order (announce each group before creating):

1. **Root structure** — `.gitignore`, `README.md`, `CLAUDE.md`, `.npmrc` (pnpm hardening if applicable)
2. **Claude config** — `.claude/settings.json` from `context/templates/managed-settings.template.json` (managed hierarchy if Q15a≠off), `.claude/hooks/*.sh` including governance hooks (`block-secrets`, `enforce-invariants`, `require-tests`, `provenance-stamp`, plus the 4 Terraform hooks if infra selected) per `context/governance.md`. Substitute placeholders from interview answers:
   - `{{LLM_GATEWAY_URL}}` ← Q15c (or remove env var if empty)
   - `{{OTEL_ENDPOINT}}`, `{{TEAM}}`, `{{COST_CENTER}}` ← Q15d
   - `{{ALLOWED_DOMAIN_*}}` ← Q15f
   - `{{MCP_SERVER_*}}` ← Q15e
   Also emit `tools/governance-report.sh` (copy from this project's `tools/`) so the generated repo can self-report metrics.
   If Q15d ≠ none, also emit `docs/observability.md` from `context/templates/opentelemetry.template.md` with placeholders substituted, and instrumentation snippets for the selected backend/frontend.
3. **GOTCHA framework** — `goals/manifest.md`, `context/`, `tools/manifest.md`
4. **SDD + ATLAS artifacts** (if methodology option 1 selected):
   - `specs/` — Specification templates (user stories, acceptance criteria, NFRs)
   - `specs/functional/` — Functional requirements captured during interview
   - `specs/non-functional/` — Non-functional requirements captured during interview
   - `atlas/` — ATLAS checklist templates per component
   - Issue templates following SDD → ATLAS → GOTCHA flow
5. **Backend** — .NET solution, projects, tests (Clean Architecture)
6. **Frontend** — Vite + React app, component structure, routing
7. **Mobile** — React Native / MAUI / Flutter project structure (if selected)
8. **Infrastructure** — Terraform/Pulumi/Bicep modules, variables, environments. If Terraform + Q15a≠off:
    - `.tflint.hcl` from `context/templates/tflint.template.hcl` (resolve `{{IF_AZURE/AWS/GCP}}` from Q9)
    - `.claude/tf-required-tags` with the list from Q15h
    - `policy/required_tags.rego`, `policy/deny_public.rego`, `policy/allowed_regions.rego` (substitute `{{ALLOWED_REGIONS}}` from Q15i)
    - `modules/<name>/` skeletons from `context/templates/tf-module/*` for each module declared, including `tests/basic.tftest.hcl`
    - State backend config block per Q15j, segmented per Q15k
    - Module sources point to private registry from Q15l when provided
9. **Local dev** — Aspire AppHost or docker-compose
10. **CI/CD** — GitHub Actions / GitLab CI / ADO pipeline YAML. If Q15a ∈ {full, minimal}, also generate:
    - `.pre-commit-config.yaml` from `context/templates/pre-commit-config.template.yaml` (substitute `{{PROJECT_NAME}}` and resolve `{{IF_DOTNET}}` / `{{IF_FRONTEND}}` / `{{IF_TERRAFORM}}` blocks based on Phase 3 selections)
    - `Directory.Build.props` (root of .NET solution) from `context/templates/Directory.Build.props.template` if backend selected — enforces analyzers, nullable, TreatWarningsAsErrors, deterministic builds
    - Governance workflow re-running the seven invariants in a clean env, picked by Q11/Q13:
      - GitHub → `.github/workflows/governance.yml` from `context/templates/governance.github.template.yml`
      - GitLab → `governance.gitlab.yml` from `context/templates/governance.gitlab.template.yml`
      - Azure DevOps → `governance.ado.yml` from `context/templates/governance.ado.template.yml`
    - If Terraform selected, ALSO emit a Terraform-specific governance pipeline (in addition to the app one):
      - GitHub → `.github/workflows/terraform-governance.yml` from `context/templates/governance.terraform.github.template.yml`
      - GitLab → `governance.terraform.gitlab.yml` from `context/templates/governance.terraform.gitlab.template.yml`
      - Azure DevOps → `governance.terraform.ado.yml` from `context/templates/governance.terraform.ado.template.yml`
      - Configure Infracost threshold (Q15n), drift cron (Q15m) and OIDC auth (Q15o) in the emitted file
      - If Q15o = yes, ALSO emit `docs/oidc-setup.md` from `context/templates/oidc-setup.template.md` with the appropriate `{{IF_AZURE/AWS/ADO}}` block resolved per Q9 + Q11. This is the runbook the user follows once to bootstrap federated credentials — do NOT execute the `az`/`aws` commands inside.
    - `GOVERNANCE.md` in the project root linking back to `context/governance.md` semantics and listing the seven invariants + how each is enforced in this specific project
11. **Issue creation** (if issue tracking selected):
    - Generate initial issues/work items based on modules and requirements
    - For GitHub: print `gh issue create` commands as a runnable script
    - For Azure DevOps: print `az boards work-item create` commands as a runnable script
    - For GitLab: print `glab issue create` commands as a runnable script
    - Issues follow the structure: one epic/feature per module, child tasks per functional requirement
    - If ATLAS+GOTCHA+SDD selected, each issue includes the SDD spec template and ATLAS checklist
12. **Git platform setup** — Print commands to create repo, labels, milestones (do NOT execute)
13. **AI agent skills** — run `npx autoskills -y` in `{outputPath}` to auto-install relevant AI skills.
    > NOTE: autoskills writes files into `.claude/skills/` which would normally trigger `enforce-invariants.sh`, `require-tests.sh` and `provenance-stamp.sh`. Run autoskills BEFORE the governance hooks are wired (i.e. before step 2's hook activation) OR temporarily set `CLAUDE_HOOKS_DISABLED=1` for the duration of this single command and re-enable immediately. Provenance for autoskills-generated files is captured by a one-shot `tools/stamp-existing-files.sh` after the command completes.

## Post-conditions

- All files created in `{outputPath}`
- AI agent skills installed for the detected stack (via autoskills)
- Requirements captured in `specs/` (if SDD selected) or `docs/` directory
- Initial issues generated as runnable script (if issue tracking selected)
- A `NEXT-STEPS.md` is generated with:
  1. Git init + first commit instructions
  2. Repo creation command (GitHub/GitLab/ADO)
  3. Local dev startup instructions
  4. Issue creation script execution instructions
  5. First sprint/iteration planning guidance (if ATLAS+GOTCHA+SDD)

## Constraints

- NEVER generate files until Phase 9 affirmative confirmation is received
- NEVER make design decisions on behalf of the user (module names, folder names, port numbers — all come from answers)
- NEVER push to any git remote (print the commands, let the user run them)
- NEVER run `terraform apply` or any destructive command
- NEVER create issues automatically — always generate as a script the user runs
- If a question is skipped or unclear, ask again — never assume
