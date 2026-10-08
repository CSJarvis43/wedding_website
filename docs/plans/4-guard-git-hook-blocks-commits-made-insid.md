# Plan: #4 guard-git hook blocks commits made inside worktrees

**Issue:** #4. **Branch:** `fix/4-guard-git-hook-blocks-commits-made-insid`. **Size:** small.

## Goal

Commits and pushes on a feature branch inside a worktree are allowed. Commits on `main`, pushes to `main`, and force pushes are still blocked.

## Out of scope

Changing which actions are blocked. Slug truncation in `new-worktree.sh` cuts mid-word (follow-up issue).

## Approach

Judge the branch of the directory the git command runs in, not `$CLAUDE_PROJECT_DIR`. Start from the hook input's `cwd`, follow `cd <dir>` segments earlier in the same command, and honor `git -C <dir>`. The hook checks I've been running by hand become a committed test script, `.claude/hooks/tests/run.sh`, that builds a throwaway repo with a worktree.

## Files touched

- `.claude/hooks/tests/run.sh`: new hook test suite (guard-git, protect-secrets, require-worktree)
- `.claude/hooks/guard-git.sh`: per-command working-directory detection
- `CLAUDE.md`: mention the hook tests under Commands

## Steps

- [x] **1. Failing test.** `run.sh` covers the existing guard-git, protect-secrets, and require-worktree cases plus the new ones: `cd <worktree> && git commit` on a feature branch is allowed, `git -C <worktree> commit` is allowed, `cd <main checkout> && git commit` is still blocked. The worktree cases fail against the current hook. Commit: `test(hooks): add hook test suite reproducing #4`
- [x] **2. Fix.** Resolve the working directory per segment in `guard-git.sh`. `run.sh` passes. Commit: `fix(hooks): check the branch where the git command runs`
- [x] **3. Docs.** Add `bash .claude/hooks/tests/run.sh` to `CLAUDE.md` Commands. Commit: `docs: document hook tests`

## Verification

- [x] `bash .claude/hooks/tests/run.sh` passes
- [ ] `pii-scan.py` is clean

## Config/PII impact

None.

## Open questions / risks

Bootstrap: Claude's hooks run from the main checkout, which still has the buggy hook until this merges. Claude can't commit this fix itself, so the user runs the commit and push for this PR with `!`.
