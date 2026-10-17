import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from wedding.main import app


def test_startup_fails_without_database_url(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)

    with pytest.raises(ValidationError, match="database_url"), TestClient(app):
        pass
