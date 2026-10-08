# Plan: #3 Record stack decisions: FastAPI, Render, R2, Tailwind + shadcn/ui

**Issue:** #3. **Branch:** `docs/3-record-stack-decisions-fastapi-render-r2`. **Size:** small.

## Goal

`CLAUDE.md`, the Spec Kit constitution, and the Claude Project handoff all describe the same decided stack, and `docs/decisions.md` records why each choice was made, so future scaffolding issues start from settled ground.

## Out of scope

Scaffolding `backend/` or `frontend/`, writing `render.yaml`, creating Render/Cloudflare accounts, and the still-open decisions (guest lookup method, registry, visual design).

## Approach

Add a decision log (`docs/decisions.md`) with one short entry per decision: context, decision, rationale, alternatives rejected. Then update the two rule documents and refresh the handoff with `update-handoff`. Documentation only, so no tests.

## Files touched

- `docs/decisions.md`: new decision log
- `CLAUDE.md`: tech stack table
- `.specify/memory/constitution.md`: Technology Constraints, version 1.0.0 → 1.1.0 (MINOR: new constraints)
- `docs/claude-project-handoff.md`: stack table, "Still to decide", status line

## Steps

- [x] **1. Decision log.** Write `docs/decisions.md` covering backend (FastAPI + SQLModel + Alembic + session-cookie admin auth), database (Postgres), hosting (Render via `render.yaml`), photo storage (Cloudflare R2), and styling (Tailwind + shadcn/ui). Commit: `docs: add decision log for stack choices`
- [x] **2. Rule documents.** Update the `CLAUDE.md` stack table and the constitution's Technology Constraints, and bump the constitution version. Commit: `docs: record decided stack in CLAUDE.md and constitution`
- [x] **3. Handoff.** Run `update-handoff` (move decided items out of "Still to decide", update status) and copy it to the clipboard. Commit: `docs: update project handoff`

## Verification

- [x] `CLAUDE.md`, the constitution, the handoff, and `docs/decisions.md` name the same choices (grep each for FastAPI, Render, R2, shadcn)
- [x] `pii-scan.py` is clean

## Config/PII impact

None. Future settings (R2 keys, DB URL, session secret) get added to `.env.example` when they're implemented.

## Open questions / risks

- Render pricing comes from third-party sources (Starter web service $7/mo; Postgres about $6–20/mo). Confirm on render.com/pricing before provisioning.
