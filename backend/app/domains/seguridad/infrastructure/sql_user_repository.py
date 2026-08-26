from typing import Optional, List
from sqlalchemy.orm import Session

from app.domains.seguridad.domain.ports.user_repository_port import UserRepositoryPort
from app.domains.seguridad.domain.entities.rbac import UserEntity, RoleEntity, PermissionEntity
from app.domains.seguridad.infrastructure.models import UsuarioModel, RolModel, PermisoModel


class SqlUserRepository(UserRepositoryPort):
    """
    Adaptador de repositorio que implementa UserRepositoryPort
    usando SQLAlchemy y PostgreSQL.
    """

    def __init__(self, db: Session):
        self._db = db

    def get_by_name(self, nombre: str) -> Optional[UserEntity]:
        user_model = self._db.query(UsuarioModel).filter(UsuarioModel.nombre == nombre).first()
        if not user_model:
            return None
        return self._to_entity(user_model)

    def create_user(self, nombre: str) -> UserEntity:
        user_model = UsuarioModel(nombre=nombre)
        self._db.add(user_model)
        self._db.commit()
        self._db.refresh(user_model)
        return self._to_entity(user_model)

    def sync_keycloak_user(self, nombre: str, keycloak_roles: List[str]) -> UserEntity:
        # 1. Obtener o crear usuario
        user_model = self._db.query(UsuarioModel).filter(UsuarioModel.nombre == nombre).first()
        if not user_model:
            user_model = UsuarioModel(nombre=nombre)
            self._db.add(user_model)
            self._db.flush()

        # 2. Sincronizar roles asociados
        existing_roles = {r.nombre_rol: r for r in user_model.roles}
        for role_name in keycloak_roles:
            if not role_name or role_name.startswith("default-"):
                continue  # Omitir roles internos no configurados

            if role_name not in existing_roles:
                # Buscar si el rol existe en la base de datos
                db_role = self._db.query(RolModel).filter(RolModel.nombre_rol == role_name).first()
                if not db_role:
                    db_role = RolModel(nombre_rol=role_name)
                    self._db.add(db_role)
                    self._db.flush()

                user_model.roles.append(db_role)

        self._db.commit()
        self._db.refresh(user_model)
        return self._to_entity(user_model)

    def get_user_permissions(self, nombre: str) -> List[str]:
        user_model = self._db.query(UsuarioModel).filter(UsuarioModel.nombre == nombre).first()
        if not user_model:
            return []

        permissions_set = set()
        for role in user_model.roles:
            for perm in role.permisos:
                permissions_set.add(perm.nombre_permiso)

        return sorted(list(permissions_set))

    def _to_entity(self, model: UsuarioModel) -> UserEntity:
        roles_entities = []
        for r in model.roles:
            perms_entities = [
                PermissionEntity(id_permiso=p.id_permiso, nombre_permiso=p.nombre_permiso)
                for p in getattr(r, "permisos", [])
            ]
            roles_entities.append(
                RoleEntity(
                    id_rol=r.id_rol,
                    nombre_rol=r.nombre_rol,
                    keycloak_id=r.keycloak_id,
                    permisos=perms_entities,
                )
            )

        return UserEntity(
            id_usuario=model.id_usuario,
            nombre=model.nombre,
            roles=roles_entities,
        )
