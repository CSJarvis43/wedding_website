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
   - Read the template so you fill its real sections, not ones you remember.

2. **Draft the issue.**
   - Title: short and imperative, with no Conventional Commit prefix ("RSVP lookup by invite code", not "feat: …"). The branch slug is derived from it, so keep it under about 50 characters.
   - Body: fill every template section from what the user said. Write acceptance criteria as checkable outcomes. If something important is unknown, put it under Notes as an open question rather than inventing an answer.
   - If the user's description is too thin to write any acceptance criteria, ask one focused question first.

3. **Check for PII before it leaves the machine.** Issues are public in this repo. Replace any real guest names, emails, phone numbers, addresses, or RSVP details with obvious fakes (`Jane Doe`, `guest@example.com`), and tell the user you did.

4. **Show the draft and get a yes.** Filing an issue is visible to anyone, so confirm the title and body with the user first.

5. **File it** with the body in a scratchpad file. Passing it with `--body-file` keeps the secrets hook from tripping on body text that happens to mention a secrets path.
   ```bash
   gh issue create --title "<title>" --label <bug|enhancement> --body-file <scratchpad>/issue.md
   ```
   If the label doesn't exist yet, create it (`gh label create <name>`) and retry.

6. **Report and hand off.** Give the issue URL and number, and offer to run `create-worktree <number>` to start work on it.
