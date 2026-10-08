---
name: create-worktree
description: Create or reopen the git worktree and branch for a GitHub issue in this wedding-website repo. Use this whenever the user wants to start, resume, or switch to work on an issue ("let's work on #12", "pick up the RSVP issue", "start on 7"), and before any file edit for a task, since all development here happens in a worktree under .worktrees/ and edits in the main checkout are blocked by a hook.
argument-hint: "<issue#> [feat|fix|chore|docs|refactor|test|ci]"
---

# create-worktree

All development in this repo happens in a git worktree, one per issue, under `.worktrees/`. The main checkout only tracks `main`, and a hook blocks edits there. That keeps parallel tasks from stepping on each other and keeps `main` clean.

## Steps

1. **Get the issue number.** If the user named an issue by description rather than number, find it with `gh issue list --search "<words>"` and confirm which one. If there's no issue yet, use `create-issue` first.

2. **Run the script** from anywhere inside the repo:
   ```bash
   bash .claude/skills/create-worktree/scripts/new-worktree.sh <issue#> [type]
   ```
   It checks the issue is open, picks the branch type from the labels (`bug`→`fix`, `enhancement`/`epic`→`feat`), and creates `.worktrees/<#>-<slug>` on `<type>/<#>-<slug>` from a fresh `origin/main`. If a worktree for the issue already exists, it reuses it and prints `status=exists`. It prints `key=value` lines. Use `path` and `branch` from them.
   - **Exit 3** means it couldn't infer the type. Ask the user (suggest one based on the title, such as `chore` for tooling or `docs` for writing), then rerun with the type.
   - **Exit 1** means the issue isn't open. Tell the user rather than reopening it yourself.

3. **Move into the worktree.** `cd <path>` so later commands run there. From now on, edit files under that path only.

4. **Install dependencies** if the parts exist, so tests can run right away:
   - `backend/pyproject.toml` exists → `cd backend && uv sync`
   - `frontend/package.json` exists → `cd frontend && pnpm install`

5. **Environment file.** The real env file is git-ignored, so it doesn't follow into new worktrees, and you can't copy it (the secrets hook blocks it). If the main checkout has one and this task needs it, give the user this line to run (substituting the real path):
   ```
   ! cp <main checkout>/.env <worktree path>/.env
   ```

6. **Report:** the branch, the path, and the next step. That's usually `plan-task <#>`. If a plan for this issue already exists (a comment starting with `<!-- issue-plan -->`, checked with `gh api repos/CSJarvis43/wedding_website/issues/<#>/comments --jq '.[] | select(.body | startswith("<!-- issue-plan -->")) | .id'`, or `specs/<#>-*/`), say so and suggest `start-work` instead.
