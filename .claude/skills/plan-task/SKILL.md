---
name: plan-task
description: Plan the implementation of a GitHub issue in this wedding-website repo before any code is written. Sizes the work, then writes a small-task plan from docs/templates/plan.md and posts it as a comment on the issue, or, for large work, runs the Spec Kit flow (speckit-specify → speckit-plan → speckit-tasks) and splits it into sub-issues. Use this whenever the user wants to plan, scope, design, break down, or "figure out how to build" an issue, or asks to start coding on an issue that has no plan yet.
argument-hint: "<issue#>"
---

# plan-task

Writing a plan before code catches design mistakes while they're cheap, and gives `start-work` a checklist to follow. How much planning a task needs depends on its size, so start by sizing it.

## 0. Preconditions

- You must be inside the issue's worktree (`git rev-parse --show-toplevel` is under `.worktrees/`). If you're not, run `create-worktree <#>` first.
- Read the issue (`gh issue view <#> --comments`), `CLAUDE.md`, and `.specify/memory/constitution.md`. The plan has to respect them, especially no PII and test-first.
- Look at the code the task will touch, so the plan names real files.

## 1. Size it

Suggest a size with a one-line reason, and let the user confirm or override:

- **Small:** fits in one PR, touches one area (backend *or* frontend, or a thin slice of both), adds no new data model or outside service, roughly under 400 changed lines.
- **Large:** anything else. Typical signs are a new feature area, a schema plus API plus UI together, an outside integration (email, storage, payments), or real unknowns that need research.

When unsure, lean small. A small plan that turns out too big can still be promoted to large.

## 2a. Small path

1. Copy `docs/templates/plan.md` to a scratchpad file (`<scratchpad>/plan-<#>.md`). Keep the `<!-- issue-plan -->` marker as line 1. The plan is not committed to the repo.
2. Fill every section. Each step is one red → green → refactor cycle, named by the behavior it adds, with the failing test spelled out ("POST /rsvp with an unknown code returns 404"). Pure styling or copy steps can skip the test. If the issue is a sub-issue of an epic, link the spec and the task IDs it covers.
3. Show the plan to the user and revise until they approve. This is the point to change direction, so ask about anything uncertain rather than guessing.
4. Post it as a single comment on the issue, so it can be found from GitHub and ticked in place by `start-work`:
   ```bash
   gh issue comment <#> --body-file <scratchpad>/plan-<#>.md
   ```
   If a plan comment already exists (`gh api --paginate repos/{owner}/{repo}/issues/<#>/comments --jq '.[] | select(.body | startswith("<!-- issue-plan -->")) | .id' | tail -1`), edit it instead of posting a second one: `gh api -X PATCH repos/{owner}/{repo}/issues/comments/<id> -F body=@<scratchpad>/plan-<#>.md`.
5. Suggest `start-work <#>`.

## 2b. Large path

Large work becomes an **epic**. The epic's own PR contains only the spec. The building happens in sub-issues, each small enough for the small path.

1. Label the issue: `gh issue edit <#> --add-label epic` (create the label if it's missing).
2. Pin the spec directory to the issue *before* running Spec Kit. Its `create-new-feature.sh` would zero-pad the number (`030-…`), so don't use it:
   ```bash
   mkdir -p specs/<#>-<slug>
   printf '{"feature_directory": "specs/<#>-<slug>"}\n' > .specify/feature.json
   ```
   `.specify/feature.json` is git-ignored, per-worktree state that `speckit-plan` and `speckit-tasks` read to find the feature. Shell variables don't persist between commands, so rely on that file, not an `export`.
3. Follow `speckit-specify`, telling it the feature directory is `SPECIFY_FEATURE_DIRECTORY=specs/<#>-<slug>` (it uses a user-provided directory as-is), then `speckit-plan`, then `speckit-tasks`. Have the user review after each one. Optional skills: `speckit-clarify` when requirements are fuzzy, `speckit-analyze` before splitting.
4. Commit the spec (`docs: add spec for #<#>`), then use `create-pr`. It writes `Part of #<#>` rather than `Closes`, so merging the spec leaves the epic open.
5. **After the spec PR merges**, split `tasks.md` into sub-issues. Each sub-issue is a coherent group of tasks that ships as one small PR, and they're ordered by dependency.
   - Draft the list (title + the task IDs each covers) and get the user's OK before creating anything.
   - Create each with `create-issue`. Put `Part of #<epic>` and the task IDs in the body.
   - Link each as a GitHub sub-issue:
     ```bash
     gh api -X POST repos/{owner}/{repo}/issues/<epic>/sub_issues -F sub_issue_id=$(gh api repos/{owner}/{repo}/issues/<child> --jq .id)
     ```
     If that call fails, fall back to a task-list checklist (`- [ ] #<child>`) in an epic comment.
6. Each sub-issue then goes `create-worktree` → `plan-task` (small path, linking the spec) → `start-work` → `create-pr`.

In this repo `start-work` implements tasks, not `speckit-implement`. The split into sub-issues is what keeps PRs reviewable.
