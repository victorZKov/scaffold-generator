# Goals Manifest — Startup Scaffolding Generator

## Purpose

This project generates deterministic, production-grade project scaffolding for new projects. It conducts a structured interview with the user and then generates all required files without ambiguity.

## Active Goals

| ID | Goal | Status | File |
|----|------|--------|------|
| G-01 | Project scaffolding via interview | Active | `scaffold.md` |

## Principles

1. **Never generate without full answers** — all interview questions must be answered before generating any file.
2. **Deterministic output** — the same answers must always produce the same files.
3. **No shortcuts** — generate complete, production-ready structures, not stubs.
4. **Security first** — every generated project includes security guardrails from day one.
5. **One decision at a time** — never assume answers. Ask.

## What This System Generates

Given a set of answers, this system produces:

- `CLAUDE.md` — project handbook (pre-filled)
- `.claude/settings.json` — hooks configuration
- `.claude/hooks/` — all governance hook scripts
- `.gitignore` — comprehensive ignore rules
- `README.md` — project overview skeleton
- `src/backend/` — .NET Clean Architecture solution structure
- `src/frontend/` — React + Vite application structure
- `infrastructure/` — Terraform module skeleton
- `docker-compose.yml` or Aspire `AppHost` — local dev
- `.github/workflows/` — CI/CD pipeline definitions
- `goals/`, `context/`, `tools/` — GOTCHA framework skeleton

## Reference Projects

- `/Users/victorzaragoza/Documents/Dev/k/tb/DXPortal` — Full stack, Azure, ADO pipelines
- `/Users/victorzaragoza/Documents/Dev/k/quantumapi` — Full stack, multi-tenant SaaS, GitHub Actions
