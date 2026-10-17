import pytest
from pydantic import ValidationError

from wedding.settings import Settings


@pytest.mark.parametrize(
    ("missing", "field"), [("DATABASE_URL", "database_url"), ("APP_ENV", "app_env")]
)
def test_missing_required_setting_fails_loudly(monkeypatch, missing, field):
    monkeypatch.setenv("DATABASE_URL", "sqlite://")
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.delenv(missing)

    with pytest.raises(ValidationError, match=field):
        Settings(_env_file=None)


def test_loads_settings_from_environment(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "sqlite://")
    monkeypatch.setenv("APP_ENV", "test")

    settings = Settings(_env_file=None)

    assert settings.database_url == "sqlite://"
    assert settings.app_env == "test"
