from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

BACKEND_DIR = Path(__file__).resolve().parents[1]


def test_upgrade_head_runs_against_configured_database(monkeypatch, tmp_path):
    database_url = f"sqlite:///{tmp_path / 'test.db'}"
    monkeypatch.setenv("DATABASE_URL", database_url)
    monkeypatch.setenv("APP_ENV", "test")

    config = Config(BACKEND_DIR / "alembic.ini")
    command.upgrade(config, "head")

    assert "alembic_version" in inspect(create_engine(database_url)).get_table_names()
