# CLAUDE.md — ERP Catastro (Alcaldía)

Reglas de arquitectura del proyecto. Todo desarrollador (humano o Claude) debe seguir esto al escribir código. Si una regla de acá y una conveniencia puntual del código chocan, gana esta guía — se discute el cambio acá primero, no se rompe la regla en silencio.

Referencia completa (con justificaciones): documento "Blueprint de arquitectura del ERP" (fases 1-10). Este archivo es el resumen operativo para el día a día.

---

## 1. Qué estamos construyendo

Un ERP municipal, con **Catastro como primer dominio de negocio**, diseñado para que se agreguen más dominios (Administración, Documentación, ...) sin tocar los existentes. Es un **monolito modular**, no microservicios, no microfrontends — decisión tomada explícitamente por el tamaño y nivel del equipo (6 devs), no por desconocimiento de las alternativas. No proponer split a microservicios sin que un dominio concreto lo justifique con evidencia real (carga, equipo dedicado, ciclo de release propio).

Stack: **Python + FastAPI + PostgreSQL** (backend, Clean Architecture, `snake_case`), **React** (frontend, arquitectura por dominio), **Keycloak** (autenticación — no autorización de negocio).

---

## 2. Regla de oro: límites entre dominios

```
ERP
 └─ Dominio        (Catastro, Seguridad, Documentación, Administración...)
     └─ Módulo      (subdominio dentro de un dominio)
         └─ Feature  (caso de uso concreto)
```

| Relación | ¿Permitido? |
|---|---|
| Dominio → `core/` (shared kernel) | Sí, siempre |
| Módulo → otro módulo del **mismo** dominio | Sí |
| Dominio A → `contracts/` de Dominio B | Sí — es el único punto de entrada permitido |
| Dominio A → `domain/`, `application/` o `infrastructure/` de Dominio B | **No, nunca** |
| Dominio A → tablas/schema de Dominio B en la base de datos | **No, nunca** — ni siquiera con JOIN cross-schema |
| Dependencia circular entre dominios (A→B→A) | **No, nunca** — si aparece, falta un concepto que debe subir a `core/` |

Si necesitás datos de otro dominio: usá su servicio público en `contracts/`, o suscribite a un evento que ese dominio publica. Nunca importes nada de sus capas internas.

Esto se hace cumplir con herramientas, no solo con disciplina:
- Backend: `import-linter` con reglas que prohíben imports cruzados entre `domains/*/domain`, `domains/*/application` e `domains/*/infrastructure`.
- Frontend: ESLint (`eslint-plugin-boundaries` o `import/no-restricted-paths`) bloqueando imports entre `domains/*` que no pasen por `contracts`/`api` públicos.

Un PR que viola esto no se aprueba, aunque "funcione".

---

## 3. Estructura de carpetas

### Backend

```
backend/app/
├── core/                    # shared kernel — lo único que todo dominio puede importar libremente
│   ├── config/
│   ├── security/            # validación de JWT de Keycloak
│   ├── database/            # engine, session, Base, repositorio base
│   ├── authorization/       # resolución de permisos internos
│   ├── events/               # bus de eventos in-process
│   ├── errors/
│   └── logging/
├── domains/
│   ├── seguridad/            # usuarios, roles internos, permisos, auditoría
│   │   ├── domain/            # entidades, puertos (interfaces) — sin FastAPI ni SQLAlchemy
│   │   ├── application/       # casos de uso, DTOs, orquestación
│   │   ├── infrastructure/    # modelos ORM, repos concretos, integración Keycloak
│   │   ├── presentation/      # routers FastAPI, schemas Pydantic
│   │   ├── contracts/         # lo único que otros dominios pueden importar de este
│   │   └── tests/
│   └── catastro/              # mismo esqueleto — y así cada dominio nuevo
├── registry.py               # único lugar que conoce todos los dominios (rutas + migraciones)
└── main.py                   # arma la app FastAPI a partir del registry
```

Responsabilidad de cada capa dentro de un dominio:

- **`domain/`** — entidades y value objects simples, interfaces de repositorio. No conoce FastAPI, SQLAlchemy, Pydantic ni HTTP.
- **`application/`** — un caso de uso = una acción de negocio. Depende de interfaces (`domain/`), nunca de implementaciones concretas.
- **`infrastructure/`** — modelos ORM, implementación real de repositorios, clientes externos. Nada de rutas ni schemas HTTP acá.
- **`presentation/`** — routers, schemas Pydantic de entrada/salida, aplica las dependencias de auth/autorización al endpoint. Solo traduce HTTP ↔ casos de uso, no contiene lógica de negocio.
- **`contracts/`** — DTOs y eventos que este dominio expone hacia afuera. Es la única puerta de entrada para otros dominios.

