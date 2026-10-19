# Decision log

Short records of project decisions: context, what was decided, why, and what was rejected. New entries go at the bottom. A changed decision gets a new entry that says which one it replaces. Don't edit the old entry.

---

## D1: Frontend: React + Vite + TypeScript SPA (2026-10-08)

**Context:** The site mixes static info pages with app-like features: an RSVP flow, an admin dashboard, and photo uploads. The couple is comfortable with React.

**Decision:** A static single-page app built with React, TypeScript, and Vite, using React Router and TanStack Query. All server logic lives in Python.

**Why:** It matches existing skills, keeps a single backend, and is the simplest thing to host and test. SEO doesn't matter for a wedding site, and link-preview meta tags can live in `index.html`.

**Rejected:** Next.js, because it brings its own Node server and would duplicate the Python backend. Astro with React islands, because too much of the site is interactive, so it would mean two rendering models.

---

## D2: Backend: FastAPI + SQLModel + Alembic (2026-10-08)

**Context:** The admin side (viewing and exporting RSVPs, managing the guest list) will be a **custom React dashboard**, not a generated admin.

**Decision:** FastAPI for the API, SQLModel (SQLAlchemy + Pydantic) for models, and Alembic for migrations. The two admin accounts log in with a server-side session cookie (HTTP-only, secure, same-site).

**Why:** With a custom dashboard, Django's main draw, its built-in admin, would go unused. FastAPI is lean and typed, and its generated OpenAPI schema can drive typed API clients in the frontend. SQLModel keeps one model definition for the database and the API. Session cookies are simpler and safer than tokens for a browser-only admin.

**Rejected:** Django (+ Django Ninja), which is excellent if the built-in admin is enough, and that was declined here. Litestar, which is capable but has a smaller ecosystem and fewer examples.

---

## D3: Database: Postgres (2026-10-08)

**Decision:** Postgres, managed by the hosting platform (D4).

**Why:** It's the standard choice for SQLModel and Alembic, it comes managed with backups on the chosen host, and it's plenty for a guest list in the hundreds.

**Rejected:** SQLite, which is fine at this scale but needs a persistent disk and separate backups on a PaaS.

---

## D4: Hosting: Render (2026-10-08)

**Context:** Priority is one platform with the simplest setup, over the lowest cost.

**Decision:** Render hosts the frontend as a static site, the FastAPI API as a web service, and Postgres. The infrastructure is defined in a committed `render.yaml` (Blueprint), so infra changes are reviewed in PRs like code.

**Why:** One dashboard and auto-deploys from GitHub, with predictable fixed plans.

**Cost (to confirm on render.com/pricing before provisioning):** static sites are free, an always-on Starter web service is about $7/mo, and a paid Postgres instance is about $6–20/mo depending on size. Render's free Postgres expires, so it isn't for production data.

**Rejected:**
- Railway: similar, but usage-based billing is harder to predict.
- Cloudflare Pages + Fly.io + Neon: cheapest, but three services to wire together.
- Single VPS: we'd own updates, backups, and TLS.

---

## D5: Photo storage: Cloudflare R2 (2026-10-08)

**Decision:** Guest photo uploads go to a Cloudflare R2 bucket through its S3-compatible API. The backend issues presigned upload URLs, and the bucket is private, never publicly listable.

**Why:** No egress fees, which matters for a gallery that guests browse repeatedly. It works with any S3 client library, and its free tier covers a wedding's worth of photos.

**Rejected:** AWS S3, because egress costs scale with gallery views. Storing photos on the web service's disk, because it doesn't survive redeploys and doesn't scale.

Photos are PII: access rules are decided in the photo-uploads feature spec.

---

## D6: Styling: Tailwind CSS + shadcn/ui (2026-10-08)

**Context:** The site needs a distinctive look for guest-facing pages, plus practical forms, dialogs, and data tables for the admin dashboard.

**Decision:** Tailwind CSS for styling. shadcn/ui components (copied into the repo, built on Radix) for forms, dialogs, and the admin data table.

**Why:** Full control over the visual design with no library theme to fight. Accessible primitives for interactive components. The components live in our code, so they can be restyled freely.

**Rejected:** Mantine, which is fastest for the admin side but needs heavy theming to make guest pages not look library-default. Plain CSS Modules, which would mean building every control and its accessibility by hand.

---

