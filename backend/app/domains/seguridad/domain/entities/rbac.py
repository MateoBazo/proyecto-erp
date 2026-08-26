from dataclasses import dataclass, field
from typing import List, Optional
from datetime import datetime


@dataclass
class PermissionEntity:
    """Entidad de dominio para Permisos del sistema RBAC."""
    id_permiso: Optional[int]
    nombre_permiso: str
    descripcion: Optional[str] = None


@dataclass
class RoleEntity:
    """Entidad de dominio para Roles del sistema RBAC."""
    id_rol: Optional[int]
    nombre_rol: str
    keycloak_id: Optional[str] = None
    descripcion: Optional[str] = None
    permisos: List[PermissionEntity] = field(default_factory=list)


@dataclass
class UserEntity:
    """Entidad de dominio para Usuarios locales y su mapeo con Keycloak."""
    id_usuario: Optional[int]
    nombre: str
    keycloak_id: Optional[str] = None
    correo: Optional[str] = None
    activo: bool = True
    fecha_creacion: Optional[datetime] = None
    roles: List[RoleEntity] = field(default_factory=list)
