import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError
from sqlmodel import Session, create_engine

from wedding.db import get_session
from wedding.main import app


class UnreachableSession:
    def exec(self, *args, **kwargs):
        raise OperationalError("SELECT 1", {}, Exception("connection refused"))


@pytest.fixture
def client():
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_health_ok_when_database_reachable(client):
    def sqlite_session():
        with Session(create_engine("sqlite://")) as session:
            yield session

    app.dependency_overrides[get_session] = sqlite_session

    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_health_unavailable_when_database_unreachable(client):
    app.dependency_overrides[get_session] = lambda: UnreachableSession()

    response = client.get("/api/health")

    assert response.status_code == 503
    assert response.json() == {"status": "unavailable"}
