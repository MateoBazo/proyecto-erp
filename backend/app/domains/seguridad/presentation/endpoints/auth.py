from fastapi import APIRouter, Depends
import logging

from app.domains.seguridad.presentation.schemas.auth_schema import (
    LoginRequest,
    LoginResponse,
    RefreshRequest,
)
from app.domains.seguridad.application.use_cases import (
    AuthenticateDomainUseCase,
    AuthenticateCredentialsUseCase,
    RefreshTokenUseCase,
    VerifyTokenUseCase,
    SyncUserRbacUseCase,
)
from app.domains.seguridad.application.dtos.auth_dto import (
    DomainLoginInputDTO,
    CredentialsLoginInputDTO,
    RefreshTokenInputDTO,
)
from app.domains.seguridad.domain.exceptions import InvalidDomainException
from app.domains.seguridad.presentation.deps import (
    get_authenticate_domain_use_case,
    get_authenticate_credentials_use_case,
    get_refresh_token_use_case,
    get_verify_token_use_case,
    get_sync_user_rbac_use_case,
)

logger = logging.getLogger("uvicorn.error")

router = APIRouter(tags=["Autenticación"])


@router.post("/login", response_model=LoginResponse)
def login(
    payload: LoginRequest,
    domain_use_case: AuthenticateDomainUseCase = Depends(get_authenticate_domain_use_case),
    credentials_use_case: AuthenticateCredentialsUseCase = Depends(get_authenticate_credentials_use_case),
    verify_use_case: VerifyTokenUseCase = Depends(get_verify_token_use_case),
    sync_rbac: SyncUserRbacUseCase = Depends(get_sync_user_rbac_use_case),
):
    """
    Endpoint de Autenticación compatible con Dominio Institucional y Credenciales Directas.
    - Si se envía `domain`: Valida el dominio institucional con Keycloak.
    - Si se envía `username` y `password`: Valida credenciales directas contra Keycloak
      y garantiza que el usuario exista en la tabla 'usuario' (sin asignar roles).
    """
    if payload.domain:
        result = domain_use_case.execute(DomainLoginInputDTO(domain=payload.domain))
        return LoginResponse(
            message=result.message,
            access_token=result.access_token,
            domain=result.domain,
        )

    if payload.username and payload.password:
        result = credentials_use_case.execute(
            CredentialsLoginInputDTO(
                username=payload.username,
                password=payload.password,
            )
        )

        # Garantizar que el usuario exista en 'usuario' (vinculado por keycloak_sub)
        try:
            profile = verify_use_case.execute(result.access_token)
            sync_rbac.execute(
                keycloak_sub=profile.sub,
                username=profile.username,
                correo=profile.email,
            )
        except Exception as exc:
            logger.warning(f"Aviso al guardar usuario en base de datos: {exc}")

        return LoginResponse(
            message=result.message,
            access_token=result.access_token,
            refresh_token=result.refresh_token,
            expires_in=result.expires_in,
        )

    raise InvalidDomainException("Debe ingresar un dominio institucional o usuario y contraseña.")


@router.post("/refresh", response_model=LoginResponse)
def refresh(
    payload: RefreshRequest,
    refresh_use_case: RefreshTokenUseCase = Depends(get_refresh_token_use_case),
):
    """
    Renueva la sesión a partir de un refresh_token vigente, sin requerir credenciales.
    Permite un refresh silencioso desde el frontend antes de que expire el access_token.
    """
    result = refresh_use_case.execute(RefreshTokenInputDTO(refresh_token=payload.refresh_token))

    return LoginResponse(
        message=result.message,
        access_token=result.access_token,
        refresh_token=result.refresh_token,
        expires_in=result.expires_in,
    )
