from typing import List, Optional, Tuple

from app.domains.seguridad.domain.entities.rbac import UserEntity
from app.domains.seguridad.domain.exceptions import UsuarioInactivoException
from app.domains.seguridad.domain.ports.user_repository_port import UserRepositoryPort


INSTITUTIONAL_SUB_SENTINEL = "institucional"


class SyncUserRbacUseCase:
    """
    Garantiza que el usuario autenticado por Keycloak tenga un registro en
    PostgreSQL (vinculado por keycloak_sub) y devuelve sus permisos RBAC.

    No copia roles de Keycloak: un usuario nuevo arranca con un punto de partida
    fijo (área "Catastro" + rol "Inicio", ver SqlUserRepository.ensure_user_exists),
    no algo derivado del token.

    Caso "institucional": si el token no trae 'sub' (cuenta de servicio, no una
    persona), se reutiliza siempre el mismo usuario 'Institucional'. Ojo: bajo ese
    modo ninguna acción se puede auditar por persona.
    """

    def __init__(self, user_repository: UserRepositoryPort):
        self._user_repository = user_repository

    def execute(
        self, keycloak_sub: str, username: str, correo: Optional[str] = None
    ) -> Tuple[UserEntity, List[str]]:
        clean_sub = (keycloak_sub or "").strip()
        clean_username = (username or "").strip() or "usuario_anonimo"

        if not clean_sub:
            clean_sub = INSTITUTIONAL_SUB_SENTINEL
            clean_username = clean_username if clean_username != "usuario_anonimo" else "Institucional"

        usuario_existente = self._user_repository.get_by_keycloak_sub(clean_sub)
        if usuario_existente and not usuario_existente.activo:
            raise UsuarioInactivoException(
                "Tu usuario está inactivo. Contactá a un administrador."
            )

        user_entity = self._user_repository.ensure_user_exists(
            keycloak_sub=clean_sub, username=clean_username, correo=correo
        )
        permissions = self._user_repository.get_user_permissions(clean_sub)
        return user_entity, permissions
