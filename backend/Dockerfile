# Local development image. Source is bind-mounted by docker-compose.yml;
# the virtualenv lives outside /app so the host's .venv never shadows it.
FROM python:3.13.16-slim

COPY --from=ghcr.io/astral-sh/uv:0.11.20 /uv /uvx /bin/

ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-install-project

COPY . .
RUN uv sync --locked

EXPOSE 8000
CMD ["sh", "-c", "alembic upgrade head && uvicorn wedding.main:app --host 0.0.0.0 --port 8000 --reload --reload-dir src"]
