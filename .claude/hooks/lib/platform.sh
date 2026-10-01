#!/bin/bash
# =============================================================================
# platform.sh: cross-platform helpers shared by the Claude hooks
# =============================================================================
# Added to make the hooks work on Windows (Claude Code runs hooks through
# Git Bash there) WITHOUT changing their behaviour on macOS or Linux.
#
# Every hook sources this file right after it parses its JSON input with jq.
# It detects the operating system once, then:
#
#   macOS / Linux  -> every helper returns its input unchanged, so the
#                     original hook logic runs exactly as before.
#   Windows        -> two input quirks are fixed before the hook's checks run:
#                     1. jq.exe writes CRLF line endings, leaving a stray "\r"
#                        on every value (breaks [ -f "$FILE_PATH" ], *.tf
#                        matching, etc.).
#                     2. Claude passes Windows paths (C:\repo\src\x.cs), but
#                        the hooks match forward-slash globs such as */tests/*,
#                        */hooks/*, *.Api/* and *modules/*.
#
# Override for testing: CLAUDE_HOOKS_PLATFORM=windows|mac|linux
# =============================================================================

if [ -z "${CLAUDE_HOOKS_PLATFORM:-}" ]; then
    case "$(uname -s 2>/dev/null)" in
        Darwin)               CLAUDE_HOOKS_PLATFORM="mac" ;;
        Linux)                CLAUDE_HOOKS_PLATFORM="linux" ;;
        MINGW*|MSYS*|CYGWIN*) CLAUDE_HOOKS_PLATFORM="windows" ;;  # Git Bash / MSYS2 / Cygwin
        *)                    CLAUDE_HOOKS_PLATFORM="unknown" ;;  # treated like macOS/Linux: no changes
    esac
fi
export CLAUDE_HOOKS_PLATFORM

# normalize_text <value>
#   Windows: remove the "\r" characters that jq.exe adds (CRLF output).
#   macOS/Linux: returns the value unchanged.
normalize_text() {
    if [ "$CLAUDE_HOOKS_PLATFORM" = "windows" ]; then
        printf '%s' "${1//$'\r'/}"
    else
        printf '%s' "$1"
    fi
}

# normalize_path <path>
#   Windows: remove "\r" and turn backslashes into forward slashes, so
#            C:\repo\modules\net\main.tf becomes C:/repo/modules/net/main.tf
#            (Git Bash accepts C:/ paths for [ -f ], find, sha256sum, ...).
#   macOS/Linux: returns the path unchanged.
normalize_path() {
    if [ "$CLAUDE_HOOKS_PLATFORM" = "windows" ]; then
        local p="${1//$'\r'/}"
        printf '%s' "${p//\\//}"
    else
        printf '%s' "$1"
    fi
}

# sha256_file <file>
#   Prints the SHA-256 of a file. Uses `shasum -a 256` whenever it exists
#   (the original behaviour; macOS and most Linux distros ship it). Git Bash on
#   Windows has no shasum, so it falls back to `sha256sum` (coreutils).
sha256_file() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" 2>/dev/null | awk '{print $1}'
    fi
}
