from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class PermissionEntity:
    """Entidad de dominio para un permiso: una 'accion' sobre un 'recurso' concreto."""
    id_permiso: Optional[str]
    accion: str
    recurso: Optional[str] = None
    descripcion: Optional[str] = None

    @property
    def codigo(self) -> str:
        """Representación 'recurso.accion' del permiso."""
        return f"{self.recurso}.{self.accion}" if self.recurso else self.accion


@dataclass
class RoleEntity:
    """Rol interno (tabla rol_interno). Sin keycloak_id: es independiente de Keycloak."""
    id_rol: Optional[str]
    nombre: str
    descripcion: Optional[str] = None
    activo: bool = True
    permisos: List[PermissionEntity] = field(default_factory=list)


@dataclass
class UserEntity:
    """Entidad de dominio para un usuario local (tabla usuario) y su vínculo con Keycloak."""
    id_usuario: Optional[str]
    username: str
    keycloak_sub: Optional[str] = None
    correo: Optional[str] = None
    activo: bool = True
    roles: List[RoleEntity] = field(default_factory=list)


@dataclass
class AreaEntity:
    """Área (tabla area): el alcance con el que se asigna un rol a un usuario."""
    id_area: Optional[str]
    nombre: str
    tipo: Optional[str] = None


@dataclass
class UsuarioAsignacionEntity:
    """Usuario con su asignación actual de roles + área. Puede tener varios roles
    a la vez, pero siempre dentro de una misma área."""
    id_usuario: str
    username: str
    correo: Optional[str]
    roles: List[RoleEntity] = field(default_factory=list)
    area_id: Optional[str] = None
    area_nombre: Optional[str] = None
    activo: bool = True
