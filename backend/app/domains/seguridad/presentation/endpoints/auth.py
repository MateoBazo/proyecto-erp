from fastapi import APIRouter, Depends
import logging

from app.domains.seguridad.presentation.schemas.auth_schema import LoginRequest, LoginResponse
from app.domains.seguridad.application.use_cases import (
    AuthenticateDomainUseCase,
    AuthenticateCredentialsUseCase,
    VerifyTokenUseCase,
    SyncUserRbacUseCase,
)
from app.domains.seguridad.application.dtos.auth_dto import (
    DomainLoginInputDTO,
    CredentialsLoginInputDTO,
)
from app.domains.seguridad.domain.exceptions import InvalidDomainException
from app.domains.seguridad.presentation.deps import (
    get_authenticate_domain_use_case,
    get_authenticate_credentials_use_case,
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
      y guarda/sincroniza automáticamente al usuario en la base de datos (tabla 'usuarios').
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

        # Sincronizar y persistir automáticamente en la tabla 'usuarios'
        try:
            profile = verify_use_case.execute(result.access_token)
            sync_rbac.execute(username=profile.username, keycloak_roles=profile.roles)
        except Exception as exc:
            logger.warning(f"Aviso al guardar usuario en base de datos: {exc}")

        return LoginResponse(
            message=result.message,
            access_token=result.access_token,
        )

    raise InvalidDomainException("Debe ingresar un dominio institucional o usuario y contraseña.")
