"""
Script para inicializar las tablas de la base de datos PostgreSQL
basadas en los modelos ORM declarativos de SQLAlchemy.
"""
from app.core.database.connection import engine, Base
from app.domains.seguridad.infrastructure.models import UsuarioModel, RolModel, PermisoModel, usuario_rol, rol_permiso
from app.core.config import settings


def init_database():
    print(f"[*] Conectando a PostgreSQL: {settings.SQLALCHEMY_DATABASE_URI}")
    try:
        # Crea todas las tablas si no existen
        Base.metadata.create_all(bind=engine)
        print("[+] ¡Tablas creadas/verificadas exitosamente en PostgreSQL!")
    except Exception as exc:
        print(f"[-] Error al inicializar la base de datos: {exc}")


if __name__ == "__main__":
    init_database()
