from abc import ABC, abstractmethod
from typing import Optional, List
from app.domains.seguridad.domain.entities.rbac import UserEntity


class UserRepositoryPort(ABC):
    """
    Puerto (interfaz abstracta) para operaciones de persistencia del usuario
    y sincronización RBAC en la base de datos PostgreSQL.
    """

    @abstractmethod
    def get_by_name(self, nombre: str) -> Optional[UserEntity]:
        """Obtiene un usuario por su nombre o identificador."""
        pass

    @abstractmethod
    def create_user(self, nombre: str) -> UserEntity:
        """Registra un nuevo usuario en la base de datos."""
        pass

    @abstractmethod
    def sync_keycloak_user(self, nombre: str, keycloak_roles: List[str]) -> UserEntity:
        """
        Garantiza que el usuario exista y asocia los roles de Keycloak correspondientes.
        """
        pass

    @abstractmethod
    def get_user_permissions(self, nombre: str) -> List[str]:
        """
        Retorna la lista agregada de nombres de permisos que el usuario tiene
        a través de todos sus roles asignados.
        """
        pass
