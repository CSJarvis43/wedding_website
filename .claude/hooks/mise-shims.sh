#!/usr/bin/env bash
# SessionStart: put mise's shims on PATH for Claude's Bash commands.
# Claude's shell is non-interactive, so `mise activate` never fires there; shims
# resolve the version pinned in mise.toml per directory at run time instead.
# Does nothing when mise isn't installed or Claude Code gave no env file.
set -uo pipefail

[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0
command -v mise >/dev/null || exit 0

mise activate bash --shims >> "$CLAUDE_ENV_FILE" 2>/dev/null
exit 0
