---
name: update-handoff
description: Refresh docs/claude-project-handoff.md, the self-contained project summary the user pastes into their Claude Project, and copy it to the clipboard. Use this whenever a project decision is made or changes (backend framework, database, styling, hosting, auth, storage, conventions), when a spec merges, or when the user asks to update, regenerate, or copy the handoff, project context, or project summary.
---

# update-handoff

`docs/claude-project-handoff.md` is how the user's Claude Project (on claude.ai, with no repo access) knows where this project stands. It has to stand on its own: someone reading only that file should know what's being built, on what stack, by which rules, and what's still undecided.

## 1. Where to edit

The main checkout is read-only, so make the change inside a worktree, ideally the one whose work caused the decision, so the handoff ships in the same PR. If there's no suitable worktree, use `create-issue` ("Update project handoff") and `create-worktree`.

## 2. Gather the current truth

Read, in the worktree:
- `CLAUDE.md`: stack, layout, conventions, workflow.
- `.specify/memory/constitution.md`: principles.
- `specs/*/spec.md` and `docs/plans/*.md`: features specified or built.
- The existing handoff, to keep its structure and history.
- Recent merged PRs (`gh pr list --state merged --limit 15`) for decisions not yet captured.

## 3. Update the file

Keep the existing sections: what we're building, tech stack (decided), rationale and rejected alternatives, still to decide, conventions. Then:
- Move newly decided items from "Still to decide" into the stack table, each with a one-line *why*. The reasoning is the most useful part for a later conversation.
- Add new features or epics to "What we're building", with their status.
- Set the status line to today's date and a one-sentence summary of where things stand.
- Keep it short and self-contained. It's context for another Claude, not a changelog.
- No PII. This file is public and pasted elsewhere.

## 4. Commit and copy

```bash
git add docs/claude-project-handoff.md && git commit -m "docs: update project handoff"
pbcopy < docs/claude-project-handoff.md
```
Tell the user it's on their clipboard, ready to paste into the Claude Project's knowledge, and summarize what changed in a few bullets.
