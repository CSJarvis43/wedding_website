from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# backend/src/wedding/settings.py -> repo root, where .env lives.
# Missing files are ignored, so containers rely on real environment variables.
ENV_FILE = Path(__file__).resolve().parents[3] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=ENV_FILE, extra="ignore")

    database_url: str
    app_env: str = "development"


@lru_cache
def get_settings() -> Settings:
    return Settings()