## D7: Local development: Docker Compose + mise (2026-10-17)

**Context:** Development needs a real Postgres (D3), the FastAPI backend, and the Vite frontend running together, with the same tool versions on every machine and in CI.

**Decision:** `docker compose up` runs the whole stack: Postgres 17, the backend (Alembic migrations on start, then uvicorn with auto-reload), and the Vite dev server on port 3000, with source bind-mounted for hot reload. The Dockerfiles are for local development only. Toolchains (Python, Node, uv, pnpm) are pinned to exact versions in a committed `mise.toml`, so native test, lint, and editor tooling match the containers. CI keeps reading `.python-version` and `packageManager`.

**Why:** One command gives a working stack with a real database, and nothing but Docker and mise has to be installed. Pinned versions stop a Homebrew upgrade from quietly drifting a laptop away from CI.

**Rejected:** Postgres-only Compose with the apps run natively, which means juggling three terminals. Running tests and lint only inside containers, which is slow and awkward for editor tooling. Homebrew-installed toolchains with versions listed in the README, which nothing enforces.

**Also reconfirmed:** Postgres (D3) over SQLite. SQLite would handle the load, but on Render it means a persistent disk attached to the web service (downtime on each deploy) and backups we'd have to run ourselves, for example with Litestream to R2. Managed Postgres with backups costs about $6/mo and protects the one dataset we can't lose, and Compose makes it cheap to run locally.

---

## D8: Guest lookup: household link + name lookup (2026-10-19)

**Context:** Guests come to the site twice. First, before invitations are mailed, the couple needs everyone's mailing address. A paper save-the-date has already gone out, and the address request goes out by text or email. Later, guests RSVP with a paper invitation in hand. The couple will have the full guest list, grouped by household, before any address request is sent. Some guests aren't comfortable with tech.

**Decision:** The household is the unit that's invited. It has one invitation and one RSVP.

- **Address collection:** each household gets a personal link carrying a private, unguessable token. The couple copies it from the admin dashboard and sends it by hand from personal email or phone. The page greets the household by name and only accepts an address. It never shows a stored address back. The dashboard shows which households have responded.
- **RSVP:** guests look themselves up by name. The last name must match some member of the household, ignoring case, extra whitespace, and accents, and either part of a hyphenated surname counts. The first name is forgiving: small typos, prefixes ("Rob" finds Robert), and an optional nickname the couple can store. Nothing is shown until both names match. If nothing matches, the page asks the guest to contact the couple. The personal household link also opens the RSVP.
- **RSVP shape:** whoever fills in the form marks each person in the household as attending or not. A household may be allowed a number of extra guests (default 0), and the form lets them add up to that many by name. Those guests are recorded as added by the household and aren't used for name lookup.

**Why:** A link sent digitally needs no typing at all, and nobody has to print a code on every invitation. A last-name match plus a loose first name lets guests who use a nickname or make a typo find themselves without listing anyone else's names. Recording attendance per person gives the headcount, meal choices, and seating that a household-level yes/no can't.

**Rejected:** Invite codes printed on the paper invitations, which are awkward to type and add a printing step. One generic address link where guests type their own names, which leaves the couple matching replies by hand and handling duplicates from the same household. Strict exact-name lookup, which strands anyone who goes by a nickname. Loose lookup that lists partial matches, which exposes guest names to anyone typing a common surname.

---

## D9: Email: Resend (2026-10-19)

**Context:** The app will need to send some email: announcements to guests, and maybe RSVP confirmations. The volume is small, a few hundred households over a few rounds.

**Decision:** App-sent email goes through Resend. The first address requests (D8) are sent by hand from the couple's own email and phone, not from the app. Sending needs a domain the couple controls, with SPF, DKIM, and DMARC records, and a Resend API key read from the environment. Both are added with the first feature that sends email.

**Why:** A simple API with a Python SDK, and a free tier that covers a wedding's volume. A personal note from the couple's own account lands in inboxes better than anything from a new sending domain, which is why the first requests go by hand.

**Rejected:** Postmark, which delivers well but has a very small free tier. Amazon SES, which is the cheapest at scale but fiddly to set up and get approved for sending. Brevo, which is geared toward marketing campaigns. Texts sent from the app, which in the US require registering a business sender (10DLC) before sending.

---

## Still open

- Registry (links to external registries vs a built-in fund)
- Visual design and branding
