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

ALTER TABLE auditoria_acceso ADD COLUMN descripcion VARCHAR(255);

CREATE INDEX idx_auditoria_acceso_usuario ON auditoria_acceso(usuario_id);
CREATE INDEX idx_auditoria_acceso_timestamp ON auditoria_acceso(timestamp);
CREATE INDEX idx_auditoria_geoocr_usuario ON auditoria_geoocr(usuario_id);
CREATE INDEX idx_auditoria_geoocr_timestamp ON auditoria_geoocr(timestamp);
CREATE INDEX idx_usuario_rol_area_usuario ON usuario_rol_area(usuario_id);
CREATE INDEX idx_rol_permiso_rol ON rol_permiso(rol_id);
CREATE INDEX idx_permiso_recurso ON permiso(recurso_id);
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
-- =========================================
-- 1. SISTEMA
-- =========================================
INSERT INTO sistema (id, nombre, activo, descripcion)
VALUES (gen_random_uuid(), 'ERP GAMC', true, 'Sistema municipal IDEC');

-- =========================================
-- 2. SUBSISTEMA (módulos del ERP)
-- =========================================
INSERT INTO subsistema (id, sistema_id, nombre, activo, es_opcional)
SELECT gen_random_uuid(), s.id, m.nombre, true, false
FROM sistema s
CROSS JOIN (VALUES ('geoextraccion'), ('seguridad')) AS m(nombre)
WHERE s.nombre = 'ERP GAMC';

-- =========================================
-- 3. RECURSO (1 por módulo, por ahora)
-- =========================================
INSERT INTO recurso (id, subsistema_id, nombre, ruta_endpoint)
SELECT gen_random_uuid(), sub.id, sub.nombre, '/api/' || sub.nombre
FROM subsistema sub;

-- =========================================
-- 4. PERMISO (ver / editar por recurso)
-- =========================================
INSERT INTO permiso (id, recurso_id, accion, descripcion)
SELECT gen_random_uuid(), r.id, a.accion, r.nombre || '.' || a.accion
FROM recurso r
CROSS JOIN (VALUES ('ver'), ('editar')) AS a(accion);

-- =========================================
-- 5. ROL_INTERNO
-- =========================================
INSERT INTO rol_interno (id, nombre, descripcion, activo)
VALUES
    (gen_random_uuid(), 'Administrador', 'Control total del ERP', true),
    (gen_random_uuid(), 'Operador OCR', 'Acceso a Geo-Extract', true),
    (gen_random_uuid(), 'Solo lectura', 'Solo consulta', true);

-- =========================================
-- 6. ROL_PERMISO
-- Administrador: todos los permisos
-- Operador OCR: solo ver+editar geoextraccion
-- Solo lectura: solo ver en ambos módulos
-- =========================================

-- Administrador -> todo
INSERT INTO rol_permiso (id, rol_id, permiso_id)
SELECT gen_random_uuid(), ri.id, p.id
FROM rol_interno ri
CROSS JOIN permiso p
WHERE ri.nombre = 'Administrador';

-- Operador OCR -> geoextraccion.ver + geoextraccion.editar
INSERT INTO rol_permiso (id, rol_id, permiso_id)
SELECT gen_random_uuid(), ri.id, p.id
FROM rol_interno ri
JOIN permiso p ON true
JOIN recurso r ON r.id = p.recurso_id
WHERE ri.nombre = 'Operador OCR'
  AND r.nombre = 'geoextraccion';

-- Solo lectura -> solo acción 'ver' en ambos módulos
INSERT INTO rol_permiso (id, rol_id, permiso_id)
SELECT gen_random_uuid(), ri.id, p.id
FROM rol_interno ri
JOIN permiso p ON p.accion = 'ver'
WHERE ri.nombre = 'Solo lectura';

-- =========================================
-- 7. AREA
-- =========================================
INSERT INTO area (id, nombre, tipo)
VALUES
    (gen_random_uuid(), 'Sistemas', 'interna'),
    (gen_random_uuid(), 'Catastro', 'operativa'),
    (gen_random_uuid(), 'Administración', 'interna');

-- =========================================
-- 8. USUARIO (usuarios demo de la Imagen 5)
-- =========================================
INSERT INTO usuario (id, keycloak_sub, username, correo, activo)
VALUES
    (gen_random_uuid(), 'kc-sub-demo1', 'usuario.demo1', 'demo1@gamc.gob.bo', true),
    (gen_random_uuid(), 'kc-sub-demo2', 'usuario.demo2', 'demo2@gamc.gob.bo', true),
    (gen_random_uuid(), 'kc-sub-demo3', 'usuario.demo3', 'demo3@gamc.gob.bo', true);

-- =========================================
-- 9. USUARIO_ROL_AREA
-- demo1 -> Administrador / Sistemas
-- demo2 -> Operador OCR / Catastro
-- demo3 -> sin asignar (queda sin fila, como marca CLAUDE.md)
-- =========================================
INSERT INTO usuario_rol_area (id, usuario_id, rol_id, area_id)
SELECT gen_random_uuid(), u.id, ri.id, a.id
FROM usuario u, rol_interno ri, area a
WHERE u.username = 'usuario.demo1' AND ri.nombre = 'Administrador' AND a.nombre = 'Sistemas';

