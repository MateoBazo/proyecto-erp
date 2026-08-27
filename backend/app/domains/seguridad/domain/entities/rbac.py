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
