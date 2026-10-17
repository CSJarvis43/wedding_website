---
name: create-issue
description: File a GitHub issue for this wedding-website repo using the project's feature or bug template. Use this whenever the user describes new work, a bug, an idea, or a decision to make that doesn't have an issue yet ("we should add…", "the RSVP form is broken", "let's decide on hosting"), because every change in this repo starts from an issue. Also use it when another workflow step needs an issue number and none exists.
---

# create-issue

Every branch, plan, and PR in this repo hangs off a GitHub issue number, so filing one is the first step of any work. The aim is a short, specific issue a future reader can act on, with no personal data in it.

## Steps

1. **Pick the template.**
   - Something broken → `.github/ISSUE_TEMPLATE/bug.md` (label `bug`).
   - Anything else (feature, improvement, decision, chore) → `.github/ISSUE_TEMPLATE/feature.md` (label `enhancement`).
   - If it could be either (for example, "the RSVP form doesn't save dietary notes" could be a bug or a missing feature), ask with `AskUserQuestion`: Bug / Feature, putting the one you think fits first with "(Recommended)".
   - Read the template so you fill its real sections, not ones you remember.

2. **Draft the issue.**
   - Title: short and imperative, with no Conventional Commit prefix ("RSVP lookup by invite code", not "feat: …"). The branch slug is derived from it, so keep it under about 50 characters.
   - Body: fill **every** template section from what the user said. Write acceptance criteria as checkable outcomes. Sections that don't apply get a short answer ("None", "Visual only"), not a blank.
   - **Fill gaps with `AskUserQuestion`, don't guess.** For each template section the user didn't cover and you can't reasonably infer, ask. The usual gaps are area (backend / frontend / infra / docs, multi-select), priority (feature) or severity (bug), whether real guest data is involved (bug), dependencies, decisions relied on, and config/PII impact. Put the recommended option first.
   - **Four questions per call at most.** If there are more, ask the most important four first (acceptance criteria, then bug-vs-feature, area, priority/severity), then make a second call for the rest. Don't drop questions to fit.
   - If you can't write any acceptance criteria, ask that first, as a focused question with the likely outcomes as options (the user can pick "Other" to type their own).
   - Never write "None" for Dependencies, Decisions relied on, or Config/PII impact just because the user didn't mention them. Ask, or put the unknown under Notes as an open question. "None" must mean the user said so.
   - Anything still unknown goes under Notes as an open question, not an invented answer.

3. **Check for PII before it leaves the machine.** Issues are public in this repo. Replace any real guest names, emails, phone numbers, addresses, or RSVP details with obvious fakes (`Jane Doe`, `guest@example.com`), and tell the user you did.

4. **Show the final issue and ask File / Edit / Cancel.** Filing an issue is visible to anyone, so don't file without an explicit "File".
   - Print the exact title, labels, and full body as it will be filed (the whole text, not a summary).
   - Then call `AskUserQuestion` with these options, in this order: **File (Recommended)**, **Edit**, **Cancel**.
   - **Edit:** ask what to change (free text), update the draft, and show it and ask again. Repeat until File or Cancel.
   - **Cancel:** stop. Don't file, and say nothing was created.
   - "Other" text is an edit request, not approval.

5. **File it** (only after "File") with the body in a scratchpad file. Passing it with `--body-file` keeps the secrets hook from tripping on body text that happens to mention a secrets path. Labels are the type label plus one area label per chosen area (`backend`, `frontend`, `infra`; docs uses `documentation`).
   ```bash
   gh issue create --title "<title>" --label <bug|enhancement>[,<area>...] --body-file <scratchpad>/issue.md
   ```
   If a label doesn't exist yet, create it (`gh label create <name>`) and retry.

6. **Report and hand off.** Give the issue URL and number, and offer to run `create-worktree <number>` to start work on it.
