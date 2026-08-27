from typing import Optional, List
from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """Esquema para la solicitud de inicio de sesión."""
    domain: Optional[str] = Field(None, description="Dominio institucional (ej. gamc.gob.bo)")
    username: Optional[str] = Field(None, description="Nombre de usuario para acceso directo")
    password: Optional[str] = Field(None, description="Contraseña de usuario")


class LoginResponse(BaseModel):
    """Esquema de respuesta exitosa de inicio de sesión."""
    message: str
    access_token: str
    domain: Optional[str] = None


class PublicMessageResponse(BaseModel):
    """Esquema de respuesta para rutas públicas."""
    message: str


class DatabaseHealthResponse(BaseModel):
    """Esquema de respuesta para verificación del estado de PostgreSQL."""
    status: str
    database: str
    message: str


class PrivateProfileResponse(BaseModel):
    """Esquema de respuesta para información de perfil protegido."""
    message: str
    usuario: str
    email: str
    roles: List[str] = []
    client_id: Optional[str] = None
    id_usuario: Optional[str] = None
    permisos: List[str] = []
