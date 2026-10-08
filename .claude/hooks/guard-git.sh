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

# Check each chained command on its own, so e.g. `git push && gh pr create --base main`
# isn't mistaken for a push to main.
segments=$(printf '%s\n' "$cmd" | awk '{ gsub(/&&|\|\||;|\|/, "\n"); print }')

while IFS= read -r seg; do
  echo "$seg" | grep -Eq '^[[:space:]]*git[[:space:]]+(push|commit)([[:space:]]|$)' || continue

  if echo "$seg" | grep -Eq '^[[:space:]]*git[[:space:]]+push([[:space:]]|$)'; then
    if echo "$seg" | grep -Eq '[[:space:]](-f|--force|--force-with-lease|--force-if-includes)([[:space:]=]|$)'; then
      block "force pushes are not allowed."
    fi
    if echo "$seg" | grep -Eq '[[:space:]+:]main([[:space:]]|$)'; then
      block "pushing to main is not allowed."
    fi
    [ "$branch" = "main" ] && block "pushing from main is not allowed."
  else
    [ "$branch" = "main" ] && block "committing directly on main is not allowed."
  fi
done <<< "$segments"

exit 0