INSERT INTO usuario_rol_area (id, usuario_id, rol_id, area_id)
SELECT gen_random_uuid(), u.id, ri.id, a.id
FROM usuario u, rol_interno ri, area a
WHERE u.username = 'usuario.demo2' AND ri.nombre = 'Operador OCR' AND a.nombre = 'Catastro';

-- demo3 se deja sin fila -> aparece "Sin rol / Sin área" en el frontend

-- =========================================
-- 10. AUDITORIA_ACCESO (ejemplo de una acción real)
-- =========================================
INSERT INTO auditoria_acceso (id, usuario_id, rol_id, recurso_id, permiso_id, accion, permitido, ip_origen)
SELECT gen_random_uuid(), u.id, ri.id, r.id, p.id, 'editar_permisos_rol', true, '192.168.1.10'
FROM usuario u, rol_interno ri, recurso r, permiso p
WHERE u.username = 'usuario.demo1'
  AND ri.nombre = 'Administrador'
  AND r.nombre = 'seguridad'
  AND p.accion = 'editar' AND p.recurso_id = r.id;
SELECT u.username, u.correo, ri.nombre AS rol, a.nombre AS area
FROM usuario u
LEFT JOIN usuario_rol_area ura ON ura.usuario_id = u.id
LEFT JOIN rol_interno ri ON ri.id = ura.rol_id
LEFT JOIN area a ON a.id = ura.area_id;

CREATE VIEW vista_auditoria_resumen AS
SELECT
    u.username           AS usuario,
    aa.timestamp          AS tiempo,
    aa.accion             AS accion,
    aa.descripcion        AS descripcion,
    aa.permitido          AS permitido
FROM auditoria_acceso aa
JOIN usuario u ON u.id = aa.usuario_id

UNION ALL

SELECT
    u.username           AS usuario,
    ag.timestamp          AS tiempo,
    ag.accion             AS accion,
    ag.descripcion        AS descripcion,
    true                  AS permitido   -- auditoria_geoocr no guarda "permitido", se asume true si quedó registrada
FROM auditoria_geoocr ag
JOIN usuario u ON u.id = ag.usuario_id

ORDER BY tiempo DESC;

SELECT * FROM vista_auditoria_resumen
LIMIT 50;

SELECT * FROM vista_auditoria_resumen
WHERE usuario = 'usuario.demo1';

INSERT INTO auditoria_geoocr (id, usuario_id, accion, descripcion)
SELECT gen_random_uuid(), u.id, 'generar_shapefile', 'El usuario generó un shapefile fusionado de 3 capas catastrales'
FROM usuario u
WHERE u.username = 'usuario.demo2';

ALTER TABLE sistema             ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();
ALTER TABLE sistema             ADD COLUMN fecha_actualizacion TIMESTAMP DEFAULT NOW();

ALTER TABLE subsistema          ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();
ALTER TABLE subsistema          ADD COLUMN fecha_actualizacion TIMESTAMP DEFAULT NOW();

ALTER TABLE recurso             ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();
ALTER TABLE recurso             ADD COLUMN fecha_actualizacion TIMESTAMP DEFAULT NOW();

ALTER TABLE usuario             ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();
ALTER TABLE usuario             ADD COLUMN fecha_actualizacion TIMESTAMP DEFAULT NOW();

ALTER TABLE area                ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();
ALTER TABLE area                ADD COLUMN fecha_actualizacion TIMESTAMP DEFAULT NOW();

ALTER TABLE rol_interno         ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();
ALTER TABLE rol_interno         ADD COLUMN fecha_actualizacion TIMESTAMP DEFAULT NOW();

ALTER TABLE usuario_rol_area    ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();

ALTER TABLE permiso             ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();

ALTER TABLE rol_permiso         ADD COLUMN fecha_creacion TIMESTAMP DEFAULT NOW();

CREATE INDEX idx_auditoria_acceso_usuario ON auditoria_acceso(usuario_id);
CREATE INDEX idx_auditoria_acceso_timestamp ON auditoria_acceso(timestamp);
CREATE INDEX idx_auditoria_geoocr_usuario ON auditoria_geoocr(usuario_id);
CREATE INDEX idx_auditoria_geoocr_timestamp ON auditoria_geoocr(timestamp);
CREATE INDEX idx_usuario_rol_area_usuario ON usuario_rol_area(usuario_id);
CREATE INDEX idx_rol_permiso_rol ON rol_permiso(rol_id);
CREATE INDEX idx_permiso_recurso ON permiso(recurso_id);

SELECT indexname FROM pg_indexes WHERE schemaname = 'public' AND indexname LIKE 'idx_%';

SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public' AND indexname LIKE 'idx_%';

SELECT table_name, column_name 
FROM information_schema.columns 
WHERE column_name IN ('fecha_creacion', 'fecha_actualizacion')
ORDER BY table_name, column_name;