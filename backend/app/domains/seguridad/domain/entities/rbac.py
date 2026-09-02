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
        """Representación 'recurso.accion' — aproximación al formato dominio.recurso.accion
        de CLAUDE.md §8. El nivel 'dominio' (sistema/subsistema en la base real) todavía no
        está confirmado como equivalente a los dominios del ERP; no asumir que lo es sin
        confirmar con el equipo (ver CLAUDE.md §10)."""
        return f"{self.recurso}.{self.accion}" if self.recurso else self.accion


@dataclass
class RoleEntity:
    """Entidad de dominio para un rol interno (tabla rol_interno). Sin keycloak_id: un rol
    interno es independiente de los roles de Keycloak (CLAUDE.md §5 y §6)."""
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
    """Entidad de dominio para un área (tabla area) — el 'alcance' con el que se asigna
    un rol_interno a un usuario (usuario_rol_area, ver CLAUDE.md §5)."""
    id_area: Optional[str]
    nombre: str
    tipo: Optional[str] = None


@dataclass
class UsuarioAsignacionEntity:
    """Vista de un usuario junto con su asignación actual de rol + área (usuario_rol_area).
    El esquema real permite varias filas por usuario (varios rol+área a la vez), pero esta
    entidad representa una única asignación 'activa' por usuario — la pantalla de admin de
    CLAUDE.md §10 asume un rol y un área a la vez por usuario, no un set de asignaciones."""
    id_usuario: str
    username: str
    correo: Optional[str]
    rol_id: Optional[str] = None
    rol_nombre: Optional[str] = None
    area_id: Optional[str] = None
    area_nombre: Optional[str] = None
