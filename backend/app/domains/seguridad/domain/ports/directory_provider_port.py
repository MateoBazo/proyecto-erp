from abc import ABC, abstractmethod


class DirectoryProviderPort(ABC):
    """
    Escritura directa contra el directorio institucional (LDAP/Samba4 vía Zentyal).

    Keycloak no propaga el cambio de contraseña de vuelta al directorio, así que
    esto actualiza la contraseña real ahí directamente.
    """

    @abstractmethod
    def reset_password(self, username: str, new_password: str) -> None:
        """Cambia la contraseña de `username` con una cuenta admin (no self-service)."""
        pass
