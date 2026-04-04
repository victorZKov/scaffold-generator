# Goal: Project Scaffolding via Interview

## Trigger

User opens this project and asks to create/scaffold/start a new project.

## Pre-conditions

- None. This is the starting point.

## Process

### Phase 0: Announce Intent

Tell the user:
> "Voy a hacerte una serie de preguntas para generar el scaffolding de tu proyecto de manera determinista. No generaré ningún archivo hasta que hayamos respondido todas las preguntas. Responde con el mayor detalle posible — no hagas suposiciones."

Then begin Phase 1.

---

### Phase 1: Project Identity

Ask each question individually, wait for the answer before proceeding.

**Q1 — Project name**
> ¿Cómo se llama el proyecto? (PascalCase, ej: `QuantumApi`, `DxPortal`, `SiroApp`)
- Used for: .NET namespaces, solution name, display name
- Derived automatically: kebab-case for repo/folder (e.g. `quantum-api`)

**Q2 — Project description**
> Describe el proyecto en 1-2 frases. ¿Qué hace y para quién?

---

### Phase 2: Requirements

This phase captures the project's architecture and requirements upfront. The user can paste as much or as little as they have — but encourage detail.

**Q3 — Architecture description**
> Describe la arquitectura deseada del proyecto. Puedes ser tan detallado como quieras:
> - ¿Qué componentes tiene? (frontend, backend, APIs, workers, etc.)
> - ¿Cómo se comunican entre sí?
> - ¿Hay servicios externos o integraciones?
>
> Si ya tienes un diagrama o documento, pégalo aquí.

**Q4 — Functional requirements**
> Pega o describe los requerimientos funcionales del proyecto.
> Pueden ser user stories, casos de uso, o una lista de funcionalidades.
>
> Ejemplo:
> - Como usuario, puedo registrarme e iniciar sesión
> - Como admin, puedo gestionar usuarios y roles
> - El sistema envía notificaciones por email

**Q5 — Non-functional requirements**
> Pega o describe los requerimientos no funcionales.
> Incluye: rendimiento, disponibilidad, seguridad, escalabilidad, compliance, etc.
>
> Ejemplo:
> - Disponibilidad 99.9%
> - Latencia < 200ms en P95
> - GDPR compliance
> - Soporte para 10,000 usuarios concurrentes

---

### Phase 3: Project Type

**Q6 — Project type** (show options, wait for selection — multiple selections allowed)
> ¿Qué tipo de proyecto es? Puedes elegir más de una opción (ej: `1,2` o `1,3,5`).
>
> 1. **Web Frontend** — React/Vite, Next.js, etc.
> 2. **Backend / API** — .NET, Node.js, etc.
> 3. **Mobile** — React Native, .NET MAUI, Flutter
> 4. **Infrastructure** — Terraform, Pulumi
> 5. **Database** — Solo esquema + migraciones
> 6. **Worker / Background service** — Jobs, colas, procesamiento async
>
> **Combinaciones comunes:**
> - `1,2,4,5` = Full mono-repo (web + API + infra + DB) — más común
> - `2,5` = Backend + DB (sin frontend)
> - `1` = Solo frontend
> - `3,2,5` = Mobile + API + DB

Based on answer, proceed to Phase 4 with appropriate conditional questions.

---

### Phase 4: Tech Stack

Ask only the questions relevant to the selected project types from Phase 3.

**If includes Web Frontend (option 1):**

> Q7a — ¿Framework frontend?
> 1. React + Vite (recomendado)
> 2. Next.js

> Q7b — ¿Librería UI?
> 1. shadcn/ui + Tailwind CSS (recomendado)
> 2. MUI
> 3. Sin librería (solo Tailwind)

**If includes Backend / API (option 2):**

> Q7c — ¿Tecnología backend?
> 1. .NET 10 (recomendado)
> 2. .NET 9
> 3. .NET 8
> 4. Node.js + Express/Fastify

> Q7d — ¿Base de datos?
> 1. PostgreSQL (recomendado)
> 2. SQL Server / Azure SQL
> 3. MongoDB
> 4. Sin base de datos