No se exige DDD táctico completo (Value Objects para todo, agregados estrictos, CQRS) desde el día uno. Empezar simple: entidades + casos de uso + repositorios. Subir el rigor solo si un dominio concreto lo justifica.

### Frontend

```
frontend/src/
├── app/           # bootstrap: providers, router raíz, layout, error boundary global
├── auth/          # integración Keycloak, sesión, guardas de ruta
├── core/          # cliente HTTP base, manejo de errores global, config de entorno
├── shared/        # design system genérico (Button, Table, Modal), hooks/utils sin dominio
└── domains/
    ├── seguridad/
    │   ├── pages/
    │   ├── features/       # componentes + hooks + lógica propia de cada feature
    │   ├── components/     # compartido SOLO dentro de este dominio
    │   ├── api/             # cliente de /seguridad/*
    │   ├── permissions.ts   # qué permiso requiere cada pantalla/acción
    │   └── routes.tsx       # se registra en el router raíz
    └── catastro/            # mismo esqueleto
```

Routing por **paths** dentro de un solo SPA (`erp.dominio.bo/catastro/...`), no subdominios ni microfrontends. Estado de servidor con TanStack Query; sin store global tipo Redux salvo justificación concreta.

**Estado actual (2026-08-25):** el proyecto es JS/JSX (no TypeScript — no hay `tsconfig`/dependencia de TS instalada), así que hoy los archivos son `.jsx`/`.js`, no `.tsx`/`.ts`. La autenticación (login, sesión, guardas de ruta, y las pantallas de Login/Dashboard) sigue viviendo completa en `auth/` en vez de en `domains/seguridad/` — no tiene sentido crear un `domains/seguridad/` vacío antes de que exista una pantalla de negocio real (ej. administrar roles/permisos desde el ERP) que lo justifique. El primer dominio de negocio real es **`domains/geoextraccion/`** (digitalización cartográfica: captura OCR + fusión de Shapefiles, migrado desde el proyecto standalone `geo-extract/`) — sigue el esqueleto de esta sección y es la referencia a copiar para el siguiente dominio (Catastro u otro). Ver `docs/COMO_AGREGAR_UN_DOMINIO.md` para la receta paso a paso y `Frontend/README.md` para el árbol de carpetas real.

---

## 4. Cómo agregar cosas

**Un dominio nuevo:** crear `domains/<nombre>/` con el esqueleto completo (backend y frontend), registrar sus rutas en `registry.py` / router raíz. No tocar código de otros dominios.

**Un módulo dentro de un dominio existente:** subcarpeta dentro de `application/`, `presentation/`, `features/`, etc. de ese dominio. No necesita su propio schema de base de datos salvo que la tabla lo amerite.

**Un permiso nuevo:** agregarlo al catálogo de `seguridad.permisos` con el formato `dominio.recurso.accion` (ej. `catastro.videos.subir`). Asociarlo a los roles internos que correspondan en `rol_permiso`. Nunca crear un permiso implícito solo chequeado en código sin fila en la tabla.

**Un rol interno nuevo:** fila en `seguridad.roles`. Es independiente de los roles de Keycloak — no se crea un rol interno "para reflejar" un rol de Keycloak.

**Eliminar un dominio:** borrar su carpeta en backend y frontend, quitar su línea de `registry.py` y del router raíz, dropear su schema de PostgreSQL si aplica. Si otro dominio se rompe al hacer esto, es porque violó la Sección 2 — corregir ahí, no revertir el borrado.

---

## 5. Autenticación y autorización

**Keycloak autentica. El ERP autoriza.** Esta separación no se negocia:

- Keycloak: identidad, credenciales, sesión SSO, emisión de JWT, rol global grueso opcional (informativo).
- Backend (Postgres, schema `seguridad`): TODOS los permisos finos — por módulo, recurso y acción. Modelo RBAC con `alcance` opcional para casos con contexto (no ABAC completo salvo necesidad real y demostrada).

