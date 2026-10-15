# Wedding Website: Project Handoff

Context for a Claude Project. It summarizes the decisions made so far so new conversations start from the same place. The source of truth for day-to-day conventions is `CLAUDE.md` in the repo.

- **Repo:** https://github.com/CSJarvis43/wedding_website (public; contains no PII by design)
- **Status (2026-10-08):** SDLC scaffolding done (conventions, CI, hooks with a test suite, seven workflow skills, Spec Kit), and the core stack is decided (see `docs/decisions.md`). No application code yet. Next: scaffold `backend/` and `frontend/`.

## What we're building

A wedding website for guests and for the couple:

1. **Info pages:** our story, schedule, venue and travel, accommodations, FAQ.
2. **RSVP with guest lookup:** a guest finds their invitation (by name or code) and RSVPs for their party, including meal choice and dietary notes.
3. **Registry.**
4. **Photo uploads after the wedding:** guests upload photos they took.
5. **Admin dashboard:** the couple logs in to view and export RSVPs and manage the guest list.

## Tech stack (decided)

| Area | Choice |
|---|---|
| Frontend | React + TypeScript single-page app, built with Vite |
| Frontend routing / data | React Router, TanStack Query |
| Frontend tooling | pnpm, Node 24 LTS, ESLint, Prettier, Vitest + React Testing Library |
| Backend | Python 3.13 + FastAPI, managed with `uv` |
| Backend data | SQLModel + Alembic, Postgres |
| Admin auth | Server-side session cookie for the two admin accounts |
| Backend tooling | ruff (lint + format), pytest |
| Styling | Tailwind CSS + shadcn/ui |
| Hosting | Render: static site + web service + Postgres, defined in `render.yaml` (about $13–30/mo; confirm on render.com/pricing) |
| Photo storage | Cloudflare R2, private bucket, presigned uploads |
| CI | GitHub Actions: gitleaks secret scan, backend checks, frontend checks |
| Planning | Spec Kit v1.0.11 for large features; a plan template for small tasks |

**Why a React + Vite SPA:** the couple is comfortable with React. The site mixes static info pages with app-like features (RSVP flow, admin dashboard, uploads). A static SPA keeps all server logic in Python and is the simplest thing to host and test. SEO doesn't matter for a wedding site, and link-preview meta tags can live in the static `index.html`.

**Rejected alternatives:**
- **Next.js:** it brings its own Node server, which would duplicate the Python backend.
- **Astro with React islands:** too much of the site is interactive, so it would mean two rendering models in one project.

**Why FastAPI:** the admin side is a **custom React dashboard**, so Django's built-in admin would go unused. FastAPI is lean and typed, and its OpenAPI schema can drive typed frontend clients. Rejected: Django + Ninja, Litestar.

**Why Render:** one platform, the simplest setup, predictable fixed plans, and infrastructure as code reviewed in PRs. Rejected: Railway (usage billing), Cloudflare Pages + Fly + Neon (three services to wire), a VPS (we'd own ops).

**Why R2:** no egress fees for a gallery guests browse repeatedly, and it's S3-compatible. Photos are PII, so access rules belong in the photo feature's spec.

**Why Tailwind + shadcn/ui:** a custom guest-facing look plus accessible forms and tables for the admin, with no library theme to fight. Rejected: Mantine, plain CSS Modules.

## Still to decide

- **Photo rules:** size limits, moderation, and who can see the gallery (decide in the photo-uploads spec).
- **Guest lookup** method (name match vs invite code).
- **Registry:** links to external registries or a built-in fund.
- **Visual design** and branding.

## Conventions

- **No PII or secrets in the repo, ever.** That covers guest names, emails, phones, addresses, dietary notes, RSVP data, photos, API keys, and DB credentials. Real values live in a git-ignored `.env` / `secrets/`. A committed `.env.example` lists keys with placeholders only. Tests use obviously fake data (`guest@example.com`). The app fails loudly if required config is missing.
- **Workflow:** issue → worktree → plan → test-first implementation → PR → green CI → squash merge, driven by project skills in `.claude/skills/`:
  - `create-issue`: file the issue every piece of work starts from.
  - `create-worktree <#>`: one git worktree per issue at `.worktrees/<#>-<slug>`, on branch `<type>/<#>-<slug>`.
  - `plan-task <#>`: sizes the work. Small → a plan comment on the issue (first line `<!-- issue-plan -->`, from `docs/templates/plan.md`), ticked in place and not committed. Large → an epic: a Spec Kit spec (`specs/<#>-<slug>/`) merged first, then sub-issues that each go through the small path.
  - `start-work <#>`: implements the approved plan red → green → refactor, one commit per step.
  - `create-pr`: runs checks, a PII scan, and a code review, then opens the PR from the template (`Closes #N`).
  - `/finish-work <#>`: manual only. Confirms, squash-merges, and cleans up the worktree.
  - `update-handoff`: refreshes this document.
- **`main` is protected:** PRs only, required checks (gitleaks, backend, frontend), no force pushes. Conventional Commits.
- **Testing:** TDD for logic (backend, API endpoints, non-trivial frontend behavior). Pure styling is exempt. Bug fixes start with a failing test.
- **Layout:** `backend/` (Python API), `frontend/` (React app), `docs/` (plans, templates, handoffs), `specs/` (Spec Kit), `.worktrees/` (git-ignored).
- **Claude Code guardrails:** hooks block file edits outside a worktree, commits/pushes to `main`, force pushes, and any access to `.env*` / `secrets/`. Python and TypeScript files are auto-formatted after edits.
- **Spec Kit constitution** (`.specify/memory/constitution.md`) mirrors `CLAUDE.md`, and the two change together. Principles: no PII/secrets (non-negotiable), test-first (non-negotiable), Python owns the server, small reviewable changes, simplicity.