**If includes Mobile (option 3):**

> Q7e — ¿Framework mobile?
> 1. React Native + Expo
> 2. .NET MAUI
> 3. Flutter

> Q7f — ¿Plataformas target?
> 1. iOS + Android (ambas)
> 2. Solo iOS
> 3. Solo Android

**If includes Infrastructure (option 4):**

> Q7g — ¿Herramienta de IaC?
> 1. Terraform (recomendado)
> 2. Pulumi
> 3. Bicep (Azure only)

**If full mono-repo (frontend + backend selected):**

> Q7h — ¿Local dev orchestration?
> 1. .NET Aspire (recomendado)
> 2. docker-compose
> 3. Ambos

---

### Phase 5: Infrastructure & Auth

**Q8 — Authentication** (only if backend, API, or mobile selected)
> ¿Cómo se autentican los usuarios?
> 1. Azure AD / Entra ID (OpenID Connect)
> 2. JWT local (propio identity server)
> 3. Auth0 / third-party provider
> 4. Sin autenticación (API interna/privada)

**Q9 — Cloud infrastructure** (only if infrastructure selected or full mono-repo)
> ¿En qué cloud se despliega?
> 1. Azure (AKS, Container Apps, Azure SQL, etc.)
> 2. AWS (ECS, RDS, etc.)
> 3. GCP (Cloud Run, Cloud SQL, etc.)
> 4. Sin infra cloud (solo local/k8s genérico)

**Q10 — Environments**
> ¿Qué entornos necesitas?
> 1. dev + staging + prod (estándar)
> 2. dev + prod
> 3. Solo dev (MVP/POC)
> 4. Personalizado (especifica cuáles)

---

### Phase 6: DevOps & Governance

**Q11 — Git platform**
> ¿Dónde se alojará el código fuente?
> 1. GitHub
> 2. GitLab
> 3. Azure DevOps Repos

**Q12 — Organization / group**
> ¿Cuál es el nombre de la organización, grupo, o proyecto donde se publicará el repositorio?
> - GitHub: organización o usuario (ej: `mycompany`)
> - GitLab: grupo (ej: `mycompany/platform`)
> - Azure DevOps: organización/proyecto (ej: `mycompany/MyProject`)

**Q13 — CI/CD**
> ¿Cómo se construye y despliega?
> 1. GitHub Actions (recomendado si GitHub)
> 2. GitLab CI/CD (recomendado si GitLab)
> 3. Azure DevOps Pipelines (recomendado si ADO)
> 4. Combinación (especifica)

**Q14 — Issue tracking & project management**
> ¿Dónde quieres gestionar issues y trabajo del proyecto?
> 1. GitHub Issues + Projects (recomendado si GitHub)
> 2. Azure DevOps Boards + Work Items
> 3. GitLab Issues + Boards
> 4. Jira
> 5. Linear
> 6. No crear issues automáticamente
>
> Si eliges una opción con soporte (1, 2, o 3), al generar el proyecto crearé los issues/work items iniciales automáticamente basándome en los módulos y requerimientos que definiste.

