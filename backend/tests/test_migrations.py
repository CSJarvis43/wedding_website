from pathlib import Path

from alembic import command
from alembic.config import Config

from wedding.settings import get_settings

BACKEND_DIR = Path(__file__).resolve().parents[1]


def test_upgrade_head_runs_against_configured_database(monkeypatch, tmp_path):
    db_file = tmp_path / "test.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{db_file}")
    get_settings.cache_clear()

    config = Config(BACKEND_DIR / "alembic.ini")
    command.upgrade(config, "head")

    assert db_file.exists()
    get_settings.cache_clear()
