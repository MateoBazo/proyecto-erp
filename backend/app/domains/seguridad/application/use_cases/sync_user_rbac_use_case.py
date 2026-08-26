from typing import List, Tuple
from app.domains.seguridad.domain.ports.user_repository_port import UserRepositoryPort
from app.domains.seguridad.domain.entities.rbac import UserEntity


class SyncUserRbacUseCase:
    """
    Caso de uso: Sincroniza al usuario autenticado por Keycloak en la base de datos PostgreSQL
    y recupera los permisos asignados en el modelo de seguridad RBAC.
    """

    def __init__(self, user_repository: UserRepositoryPort):
        self._user_repository = user_repository

    def execute(self, username: str, keycloak_roles: List[str]) -> Tuple[UserEntity, List[str]]:
        clean_name = (username or "").strip()
        if not clean_name:
            clean_name = "usuario_anonimo"

        user_entity = self._user_repository.sync_keycloak_user(clean_name, keycloak_roles)
        permissions = self._user_repository.get_user_permissions(clean_name)

        return user_entity, permissions
