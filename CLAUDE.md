# CLAUDE.md — Startup Scaffolding Generator

## What This Project Is

This project generates deterministic, production-grade scaffolding for new projects. It conducts a structured interview and produces all required files without making design assumptions.

**Reference projects:**
- `/Users/victorzaragoza/Documents/Dev/k/tb/DXPortal` — Full stack, Azure, ADO pipelines
- `/Users/victorzaragoza/Documents/Dev/k/quantumapi` — Full stack, SaaS, GitHub Actions

---

## How to Use This

When the user asks to create / scaffold / start a new project, follow **`goals/scaffold.md`** exactly:

1. Announce the interview process
2. Ask questions one at a time — wait for each answer
3. Never generate files until receiving explicit "SÍ" confirmation
4. Generate in the prescribed order

**Never take shortcuts. Never assume answers. Always ask.**

---

## Standard Tech Stack

Our standard mono-repo project uses:

| Layer | Technology |
|-------|-----------|
| Frontend | React + Vite + TypeScript + shadcn/ui + Tailwind CSS |
| Backend | .NET 10 (Clean Architecture) |
| Database | PostgreSQL |
| Local dev | .NET Aspire |
| Infrastructure | Terraform (Azure) |
| CI/CD | GitHub Actions |
| Package manager | **pnpm only** (never npm) |
| Auth | Azure AD / Entra ID |

---

## Architecture Reference

See `context/architecture.md` for:
- .NET Clean Architecture layer structure and naming conventions
- React/Vite directory structure and key packages
- Terraform module pattern (Azure)
- Aspire AppHost pattern
- GitHub Actions workflow patterns
- Code coverage requirements (75% minimum)
- GitHub issue governance

---

## CRITICAL: Guardrails

These are non-negotiable. Hooks enforce most of them automatically.

| Rule | Enforced by hook |
|------|-----------------|
| **Never use npm** — always pnpm | `block-npm.sh` |
| **Never git push** without explicit user authorization | `block-git-push.sh` |
| **Never terraform apply** — pipelines only | `block-terraform-apply.sh` |
| **Never --no-verify** — fix the hook, don't skip | `block-no-verify.sh` |
| **Never Claude attribution** in commits | `block-claude-attribution.sh` |
| **Never destructive az CLI** — only read-only | `block-destructive-actions.sh` |
| **Never rm -rf** without explicit confirmation | `block-destructive-actions.sh` |

### Additional guardrails (not hook-enforced)

- **Never make design decisions** — module names, folder names, ports, DB schema all come from the user
- **Never generate files** until the full interview is complete and confirmed with "SÍ"
- **Never create a file** unless it's absolutely required for the generation goal
- **Never take shortcuts** — generate complete structures, not stubs
- **Always ask** when anything is ambiguous — never assume

*(Add new guardrails as mistakes happen. Keep this under 15 additional items.)*

---

## GOTCHA Framework

This project uses the GOTCHA framework internally:

| Layer | Path | Purpose |
|-------|------|---------|
| Goals | `goals/` | What to produce and why |
| Orchestration | Claude | Conducts interview, generates files |
| Tools | `tools/` | Shell scripts for generation tasks |
| Context | `context/` | Architecture patterns and templates |
| Hard prompts | (this file) | Non-negotiable rules |
| Args | User answers | Drive all generation decisions |

---

## File Structure

```
startup/
├── CLAUDE.md                        ← This file
├── .gitignore
├── .claude/
│   ├── settings.json                ← Hooks configuration
│   └── hooks/
│       ├── block-npm.sh
│       ├── block-git-push.sh
│       ├── block-terraform-apply.sh
│       ├── block-no-verify.sh
│       ├── block-claude-attribution.sh
│       └── block-destructive-actions.sh
├── goals/
│   ├── manifest.md                  ← Active goals
│   └── scaffold.md                  ← The scaffolding interview + generation workflow
├── context/
│   ├── architecture.md              ← Standard architecture patterns
│   └── templates/
│       ├── CLAUDE.template.md       ← Template for generated project CLAUDE.md
│       └── gitignore.template       ← Template for generated .gitignore
└── tools/
    └── manifest.md                  ← Available tools manifest
```

---

## Code Coverage Policy

All generated backend projects enforce:
- **75% minimum** — CI pipeline fails below this
- **Target: 80%+**
- Enforced via `coverlet` + `reportgenerator` in GitHub Actions

---

## Commit Policy

- Conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`
- No Claude attribution — ever
- No `--no-verify` — fix the hook
- User decides when to push — Claude never pushes autonomously
