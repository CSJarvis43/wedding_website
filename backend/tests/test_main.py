import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from wedding.main import app


def test_startup_fails_without_required_settings(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("APP_ENV", raising=False)

    with pytest.raises(ValidationError, match="database_url"), TestClient(app):
        pass
