from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from sqlmodel import Session, select

from wedding.db import get_session
from wedding.settings import get_settings


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    get_settings()  # Fail at startup, not on the first request, if config is missing.
    yield


app = FastAPI(title="Wedding API", lifespan=lifespan)


@app.get("/api/health")
def health(session: Annotated[Session, Depends(get_session)]) -> JSONResponse:
    try:
        session.exec(select(1))
    except SQLAlchemyError:
        return JSONResponse(status_code=503, content={"status": "unavailable"})
    return JSONResponse(content={"status": "ok"})
