---
name: create-pr
description: Open a pull request for the current worktree's branch in this wedding-website repo. Runs the full checks, scans the diff for PII, runs a code review, fills the repo's PR template, pushes, and opens the PR linked to its issue. Use this whenever the user wants to open, create, submit, or send up a PR, says the work is ready for review, or asks to "ship"/"push this up" from a feature branch.
argument-hint: "[issue#]"
---

# create-pr

A PR here should arrive green, reviewed, linked to its issue, and free of personal data, so that merging is the only thing left. Each step below catches something CI or a reviewer would otherwise catch later and more slowly.

## 0. Preconditions

- You're in a worktree on a feature branch (`<type>/<#>-<slug>`), not `main`. The issue number is the `<#>` in the branch name.
- The working tree is clean (`git status`). Commit or ask about stray changes first.
- There are commits ahead of main (`git fetch -q origin && git log --oneline origin/main..`).
- If a PR is already open for this branch (`gh pr view --json url,state`), update it instead: push, and edit the body if it needs it.

## 1. Run the checks for every part that changed

Look at `git diff --name-only origin/main...` to see which areas changed.
- `backend/` → `uv run ruff check . && uv run ruff format --check . && uv run pytest`
- `frontend/` → `pnpm lint && pnpm format:check && pnpm typecheck && pnpm test`

Fix failures before going on. A red PR wastes the reviewer's attention.

## 2. Scan for PII

```bash
python3 .claude/skills/create-pr/scripts/pii-scan.py
```
It flags real-looking emails, phone numbers, and street addresses in added lines (exit 1). For each hit, replace the value with an obvious fake, or, if it's genuinely public wedding info such as the venue address, ask the user before adding a `pii-ok` marker on that line. The script can't recognize names, so also skim added fixtures, seed data, and test data for real-looking names. This repo is public, and once something is pushed it's effectively published.

**Fix the history, not just the tip.** The scan reads the branch's net diff, but every commit gets pushed. A follow-up "remove PII" commit still publishes the data in the earlier one. If any PII came from a commit that hasn't been pushed yet (`git log origin/<branch>..` or, for a never-pushed branch, everything since `origin/main`), rewrite those commits before pushing: amend, or `git reset --soft origin/main` and recommit. Then confirm it's gone with `git log -p origin/main..HEAD | grep -nF '<value>'`. If the commit was **already pushed**, stop and tell the user. Removing it then needs a force push (blocked here on purpose) and possibly GitHub support, and that's their call.

## 3. Review the code

Run `/code-review` on the branch and address the findings: fix what's real, and note anything deliberately left as is for the PR description. Re-run the step 1 checks if you changed code.

## 4. Write the PR

- **Title:** a Conventional Commit summary of the whole change (`feat: RSVP lookup by invite code`). It becomes the squash commit on `main`.
- **Body:** read `.github/pull_request_template.md` and fill it in. It's the single source of truth for PR structure, so don't invent another format.
  - Link the issue: `Closes #<#>`. For an epic's spec PR (the branch adds `specs/<#>-*/` and the issue is labeled `epic`), use `Part of #<#>` so merging the spec doesn't close the epic.
  - "How it was tested" lists the real commands you ran and what they showed.
  - Tick only the checklist items that are actually true.
  - End with the attribution line from the session's git instructions, if one is set.
- Write the body to a scratchpad file. Passing it with `--body-file` keeps the secrets hook from tripping on text that mentions secrets paths.

## 5. Push and open

```bash
git push -u origin HEAD
gh pr create --base main --title "<title>" --body-file <scratchpad>/pr.md
```

## 6. Report

Give the PR URL, then watch CI (`gh pr checks <pr> --watch`). If a check fails, read its log (`gh run view <run-id> --log-failed`), fix, commit, and push. Once it's green, tell the user it's ready, and that `/finish-work` merges and cleans up when they decide to.
