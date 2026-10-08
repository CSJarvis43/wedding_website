# Wedding Website Constitution

This mirrors the rules in `CLAUDE.md`. If you change one, change the other in the same PR.

## Core Principles

### I. No PII or Secrets in the Repo (NON-NEGOTIABLE)

The site handles real guest data. No guest names, emails, phone numbers, addresses, dietary or accessibility notes, RSVP responses, photos, or private details about the couple appear anywhere in the repo: not in code, tests, fixtures, seed data, specs, docs, commit messages, PR text, or issues. The same goes for secrets (API keys, tokens, passwords, signing keys, credentialed DB URLs).

Real values live in git-ignored `.env` / `secrets/`. `.env.example` lists every key with placeholders only. The app reads config at startup and fails loudly when a required value is missing. Tests and specs use obviously fake data (`Jane Doe`, `guest@example.com`, `555-0100`).

### II. Test-First for Logic (NON-NEGOTIABLE)

Backend logic, API endpoints, and non-trivial frontend behavior (forms, validation, data fetching, auth) are built red → green → refactor: write the failing test, make it pass, then clean up. Bug fixes start with a test that reproduces the bug. Purely visual changes are exempt. Tests never touch real external services or real guest data.

### III. Python Owns the Server

All server-side logic (auth, guest data, RSVPs, registry, uploads) lives in the Python backend. The frontend is a static React + Vite + TypeScript build that talks to the backend API. Don't add a Node server.

### IV. Small, Reviewable Changes

Every change maps to a GitHub issue and lands as one focused PR. Large features become an epic: first a spec PR, then sub-issues that each fit in one PR.

### V. Simplicity

Build what the current issue needs. Prefer boring, well-known libraries. Any extra complexity (new services, new infrastructure, abstractions with one caller) needs a written justification in the plan.

## Technology Constraints

- **Backend:** Python 3.13 + FastAPI with `uv`. SQLModel + Alembic on Postgres. Server-side session-cookie auth for admins. `ruff` (lint + format), `pytest`.
- **Frontend:** React + TypeScript + Vite SPA, React Router, TanStack Query, Tailwind CSS + shadcn/ui, `pnpm` on Node 24 LTS, ESLint, Prettier, Vitest + React Testing Library.
- **Hosting:** Render (static site, web service, Postgres) defined in a committed `render.yaml`. Guest photos in a private Cloudflare R2 bucket via presigned URLs.
- **Decisions:** reasoning and rejected alternatives are recorded in `docs/decisions.md`. Changing a decision means adding a new entry there.
- **CI:** GitHub Actions running `gitleaks`, the backend checks, and the frontend checks. All three are required to merge into `main`.

## Development Workflow

- Work flows issue → worktree → plan → test-first implementation → PR → green CI → squash merge, through the project skills: `create-issue`, `create-worktree`, `plan-task`, `start-work`, `create-pr`, `finish-work`.
- All edits happen in a git worktree under `.worktrees/`, never in the main checkout. Branches are named `<type>/<issue#>-<slug>`. Commits follow Conventional Commits.
- `main` is protected: PRs only, required checks, no force pushes.
- Small tasks are planned in `docs/plans/<issue#>-<slug>.md`. Large tasks are specified in `specs/<issue#>-<slug>/` with Spec Kit (`speckit-specify` → `speckit-plan` → `speckit-tasks`) and implemented through sub-issues. `start-work` replaces `speckit-implement` in this repo.

## Governance

This constitution and `CLAUDE.md` are the source of truth for how work is done. Every spec, plan, and PR must comply. Amendments go through a normal PR that updates both files and bumps the version: MAJOR for removing or redefining a principle, MINOR for adding one, PATCH for clarifications.

**Version**: 1.1.0 | **Ratified**: 2026-10-08 | **Last Amended**: 2026-10-08
