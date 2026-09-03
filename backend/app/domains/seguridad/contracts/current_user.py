"""Punto de entrada público de seguridad para saber quién es el usuario autenticado."""
from app.domains.seguridad.domain.entities.user import UserProfile
from app.domains.seguridad.presentation.deps import get_current_user

__all__ = ["UserProfile", "get_current_user"]
