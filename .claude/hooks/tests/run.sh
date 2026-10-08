#!/usr/bin/env bash
# Test suite for the Claude Code hooks in .claude/hooks/.
# Builds a throwaway repo (main checkout on main + one feature worktree)
# and feeds each hook sample tool calls. Exit 0 = all pass.
#
# Usage: bash .claude/hooks/tests/run.sh
set -uo pipefail

HOOKS=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

G() { git -c user.email=dev@example.com -c user.name="Dev Example" "$@"; }
REPO=$TMP/repo
G init -q -b main "$REPO"
G -C "$REPO" commit -q --allow-empty -m init
G -C "$REPO" worktree add -q -b feat/9-example "$REPO/.worktrees/9-example"
WT=$REPO/.worktrees/9-example
export CLAUDE_PROJECT_DIR=$REPO

pass=0; fail=0
check() { # expected-exit hook json description
  local want=$1 hook=$2 json=$3 desc=$4 got
  printf '%s' "$json" | "$HOOKS/$hook" >/dev/null 2>&1; got=$?
  if [ "$got" = "$want" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL [$hook] $desc: want exit $want, got $got"; fi
}
bash_in() { jq -nc --arg c "$2" --arg d "$1" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d}'; }
file() { jq -nc --arg t "$1" --arg f "$2" '{tool_name:$t,tool_input:{file_path:$f}}'; }

# --- guard-git: session cwd = main checkout (on main) ---
check 2 guard-git.sh "$(bash_in "$REPO" 'git commit -m x')" "commit on main"
check 2 guard-git.sh "$(bash_in "$REPO" 'git add . && git commit -m x')" "chained commit on main"
check 2 guard-git.sh "$(bash_in "$REPO" 'git push')" "push from main"
check 2 guard-git.sh "$(bash_in "$REPO" 'git push origin main')" "push to main"
check 2 guard-git.sh "$(bash_in "$REPO" 'git push origin HEAD:main')" "push HEAD:main"
check 2 guard-git.sh "$(bash_in "$REPO" 'git push --force origin x')" "force push"
check 2 guard-git.sh "$(bash_in "$WT" 'git push -f')" "force push from worktree"
check 2 guard-git.sh "$(bash_in "$WT" 'cd '"$REPO"' && git commit -m x')" "cd back to main checkout, commit"
check 0 guard-git.sh "$(bash_in "$REPO" 'git status')" "status on main"
check 0 guard-git.sh "$(bash_in "$REPO" 'gh pr create --base main --title "git push origin main"')" "gh text mentioning main"
# --- guard-git: work happening in the worktree (#4) ---
check 0 guard-git.sh "$(bash_in "$REPO" 'cd '"$WT"' && git commit -m "docs: x"')" "cd worktree && commit"
check 0 guard-git.sh "$(bash_in "$REPO" 'cd .worktrees/9-example && git add -A && git commit -m x')" "relative cd worktree && commit"
check 0 guard-git.sh "$(bash_in "$REPO" 'git -C '"$WT"' commit -m x')" "git -C worktree commit"
check 0 guard-git.sh "$(bash_in "$WT" 'git commit -m x')" "cwd is worktree, commit"
check 0 guard-git.sh "$(bash_in "$WT" 'git push -u origin HEAD')" "cwd is worktree, push"
check 0 guard-git.sh "$(bash_in "$REPO" 'cd '"$WT"' && git push -u origin HEAD && gh pr create --base main')" "push from worktree then gh pr create"
check 2 guard-git.sh "$(bash_in "$WT" 'git push origin HEAD:main')" "push worktree branch onto main"

# --- protect-secrets ---
check 2 protect-secrets.sh "$(bash_in "$REPO" 'cat .env')" "cat .env"
check 2 protect-secrets.sh "$(bash_in "$REPO" 'grep KEY .env.local')" "grep .env.local"
check 2 protect-secrets.sh "$(bash_in "$REPO" 'cp secrets/db.json /tmp/')" "cp from secrets/"
check 2 protect-secrets.sh "$(file Read "$REPO/.env")" "Read .env"
check 2 protect-secrets.sh "$(file Read "$REPO/backend/secrets/x.json")" "Read secrets/"
check 0 protect-secrets.sh "$(bash_in "$REPO" 'cat .env.example')" "cat .env.example"
check 0 protect-secrets.sh "$(bash_in "$REPO" 'git commit -m "docs: mention .env and secrets/"')" "quoted mention"
check 0 protect-secrets.sh "$(bash_in "$REPO" "$(printf 'cat > /tmp/x <<EOF\nvalues live in .env\nEOF')")" "heredoc mention"
check 0 protect-secrets.sh "$(file Read "$REPO/.env.example")" "Read .env.example"

# --- require-worktree ---
check 2 require-worktree.sh "$(file Edit "$REPO/README.md")" "edit in main checkout"
check 2 require-worktree.sh "$(file Write "$REPO/backend/new/deep.py")" "new file in main checkout"
check 0 require-worktree.sh "$(file Edit "$WT/README.md")" "edit in worktree"
check 0 require-worktree.sh "$(file Write "$WT/backend/new/deep.py")" "new file in worktree"
check 0 require-worktree.sh "$(file Write "$TMP/outside.md")" "file outside any repo"

echo "hook tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
