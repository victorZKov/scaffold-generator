# Tools Manifest — Startup Scaffolding Generator

## Available Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| `governance-report.sh` | Compute Gartner success metrics for a generated project (provenance completeness, bypass attempts, src↔test pairing, TF module coverage). Exits non-zero on debt. | `./tools/governance-report.sh [path] [--json]` |

## Rules for Adding Tools

1. **Check this manifest first** — never write a script that already exists.
2. **Name tools by action** — `generate-solution.sh`, not `tool1.sh`.
3. **Document immediately** — add to this manifest when the tool is created.
4. **Test before documenting** — verify output format before chaining into another tool.
5. **One responsibility** — each tool does one thing.

## Future Tools

Tools to add as the system matures:

| Planned Tool | Purpose |
|-------------|---------|
| `generate-dotnet-solution.sh` | Creates .NET solution + project files via `dotnet new` |
| `generate-vite-app.sh` | Scaffolds React + Vite app via pnpm create vite |
| `generate-terraform-structure.sh` | Creates Terraform module directories |
| `generate-github-labels.sh` | Prints `gh label create` commands for standard label set |
| `generate-claude-config.sh` | Copies hooks + settings.json to target project |
