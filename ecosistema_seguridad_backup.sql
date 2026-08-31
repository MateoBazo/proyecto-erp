-- =========================================
-- Regenerado el 2026-08-31 con `pg_dump --schema-only` directo contra la base
-- compartida real (172.16.66.103 / gis_seguridad) — reemplaza la versión anterior
-- de este archivo, que había quedado desactualizada (rol_permiso tenía id_rol/
-- id_permiso como integer sin PK propia; ninguna tabla tenía fecha_creacion/
-- fecha_actualizacion; auditoria_acceso no tenía descripcion). El equipo de BD
-- corrió la migración que corrige eso (ver seguridad_migracion_2026-08-31_
-- rol_permiso_y_fechas.sql en la raíz del repo) y esto ya refleja el resultado.
--
-- ⚠️ IMPORTANTE — descubierto en este mismo dump: existen 4 tablas legacy que
-- NO son parte del esquema que usa el ORM (backend/app/domains/seguridad/
-- infrastructure/models.py) ni el resto de esta app: `usuarios`, `roles`,
-- `permisos`, `usuario_rol` (en plural/distinto de `usuario`, `rol_interno`,
-- `permiso`, `usuario_rol_area`). Usan PK integer con secuencias, en vez de
-- uuid — son de una iteración anterior del esquema. Nada en el backend las
-- referencia y están casi vacías (usuarios: 1 fila; roles/permisos/
-- usuario_rol: 0 filas) al momento de este dump. No se tocaron — confirmar
-- con el equipo de base de datos si conviene eliminarlas (CLAUDE.md: los
-- cambios de esquema los decide el equipo de BD, no se asume acá).
-- =========================================
--
-- PostgreSQL database dump
--

\restrict hInJDfZn8LydRuiisoGkRWQee1TP1FAqLvHpRydcgwY9ireTJiWm2BPgTRwKdvz

-- Dumped from database version 14.3 (Ubuntu 14.3-1.pgdg18.04+1)
-- Dumped by pg_dump version 17.11 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: area; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.area (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    tipo character varying(50),
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);


--
-- Name: auditoria_acceso; Type: TABLE; Schema: public; Owner: -
--

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


--
-- Name: auditoria_geoocr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditoria_geoocr (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    accion character varying(50) NOT NULL,
    descripcion character varying(255),
    "timestamp" timestamp without time zone DEFAULT now()
);


--
-- Name: permiso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permiso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recurso_id uuid NOT NULL,
    accion character varying(50) NOT NULL,
    descripcion character varying(150),
    fecha_creacion timestamp without time zone DEFAULT now()
);


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permisos (
    id_permiso integer NOT NULL,
    nombre_permiso character varying(50) NOT NULL
);


--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permisos_id_permiso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permisos_id_permiso_seq OWNED BY public.permisos.id_permiso;


--
-- Name: recurso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subsistema_id uuid NOT NULL,
    nombre character varying(100) NOT NULL,
    ruta_endpoint character varying(200),
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);


--
-- Name: rol_interno; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rol_interno (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion character varying(150),
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);


--
-- Name: rol_permiso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rol_permiso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rol_id uuid NOT NULL,
    permiso_id uuid NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now()
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id_rol integer NOT NULL,
    nombre_rol character varying(50) NOT NULL,
    keycloak_id character varying(100)
);


--
-- Name: roles_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_rol_seq OWNED BY public.roles.id_rol;


--
-- Name: sistema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sistema (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    activo boolean DEFAULT true,
    descripcion character varying(255),
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);


--
-- Name: subsistema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subsistema (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sistema_id uuid NOT NULL,
    nombre character varying(100) NOT NULL,
    activo boolean DEFAULT true,
    es_opcional boolean DEFAULT false,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    keycloak_sub character varying(100),
    username character varying(50) NOT NULL,
    correo character varying(100),
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone DEFAULT now()
);


--
-- Name: usuario_rol; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario_rol (
    id_usuario integer NOT NULL,
    id_rol integer NOT NULL
);


--
-- Name: usuario_rol_area; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario_rol_area (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    rol_id uuid NOT NULL,
    area_id uuid NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now()
);


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id_usuario integer NOT NULL,
    nombre character varying(50) NOT NULL
);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_id_usuario_seq OWNED BY public.usuarios.id_usuario;


--
-- Name: vista_auditoria_resumen; Type: VIEW; Schema: public; Owner: -
--

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


--
-- Name: permisos id_permiso; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos ALTER COLUMN id_permiso SET DEFAULT nextval('public.permisos_id_permiso_seq'::regclass);


--
-- Name: roles id_rol; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id_rol SET DEFAULT nextval('public.roles_id_rol_seq'::regclass);


--
-- Name: usuarios id_usuario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuarios_id_usuario_seq'::regclass);


--
-- Name: area area_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (id);


--
-- Name: auditoria_acceso auditoria_acceso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_pkey PRIMARY KEY (id);


--
-- Name: auditoria_geoocr auditoria_geoocr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria_geoocr
    ADD CONSTRAINT auditoria_geoocr_pkey PRIMARY KEY (id);


