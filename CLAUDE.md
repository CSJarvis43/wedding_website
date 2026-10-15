# Wedding Website

A wedding website with a Python backend API and a React frontend. Guests read event info, RSVP, view the registry, and upload photos after the wedding. The couple uses an admin dashboard to manage guests and RSVPs.

## Tech stack

| Area | Choice |
|---|---|
| Backend | Python 3.13 + FastAPI, managed with `uv` |
| Backend data | SQLModel (SQLAlchemy + Pydantic), Alembic migrations, Postgres |
| Admin auth | Server-side session cookie (HTTP-only, secure, same-site) for the two admin accounts |
| Backend lint/format | `ruff` (lint + format) |
| Backend tests | `pytest` |
| Frontend | React + TypeScript, built with Vite (single-page app) |
| Frontend routing / data | React Router, TanStack Query |
| Styling | Tailwind CSS + shadcn/ui (components copied into the repo) |
| Frontend package manager | `pnpm`, Node 24 LTS |
| Frontend lint/format | ESLint, Prettier |
| Frontend tests | Vitest + React Testing Library |
| Hosting | Render (static site + web service + Postgres), defined in `render.yaml` |
| Photo storage | Cloudflare R2 (private bucket, presigned uploads) |
| Secret scanning | `gitleaks` (CI) |

The frontend is a static build. All server-side logic (auth, guest data, RSVPs, uploads) lives in the Python backend. Don't add a Node server. The reasoning and rejected alternatives for each choice are in `docs/decisions.md`. Record new decisions there.

## Repo layout

```
backend/    Python API (pyproject.toml, src/, tests/)
frontend/   React + Vite app (package.json, src/)
docs/       Templates (docs/templates/), handoff notes
specs/      Spec Kit specs for large work (specs/<#>-<slug>/)
.specify/   Spec Kit config, scripts, templates, constitution
.worktrees/ One git worktree per issue (git-ignored)
.claude/    Shared Claude Code settings, hooks, and skills
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
- The Bash hook checks the command's bare words, ignoring quoted strings and heredoc bodies, so commit messages and PR text can mention these paths. Writing long prose to a scratchpad file and passing `-F` / `--body-file` is still the tidiest way.

## Workflow

Every change goes **issue → worktree → plan → test-first implementation → PR → green CI → squash merge**, using the project skills in `.claude/skills/`. Small-task plans live in a single issue comment (first line `<!-- issue-plan -->`) that `start-work` ticks in place, and are not committed. Large-task specs are committed under `specs/`.

```
create-issue → create-worktree → plan-task → start-work → create-pr → /finish-work
                                    │
                    large ──────────┴──── small
          Spec Kit spec PR (epic)        plan comment on the issue
          → sub-issues, each through
            the small path
```

| Skill | Use it to |
|---|---|
| `create-issue` | File the issue every piece of work starts from |
| `create-worktree <#>` | Create or reopen `.worktrees/<#>-<slug>` on `<type>/<#>-<slug>` |
| `plan-task <#>` | Size the work. Small: plan from `docs/templates/plan.md`, posted as a comment on the issue. Large: Spec Kit epic + sub-issues |
| `start-work <#>` | Implement the approved plan, red → green → refactor, one commit per step |
| `create-pr` | Checks, PII scan, code review, PR from `.github/pull_request_template.md` |
| `/finish-work <#>` | Squash-merge after confirmation, clean up the worktree and branch (manual only) |
| `update-handoff` | Refresh `docs/claude-project-handoff.md` when a decision changes, and copy it |

These project skills are the canonical workflow and don't depend on any plugin. In this repo, use them instead of similar global skills, such as superpowers' worktree, plan, or finish-branch skills, and instead of `speckit-implement`.

Rules the skills follow:

- **All edits happen in a worktree** under `.worktrees/` (git-ignored). The main checkout only tracks `main`, and `.claude/hooks/require-worktree.sh` blocks file edits there.
- **Branches:** `<type>/<issue#>-<slug>`, e.g. `feat/12-rsvp-lookup`.
- **Commits** use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`, `ci:`. Imperative mood, subject under ~72 chars.
- **PRs** use the template, reference the issue (`Closes #12`, or `Part of #N` for an epic's spec), and stay focused on one issue.
- **`main` is protected:** PRs only, `gitleaks`/`backend`/`frontend` must pass, no force pushes. Hooks also block `git commit`/`git push` on `main` and all force pushes.
- **Spec Kit** (v1.0.11, `.specify/`) handles large work. Its constitution, `.specify/memory/constitution.md`, mirrors this file, so change both together.

## Testing: TDD for logic

- For backend logic, API endpoints, and non-trivial frontend behavior (forms, validation, data fetching, auth flows), **write a failing test first**, make it pass, then refactor.
- Purely visual changes (styling, layout, copy) don't need tests.
- Bug fixes start with a test that reproduces the bug.
- Backend tests live in `backend/tests/`. Frontend tests sit next to the code as `*.test.ts(x)`.
- Tests must not touch real external services or real guest data.

## Commands

Claude Code hooks (run from the repo root). Run these after changing anything in `.claude/hooks/`:

```bash
bash .claude/hooks/tests/run.sh
```

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

- [ ] Linked to an issue, built in its worktree from an approved plan
- [ ] Tests written first for any logic; all tests pass
- [ ] Lint, format, and typecheck are clean
- [ ] No PII or secrets added; new settings added to `.env.example`
- [ ] Code review run and findings addressed
- [ ] PR opened with the template filled in; CI green
