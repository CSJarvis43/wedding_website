# Wedding Website: Project Handoff

Context for a Claude Project. It summarizes the decisions made so far so new conversations start from the same place. The source of truth for day-to-day conventions is `CLAUDE.md` in the repo.

- **Repo:** https://github.com/CSJarvis43/wedding_website (public; contains no PII by design)
- **Status (2026-10-19):** The project is scaffolded (#16): `backend/` (FastAPI, settings, `/api/health`, Alembic), `frontend/` (Vite, Router, Query, Tailwind, shadcn), and a Docker Compose dev stack. The guest lookup and email decisions are made (D8, D9), and the core data model is designed (`docs/data-model.md`, D10). Next: the SQLModel models and first migration, then address collection.

## What we're building

A wedding website for guests and for the couple:

1. **Info pages:** our story, schedule, venue and travel, accommodations, FAQ.
2. **Address collection (first, before invitations are mailed):** each household gets a personal link (also available as a QR code), sent by hand by the couple, where guests submit their mailing address.
3. **RSVP with guest lookup:** a guest arrives by their link/QR or finds their household by name, then answers for everyone in it on one form: yes/no (or maybe, where an event allows it) per person per event, any allowed plus-ones by name, and optional dietary notes. No meal choices (buffet). Answers can be changed until one site-wide deadline, about a month out.
4. **Registry.**
5. **Photo uploads after the wedding:** guests upload photos they took. Each photo needs the couple's approval, and the gallery is only for recognized households.
6. **Admin dashboard:** the couple logs in to manage households, guests, and events, copy each household's link or QR, see who has sent an address, approve photos, view and export RSVPs, and see or restore anything removed.
7. **Announcements:** email to guests sent from the app.

**Core data model (designed in #23; see `docs/data-model.md`):**
- **Tables:** `household`, `guest`, `event`, `event_invitee`, `rsvp_response`, `photo`, `admin_user`, `admin_session`, plus an `RSVP_DEADLINE` setting.
- **Household:** the unit that's invited, with one invitation and one RSVP. It holds the display name (also the envelope line), a US mailing address, a never-expiring resettable link token, and a plus-one allowance.
- **Guest:** first and last name, an optional search-only nickname, optional dietary notes, and a flag for plus-ones the household added.
- **Events:** the welcome party, rehearsal (invited-only, no RSVP), wedding (no "maybe"), and after party. Each event says who's invited (everyone, or a per-guest list), whether it takes RSVPs, and whether "maybe" is allowed.
- **Answers:** stored per guest per event and overwritten on change, with no history.
- **Removing things:** households, guests, and events are soft deleted. A permanent delete is only for erasure requests.

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
| Guest lookup | Two ways in, same result: a personal household link/QR, or name lookup (last name must match, first name forgiving); both set a signed household cookie |
| Data model conventions | Soft deletes, name matching in Python, link tokens stored as is, integer IDs (D10) |
| Email | Resend for app-sent email (announcements, maybe RSVP confirmations) |
| CI | GitHub Actions: gitleaks secret scan, backend checks, frontend checks |
| Planning | Spec Kit v1.0.11 for large features; a plan template for small tasks |
| Local dev | Docker Compose (Postgres 17, backend with auto-reload, Vite on :3000); toolchains pinned in `mise.toml` |

**Why a React + Vite SPA:** the couple is comfortable with React. The site mixes static info pages with app-like features (RSVP flow, admin dashboard, uploads). A static SPA keeps all server logic in Python and is the simplest thing to host and test. SEO doesn't matter for a wedding site, and link-preview meta tags can live in the static `index.html`.

**Rejected alternatives:**
- **Next.js:** it brings its own Node server, which would duplicate the Python backend.
- **Astro with React islands:** too much of the site is interactive, so it would mean two rendering models in one project.

**Why FastAPI:** the admin side is a **custom React dashboard**, so Django's built-in admin would go unused. FastAPI is lean and typed, and its OpenAPI schema can drive typed frontend clients. Rejected: Django + Ninja, Litestar.

**Why Render:** one platform, the simplest setup, predictable fixed plans, and infrastructure as code reviewed in PRs. Rejected: Railway (usage billing), Cloudflare Pages + Fly + Neon (three services to wire), a VPS (we'd own ops).

**Why R2:** no egress fees for a gallery guests browse repeatedly, and it's S3-compatible. Photos are PII, so access rules belong in the photo feature's spec.

**Why Tailwind + shadcn/ui:** a custom guest-facing look plus accessible forms and tables for the admin, with no library theme to fight. Rejected: Mantine, plain CSS Modules.

**Why Docker Compose + mise for local dev:** one command runs the full stack against a real Postgres, and pinned toolchain versions keep laptops, containers, and CI in step. Rejected: Postgres-only Compose (three terminals), tests only in containers (slow, awkward for editors), unpinned Homebrew toolchains.

**Postgres reconfirmed over SQLite:** SQLite would handle the load, but on Render it needs a disk attached to the web service (deploy downtime) and self-run backups. About $6/mo of managed Postgres with backups protects the RSVP data.

**Why this guest lookup:** guests come twice. The address request goes out digitally, so a personal link needs no typing. The RSVP comes after a paper invitation, where a printed code is awkward, especially for guests who aren't comfortable with tech. Name lookup needs the last name to match someone in the household (ignoring case and accents; either part of a hyphenated name counts) and is forgiving on the first name (typos, "Rob" for Robert, a stored nickname). Nothing is shown until both names match, so typing a surname never lists guests. Address forms accept a submission and never show a stored address back. Rejected: printed invite codes, one generic address link (manual matching, duplicates), strict exact names, loose partial-match lists (exposes names).

**Why Resend:** a simple API with a Python SDK, and a free tier that covers a wedding's volume. The first address requests are sent by hand from the couple's own accounts, which reach inboxes better. It needs a sending domain with SPF/DKIM/DMARC and a `RESEND_API_KEY`, both added with the first email feature. Rejected: Postmark (tiny free tier), Amazon SES (fiddly setup), Brevo (marketing-oriented), texts sent from the app (US 10DLC registration).

**Why these data model conventions (D10):** soft deletes mean nobody silently drops off the guest list. Matching names in Python is instant at this scale and keeps the rules easy to test. Link tokens are stored as is because a hashed token could only be shown once, which rules out copying links and printing QR codes at any time; anyone who could read the token could already read the addresses beside it. Rejected: hard deletes by default, Postgres `unaccent`/`pg_trgm`, stored cleaned-up name columns, hashed link tokens, UUID keys.

## Still to decide

- **Photo rules:** size limits, file types, and storage rules (decide in the photo-uploads spec). Approval and gallery access are decided.
- **Lookup rate limits:** the numbers (decide in the RSVP API work).
- **"Maybe" on the welcome party and after party:** a per-event switch, flippable any time.
- **Registry:** links to external registries or a built-in fund.
- **Visual design** and branding.

## Conventions

- **No PII or secrets in the repo, ever.** That covers guest names, emails, phones, addresses, dietary notes, RSVP data, photos, API keys, and DB credentials. Real values live in a git-ignored `.env` / `secrets/`. A committed `.env.example` lists keys with placeholders only. Tests use obviously fake data (`guest@example.com`). The app fails loudly if required config is missing.
- **Workflow:** issue → worktree → plan → test-first implementation → PR → green CI → squash merge, driven by project skills in `.claude/skills/`:
  - `create-issue`: file the issue every piece of work starts from, using structured feature and bug templates (who it's for, area, priority, dependencies, config/PII impact, decisions relied on, testing notes). It asks about gaps, then shows the exact issue and waits for an explicit File. Labels: a type label (`bug` or `enhancement`) plus area labels (`backend`, `frontend`, `infra`, `documentation`).
  - `create-worktree <#>`: one git worktree per issue at `.worktrees/<#>-<slug>`, on branch `<type>/<#>-<slug>`.
  - `plan-task <#>`: sizes the work. Small → a plan comment on the issue (first line `<!-- issue-plan -->`, from `docs/templates/plan.md`), ticked in place and not committed. Large → an epic: a Spec Kit spec (`specs/<#>-<slug>/`) merged first, then sub-issues that each go through the small path.
  - `start-work <#>`: implements the approved plan red → green → refactor, one commit per step.
  - `create-pr`: runs checks, a PII scan, and a code review, asking at each decision point (PII hits, history rewrites, review findings). It shows the exact PR title and body and waits for an explicit Open before pushing, then opens the PR from the template. The body says `Closes #N`, so GitHub links the PR to its issue and closes it on merge.
  - `/finish-work <#>`: manual only. Confirms, squash-merges, and cleans up the worktree.
  - `update-handoff`: refreshes this document.
- **`main` is protected:** PRs only, required checks (gitleaks, backend, frontend), no force pushes. Conventional Commits.
- **Testing:** TDD for logic (backend, API endpoints, non-trivial frontend behavior). Pure styling is exempt. Bug fixes start with a failing test.
- **Layout:** `backend/` (Python API, package `wedding`), `frontend/` (React app), `docker-compose.yml` + `mise.toml` at the root, `docs/` (decisions log, templates, handoffs), `specs/` (Spec Kit), `.worktrees/` (git-ignored).
- **Claude Code guardrails:** hooks block file edits outside a worktree, commits/pushes to `main`, force pushes, and any access to `.env*` / `secrets/`. Python and TypeScript files are auto-formatted after edits. A SessionStart hook puts mise's shims on PATH, so Claude's non-interactive shell uses the pinned toolchain versions.
- **Spec Kit constitution** (`.specify/memory/constitution.md`) mirrors `CLAUDE.md`, and the two change together. Principles: no PII/secrets (non-negotiable), test-first (non-negotiable), Python owns the server, small reviewable changes, simplicity.
