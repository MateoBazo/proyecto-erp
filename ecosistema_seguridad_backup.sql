-- =========================================
-- Extensión necesaria para UUIDs
-- =========================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================
-- MÓDULO 1: ESTRUCTURA DEL SISTEMA
-- =========================================

CREATE TABLE sistema (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(100) NOT NULL,
    activo      BOOLEAN DEFAULT TRUE,
    descripcion VARCHAR(255)
);

CREATE TABLE subsistema (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sistema_id  UUID NOT NULL REFERENCES sistema(id) ON DELETE CASCADE,
    nombre      VARCHAR(100) NOT NULL,
    activo      BOOLEAN DEFAULT TRUE,
    es_opcional BOOLEAN DEFAULT FALSE
);

CREATE TABLE recurso (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subsistema_id  UUID NOT NULL REFERENCES subsistema(id) ON DELETE CASCADE,
    nombre         VARCHAR(100) NOT NULL,
    ruta_endpoint  VARCHAR(200)
);

-- =========================================
-- MÓDULO 2: USUARIOS Y ORGANIZACIÓN
-- =========================================

CREATE TABLE usuario (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keycloak_sub  VARCHAR(100) UNIQUE,
    username      VARCHAR(50) NOT NULL UNIQUE,
    correo        VARCHAR(100),
    activo        BOOLEAN DEFAULT TRUE
);

CREATE TABLE area (
    id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre  VARCHAR(100) NOT NULL,
    tipo    VARCHAR(50)
);

CREATE TABLE rol_interno (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(150),
    activo      BOOLEAN DEFAULT TRUE
);

CREATE TABLE usuario_rol_area (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id  UUID NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    rol_id      UUID NOT NULL REFERENCES rol_interno(id) ON DELETE CASCADE,
    area_id     UUID NOT NULL REFERENCES area(id) ON DELETE CASCADE
);

-- =========================================
-- MÓDULO 3: PERMISOS Y ROLES
-- =========================================

CREATE TABLE permiso (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recurso_id  UUID NOT NULL REFERENCES recurso(id) ON DELETE CASCADE,
    accion      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(150)
);

CREATE TABLE rol_permiso (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rol_id      UUID NOT NULL REFERENCES rol_interno(id) ON DELETE CASCADE,
    permiso_id  UUID NOT NULL REFERENCES permiso(id) ON DELETE CASCADE
);

-- =========================================
-- MÓDULO 4: AUDITORÍA Y SEGURIDAD
-- =========================================

CREATE TABLE auditoria_acceso (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id  UUID REFERENCES usuario(id),
    rol_id      UUID REFERENCES rol_interno(id),
    recurso_id  UUID REFERENCES recurso(id),
    permiso_id  UUID REFERENCES permiso(id),
    accion      VARCHAR(50),
    permitido   BOOLEAN,
    timestamp   TIMESTAMP DEFAULT NOW(),
    ip_origen   VARCHAR(45)
);

-- =========================================
-- MÓDULO 5: AUDITORÍA DEL SUBSISTEMA GEOOCR
-- =========================================

CREATE TABLE auditoria_geoocr (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id   UUID NOT NULL REFERENCES usuario(id),
    accion       VARCHAR(50) NOT NULL,
    descripcion  VARCHAR(255),
    timestamp    TIMESTAMP DEFAULT NOW()
);

-- =========================================
-- RELACIONES (resumen)
-- =========================================
-- subsistema.sistema_id      > sistema.id
-- recurso.subsistema_id      > subsistema.id
-- permiso.recurso_id         > recurso.id
-- rol_permiso.rol_id         > rol_interno.id
-- rol_permiso.permiso_id     > permiso.id
-- usuario_rol_area.usuario_id> usuario.id
-- usuario_rol_area.rol_id    > rol_interno.id
-- usuario_rol_area.area_id   > area.id
-- auditoria_acceso.usuario_id> usuario.id
-- auditoria_acceso.rol_id    > rol_interno.id
-- auditoria_acceso.recurso_id> recurso.id
-- auditoria_acceso.permiso_id> permiso.id
-- auditoria_geoocr.usuario_id> usuario.id