**Q15 — Metodología de desarrollo con AI**
> ¿Quieres aplicar alguna de estas metodologías para estructurar el trabajo con AI?
>
> 1. **ATLAS + GOTCHA + SDD** (recomendado) — Combina pensamiento arquitectónico (ATLAS), prompts estructurados (GOTCHA), y desarrollo dirigido por especificaciones (SDD). [Más info](https://blog.victorz.cloud/blog/article-09-sdd-comparison)
>    - **ATLAS:** Architect → Trace → Link → Assemble → Stress-test
>    - **GOTCHA:** Goals → Orchestration → Tools → Context → Heuristics → Args
>    - **SDD:** Specify → Plan → Execute (specs como artefactos primarios)
> 2. **GOTCHA solamente** — Solo el framework de prompts estructurados (ya incluido por defecto en el scaffolding)
> 3. **Sin metodología adicional** — Solo el scaffolding básico con CLAUDE.md
>
> Si eliges la opción 1, el proyecto incluirá:
> - `specs/` — Directorio de especificaciones SDD (user stories, acceptance criteria)
> - `atlas/` — Checklists ATLAS por feature/componente
> - GOTCHA framework completo en `goals/`, `context/`, `tools/`
> - Template de issue que sigue el flujo: User Story (SDD) → ATLAS Checklist → GOTCHA Prompt → Task Breakdown → Code

---

### Phase 7: Modules

**Q16 — Application modules**
> Lista los módulos o secciones principales de la aplicación. Ejemplos: `Auth`, `Users`, `Dashboard`, `Reports`, `Notifications`, `Admin`.
>
> Escríbelos separados por comas. Estos serán los módulos base que se crearán en backend y frontend.

---

### Phase 8: Output

**Q17 — Output directory**
> ¿Dónde quieres generar el proyecto? Proporciona la ruta absoluta.
> (Ej: `/Users/victorzaragoza/Documents/Dev/k/mynewproject`)
>
> IMPORTANT: Never use a relative path. Confirm the path exists or will be created.

---

### Phase 9: Confirmation

Before generating ANY file, present a full summary:

```
RESUMEN DEL PROYECTO
====================
Nombre:         {ProjectName}
Descripción:    {description}

REQUERIMIENTOS
--------------
Arquitectura:   {architectureSummary} (resumen de lo que describió el usuario)
Funcionales:    {functionalReqCount} requerimientos capturados
No funcionales: {nonFunctionalReqCount} requerimientos capturados

TIPO DE PROYECTO
----------------
Componentes:    {selectedTypes} (ej: Web Frontend + Backend/API + Infrastructure + DB)

STACK
-----
Frontend:       {frontendFramework} + {uiLibrary}
Backend:        {backendTech} (Clean Architecture)
Mobile:         {mobileFramework} — {mobilePlatforms}
Base de datos:  {database}
IaC:            {iacTool}
Local dev:      {localDev}

INFRAESTRUCTURA
---------------
Auth:           {authType}
Cloud:          {cloud}
Entornos:       {environments}

DEVOPS & GOVERNANCE
-------------------
Git platform:   {gitPlatform}
Organización:   {orgName}
Repo:           {orgName}/{project-name-kebab}
CI/CD:          {cicd}
Issue tracking: {issueTracking}
Metodología AI: {methodology}

MÓDULOS
-------
{module1}, {module2}, ...

SALIDA
------
Directorio:     {outputPath}

¿Todo correcto? Responde SÍ para generar, o indica qué cambiar.
```

Only proceed after explicit "SÍ" confirmation.

---

### Phase 10: Generation

Generate files in this order (announce each group before creating):

1. **Root structure** — `.gitignore`, `README.md`, `CLAUDE.md`, `.npmrc` (pnpm hardening if applicable)
2. **Claude config** — `.claude/settings.json`, `.claude/hooks/*.sh`
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
8. **Infrastructure** — Terraform/Pulumi/Bicep modules, variables, environments
9. **Local dev** — Aspire AppHost or docker-compose
10. **CI/CD** — GitHub Actions / GitLab CI / ADO pipeline YAML
11. **Issue creation** (if issue tracking selected):
    - Generate initial issues/work items based on modules and requirements
    - For GitHub: print `gh issue create` commands as a runnable script
    - For Azure DevOps: print `az boards work-item create` commands as a runnable script
    - For GitLab: print `glab issue create` commands as a runnable script
    - Issues follow the structure: one epic/feature per module, child tasks per functional requirement
    - If ATLAS+GOTCHA+SDD selected, each issue includes the SDD spec template and ATLAS checklist
12. **Git platform setup** — Print commands to create repo, labels, milestones (do NOT execute)
13. **AI agent skills** — run `npx autoskills -y` in `{outputPath}` to auto-install relevant AI skills

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

- NEVER generate files until Phase 9 "SÍ" confirmation is received
- NEVER make design decisions on behalf of the user (module names, folder names, port numbers — all come from answers)
- NEVER push to any git remote (print the commands, let the user run them)
- NEVER run `terraform apply` or any destructive command
- NEVER create issues automatically — always generate as a script the user runs
- If a question is skipped or unclear, ask again — never assume
