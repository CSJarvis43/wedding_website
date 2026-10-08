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

## Still open

- Guest lookup method (name match vs invite code)
- Registry (links to external registries vs a built-in fund)
- Visual design and branding
