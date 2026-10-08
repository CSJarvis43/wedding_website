# Plan: #1 SDLC setup (workflow skills)

**Issue:** #1. **Branch:** `chore/1-sdlc-setup`. **Size:** small (config and docs only, one PR).

> Bootstrap exception: this PR creates the worktree workflow, so it is built in the main checkout on its feature branch. All later work follows the worktree rule.

## Goal

Encode the development workflow as seven self-contained, repo-committed Claude Code skills, enforce "edits only in worktrees" with a hook, and initialize Spec Kit for large work.

## Out of scope

- Backend framework, styling, hosting (separate decisions).
- Depending on the superpowers plugin. Project skills don't call it.

## Lifecycle

```
create-issue → create-worktree → plan-task → start-work → create-pr → finish-work
                                    │
                    large ──────────┴──── small
          Spec Kit spec PR (epic)        docs/plans/<#>-<slug>.md
          → sub-issues, each through
            the small path
```

## Skills (`.claude/skills/<name>/SKILL.md`)

| Skill | Does |
|---|---|
| `create-issue` | Fills the feature/bug issue template from a plain description, checks for PII, files via `--body-file`, offers `create-worktree`. |
| `create-worktree <#>` | Verifies the issue is open. Derives the type from the label (`bug`→`fix`, `enhancement`→`feat`, else ask). Creates `.worktrees/<#>-<slug>` on `<type>/<#>-<slug>` from fresh `origin/main`. Installs deps if `backend/`/`frontend/` exist. Prints the `! cp` command for the user's env file. Reuses an existing worktree. |
| `plan-task <#>` | Runs in the issue's worktree. Suggests a size and the user confirms. **Small** (one PR, one area, no new data model or integrations, ~<400 changed lines): fill `docs/templates/plan.md` into `docs/plans/<#>-<slug>.md`, get approval, commit, comment on the issue with a link. **Large:** label the issue `epic`, run Spec Kit specify→plan→tasks into `specs/<#>-<slug>/` with review at each step, open a spec PR (`Part of #N`). After it merges, turn task groups into GitHub sub-issues that each follow the small path. |
| `start-work <#>` | Requires an approved plan. Per step: failing test → pass → refactor → Conventional Commit. Ticks the plan's checkboxes. Stops and asks if the plan is wrong. Ends by suggesting `create-pr`. |
| `create-pr` | Runs checks for the touched areas, scans the diff for PII (stops on a hit), runs `/code-review` and fixes findings, fills `.github/pull_request_template.md`, pushes, opens the PR (`Closes #N`, or `Part of #N` for an epic spec), reports CI. |
| `finish-work <#>` | Verifies CI is green and the PR is mergeable, **asks the user to confirm**, squash-merges, removes the worktree and local branch, pulls `main` in the main checkout. For sub-issues, ticks off the epic and closes it when all are done. |
| `update-handoff` | Rebuilds `docs/claude-project-handoff.md` from `CLAUDE.md`, the Spec Kit constitution, and merged specs, inside the relevant worktree, then copies it to the clipboard. |

## Enforcement

- `.claude/hooks/require-worktree.sh` (PreToolUse on Edit/Write/MultiEdit/NotebookEdit) blocks edits to files in the main checkout. It decides by asking git whether the file's directory is a linked worktree (`--git-dir` differs from `--git-common-dir`). Files outside any repo (scratchpad, Claude memory) are allowed.
- `.worktrees/` is git-ignored.

## Templates & Spec Kit

- `docs/templates/plan.md`: issue link, goal, out of scope, approach, files touched, steps (test first), verification, config/PII impact, open questions/risks.
- The PR template stays `.github/pull_request_template.md` (single source).
- Spec Kit: `specify init --here --ai claude`, pinned to a release. The constitution is written from the rules in `CLAUDE.md`, and the two must change together. Spec Kit must use `<#>-<slug>` naming and must not create its own branches.

## Steps

- [x] Plan template + this plan
- [x] Build the seven skills with skill-creator (dry-run evals: 92% vs 81% baseline; fixes applied)
- [x] Initialize Spec Kit and write the constitution; adapt naming/branching
- [x] `require-worktree.sh` hook + settings + `.gitignore` (last, see bootstrap note)
- [x] Test the hooks against sample inputs
- [x] Update `CLAUDE.md` (workflow section names the skills) and the handoff doc
- [ ] Update PR #2 description

## Verification

Hook tests pass. Each skill has been read through end to end against a dry-run issue. Spec Kit commands are present and the constitution matches `CLAUDE.md`.

## Config/PII impact

None. No new settings.

## Open questions / risks

- Spec Kit's branch creation must be disabled or wrapped (verify against the pinned release).
- The sub-issues API: fall back to `Part of #N` plus an epic checklist if `gh` support is missing.
