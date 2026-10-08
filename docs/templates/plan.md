<!-- issue-plan -->
# Plan: #<issue> <title>

**Issue:** #<issue>. **Branch:** `<type>/<issue>-<slug>`. **Size:** small.
<!-- Sub-issue of an epic? Add: **Spec:** specs/<epic#>-<slug>/ (tasks T0xx–T0yy) -->

## Goal

<!-- One or two sentences: what will be true when this is done, from a guest's or admin's point of view. -->

## Out of scope

<!-- What this deliberately doesn't do, so the PR stays small. -->

## Approach

<!-- How it'll work and why this way. Mention any alternative you rejected. -->

## Files touched

<!-- Paths to create or modify, with a few words each. -->

## Steps

<!-- Each step is one red → green → refactor cycle ending in a commit.
     Pure styling/copy steps can skip the test line. -->

- [ ] **1. <behavior>**
  - Test: `<test file>`: <what the failing test asserts>
  - Implement: <what changes to make it pass>
  - Commit: `<type>: <message>`
- [ ] **2. ...**

## Verification

<!-- Commands that must pass, plus any manual check (with fake data). -->

- [ ] Backend: `uv run pytest`, `uv run ruff check .`, `uv run ruff format --check .`
- [ ] Frontend: `pnpm test`, `pnpm lint`, `pnpm format:check`, `pnpm typecheck`

## Config/PII impact

<!-- New settings (add to .env.example with placeholders)? New personal data stored or shown? "None" is a fine answer. -->

## Open questions / risks
