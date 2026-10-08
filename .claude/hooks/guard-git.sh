#!/usr/bin/env bash
# PreToolUse(Bash): block commits/pushes to main and any force push.
# Exit 2 blocks the tool call and shows stderr to Claude.
#
# The branch is judged where each git command actually runs: the hook's cwd,
# updated by any `cd <dir>` earlier in the same command, or `git -C <dir>`.
# That way commits inside a worktree (.worktrees/<#>-<slug>) on a feature
# branch are allowed while the main checkout stays on main.
set -uo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
wd=$(jq -r '.cwd // empty' <<<"$input")
wd=${wd:-${CLAUDE_PROJECT_DIR:-$PWD}}

block() {
  echo "Blocked by .claude/hooks/guard-git.sh: $1" >&2
  echo "Work on a feature branch (<type>/<issue#>-<slug>) and open a PR. See CLAUDE.md > Workflow." >&2
  exit 2
}

resolve() { # dir relative to $wd -> absolute path
  local d=$1
  d=${d#[\"\']}; d=${d%[\"\']}
  case "$d" in
    "~"*) d="$HOME${d#\~}" ;;
    /*) ;;
    *) d="$wd/$d" ;;
  esac
  printf '%s' "$d"
}

# Check each chained command on its own, so e.g. `git push && gh pr create --base main`
# isn't mistaken for a push to main.
segments=$(printf '%s\n' "$cmd" | awk '{ gsub(/&&|\|\||;|\|/, "\n"); print }')

while IFS= read -r seg; do
  # Track directory changes within the command.
  if [[ "$seg" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]]+)[[:space:]]*$ ]]; then
    wd=$(resolve "${BASH_REMATCH[1]}")
    continue
  fi

  # Normalize `git -C <dir> ...` to `git ...` run in <dir>.
  dir=$wd
  if [[ "$seg" =~ ^[[:space:]]*git[[:space:]]+-C[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
    dir=$(resolve "${BASH_REMATCH[1]}")
    seg="git ${BASH_REMATCH[2]}"
  fi

  echo "$seg" | grep -Eq '^[[:space:]]*git[[:space:]]+(push|commit)([[:space:]]|$)' || continue
  branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)

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
