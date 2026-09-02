CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';
SET default_table_access_method = heap;

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
    