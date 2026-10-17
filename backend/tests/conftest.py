import pytest

from wedding.db import get_engine
from wedding.settings import Settings, get_settings


@pytest.fixture(autouse=True)
def isolated_settings(monkeypatch):
    """Keep tests off the developer's real .env and cached config; each test sets what it needs."""
    monkeypatch.setitem(Settings.model_config, "env_file", None)
    get_settings.cache_clear()
    get_engine.cache_clear()
    yield
    get_settings.cache_clear()
    get_engine.cache_clear()
