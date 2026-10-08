---
name: start-work
description: Implement a planned GitHub issue in this wedding-website repo, test-first, step by step from its approved plan. Use this whenever the user says to start, continue, resume, or build/implement/code an issue or plan ("start on #12", "keep going", "implement the plan", "let's build the RSVP endpoint"). Use it instead of speckit-implement in this repo.
argument-hint: "<issue#>"
---

# start-work

This skill turns an approved plan into commits, one red → green → refactor cycle per step. The plan is the contract the user approved, so follow it, and stop to talk when reality disagrees with it.

## 0. Preconditions

- **In the worktree.** `git rev-parse --show-toplevel` must be under `.worktrees/` and the branch must contain `/<#>-`. If not, run `create-worktree <#>`.
- **A plan exists.** Look for `docs/plans/<#>-*.md`. If there's none, stop and run `plan-task <#>`. Coding without an approved plan is exactly what this workflow avoids. If this is an epic issue (labeled `epic`), its work is done in the sub-issues, so point the user at those.
- **Read the plan, `CLAUDE.md`, and the files the plan touches.** If the plan links a spec (`specs/<epic>-<slug>/`), read the relevant parts too.
- **Resuming?** Steps already ticked `[x]` are done. Check `git log --oneline origin/main..` to confirm, and continue from the first unticked step.

## 1. For each unticked step

1. **Red.** Write the test the plan describes, run it, and watch it fail *for the expected reason* (an assertion failure, not an import error or typo). A test that passes before you've changed anything isn't testing the new behavior. Fix the test.
2. **Green.** Write the simplest code that makes it pass. Run the test file, then the whole suite for that area, so nothing else broke.
3. **Refactor** if the code would read better, keeping tests green.
4. **Check** the area you touched:
   - backend: `uv run ruff check . && uv run ruff format --check . && uv run pytest`
   - frontend: `pnpm lint && pnpm format:check && pnpm typecheck && pnpm test`
5. **Tick the step** in the plan file (`- [ ]` → `- [x]`) and **commit** code, tests, and plan together, using the plan's Conventional Commit message (`feat: …`, `fix: …`, `test: …`).

Purely visual or copy steps skip red/green but still get checked and committed.

## 2. When the plan is wrong

Plans meet reality. A library behaves differently, a step is bigger than it looked, or a better approach shows up. **Stop and tell the user** what you found and what you propose, and update the plan file once they agree. Don't quietly drift from the plan or widen scope. The user approved specific work, and surprises in a PR are expensive to review.

## 3. Throughout

- **Fake data only** in tests, fixtures, and seed data (`Jane Doe`, `guest@example.com`, `555-0100`). Real values come from config.
- **New setting?** Read it from the environment, fail loudly if it's missing, and add the key with a placeholder to `.env.example` in the same commit.
- Edit only inside the worktree. The main checkout is read-only by design.

## 4. Finish

When every step is ticked, run the plan's Verification commands, then summarize what was built, list the commits (`git log --oneline origin/main..`), and suggest `create-pr`.
