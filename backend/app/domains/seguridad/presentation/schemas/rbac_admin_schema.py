from typing import List, Optional
from pydantic import BaseModel, Field


class RolOut(BaseModel):
    """Rol interno con sus permisos como códigos 'recurso.accion'."""
    id: str
    nombre: str
    descripcion: Optional[str] = None
    activo: bool = True
    permisos: List[str] = Field(default_factory=list)


class RolCreateRequest(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=50)
    permisos: List[str] = Field(default_factory=list)


class RolPermisosUpdateRequest(BaseModel):
    permisos: List[str] = Field(default_factory=list)


class AreaOut(BaseModel):
    id: str
    nombre: str
    tipo: Optional[str] = None


class AreaCreateRequest(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)


class AreaUpdateRequest(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)


class RolResumenOut(BaseModel):
    """Rol asignado a un usuario, sin sus permisos (esos se editan en RolesPage)."""
    id: str
    nombre: str


class UsuarioAsignacionOut(BaseModel):
    id: str
    username: str
    correo: Optional[str] = None
    roles: List[RolResumenOut] = Field(default_factory=list)
    area_id: Optional[str] = None
    area_nombre: Optional[str] = None
    activo: bool = True


class AsignarRolAreaRequest(BaseModel):
    """rol_ids y area_id van juntos o ambos vacíos. Puede haber más de un rol,
    todos bajo la misma área."""
    rol_ids: List[str] = Field(default_factory=list)
    area_id: Optional[str] = None


class UsuarioEstadoUpdateRequest(BaseModel):
    """Activar/desactivar un usuario en vez de borrarlo."""
    activo: bool
