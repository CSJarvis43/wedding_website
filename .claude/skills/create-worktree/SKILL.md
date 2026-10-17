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

4. **Have the user set up the worktree** (when the script printed `status=created`; for `status=exists`, only if the user says it isn't set up yet). A new worktree has no `.env` (it's git-ignored), and mise won't activate the pinned toolchains until the folder is trusted, so `pnpm` isn't available yet. You can't create, copy, or link the env file yourself (the secrets hook blocks it, by design), so give the user this line to run, with the real paths substituted:
   ```
   ! test -f <main checkout>/.env && ln -s <main checkout>/.env <worktree path>/.env && mise trust <worktree path>
   ```
   - The symlink means every worktree shares the main checkout's `.env`: one file to edit, and changes reach every worktree. Removing the worktree deletes only the link, never the main file.
   - If the line stops without output (`test -f` failed), the main checkout has no `.env` yet. The user creates it by running `cp .env.example .env` in the main checkout, then reruns the line. You can't check this for them.
   - Wait until the user says it's done. Don't run, verify, or work around this step.

5. **Install dependencies** if the parts exist, so tests can run right away:
   - `backend/pyproject.toml` exists → `cd backend && uv sync`
   - `frontend/package.json` exists → `cd frontend && pnpm install`

   These resolve to the pinned versions through mise's shims, which `.claude/hooks/mise-shims.sh` puts on PATH at session start. The shims still need the worktree's `mise.toml` to be trusted (step 4), so install dependencies only after that.

6. **Report:** the branch, the path, and the next step. That's usually `plan-task <#>`. If a plan for this issue already exists (a comment starting with `<!-- issue-plan -->`, checked with `gh api --paginate repos/{owner}/{repo}/issues/<#>/comments --jq '.[] | select(.body | startswith("<!-- issue-plan -->")) | .id'`, or `specs/<#>-*/`), say so and suggest `start-work` instead.
