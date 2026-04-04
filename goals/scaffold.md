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

**Q3 — GitHub organization**
> ¿Cuál es el nombre de la organización o usuario de GitHub donde se publicará el repositorio privado?

---

### Phase 2: Tech Stack

**Q4 — Stack type** (show options, wait for selection)
> ¿Qué tipo de proyecto es?
>
> 1. **Full mono-repo** — Terraform infra + React/Vite frontend + .NET backend + PostgreSQL DB (más común)
> 2. **Backend + DB** — Solo .NET + PostgreSQL (sin frontend, sin infra)
> 3. **Frontend** — Solo React/Vite (sin backend)
> 4. **Infra** — Solo Terraform

Based on answer:

**If includes frontend:**
> Q4a — ¿Framework frontend?
> 1. React + Vite (recomendado)
> 2. Next.js

> Q4b — ¿Librería UI?
> 1. shadcn/ui + Tailwind CSS (recomendado)
> 2. MUI
> 3. Sin librería (solo Tailwind)

**If includes backend:**
> Q4c — ¿Versión de .NET?
> 1. .NET 10 (recomendado)
> 2. .NET 9
> 3. .NET 8

> Q4d — ¿Base de datos?
> 1. PostgreSQL (recomendado)
> 2. SQL Server / Azure SQL
> 3. Sin base de datos

**If full mono-repo:**
> Q4e — ¿Local dev?
> 1. .NET Aspire (recomendado)
> 2. docker-compose
> 3. Ambos

---

### Phase 3: Infrastructure & Auth

**Q5 — Authentication** (only if backend or full)
> ¿Cómo se autentican los usuarios?
> 1. Azure AD / Entra ID (OpenID Connect)
> 2. JWT local (propio identity server)
> 3. Sin autenticación (API interna/privada)

**Q6 — Cloud infrastructure** (only if full mono-repo or infra)
> ¿En qué cloud se despliega?
> 1. Azure (AKS, Azure SQL, etc.)
> 2. AWS
> 3. GCP
> 4. Sin infra cloud (solo local/k8s genérico)

**Q7 — Environments**
> ¿Qué entornos necesitas?
> 1. dev + staging + prod (estándar)
> 2. dev + prod
> 3. Solo dev (MVP/POC)
> 4. Personalizado (especifica cuáles)

**Q8 — CI/CD**
> ¿Cómo se construye y despliega?
> 1. GitHub Actions (recomendado)
> 2. Azure DevOps Pipelines
> 3. Ambos

---

### Phase 4: Modules

**Q9 — Application modules**
> Lista los módulos o secciones principales de la aplicación. Ejemplos: `Auth`, `Users`, `Dashboard`, `Reports`, `Notifications`, `Admin`.
>
> Escríbelos separados por comas. Estos serán los módulos base que se crearán en backend y frontend.

---

### Phase 5: Output

**Q10 — Output directory**
> ¿Dónde quieres generar el proyecto? Proporciona la ruta absoluta.
> (Ej: `/Users/victorzaragoza/Documents/Dev/k/mynewproject`)
>
> IMPORTANT: Never use a relative path. Confirm the path exists or will be created.

---

### Phase 6: Confirmation

Before generating ANY file, present a full summary:

```
RESUMEN DEL PROYECTO
====================
Nombre:         {ProjectName}
Descripción:    {description}
GitHub Org:     {githubOrg}
Repo:           {github-org}/{project-name-kebab}

STACK
-----
Tipo:           {stackType}
Frontend:       {frontendFramework} + {uiLibrary}
Backend:        .NET {dotnetVersion} (Clean Architecture)
Base de datos:  {database}
Local dev:      {localDev}

INFRAESTRUCTURA
---------------
Auth:           {authType}
Cloud:          {cloud}
Entornos:       {environments}
CI/CD:          {cicd}

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

### Phase 7: Generation

Generate files in this order (announce each group before creating):

1. **Root structure** — `.gitignore`, `README.md`, `CLAUDE.md`, `.npmrc` (pnpm hardening)
2. **Claude config** — `.claude/settings.json`, `.claude/hooks/*.sh`
3. **GOTCHA framework** — `goals/manifest.md`, `context/`, `tools/manifest.md`
4. **Backend** — .NET solution, projects, tests (Clean Architecture)
5. **Frontend** — Vite + React app, component structure, routing
6. **Infrastructure** — Terraform modules, variables, environments
7. **Local dev** — Aspire AppHost or docker-compose
8. **CI/CD** — GitHub Actions workflows or ADO pipeline YAML
9. **GitHub setup** — `gh` commands to create repo, labels, milestones (print as runnable block, do NOT execute)
10. **AI agent skills** — run `npx autoskills -y` in `{outputPath}` to auto-install relevant AI skills (Claude Code, Cursor, etc.) based on the detected stack

## Post-conditions

- All files created in `{outputPath}`
- AI agent skills installed for the detected stack (via autoskills)
- A `NEXT-STEPS.md` is generated with:
  1. Git init + first commit instructions
  2. GitHub repo creation command
  3. Local dev startup instructions
  4. First GitHub Issue to create

## Constraints

- NEVER generate files until Phase 6 "SÍ" confirmation is received
- NEVER make design decisions on behalf of the user (module names, folder names, port numbers — all come from answers)
- NEVER push to GitHub (print the commands, let the user run them)
- NEVER run `terraform apply` or any destructive command
- If a question is skipped or unclear, ask again — never assume
