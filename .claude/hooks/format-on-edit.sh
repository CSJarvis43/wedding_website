#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): auto-format the edited file.
# Silently does nothing when the relevant tooling isn't set up yet.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-.}"
file=$(jq -r '.tool_input.file_path // ""')
[ -n "$file" ] && [ -f "$file" ] || exit 0

case "$file" in
  "$root"/backend/*.py)
    if command -v uv >/dev/null && [ -f "$root/backend/pyproject.toml" ]; then
      uv run --project "$root/backend" ruff format --quiet "$file" >/dev/null 2>&1
    fi
    ;;
  "$root"/frontend/*.ts | "$root"/frontend/*.tsx | "$root"/frontend/*.js | "$root"/frontend/*.jsx | \
  "$root"/frontend/*.css | "$root"/frontend/*.json | "$root"/frontend/*.html)
    prettier="$root/frontend/node_modules/.bin/prettier"
    if [ -x "$prettier" ]; then
      "$prettier" --write --log-level silent "$file" >/dev/null 2>&1
    fi
    ;;
esac

exit 0
