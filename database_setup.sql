-- =========================================================================
-- Script de creación de base de datos — ERP Catastro (Alcaldía)
-- =========================================================================
-- Genera desde cero, en un servidor PostgreSQL nuevo, la base `gis_seguridad`
-- tal como existe HOY en el servidor real (172.16.66.103), reflejando fielmente
-- `ecosistema_seguridad_backup.sql` (fuente de verdad, dumpeada con
-- `pg_dump --schema-only` el 2026-08-31 por el equipo de base de datos).
--
-- Este script NO "corrige" ni reordena el esquema real (mover tablas a un
-- schema `seguridad` propio, agregar fecha_creacion/actualizacion faltantes,
-- eliminar las 4 tablas legacy `usuarios`/`roles`/`permisos`/`usuario_rol`).
-- CLAUDE.md §6 es explícito: esos cambios los decide el equipo de base de
-- datos, no el backend por su cuenta — "la base manda, el backend se adapta".
--
-- Sí agrega, al final, el patrón para que la base pueda CRECER con el resto
-- del ERP sin tocar lo existente: un schema de PostgreSQL separado por cada
-- dominio nuevo (Catastro, Documentación, ...), como pide CLAUDE.md §6. No
-- se crean tablas de negocio de Catastro acá — el catálogo de módulos todavía
-- no está definido (CLAUDE.md §10: "no inventar").
--
-- Cómo correrlo:
--   1) Como superusuario, conectado a la base `postgres` (no a `gis_seguridad`):
--        psql -h <host> -U <superusuario> -d postgres -f database_setup.sql
--      CREATE DATABASE no puede ir dentro de una transacción ni ejecutarse
--      estando conectado a la misma base que se crea — por eso ese bloque
--      queda separado y hay que correrlo primero si la base no existe todavía.
--   2) Si `gis_seguridad` YA existe en el servidor (como en 172.16.66.103),
--      saltar la sección 1 y correr el resto conectado a esa base:
--        psql -h <host> -U <usuario> -d gis_seguridad -f database_setup.sql
-- =========================================================================


-- =========================================================================
-- 1) Creación de la base de datos (correr una sola vez, conectado a `postgres`)
-- =========================================================================
-- Comentado por defecto: en el servidor real la base ya existe. Descomentar
-- solo al levantar un servidor PostgreSQL nuevo (ej. entorno local).

-- CREATE DATABASE gis_seguridad
--     WITH ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TEMPLATE = template0;

-- Conectate a la base antes de seguir (en psql):
-- \c gis_seguridad


-- =========================================================================
-- 2) Extensiones
-- =========================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


-- =========================================================================
-- 3) Esquema real de `seguridad` (schema public) — copiado tal cual de
--    ecosistema_seguridad_backup.sql. No editar acá: si el equipo de base de
--    datos cambia algo, se actualiza primero ese archivo y después este.
-- =========================================================================

SET default_tablespace = '';
SET default_table_access_method = heap;

-- ⚠️ Incluye 4 tablas legacy (usuarios, roles, permisos, usuario_rol) que NO
-- usa el ORM ni el resto del backend (ver nota completa en
-- ecosistema_seguridad_backup.sql). No se eliminan acá sin confirmación del
-- equipo de base de datos.

CREATE TABLE public.area (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    tipo character varying(50),
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.auditoria_acceso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid,
    rol_id uuid,
    recurso_id uuid,
    permiso_id uuid,
    accion character varying(50),
    permitido boolean,
    "timestamp" timestamp without time zone DEFAULT now(),
    ip_origen character varying(45),
    descripcion character varying(255)
);

CREATE TABLE public.auditoria_geoocr (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    accion character varying(50) NOT NULL,
    descripcion character varying(255),
    "timestamp" timestamp without time zone DEFAULT now()
);

CREATE TABLE public.permiso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recurso_id uuid NOT NULL,
    accion character varying(50) NOT NULL,
    descripcion character varying(150),
    fecha_creacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.permisos (
    id_permiso integer NOT NULL,
    nombre_permiso character varying(50) NOT NULL
);

CREATE SEQUENCE public.permisos_id_permiso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.permisos_id_permiso_seq OWNED BY public.permisos.id_permiso;

