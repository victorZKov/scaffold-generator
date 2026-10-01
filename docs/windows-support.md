# Windows support for the Claude hooks

This branch makes the hooks in `.claude/hooks/` (and the copies in
`projectScaffolding/.claude/hooks/`) work on **Windows**, where Claude Code runs
hooks through **Git Bash**. It is purely additive: **behaviour on macOS and Linux
is unchanged**, and no existing rule or pattern was modified.

## What was wrong on Windows

All 14 hooks parse their input with `jq` and then match on paths and commands.
On Windows that went wrong in four ways:

| # | Problem | Effect |
|---|---|---|
| 1 | `jq.exe` writes CRLF, so every parsed value ends in `\r` | `[ -f "$FILE_PATH" ]`, `*.tf` and similar checks can miss |
| 2 | Claude passes Windows paths (`C:\repo\src\Demo.Api\X.cs`) | globs like `*/tests/*`, `*/hooks/*`, `*.Api/*`, `*modules/*` never match, so `require-tests`, `require-tf-module-tests` and the `block-secrets` skip rule silently did nothing |
| 3 | Git Bash has no `shasum` | `provenance-stamp.sh` recorded an empty `sha256` for every file (Auditable invariant) |
| 4 | Git for Windows defaults to `core.autocrlf=true` | `.sh` files can be checked out as CRLF, and then bash fails with `$'\r': command not found` |

## What changed

1. **New `.claude/hooks/lib/platform.sh`** (copied to `projectScaffolding/.claude/hooks/lib/`).
   It detects the OS once with `uname -s` (`Darwin` → mac, `Linux` → linux,
   `MINGW*`/`MSYS*`/`CYGWIN*` → windows) and provides:
   - `normalize_text` and `normalize_path`: on **Windows only**, strip `\r` and turn
     `\` into `/`. On macOS/Linux they return their input unchanged.
   - `sha256_file`: uses `shasum -a 256` whenever it exists (the original
     behaviour) and falls back to `sha256sum` (Git Bash).
2. **Each hook gets one commented block** right after its `jq` lines. It sources
   `lib/platform.sh` and normalises the values it just parsed. If `lib/platform.sh`
   is missing, the block is skipped and the hook runs exactly as before. No
   original line was removed.
3. **`provenance-stamp.sh`** uses `sha256_file` for the hash. The original line is
   kept, both as a comment and as the fallback.
4. **New `.gitattributes`** pins `*.sh` to LF line endings. It has no effect on
   macOS/Linux checkouts.

`settings.json` is unchanged.

## Requirements on Windows

- Git for Windows (Git Bash). Claude Code uses it to run hooks.
- `jq` on `PATH`, for example `winget install jqlang.jq`. **Without `jq` every
  hook exits 0 and allows everything**, on every OS. Restart Claude after
  installing so it picks up the new `PATH`.
- Open the project in Claude and accept the workspace trust prompt once. Project
  hooks don't load until you do.

## How it was tested

A pipe-test harness fed each hook realistic Claude payloads: 27 block/allow cases
covering all 14 hooks.

| Run | Result |
|---|---|
| Windows 11, Git Bash, OS auto-detected | 27 / 27 pass |
| Forced `CLAUDE_HOOKS_PLATFORM=mac`, Unix paths | 27 / 27 pass |
| Forced `CLAUDE_HOOKS_PLATFORM=linux`, Unix paths | 27 / 27 pass |
| Patched (forced mac) vs **original** hooks, same inputs | identical results on every compared case |
| Original hooks on Windows, before the fix | 23 / 27 (the 4 failures in the table above) |

Every script also passes `bash -n`. To force a platform when testing, set
`CLAUDE_HOOKS_PLATFORM=windows|mac|linux`.

---

## Design brief (ATLAS → GOTCHA)

**Architect.** Make the hooks work on Windows (Git Bash) with no behaviour change
on macOS/Linux. *Out of scope:* changes to blocking rules or patterns,
`settings.json`, PowerShell-only Windows (no Git Bash), installing `jq`.

**Trace.** Hook starts → parses input with `jq` → sources `lib/platform.sh` (OS
detected) → on Windows only, values are normalised → original checks run.

**Link.** One shared helper, sourced relative to each hook's own directory
(`${BASH_SOURCE[0]}`), so it works from any working directory. If the helper is
missing, the hook falls back to the original behaviour.

**Assemble.** Helper → per-hook blocks → provenance hash → `.gitattributes` →
this doc → tests.

**Stress-test.** The test matrix above. Mac/Linux equivalence is checked against
the unmodified hooks.

| GOTCHA | |
|---|---|
| Goals | All hooks pass on Windows. Identical behaviour on macOS/Linux. Every change commented. |
| Orchestration | As in Assemble |
| Tools | bash, `uname`, existing `jq`. No new dependencies. |
| Context | Upstream author's repo, so the change is additive only |
| Heuristics | DO keep original lines, detect the OS once, test each platform. DON'T touch patterns or `settings.json`. |
| Args | `CLAUDE_HOOKS_PLATFORM` override. Helper at `.claude/hooks/lib/platform.sh`. |
