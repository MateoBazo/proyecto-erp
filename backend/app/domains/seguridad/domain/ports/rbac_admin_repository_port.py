from abc import ABC, abstractmethod
from typing import List, Optional

from app.domains.seguridad.domain.entities.rbac import (
    AreaEntity,
    RoleEntity,
    UsuarioAsignacionEntity,
)


class RbacAdminRepositoryPort(ABC):
    """
    Puerto para la pantalla de administración de roles, áreas y asignación usuario-rol-área
    (rol_interno, area, usuario_rol_area, permiso, rol_permiso) — la pieza que CLAUDE.md §10
    marca como pendiente ("hoy no existe ninguna, es manual directo en la base").
    """

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
        Reemplaza por completo el conjunto de permisos de un rol. Cada código
        'recurso.accion' se resuelve a una fila real en 'permiso' (creándola si hace
        falta, junto con su 'recurso' — nunca un permiso chequeado solo en código sin
        fila en la tabla, CLAUDE.md §4).
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
        """Todos los usuarios (tabla 'usuario') junto con su rol+área actual, si tienen uno."""
        pass

    @abstractmethod
    def asignar_rol_area(
        self,
        usuario_id: str,
        rol_id: Optional[str],
        area_id: Optional[str],
        actor_usuario_id: Optional[str],
    ) -> UsuarioAsignacionEntity:
        """
        Reemplaza la asignación rol+área de un usuario por la indicada. Si rol_id o area_id
        vienen vacíos, el usuario queda sin asignación (la base exige ambos juntos o ninguno:
        no existe usuario_rol_area sin área, CLAUDE.md §6).
        """
        pass
