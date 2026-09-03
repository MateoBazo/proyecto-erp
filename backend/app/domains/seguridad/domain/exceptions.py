from app.core.errors.exceptions import DomainException

# Excepciones de autenticación/tokens viven en core.security.exceptions
# (las necesita cualquier dominio con Keycloak); se re-exportan acá por comodidad.
from app.core.security.exceptions import (  # noqa: F401
    InvalidCredentialsException,
    TokenVerificationException,
    TokenExpiredException,
    AuthProviderUnavailableException,
)


class InvalidDomainException(DomainException):
    """Se lanza cuando un dominio institucional es inválido o está vacío."""
    pass


class UsuarioInactivoException(DomainException):
    """Se lanza cuando un usuario inactivo (usuario.activo = false) intenta
    autenticarse. Sigue existiendo en Keycloak; el bloqueo lo decide el ERP."""
    http_status = 403


__all__ = [
    "DomainException",
    "InvalidDomainException",
    "UsuarioInactivoException",
    "InvalidCredentialsException",
    "TokenVerificationException",
    "TokenExpiredException",
    "AuthProviderUnavailableException",
]
