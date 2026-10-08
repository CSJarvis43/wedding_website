---
name: finish-work
description: Squash-merge a green, approved PR for this wedding-website repo, then remove its worktree and branch, update main, and tick off the parent epic. Only runs when the user invokes /finish-work.
argument-hint: "<issue# | PR#>"
disable-model-invocation: true
---

# finish-work

Merging puts code on `main` for good, so this skill runs only when the user asks, and it confirms once more before the merge itself. Afterwards it cleans up, so finished worktrees and branches don't pile up.

## 1. Find the PR

From the argument, or from the current worktree's branch:
```bash
gh pr list --state open --search "<#> in:title,body" --json number,headRefName,title
gh pr view <pr> --json number,title,state,mergeable,mergeStateStatus,headRefName,body,statusCheckRollup
```
Match the branch `<type>/<#>-<slug>` to be sure it's the right PR.

## 2. Check it's ready

- `state` is OPEN.
- Every required check (`gitleaks`, `backend`, `frontend`) passed. If any are pending, wait with `gh pr checks <pr> --watch`. If any failed, stop and report. Fixing belongs back in the branch, through `create-pr`.
- `mergeable` is MERGEABLE. If it conflicts, stop and offer to rebase the branch onto `origin/main` in its worktree, then push and re-check. Use a normal push for that, never a force push.

## 3. Confirm, then merge

Show the PR title, the number of commits, and the squash commit title, and ask the user to confirm. Only then:
```bash
gh pr merge <pr> --squash
```
The repo deletes the remote branch on merge. Don't pass `--admin` or anything else that bypasses protection. If GitHub refuses the merge, report why.

## 4. Clean up locally

Run these from the **main checkout** (the parent of `.worktrees/`), not from inside the worktree being removed:
```bash
cd <main checkout>
git worktree remove .worktrees/<#>-<slug>
git branch -D <type>/<#>-<slug>
git pull --ff-only
```
`git branch -D` is needed because a squash merge leaves the local branch looking unmerged. If `worktree remove` refuses because of uncommitted changes, show the user `git -C .worktrees/<#>-<slug> status --short` and ask before forcing anything. Those changes would be lost.

## 5. Epic bookkeeping

If the issue body says `Part of #<epic>`:
- If the epic uses a checklist comment, tick this issue in it.
- Check whether any sub-issues are still open (`gh api repos/CSJarvis43/wedding_website/issues/<epic>/sub_issues --jq '.[] | select(.state=="open") | .number'`). If none are, offer to close the epic with a short summary comment.

## 6. Report

Say what was merged (PR, squash commit on `main`), what was cleaned up, and whether any decisions in this PR (stack, hosting, conventions) mean `update-handoff` should run on the next branch.
