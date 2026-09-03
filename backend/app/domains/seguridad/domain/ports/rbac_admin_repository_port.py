from abc import ABC, abstractmethod
from typing import List, Optional

from app.domains.seguridad.domain.entities.rbac import (
    AreaEntity,
    RoleEntity,
    UsuarioAsignacionEntity,
)


class RbacAdminRepositoryPort(ABC):
    """Puerto para administrar roles, áreas y asignaciones usuario-rol-área."""

    @abstractmethod
    def list_roles(self) -> List[RoleEntity]:
        """Roles internos activos, con sus permisos ya resueltos como códigos 'recurso.accion'."""
        pass

    @abstractmethod
    def create_role(self, nombre: str) -> RoleEntity:
        """Crea un rol interno nuevo, sin permisos todavía."""
        pass

    @abstractmethod
    def set_role_permissions(self, rol_id: str, codigos: List[str], actor_usuario_id: Optional[str]) -> RoleEntity:
        """
        Reemplaza todos los permisos de un rol. Cada código 'recurso.accion' se
        resuelve a una fila real en 'permiso' (creándola si hace falta).
        """
        pass

    @abstractmethod
    def delete_role(self, rol_id: str, actor_usuario_id: Optional[str]) -> None:
        """Elimina un rol interno. Las asignaciones usuario_rol_area de ese rol se van con él
        (ON DELETE CASCADE en la base real)."""
        pass

    @abstractmethod
    def list_areas(self) -> List[AreaEntity]:
        pass

    @abstractmethod
    def create_area(self, nombre: str) -> AreaEntity:
        pass

    @abstractmethod
    def update_area(self, area_id: str, nombre: str) -> AreaEntity:
        pass

    @abstractmethod
    def delete_area(self, area_id: str, actor_usuario_id: Optional[str]) -> None:
        pass

    @abstractmethod
    def list_usuarios_con_asignacion(self) -> List[UsuarioAsignacionEntity]:
        """Todos los usuarios (tabla 'usuario') junto con su rol+área actual, si tienen uno.
        Incluye tanto activos como inactivos — un admin necesita ver a los inactivos para
        poder reactivarlos, no solo desactivarlos (ver set_usuario_activo)."""
        pass

    @abstractmethod
    def asignar_rol_area(
        self,
        usuario_id: str,
        rol_ids: List[str],
        area_id: Optional[str],
        actor_usuario_id: Optional[str],
    ) -> UsuarioAsignacionEntity:
        """
        Reemplaza la asignación de un usuario: una fila usuario_rol_area por cada
        rol_id, todas con el mismo area_id. Si rol_ids está vacío o falta area_id,
        el usuario queda sin asignación.
        """
        pass

    @abstractmethod
    def set_usuario_activo(
        self, usuario_id: str, activo: bool, actor_usuario_id: Optional[str]
    ) -> UsuarioAsignacionEntity:
        """
        Marca un usuario como activo/inactivo en vez de borrarlo. No toca sus
        roles/área: al reactivarlo recupera la asignación que ya tenía.
        """
        pass
