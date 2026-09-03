"""
Punto de entrada público de seguridad para exigir un permiso RBAC desde otro dominio.

Uso desde otro dominio, ej. catastro:

    from app.domains.seguridad.contracts import require_permission

    @router.post("/predios")
    def crear_predio(current_user = Depends(require_permission("catastro.predios.crear"))):
        ...
"""
from app.domains.seguridad.presentation.deps import require_permission

__all__ = ["require_permission"]
