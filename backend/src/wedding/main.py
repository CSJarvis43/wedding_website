from typing import Annotated

from fastapi import Depends, FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from sqlmodel import Session, select

from wedding.db import get_session

app = FastAPI(title="Wedding API")


@app.get("/api/health")
def health(session: Annotated[Session, Depends(get_session)]) -> JSONResponse:
    try:
        session.exec(select(1))
    except SQLAlchemyError:
        return JSONResponse(status_code=503, content={"status": "unavailable"})
    return JSONResponse(content={"status": "ok"})
