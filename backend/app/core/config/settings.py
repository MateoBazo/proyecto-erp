from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import computed_field


class Settings(BaseSettings):
    """
    Configuraciones globales del sistema Backend.
    Carga variables desde variables de entorno y archivo .env.
    """
    PROJECT_NAME: str = "Ecosistema Herramienta GIS - Backend"
    VERSION: str = "2.0.0"
    API_V1_STR: str = "/api"

    # Keycloak
    KEYCLOAK_URL: str = "https://auth.catastrocbba.com"
    KEYCLOAK_REALM: str = "master"
    KEYCLOAK_CLIENT_ID: str = "app-erp"
    KEYCLOAK_CLIENT_SECRET: str = ""
    KEYCLOAK_TIMEOUT_SECONDS: int = 20

    # CORS
    FRONTEND_ORIGIN: str = "http://localhost:3000"

    # PostgreSQL Database
    DB_HOST: str = "localhost"
    DB_PORT: str = "5432"
    DB_USER: str = "postgres"
    DB_PASSWORD: str = "postgres"
    DB_NAME: str = "gis_seguridad"
    DATABASE_URL: Optional[str] = None

    @computed_field
    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    @computed_field
    @property
    def ISSUER(self) -> str:
        return f"{self.KEYCLOAK_URL.rstrip('/')}/realms/{self.KEYCLOAK_REALM}"

    @computed_field
    @property
    def JWKS_URL(self) -> str:
        return f"{self.ISSUER}/protocol/openid-connect/certs"

    @computed_field
    @property
    def TOKEN_URL(self) -> str:
        return f"{self.ISSUER}/protocol/openid-connect/token"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