CREATE TABLE public.recurso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subsistema_id uuid NOT NULL,
    nombre character varying(100) NOT NULL,
    ruta_endpoint character varying(200),
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.rol_interno (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion character varying(150),
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.rol_permiso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rol_id uuid NOT NULL,
    permiso_id uuid NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.roles (
    id_rol integer NOT NULL,
    nombre_rol character varying(50) NOT NULL,
    keycloak_id character varying(100)
);

CREATE SEQUENCE public.roles_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.roles_id_rol_seq OWNED BY public.roles.id_rol;

CREATE TABLE public.sistema (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    activo boolean DEFAULT true,
    descripcion character varying(255),
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.subsistema (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sistema_id uuid NOT NULL,
    nombre character varying(100) NOT NULL,
    activo boolean DEFAULT true,
    es_opcional boolean DEFAULT false,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    keycloak_sub character varying(100),
    username character varying(50) NOT NULL,
    correo character varying(100),
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.usuario_rol (
    id_usuario integer NOT NULL,
    id_rol integer NOT NULL
);

CREATE TABLE public.usuario_rol_area (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    rol_id uuid NOT NULL,
    area_id uuid NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now()
);

CREATE TABLE public.usuarios (
    id_usuario integer NOT NULL,
    nombre character varying(50) NOT NULL
);

CREATE SEQUENCE public.usuarios_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.usuarios_id_usuario_seq OWNED BY public.usuarios.id_usuario;

CREATE VIEW public.vista_auditoria_resumen AS
 SELECT u.username AS usuario,
    aa."timestamp" AS tiempo,
    aa.accion,
    aa.descripcion,
    aa.permitido
   FROM (public.auditoria_acceso aa
     JOIN public.usuario u ON ((u.id = aa.usuario_id)))
UNION ALL
 SELECT u.username AS usuario,
    ag."timestamp" AS tiempo,
    ag.accion,
    ag.descripcion,
    true AS permitido
   FROM (public.auditoria_geoocr ag
     JOIN public.usuario u ON ((u.id = ag.usuario_id)))
  ORDER BY 2 DESC;

ALTER TABLE ONLY public.permisos ALTER COLUMN id_permiso SET DEFAULT nextval('public.permisos_id_permiso_seq'::regclass);
ALTER TABLE ONLY public.roles ALTER COLUMN id_rol SET DEFAULT nextval('public.roles_id_rol_seq'::regclass);
ALTER TABLE ONLY public.usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuarios_id_usuario_seq'::regclass);

ALTER TABLE ONLY public.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.auditoria_geoocr
    ADD CONSTRAINT auditoria_geoocr_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT permiso_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso);
ALTER TABLE ONLY public.recurso
    ADD CONSTRAINT recurso_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.rol_interno
    ADD CONSTRAINT rol_interno_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT rol_permiso_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_keycloak_id_key UNIQUE (keycloak_id);
ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_rol);
ALTER TABLE ONLY public.sistema
    ADD CONSTRAINT sistema_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.subsistema
    ADD CONSTRAINT subsistema_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_keycloak_sub_key UNIQUE (keycloak_sub);
ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_pkey PRIMARY KEY (id_usuario, id_rol);
ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);
ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);

CREATE INDEX idx_auditoria_acceso_timestamp ON public.auditoria_acceso USING btree ("timestamp");
CREATE INDEX idx_auditoria_acceso_usuario ON public.auditoria_acceso USING btree (usuario_id);
CREATE INDEX idx_auditoria_geoocr_timestamp ON public.auditoria_geoocr USING btree ("timestamp");
CREATE INDEX idx_auditoria_geoocr_usuario ON public.auditoria_geoocr USING btree (usuario_id);
CREATE INDEX idx_permiso_recurso ON public.permiso USING btree (recurso_id);
CREATE INDEX idx_rol_permiso_rol ON public.rol_permiso USING btree (rol_id);
CREATE INDEX idx_usuario_rol_area_usuario ON public.usuario_rol_area USING btree (usuario_id);
CREATE INDEX ix_permisos_id_permiso ON public.permisos USING btree (id_permiso);
CREATE UNIQUE INDEX ix_permisos_nombre_permiso ON public.permisos USING btree (nombre_permiso);
CREATE INDEX ix_roles_id_rol ON public.roles USING btree (id_rol);
CREATE UNIQUE INDEX ix_roles_nombre_rol ON public.roles USING btree (nombre_rol);
CREATE INDEX ix_usuarios_id_usuario ON public.usuarios USING btree (id_usuario);
CREATE UNIQUE INDEX ix_usuarios_nombre ON public.usuarios USING btree (nombre);

ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES public.permiso(id);
ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_recurso_id_fkey FOREIGN KEY (recurso_id) REFERENCES public.recurso(id);
ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.rol_interno(id);
ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);
ALTER TABLE ONLY public.auditoria_geoocr
    ADD CONSTRAINT auditoria_geoocr_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);
ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT permiso_recurso_id_fkey FOREIGN KEY (recurso_id) REFERENCES public.recurso(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.recurso
    ADD CONSTRAINT recurso_subsistema_id_fkey FOREIGN KEY (subsistema_id) REFERENCES public.subsistema(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT rol_permiso_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES public.permiso(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT rol_permiso_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.rol_interno(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.subsistema
    ADD CONSTRAINT subsistema_sistema_id_fkey FOREIGN KEY (sistema_id) REFERENCES public.sistema(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.area(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.rol_interno(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) ON DELETE CASCADE;
ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;


-- =========================================================================
-- 4) Patrón de extensión para los próximos dominios del ERP (CLAUDE.md §6:
--    "un schema de PostgreSQL por dominio"). Plantilla, no ejecuta nada.
-- =========================================================================
-- Cuando exista un caso de uso real que lo justifique (CLAUDE.md §10 — no
-- inventar tablas antes de tiempo), el próximo dominio de negocio (ej.
-- Catastro) sigue este patrón:
--
--   CREATE SCHEMA IF NOT EXISTS catastro;
--
--   CREATE TABLE catastro.<entidad_plural> (
--       id_<entidad> uuid DEFAULT gen_random_uuid() PRIMARY KEY,
--       -- columnas propias del caso de uso real --
--       activo boolean DEFAULT true,               -- soft delete si la tabla
--                                                    -- tiene relevancia legal
--       fecha_creacion timestamp without time zone DEFAULT now(),
--       fecha_actualizacion timestamp without time zone DEFAULT now()
--   );
--
--   CREATE INDEX ON catastro.<entidad_plural> (activo);
--   -- + un índice por cada FK de la tabla
--
-- Reglas fijas (CLAUDE.md §2 y §6), no negociables por conveniencia puntual:
--   * Nunca JOIN cross-schema hacia otro dominio (ni siquiera de solo lectura).
--   * Nunca FK desde una tabla de `catastro` hacia una tabla de otro dominio.
--     Si dos dominios necesitan compartir un dato, ese concepto sube a `core`.
--   * Cada permiso nuevo (`catastro.<recurso>.<accion>`) es una fila en
--     `public.permiso` (vía `recurso` → `subsistema` → `sistema`), enlazada a
--     los roles de `rol_interno` que correspondan en `rol_permiso` — nunca un
--     permiso chequeado solo en código sin fila en la tabla.
-- =========================================================================