Flujo: frontend redirige a Keycloak (Authorization Code + PKCE) → backend valida el JWT en cada request (firma, `exp`, `aud`, `iss` vía JWKS) → resuelve `usuarios.keycloak_id = JWT.sub` (crea el usuario en el primer login, sin roles por defecto) → resuelve permisos internos → autoriza o rechaza.

**Nunca** tomar una decisión de autorización de negocio a partir del rol de Keycloak directamente. El rol de Keycloak no es un permiso.

### 🚨 Pendiente crítico de seguridad

El client de Keycloak está actualmente registrado en el **realm `master`**. Ese realm es exclusivamente para administrar el propio Keycloak — nunca para autenticar usuarios de una aplicación de negocio. Antes de ir a producción (y preferentemente antes de seguir desarrollando), hay que pedir al equipo que administra Keycloak un realm dedicado (ej. `alcaldia-erp`) y mover el client ahí. No usar `master` en ningún ambiente, ni siquiera desarrollo.

---

## 6. Base de datos

- **Un schema de PostgreSQL por dominio** (`seguridad`, `catastro`, `auditoria`, ...), no todo en `public`.
- `snake_case`, tablas en plural, PK `id_<entidad>`, FK con el mismo nombre que la PK referenciada.
- Toda tabla de negocio lleva `fecha_creacion` y `fecha_actualizacion`. Tablas con relevancia legal (predios, usuarios) usan soft delete (`activo` o `fecha_eliminacion`), no `DELETE` físico.
- `seguridad.usuarios` requiere `keycloak_id` (UNIQUE, NOT NULL) — es lo que conecta el JWT con el usuario interno. No reducir esta tabla a solo nombre/login.
- `seguridad.roles` **no** lleva `keycloak_id` — los roles internos son un concepto separado de los roles de Keycloak (ver Sección 5).
- Migraciones con Alembic, prefijadas por dominio. Seed data en scripts idempotentes, separados de las migraciones estructurales.
- Índices en toda FK y en columnas de filtro frecuente (`activo`, `keycloak_id`, etc.).

---

## 7. Comunicación entre módulos/dominios

1. Nunca acceso directo a tablas de otro dominio.
2. Nunca import de capas internas de otro dominio — solo de su `contracts/`.
3. Para notificar algo sin esperar respuesta, usar el bus de eventos in-process (`core/events`), no una llamada directa. Ej.: Catastro emite `PredioCreado`; Documentación se suscribe sin que Catastro sepa que existe.
4. Para pedir datos con respuesta inmediata, usar el servicio de aplicación público del dominio dueño (en su `contracts/`).

---

## 8. Convenciones rápidas

| Elemento | Convención |
|---|---|
| Backend (archivos, funciones, variables, tablas, columnas) | `snake_case` |
| Clases Python | `PascalCase` |
| Endpoints | `/api/<dominio>/<recurso>` en plural, snake_case |
| Permisos | `dominio.recurso.accion` (ej. `catastro.videos.editar`) |
| Componentes React | `PascalCase`, un componente por archivo |
| Hooks React | `useAlgo` |
| Carpetas de dominio (backend y frontend) | idénticas en nombre a ambos lados |

---

## 9. Checklist de revisión de PR (arquitectura)

- [ ] ¿El código nuevo importa algo de `domain/`, `application/` o `infrastructure/` de otro dominio? → rechazar.
- [ ] ¿Hay una query o JOIN que toca el schema de otro dominio? → rechazar.
- [ ] ¿Se agregó un permiso nuevo sin fila en `seguridad.permisos`? → rechazar.
- [ ] ¿Se tomó una decisión de autorización a partir del rol de Keycloak directamente, sin pasar por el modelo interno? → rechazar.
- [ ] ¿La tabla nueva tiene `fecha_creacion`/`fecha_actualizacion` y, si corresponde, soft delete? → si no, corregir antes de aprobar.
- [ ] ¿Una acción de escritura de negocio no queda registrada en `auditoria.evento_auditoria`? → corregir antes de aprobar.

---

## 10. Lo que todavía no está definido (no inventar)

- Lista real de módulos de negocio de Catastro (más allá de los ejemplos ilustrativos: Inmuebles, Propietarios, Avalúos, Inspecciones).
- Catálogo completo de acciones por módulo.
- Naturaleza exacta de la integración posterior con Active Directory / el ERP de otro equipo.
- Entorno de despliegue final (on-premise vs. cloud).

Cuando el código toque algo de esta lista, confirmar con negocio/arquitectura antes de asumir — no completar el vacío con una suposición.
