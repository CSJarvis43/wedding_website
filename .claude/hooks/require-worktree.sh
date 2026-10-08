#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit|NotebookEdit): in this repo, edits only happen
# inside a linked worktree (.worktrees/<#>-<slug>), never in the main checkout.
# Files outside this repo (scratchpad, Claude memory, other repos) are allowed.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')
[ -n "$file" ] || exit 0

# Walk up to the nearest existing directory (the file may be new).
dir=$(dirname "$file")
while [ ! -d "$dir" ]; do dir=$(dirname "$dir"); done

git_dir=$(git -C "$dir" rev-parse --path-format=absolute --git-dir 2>/dev/null) || exit 0
common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
project_common=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0

# Another repository: not our concern.
[ "$common" = "$project_common" ] || exit 0

# A linked worktree has its own git dir (.git/worktrees/<name>); the main checkout doesn't.
if [ "$git_dir" = "$common" ]; then
  echo "Blocked by .claude/hooks/require-worktree.sh: edits happen in a worktree, not the main checkout." >&2
  echo "Run create-worktree <issue#> and edit the files under .worktrees/<#>-<slug>/. See CLAUDE.md > Workflow." >&2
  exit 2
fi

exit 0
