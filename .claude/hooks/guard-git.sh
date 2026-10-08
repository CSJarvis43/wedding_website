#!/usr/bin/env bash
# PreToolUse(Bash): block commits/pushes to main and any force push.
# Exit 2 blocks the tool call and shows stderr to Claude.
set -uo pipefail

cmd=$(jq -r '.tool_input.command // ""')
branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null || true)

block() {
  echo "Blocked by .claude/hooks/guard-git.sh: $1" >&2
  echo "Work on a feature branch (<type>/<issue#>-<slug>) and open a PR. See CLAUDE.md > Workflow." >&2
  exit 2
}

if echo "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]].*)?[[:space:]](-f|--force|--force-with-lease|--force-if-includes)([[:space:]=]|$)'; then
  block "force pushes are not allowed."
fi

if echo "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]].*)?[[:space:]+:]main([[:space:]]|$)'; then
  block "pushing to main is not allowed."
fi

if [ "$branch" = "main" ]; then
  if echo "$cmd" | grep -Eq 'git[[:space:]]+commit([[:space:]]|$)'; then
    block "committing directly on main is not allowed."
  fi
  if echo "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]]|$)'; then
    block "pushing from main is not allowed."
  fi
fi

exit 0
