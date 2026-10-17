#!/usr/bin/env bash
# SessionStart: put mise's shims on PATH for Claude's Bash commands.
# Claude's shell is non-interactive, so `mise activate` never fires there; shims
# resolve the version pinned in mise.toml per directory at run time instead.
# Does nothing when mise isn't installed or Claude Code gave no env file.
# SessionStart also fires on resume/clear/compact, so the line is added only once.
set -uo pipefail

[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0
command -v mise >/dev/null || exit 0

if ! line=$(mise activate bash --shims 2>&1); then
  echo "mise-shims: 'mise activate bash --shims' failed, so tools won't resolve to the pinned versions: $line" >&2
  exit 1
fi
grep -qxF -- "$line" "$CLAUDE_ENV_FILE" 2>/dev/null || printf '%s\n' "$line" >> "$CLAUDE_ENV_FILE"
exit 0
