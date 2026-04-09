# scaffold-generator

A deterministic project scaffolding generator for [Claude Code](https://claude.com/claude-code), built on the seven invariants from the Gartner research note *How to Govern Anthropic's Claude Code at Scale* (G00850426, March 2026).

It does one thing: it asks the right questions and generates a new project with all the security guardrails already in place — before you write a single line of code.

---

## What this is

When you start a new project with Claude, the first 20 minutes are the most dangerous. No `CLAUDE.md`, no hooks, no context. The AI is happy to use `npm` when you wanted `pnpm`, run `terraform apply` against dev, hardcode secrets, sign commits with "Co-Authored-By: Claude", and create storage accounts with `allow_blob_public_access = true`.

This project fixes that. It conducts a structured interview, captures every decision **from you**, and generates a complete project structure with:

- A project-specific `CLAUDE.md` with all the rules
- 14 hooks in `.claude/hooks/` that block dangerous actions before they hit disk
- A `governance.md` with the seven invariants every artifact must pass
- CI/CD pipelines for your platform (GitHub Actions, GitLab CI, or Azure DevOps)
- Real Clean Architecture / React / Terraform structure (depending on your answers)
- Real test scaffolding — not stubs
- A prompt-lineage ledger so you can audit every generated file later

**No design decisions are made by the AI without your consent.** Folder names, ports, schema, package versions — all come from your answers.

---

## How to use it

There is no install step, no clone-and-rename ritual. Just:

```bash
cd path/to/scaffold-generator
claude
```

Then tell Claude, in any language:

> *"I want to create a new project."*

Claude will detect your language, announce the interview, and start asking questions — one at a time. When it has everything it needs, it shows you a summary. You confirm with "SÍ" / "YES", and generation starts.

---

## The interview

Claude will walk you through 5 phases:

| Phase | What it asks |
|-------|--------------|
| 1. Identity | Project name (PascalCase) + 1-2 sentence description |
| 2. Requirements | Architecture, functional reqs, non-functional reqs |
| 3. Project type | Web, mobile, infra, API, or combinations |
| 4. DevOps | GitHub / GitLab / Azure DevOps + issue tracking platform |
| 5. Methodology | ATLAS + GOTCHA + SDD adoption |

Each question waits for your answer. No assumptions, no defaults. If you don't know an answer, Claude gives you options and explains the trade-offs.

---

## The seven invariants (Gartner)

Every generated artifact must satisfy these:

| # | Invariant | What it means |
|---|-----------|---------------|
| 1 | **Functional** | Implements the spec, passes static analysis and contract tests |
| 2 | **Tested** | Unit + integration + E2E tests, ≥75% coverage |
| 3 | **Secure** | No secrets, no CVEs, no SAST findings, no insecure flows |
| 4 | **Scalable** | No N+1 queries, async I/O, idempotent handlers |
| 5 | **Performant** | Meets P95 latency budget, no regressions |
| 6 | **Observable** | Structured logs, metrics, traces from day one |
| 7 | **Auditable** | Conventional commits, SBOM, signed artifacts, prompt lineage |

These are enforced at three checkpoints — **Generation**, **Pre-commit/pre-push**, and **CI/CD pipeline** — using the same tools with the same configuration. Skipping any one creates an exploitable gap.

See [`context/governance.md`](./context/governance.md) for the complete reference.

---

## The hooks

All hooks live in `.claude/hooks/` and run automatically. If Claude tries to do something they block, the action fails and Claude sees the error message.

| Hook | What it blocks |
|------|----------------|
| `block-npm.sh` | Any `npm install` / `npm run` — pnpm only |
| `block-git-push.sh` | `git push` without explicit user authorization |
| `block-terraform-apply.sh` | `terraform apply` from your laptop — pipelines only |
| `block-no-verify.sh` | `git commit --no-verify` — fix the hook, don't skip it |
| `block-claude-attribution.sh` | `Co-Authored-By: Claude` in commits |
| `block-destructive-actions.sh` | `rm -rf`, destructive `az` CLI commands |
| `block-secrets.sh` | Hardcoded credentials in any file |
| `block-tf-public-exposure.sh` | Public storage, open CIDRs, weak TLS in Terraform |
| `enforce-invariants.sh` | Files that violate the seven invariants |
| `enforce-tf-policy.sh` | Terraform without required tags, naming, encryption |
| `provenance-stamp.sh` | Stamps every generation with prompt lineage |
| `require-tests.sh` | Production code in Domain/Application/Api needs tests |
| `require-tf-module-tests.sh` | Terraform modules need a `tests/` folder |
| `require-tf-tags.sh` | All Azure resources need tags |

Want to verify they work? Ask Claude to write a file with a fake AWS key (`AKIA1234567890ABCDEF`). It will refuse — and the error comes from `block-secrets.sh`, not from Claude's good intentions.

---

## Standard tech stack

The generator targets a standard mono-repo stack, but you decide which parts apply:

| Layer | Technology |
|-------|------------|
| Frontend | React + Vite + TypeScript + shadcn/ui + Tailwind CSS |
| Backend | .NET 10 (Clean Architecture: Domain / Application / Infrastructure / Api) |
| Mobile | React Native + Expo / .NET MAUI / Flutter |
| Database | PostgreSQL 16 |
| Local dev | .NET Aspire |
| Infrastructure | Terraform (Azure) |
| CI/CD | GitHub Actions / GitLab CI / Azure DevOps Pipelines |
| Auth | Entra ID |
| Package manager | **pnpm only** |
| AI methodology | ATLAS + GOTCHA + SDD (optional) |

---

## Repository layout

```
scaffold-generator/
├── CLAUDE.md                  ← Rules Claude reads on every session
├── .claude/
│   ├── settings.json          ← Hook registration
│   └── hooks/                 ← The 14 enforcement scripts
├── goals/
│   ├── manifest.md
│   └── scaffold.md            ← The interview + generation workflow
├── context/
│   ├── architecture.md        ← Standard architecture patterns
│   ├── governance.md          ← The seven invariants reference
│   └── templates/             ← Reusable templates for generated files
├── tools/
│   ├── manifest.md
│   └── governance-report.sh   ← Audit helper
└── projectScaffolding/        ← Reference structure for generated projects
```

---

## Read more

- **Article:** [A Scaffold Generator for Claude — Built on Gartner's Seven Invariants](https://victorz.cloud/blog/scaffold-generator-claude-gartner)
- **ATLAS + GOTCHA series:** [victorz.cloud/series/atlas-gotcha](https://victorz.cloud/series/atlas-gotcha)
- **Gartner research:** *How to Govern Anthropic's Claude Code at Scale* (G00850426, March 2026)

---

## Sponsor

If this project saves you time or keeps your team out of trouble, consider sponsoring the work:

- [GitHub Sponsors](https://github.com/sponsors/victorZKov)
- [Buy Me a Coffee](https://buymeacoffee.com/victorxata)

---

## Contributing

If your team has a guardrail that's missing, open an issue. The hook list is meant to grow as we learn what fails in real projects.

Pull requests welcome. Conventional commits only. No `--no-verify`. No Claude attribution.

---

## License

MIT