--
-- Name: permiso permiso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT permiso_pkey PRIMARY KEY (id);


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso);


--
-- Name: recurso recurso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurso
    ADD CONSTRAINT recurso_pkey PRIMARY KEY (id);


--
-- Name: rol_interno rol_interno_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_interno
    ADD CONSTRAINT rol_interno_pkey PRIMARY KEY (id);


--
-- Name: rol_permiso rol_permiso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT rol_permiso_pkey PRIMARY KEY (id);


--
-- Name: roles roles_keycloak_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_keycloak_id_key UNIQUE (keycloak_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_rol);


--
-- Name: sistema sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sistema
    ADD CONSTRAINT sistema_pkey PRIMARY KEY (id);


--
-- Name: subsistema subsistema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subsistema
    ADD CONSTRAINT subsistema_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_keycloak_sub_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_keycloak_sub_key UNIQUE (keycloak_sub);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: usuario_rol_area usuario_rol_area_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_pkey PRIMARY KEY (id);


--
-- Name: usuario_rol usuario_rol_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_pkey PRIMARY KEY (id_usuario, id_rol);


--
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: idx_auditoria_acceso_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_acceso_timestamp ON public.auditoria_acceso USING btree ("timestamp");


--
-- Name: idx_auditoria_acceso_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_acceso_usuario ON public.auditoria_acceso USING btree (usuario_id);


--
-- Name: idx_auditoria_geoocr_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_geoocr_timestamp ON public.auditoria_geoocr USING btree ("timestamp");


--
-- Name: idx_auditoria_geoocr_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_geoocr_usuario ON public.auditoria_geoocr USING btree (usuario_id);


--
-- Name: idx_permiso_recurso; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permiso_recurso ON public.permiso USING btree (recurso_id);


--
-- Name: idx_rol_permiso_rol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rol_permiso_rol ON public.rol_permiso USING btree (rol_id);


--
-- Name: idx_usuario_rol_area_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuario_rol_area_usuario ON public.usuario_rol_area USING btree (usuario_id);


--
-- Name: ix_permisos_id_permiso; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_permisos_id_permiso ON public.permisos USING btree (id_permiso);


--
-- Name: ix_permisos_nombre_permiso; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_permisos_nombre_permiso ON public.permisos USING btree (nombre_permiso);


--
-- Name: ix_roles_id_rol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_roles_id_rol ON public.roles USING btree (id_rol);


--
-- Name: ix_roles_nombre_rol; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_roles_nombre_rol ON public.roles USING btree (nombre_rol);


--
-- Name: ix_usuarios_id_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usuarios_id_usuario ON public.usuarios USING btree (id_usuario);


--
-- Name: ix_usuarios_nombre; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_usuarios_nombre ON public.usuarios USING btree (nombre);


--
-- Name: auditoria_acceso auditoria_acceso_permiso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES public.permiso(id);


--
-- Name: auditoria_acceso auditoria_acceso_recurso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_recurso_id_fkey FOREIGN KEY (recurso_id) REFERENCES public.recurso(id);


--
-- Name: auditoria_acceso auditoria_acceso_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.rol_interno(id);


--
-- Name: auditoria_acceso auditoria_acceso_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria_acceso
    ADD CONSTRAINT auditoria_acceso_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: auditoria_geoocr auditoria_geoocr_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria_geoocr
    ADD CONSTRAINT auditoria_geoocr_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: permiso permiso_recurso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT permiso_recurso_id_fkey FOREIGN KEY (recurso_id) REFERENCES public.recurso(id) ON DELETE CASCADE;


--
-- Name: recurso recurso_subsistema_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurso
    ADD CONSTRAINT recurso_subsistema_id_fkey FOREIGN KEY (subsistema_id) REFERENCES public.subsistema(id) ON DELETE CASCADE;


--
-- Name: rol_permiso rol_permiso_permiso_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT rol_permiso_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES public.permiso(id) ON DELETE CASCADE;


--
-- Name: rol_permiso rol_permiso_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT rol_permiso_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.rol_interno(id) ON DELETE CASCADE;


--
-- Name: subsistema subsistema_sistema_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subsistema
    ADD CONSTRAINT subsistema_sistema_id_fkey FOREIGN KEY (sistema_id) REFERENCES public.sistema(id) ON DELETE CASCADE;


--
-- Name: usuario_rol_area usuario_rol_area_area_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.area(id) ON DELETE CASCADE;


--
-- Name: usuario_rol_area usuario_rol_area_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.rol_interno(id) ON DELETE CASCADE;


--
-- Name: usuario_rol_area usuario_rol_area_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol_area
    ADD CONSTRAINT usuario_rol_area_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;


--
-- Name: usuario_rol usuario_rol_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) ON DELETE CASCADE;


--
-- Name: usuario_rol usuario_rol_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict hInJDfZn8LydRuiisoGkRWQee1TP1FAqLvHpRydcgwY9ireTJiWm2BPgTRwKdvz
