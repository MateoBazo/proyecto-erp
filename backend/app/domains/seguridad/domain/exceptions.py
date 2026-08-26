from app.core.errors.exceptions import DomainException

# Excepciones técnicas de autenticación/tokens (comunicación con Keycloak) viven en
# core.security.exceptions, porque cualquier dominio que integre Keycloak las necesita,
# no solo `seguridad`. Se re-exportan acá por comodidad para el código de este dominio.
from app.core.security.exceptions import (  # noqa: F401
    InvalidCredentialsException,
    TokenVerificationException,
    TokenExpiredException,
    AuthProviderUnavailableException,
)


class InvalidDomainException(DomainException):
    """Se lanza cuando un dominio institucional es inválido o está vacío."""
    pass


__all__ = [
    "DomainException",
    "InvalidDomainException",
    "InvalidCredentialsException",
    "TokenVerificationException",
    "TokenExpiredException",
    "AuthProviderUnavailableException",
]
