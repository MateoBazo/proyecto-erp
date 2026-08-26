from sqlalchemy import Column, Integer, String, Table, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database.connection import Base

# Tabla intermedia: usuarios <-> roles
usuario_rol = Table(
    "usuario_rol",
    Base.metadata,
    Column("id_usuario", Integer, ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), primary_key=True),
    Column("id_rol", Integer, ForeignKey("roles.id_rol", ondelete="CASCADE"), primary_key=True),
)

# Tabla intermedia: roles <-> permisos
rol_permiso = Table(
    "rol_permiso",
    Base.metadata,
    Column("id_rol", Integer, ForeignKey("roles.id_rol", ondelete="CASCADE"), primary_key=True),
    Column("id_permiso", Integer, ForeignKey("permisos.id_permiso", ondelete="CASCADE"), primary_key=True),
)


class UsuarioModel(Base):
    """Modelo ORM para la tabla 'usuarios'."""
    __tablename__ = "usuarios"

    id_usuario = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre = Column(String(50), nullable=False, unique=True, index=True)

    # Relación muchos a muchos con roles
    roles = relationship("RolModel", secondary=usuario_rol, back_populates="usuarios", lazy="joined")


class RolModel(Base):
    """Modelo ORM para la tabla 'roles'."""
    __tablename__ = "roles"

    id_rol = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre_rol = Column(String(50), nullable=False, unique=True, index=True)
    keycloak_id = Column(String(100), unique=True, nullable=True)

    # Relaciones
    usuarios = relationship("UsuarioModel", secondary=usuario_rol, back_populates="roles")
    permisos = relationship("PermisoModel", secondary=rol_permiso, back_populates="roles", lazy="joined")


class PermisoModel(Base):
    """Modelo ORM para la tabla 'permisos'."""
    __tablename__ = "permisos"

    id_permiso = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre_permiso = Column(String(50), nullable=False, unique=True, index=True)

    # Relación con roles
    roles = relationship("RolModel", secondary=rol_permiso, back_populates="permisos")
