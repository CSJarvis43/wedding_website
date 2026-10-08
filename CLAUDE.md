# Wedding Website

A wedding website with a Python backend API and a React frontend. Guests read event info, RSVP, view the registry, and upload photos after the wedding. The couple uses an admin dashboard to manage guests and RSVPs.

## Tech stack

| Area | Choice |
|---|---|
| Backend | Python 3.13, managed with `uv` (framework not yet chosen) |
| Backend lint/format | `ruff` (lint + format) |
| Backend tests | `pytest` |
| Frontend | React + TypeScript, built with Vite (single-page app) |
| Frontend routing / data | React Router, TanStack Query |
| Frontend package manager | `pnpm`, Node 24 LTS |
| Frontend lint/format | ESLint, Prettier |
| Frontend tests | Vitest + React Testing Library |
| Secret scanning | `gitleaks` (CI) |

The frontend is a static build. All server-side logic (auth, guest data, RSVPs, uploads) lives in the Python backend. Don't add a Node server.

## Repo layout

```
backend/    Python API (pyproject.toml, src/, tests/)
frontend/   React + Vite app (package.json, src/)
docs/       Design specs, plans, handoff notes
.claude/    Shared Claude Code settings and hooks
.github/    CI workflow, PR and issue templates
```

`backend/` and `frontend/` don't exist yet. CI skips each one until it does.

## PII and secrets: hard rule

This site handles real guest data. **Never hardcode PII or secrets** anywhere in the repo: source, tests, fixtures, seed data, docs, comments, commit messages, PR descriptions, or issue text.

- **PII** includes guest names, emails, phone numbers, mailing addresses, dietary or accessibility notes, RSVP responses, uploaded photos, and the couple's private details (anything not meant for the public site).
- **Secrets** include API keys, tokens, passwords, session/signing keys, and database URLs with credentials.
- Real values live in **git-ignored** files: `.env` (or `.env.local`) and `secrets/`. `.env.example` is the committed template. It lists every required key with **placeholder values only**. When you add a new setting, add it to `.env.example` in the same PR.
- Code reads configuration from the environment at startup and **fails loudly** if a required value is missing. Don't fall back to a real-looking default.
- The app loads `.env` itself (through its settings module). Shell commands should never need to name `.env` or `secrets/`.
- Tests and seed data use obviously fake data: `Jane Doe`, `guest@example.com`, `555-0100`, `123 Example St`.
- Public wedding content (venue name, date, schedule) is fine in the frontend. When in doubt, ask.
- Claude Code is blocked from reading, editing, or shelling into `.env*` (except `.env.example`) and `secrets/` by `.claude/settings.json` and `.claude/hooks/protect-secrets.sh`. Don't try to work around this. Ask the user to check or change a value.

## Workflow

Every change goes **issue → branch → PR → green CI → squash merge**. `main` is protected: no direct pushes, no force pushes, CI must pass.

1. **Issue first.** Each piece of work has a GitHub issue. Create one if it doesn't exist (`gh issue create`).
2. **Branch** off an up-to-date `main`: `<type>/<issue#>-<short-slug>`, e.g. `feat/12-rsvp-lookup`, `fix/20-meal-choice-validation`.
3. **Commits** use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`, `ci:`. Use the imperative mood and keep the subject under ~72 chars.
4. **Before opening a PR**, run the full checks for the parts you touched (see Commands), then run a code review (`/code-review`) and address the findings.
5. **PR** uses the template, references the issue (`Closes #12`), and stays focused on one issue.
6. **Merge** with squash once CI is green. The branch is deleted automatically.

Claude Code hooks block `git commit`/`git push` on `main` and all force pushes.

## Testing: TDD for logic

- For backend logic, API endpoints, and non-trivial frontend behavior (forms, validation, data fetching, auth flows), **write a failing test first**, make it pass, then refactor.
- Purely visual changes (styling, layout, copy) don't need tests.
- Bug fixes start with a test that reproduces the bug.
- Backend tests live in `backend/tests/`. Frontend tests sit next to the code as `*.test.ts(x)`.
- Tests must not touch real external services or real guest data.

## Commands

Backend (run from `backend/`):

```bash
uv sync                      # install deps
uv run pytest                # tests
uv run ruff check .          # lint
uv run ruff format .         # format
```

Frontend (run from `frontend/`). `package.json` must set `"packageManager": "pnpm@<version>"` and define these scripts, since CI uses both:

```bash
pnpm install
pnpm dev                     # dev server
pnpm test                    # vitest run (non-watch)
pnpm lint                    # eslint
pnpm format                  # prettier --write
pnpm format:check            # prettier --check
pnpm typecheck               # tsc --noEmit
```

## Definition of done

- [ ] Linked to an issue, on a feature branch
- [ ] Tests written first for any logic; all tests pass
- [ ] Lint, format, and typecheck are clean
- [ ] No PII or secrets added; new settings added to `.env.example`
- [ ] Code review run and findings addressed
- [ ] PR opened with the template filled in; CI green
