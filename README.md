# Wedding Website

Wedding site with a FastAPI backend (`backend/`) and a React + Vite frontend (`frontend/`). See `CLAUDE.md` for the stack and workflow, and `docs/decisions.md` for why things are the way they are.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [mise](https://mise.jdx.dev/), which installs the pinned Python, Node, uv, and pnpm versions from `mise.toml`:
  ```bash
  brew install mise
  echo 'eval "$(mise activate zsh)"' >> ~/.zshrc   # then open a new terminal
  ```

## First-time setup

```bash
mise trust && mise install        # toolchains
cp .env.example .env              # placeholder values work for local dev
(cd backend && uv sync)           # native deps, for tests and your editor
(cd frontend && pnpm install)
```

## Run the stack

```bash
docker compose up --build
```

- Site: http://localhost:3000
- API: http://localhost:8000/api/health (also proxied at http://localhost:3000/api/health)
- Postgres: `localhost:5432`, credentials from `.env`

Editing files under `backend/src/` or `frontend/src/` reloads automatically. The backend runs `alembic upgrade head` each time it starts.

Useful variations:

```bash
docker compose up --build -V      # after changing frontend dependencies (refreshes node_modules)
docker compose down               # stop (keeps the database)
docker compose down -v            # stop and delete the local database
```

If startup fails with "port is already allocated", something else on your machine is using 3000, 8000, or 5432. Stop it, or change the host side of the port in `docker-compose.yml`.

## Tests, lint, format

Backend (from `backend/`):

```bash
uv run pytest
uv run ruff check .
uv run ruff format .
```

Frontend (from `frontend/`):

```bash
pnpm test
pnpm lint
pnpm format
pnpm typecheck
```

## Migrations

```bash
docker compose exec backend alembic revision --autogenerate -m "describe change"
docker compose exec backend alembic upgrade head
```
