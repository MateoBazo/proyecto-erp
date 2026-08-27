from functools import lru_cache
from fastapi import Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.domains.seguridad.domain.ports.auth_provider_port import AuthProviderPort
from app.domains.seguridad.domain.ports.user_repository_port import UserRepositoryPort
from app.domains.seguridad.domain.entities.user import UserProfile
from app.domains.seguridad.application.use_cases import (
    AuthenticateDomainUseCase,
    AuthenticateCredentialsUseCase,
    RefreshTokenUseCase,
    VerifyTokenUseCase,
    SyncUserRbacUseCase,
)
from app.domains.seguridad.infrastructure.keycloak_adapter import KeycloakAdapter
from app.core.security.jwks_service import JWKSService
from app.core.database.connection import get_db
from app.domains.seguridad.infrastructure.sql_user_repository import SqlUserRepository

# Mecanismo de extracción de cabecera Bearer
security = HTTPBearer()


@lru_cache()
def get_jwks_service() -> JWKSService:
    """Instancia única (singleton cacheado) para el servicio JWKS."""
    return JWKSService()


@lru_cache()
def get_auth_provider() -> AuthProviderPort:
    """Instancia única (singleton cacheado) del adaptador de Keycloak."""
    return KeycloakAdapter(jwks_service=get_jwks_service())


def get_authenticate_domain_use_case(
    auth_provider: AuthProviderPort = Depends(get_auth_provider),
) -> AuthenticateDomainUseCase:
    """Inyector del caso de uso de autenticación por dominio."""
    return AuthenticateDomainUseCase(auth_provider=auth_provider)


def get_authenticate_credentials_use_case(
    auth_provider: AuthProviderPort = Depends(get_auth_provider),
) -> AuthenticateCredentialsUseCase:
    """Inyector del caso de uso de autenticación por credenciales directas."""
    return AuthenticateCredentialsUseCase(auth_provider=auth_provider)


def get_refresh_token_use_case(
    auth_provider: AuthProviderPort = Depends(get_auth_provider),
) -> RefreshTokenUseCase:
    """Inyector del caso de uso de renovación de sesión."""
    return RefreshTokenUseCase(auth_provider=auth_provider)


def get_verify_token_use_case(
    auth_provider: AuthProviderPort = Depends(get_auth_provider),
) -> VerifyTokenUseCase:
    """Inyector del caso de uso de verificación de tokens."""
    return VerifyTokenUseCase(auth_provider=auth_provider)


def get_user_repository(db: Session = Depends(get_db)) -> UserRepositoryPort:
    """Inyector del repositorio de usuarios conectado a PostgreSQL."""
    return SqlUserRepository(db=db)


def get_sync_user_rbac_use_case(
    user_repository: UserRepositoryPort = Depends(get_user_repository),
) -> SyncUserRbacUseCase:
    """Inyector del caso de uso de sincronización RBAC."""
    return SyncUserRbacUseCase(user_repository=user_repository)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
    verify_use_case: VerifyTokenUseCase = Depends(get_verify_token_use_case),
) -> UserProfile:
    """
    Dependencia de FastAPI para proteger endpoints.
    Extrae el token Bearer, lo valida contra Keycloak y retorna la entidad UserProfile.
    """
    token = credentials.credentials
    return verify_use_case.execute(token)
