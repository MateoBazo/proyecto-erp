# Arquitectura ERP Catastro Municipal

> Documento de referencia arquitectónica. Vive en la raíz del repo como contexto persistente del proyecto. Toda decisión de estructura, módulos, permisos o base de datos debe alinearse con este documento; si una decisión real del código diverge, o se actualiza este documento, o se corrige el código — no deben quedar dos verdades.

**Estado (2026-08-25):** Diseño ya implementado en el árbol de carpetas (backend y frontend). Sin SQL definitivo ni negocio de Catastro todavía — ver plan de implementación §13. El paso 6 de §13 ("formalizar el patrón de módulo con un caso mínimo") ya se completó con el dominio `geoextraccion` (digitalización cartográfica, migrado desde el proyecto standalone `geo-extract/`) — sin base de datos propia, protegido por Keycloak igual que el resto del ERP. La receta paso 7 ("documentar el patrón como plantilla") vive en `docs/COMO_AGREGAR_UN_DOMINIO.md`.

**Nota de nomenclatura:** `CLAUDE.md` (resumen operativo, raíz del repo) es la referencia autoritativa del día a día y usa nombres ligeramente distintos a los de este documento: `domains/` en vez de `modules/`, `seguridad` en vez de `identidad`, `contracts/` en vez de `ports/` para lo que un dominio expone hacia afuera. El código sigue la nomenclatura de `CLAUDE.md`. Este documento conserva los nombres originales por fidelidad histórica de la decisión, pero donde haya conflicto, `CLAUDE.md` gana.

**Insumos usados para este diseño** (respuestas del equipo, no supuestos):
- Infraestructura de despliegue: aún no decidida → se diseña para el escenario más conservador (Docker Compose / VPS único), dejando costuras claras para migrar a Kubernetes si algún día se justifica.
- Equipo: 6 desarrolladores junior, sin DevOps dedicado.
- Alcance real de corto/mediano plazo: **Catastro** (en curso) + **Identidad/Administración** (ya existe como base técnica: Keycloak + tablas RBAC). Otros dominios (Trámites, Finanzas, etc.) son visión de largo plazo, **sin fecha comprometida**.
- Mono-tenant: el sistema es para esta Alcaldía únicamente, no se diseña multi-municipio.

Estas cuatro respuestas son las que más pesan en las decisiones de abajo: equipo junior + infraestructura no confirmada + solo 2 dominios reales hoy son un caso de libro para **monolito modular**, no microservicios — pero como la visión declarada *es* multi-área a futuro, el monolito se diseña con fronteras de módulo estrictas desde el día uno, para que extraer un dominio como servicio independiente el día que se justifique sea un *refactor*, no una reescritura.

---

## 1. Análisis de requisitos

### Funcionales conocidos
- Autenticación centralizada vía Keycloak (OIDC), ya funcional.
- ERP con múltiples dominios de negocio, empezando por Catastro (inmuebles, propietarios, avalúos, inspecciones — ejemplo ilustrativo, a confirmar con el área de Catastro antes de modelar tablas).
- Dominio de Identidad/Administración (usuarios, roles, permisos) ya parcialmente construido (tablas `usuarios`, `roles`, `permisos` con relación muchos-a-muchos).
- Permisos que **no** se resuelven solo con el rol global de Keycloak: dos usuarios "EDITOR" pueden tener capacidades distintas dentro de un mismo módulo (ej. video: uno sube/edita/elimina, otro solo ve/edita).

### No funcionales
- Aislamiento de fallos: la caída o eliminación de un módulo no debe tumbar el resto del ERP.
- Mantenibilidad y testabilidad altas, pensadas para un equipo junior (convenciones claras, bajo acoplamiento, curva de aprendizaje reproducible).
- Auditoría de acciones sensibles (login, cambios de permisos, altas/bajas, acciones administrativas).
- Escalabilidad progresiva: el diseño debe soportar crecer en módulos y datos sin reescritura, pero **sin pagar hoy el costo operativo de una arquitectura distribuida** que el equipo no puede sostener todavía.

### Restricciones
- Backend: Python + FastAPI + PostgreSQL + Clean Architecture + `snake_case`.
- Frontend: React, modular por dominio, con la puerta abierta (no la obligación) a microfrontends en el futuro.
- Keycloak ya está integrado y el flujo de login **funciona** — no se rediseña, salvo un problema puntual real (ver §9.1).
- Equipo de 6 juniors: cualquier patrón que exija disciplina operativa alta (colas de eventos distribuidas, múltiples bases de datos, orquestación de contenedores) es un riesgo de proyecto, no solo una decisión técnica.

### Supuestos declarados (a validar con negocio, no asumidos como definitivos)
- Los módulos de ejemplo de Catastro (Inmuebles, Propietarios, Avalúos, Inspecciones) son ilustrativos; el modelo de datos real de Catastro se define en una siguiente fase con el área usuaria.
- El dominio de Identidad/Administración es compartido por todo el ERP, no exclusivo de Catastro — se trata como **shared kernel**, no como un módulo de negocio más (ver §3).
- No hay requisito confirmado de multi-idioma, multi-moneda ni integración con sistemas externos (SIGEP, SIN, etc.) — si existen, cambian el diseño de integraciones y deben añadirse como requisito explícito antes de construirlas.

### Riesgos detectados en el estado actual del código
1. **Keycloak mal configurado para el caso de uso**: el backend usa `KEYCLOAK_REALM=master` y `KEYCLOAK_CLIENT_ID=admin-cli`. `admin-cli` es el cliente interno de administración de Keycloak y `master` es el realm de administración del propio servidor de Keycloak — no un realm de aplicación. Autenticar usuarios de negocio contra ese realm/cliente es un riesgo de seguridad serio (mezcla identidades administrativas de Keycloak con usuarios del ERP) y debe corregirse **antes** de construir el modelo de permisos (ver §9.1). Esto no es "rediseñar el login que ya funciona": es corregir una configuración, el flujo OIDC se mantiene igual.
2. El modelo RBAC actual (`usuarios`–`roles`–`permisos`, plano) no soporta permisos por módulo/recurso/acción ni excepciones por usuario — es de esperar, es el punto de partida, no un defecto; se evoluciona en §6–§7.
3. No hay herramienta de migraciones (Alembic o similar): las tablas se crean con `init_db_tables()` al arrancar. Aceptable en el prototipo actual, no aceptable para un ERP en producción con múltiples módulos evolucionando en paralelo — se resuelve en el plan de implementación (§10).

---

## 2. Decisión arquitectónica

### Backend: Monolito Modular (no microservicios, no "microservicios desde ya")

**Recomendación: Monolito Modular con fronteras de módulo estrictas, preparado para extraer servicios en el futuro si se justifica.**

| Opción | Por qué se descarta / se elige |
|---|---|
| Microservicios desde el inicio | Requiere infraestructura (orquestación, red entre servicios, observabilidad distribuida, gestión de fallos parciales) que el equipo no tiene y la infraestructura de despliegue **ni siquiera está decidida**. Con 6 juniors, el costo operativo de mantener N servicios vivos supera por lejos el beneficio de aislamiento, que se puede lograr igual dentro de un monolito bien modularizado. |
| Monolito "tradicional" (sin fronteras internas) | Es lo que garantiza el acoplamiento circular que el requisito no negociable prohíbe explícitamente. Se descarta. |
| **Monolito Modular** | Un solo proceso/despliegue, pero cada dominio vive en su propio subárbol de código con Clean Architecture propia, se comunica con otros dominios solo a través de contratos explícitos (puertos), y puede desactivarse o fallar sin tumbar el resto. Es el punto óptimo para el tamaño de equipo, la madurez de infraestructura y el hecho de que hoy solo hay 2 dominios reales. |
| Monolito modular → microservicios (evolutivo) | Es la misma opción de arriba, con la disciplina puesta desde el día uno para que el día que un módulo (ej. Catastro, si crece mucho en carga/equipo dedicado) necesite ser un servicio aparte, la extracción sea mecánica: mover una carpeta, exponer su puerto como API HTTP, cambiar la implementación del adaptador que lo llama. Esto es la meta explícita de este documento. |

### Frontend: Frontend modular por dominio (no microfrontends todavía)

| Opción | Por qué se descarta / se elige |
|---|---|
| Microfrontends (Module Federation, single-spa, etc.) | Añade complejidad de build, versionado y despliegue independiente que no se justifica con 6 juniors y un solo equipo trabajando sobre el mismo repo/release. Tiene sentido solo si un módulo necesita ciclo de release independiente, stack distinto, o equipo dedicado separado — ninguna de esas condiciones existe hoy. |
| Carpetas planas (`components/`, `pages/`, `services/` mezclados) | Es el problema explícito que el equipo quiere evitar; ya se ve en el repo actual el costo de esto (había componentes de login y dashboard mezclados sin fronteras). Se descarta. |
| **Frontend modular por dominio (feature-based)** | Una sola SPA React, pero organizada en `src/modules/<dominio>/` con sus propias páginas, componentes, hooks y servicios, más un `src/shared/` para lo transversal (auth, UI kit, http client). Cada módulo puede eliminarse quitando su carpeta y su entrada de rutas, sin tocar el resto. Es el equivalente frontend de la extracción mecánica que se busca en el backend, y dejaría abierta (no obligatoria) una futura migración a microfrontends si algún módulo lo justifica. |

### Routing y despliegue: un solo dominio, un solo frontend, path-based

`erp.gob.bo/catastro/...`, `erp.gob.bo/administracion/...` en una sola app — no subdominios por módulo, no apps separadas. Con mono-tenant y un solo equipo, subdominios o apps separadas solo agregan complejidad de CORS, sesión compartida y despliegue sin ningún beneficio real hoy. Se revisita si algún módulo necesita aislamiento fuerte de dominio (ej. un portal público ciudadano separado del ERP interno — ahí sí se justificaría una app aparte, porque la audiencia y el modelo de auth son distintos).

---

## 3. Arquitectura de dominios

```
ERP Municipal
 └─ Dominios (Bounded Contexts)
     ├─ Identidad y Acceso   (shared kernel — todos dependen de él, él no depende de nadie)
     ├─ Catastro             (dominio de negocio #1, en curso)
     ├─ Auditoría            (shared kernel técnico — todos pueden emitirle eventos, él no depende de nadie)
     └─ [futuros: Trámites, Finanzas, ... — mismo patrón, sin fecha comprometida]
         └─ Módulos           (ej. dentro de Catastro: Inmuebles, Propietarios, Avalúos, Inspecciones — a confirmar con negocio)
             └─ Features       (casos de uso concretos dentro de un módulo)
```

### Por qué Identidad y Auditoría son "shared kernel" y no "un módulo más"

El requisito no negociable dice "ningún módulo de negocio depende de otro". Identidad (autenticación/autorización) y Auditoría **no son negocio**, son infraestructura transversal que *todo* módulo de negocio necesita para funcionar con seguridad. Tratarlos como shared kernel con una regla de dependencia unidireccional explícita:

- **Permitido:** Catastro → Identidad, Catastro → Auditoría, cualquier dominio futuro → Identidad/Auditoría.
- **Prohibido:** Identidad → Catastro, Auditoría → Catastro, o cualquier dependencia entre dos dominios de negocio (Catastro → Trámites, Trámites → Catastro, etc.).
- Identidad y Auditoría se exponen a los demás módulos **solo** a través de puertos (interfaces) definidos en `app/shared/`, nunca importando sus modelos ORM o casos de uso internos directamente.

Esto es lo que en DDD se llama *shared kernel* + *anticorruption layer* liviano: se acepta un acoplamiento controlado y unidireccional hacia la infraestructura común, a cambio de cero acoplamiento entre dominios de negocio.

### Fronteras entre dominios de negocio

Entre dos dominios de negocio (ej. el día que exista Catastro y Trámites), la regla es:

- **Nunca** importar código (entidades, modelos ORM, casos de uso) de otro dominio de negocio directamente.
- Si un dominio necesita datos de otro (ej. Trámites necesita saber si un inmueble existe en Catastro), se hace a través de:
  1. Un **puerto de consulta** (interfaz) que el dominio dueño de los datos implementa y expone — el consumidor depende de la interfaz, no de la implementación.
  2. O un **evento de dominio** (ej. `InmuebleRegistrado`) que el dominio dueño publica y otros dominios pueden suscribir para mantener su propia copia local mínima de lo que necesitan (ej. Trámites guarda solo `id_inmueble` + estado, no todo el modelo de Catastro).
- Nunca se comparten tablas de negocio entre dominios directamente (un módulo no hace `JOIN` a las tablas internas de otro). Las únicas tablas compartibles son las del shared kernel (usuarios, roles, permisos, auditoría) y catálogos verdaderamente maestros (ver §7).

### Módulos opcionales / eliminar un módulo sin romper el resto

Cada dominio se registra en el arranque de la aplicación de forma **explícita y aislada**:

- Backend: cada dominio expone un único punto de registro (su router FastAPI + sus dependencias) que `main.py` monta condicionalmente. Si el paquete de un dominio no existe o falla al importar, el registro de ese dominio se omite (con log de advertencia) y el resto de la aplicación sigue arrancando — nunca un `import` a nivel de módulo de negocio dentro de otro módulo de negocio, así que no hay forma de que la ausencia de uno rompa la carga de otro.
- Frontend: cada dominio expone su propio archivo de rutas; `AppRoutes` las combina. Si se quita la carpeta de un módulo y su entrada de rutas, el resto de la app sigue funcionando — exactamente el patrón que ya usa hoy `routes/AppRoutes.jsx`, solo que multiplicado por dominio en vez de por página suelta.

---

## 4. Arquitectura backend (Clean Architecture, adaptada a monolito modular)

Estructura propuesta (carpetas, sin código):

```
backend/
  app/
    core/                         # bootstrap, settings, DI helpers, logging config
    shared/                       # SHARED KERNEL — lo único que un módulo de negocio puede importar de "afuera"
      identidad/
        domain/                   # entidades: Usuario, RolInterno, Permiso, Asignacion
        application/              # casos de uso: AsignarPermiso, ResolverPermisosDeUsuario, SincronizarConKeycloak
        infrastructure/           # KeycloakAdapter, repos SQLAlchemy sobre schema `identidad`
        presentation/             # router /api/identidad (gestión de roles/permisos internos)
        ports/                    # AuthorizationPort, IdentityPort — lo que otros módulos pueden consumir
      auditoria/
        domain/ application/ infrastructure/ presentation/ ports/
      db/                         # Base declarativa, engine, gestión de schemas por dominio, Alembic
      errors/                     # excepciones de dominio comunes, manejadores HTTP genéricos
      security/                   # dependency `require_permission("recurso:accion")`, validación JWT, CORS/rate limit
    modules/
      catastro/
        domain/                   # entidades, value objects, reglas de negocio puras
        application/
          use_cases/
          dtos/
          ports/                  # interfaces que la infraestructura de Catastro debe implementar
        infrastructure/
          repositories/           # SQLAlchemy sobre schema `catastro`
          adapters/                # si Catastro necesita servicios externos propios
        presentation/
          api/                    # router /api/catastro/*, schemas Pydantic
        tests/                    # unit (domain/application) + integration (infrastructure/presentation)
      # futuros dominios de negocio replican exactamente esta forma
    presentation/
      api_router.py               # combina shared.identidad.router + shared.auditoria.router + modules.*.router
    main.py                       # factory de la app, monta routers de forma tolerante a fallos
  tests/
    e2e/                          # flujos completos cruzando módulos vía HTTP, no vía imports internos
  alembic/                        # migraciones versionadas, una cadena por proyecto, con schema por dominio
```

Puntos clave:

- **`domain/application/infrastructure/presentation` se mantiene**, pero **anidado por módulo**, no como carpetas globales únicas — así cada dominio es autocontenido y extraíble.
- **`shared/`** es la única dependencia "externa" que un módulo de negocio puede tener, y siempre a través de `ports/` (interfaces), nunca importando `infrastructure/` de otro módulo directamente. Esto es lo que hace mecánica la extracción futura: si `catastro` solo conoce interfaces (`AuthorizationPort`, `AuditPort`), no clases concretas de Keycloak o SQLAlchemy de identidad, extraerlo a otro proceso solo implica cambiar la implementación inyectada por una que llame por HTTP.
- **DI**: se mantiene simple con `Depends` de FastAPI, un archivo `deps.py` por módulo (como ya existe hoy en `presentation/api/deps.py`) — no se introduce un framework de DI adicional; con 6 juniors, menos "magia" es mejor.
- **Autorización** vive como dependencia reutilizable en `shared/security` (`require_permission("catastro:inmuebles:editar")`), consumida por cualquier router de cualquier módulo — así la regla de permisos granulares (§6) se aplica de forma uniforme sin que cada módulo reinvente su propio chequeo.
- **Migraciones**: se introduce Alembic ya (ver riesgo §1.3) con una migración inicial por schema; reemplaza a `init_db_tables()` como mecanismo de producción.

---

## 5. Arquitectura frontend (React, modular por dominio)

```
Frontend/src/
  shared/                         # lo que ya existe hoy y es genuinamente transversal
    ui/                           # el actual components/common (Button, Card, Input, Spinner, Alert, Badge)
    layout/                       # el actual components/layout (Header, GisBackdrop)
    http/                         # httpClient
    storage/                      # storageService
    config/                       # env.config, endpoints.config
    core/                         # ApiError y errores comunes
    utils/
  modules/
    identidad/                    # auth + gestión de roles/permisos internos (lo que hoy vive suelto en context/, hooks/, services/auth)
      context/                    # AuthContext, AuthProvider
      hooks/                      # useAuth
      services/                   # auth.service, user.service
      guards/                     # ProtectedRoute, PublicRoute
      pages/                      # LoginPage
      routes.js                   # rutas que este módulo aporta al router raíz
    catastro/
      pages/
      components/
      hooks/
      services/
      routes.js
    # futuros dominios replican la misma forma
  routes/
    AppRoutes.jsx                 # combina modules/*/routes.js, no conoce el detalle interno de cada módulo
  App.jsx
  main.jsx
```

Reglas equivalentes a las del backend:

- Un módulo de `modules/` **nunca** importa directamente de otro módulo de `modules/` — solo de `shared/`. Si `catastro` necesita saber el usuario logueado, usa `shared`/`modules/identidad/hooks/useAuth` (que ya es, en la práctica, shared kernel de identidad, igual que en el backend).
- Cada módulo expone sus rutas y sus entradas de menú de forma declarativa; `AppRoutes.jsx` y el layout de navegación las agregan, no las conocen de antemano línea por línea — así agregar o quitar un dominio es agregar/quitar una entrada, no editar lógica de enrutamiento.
- El código ya escrito hoy (Dashboard, Login, guards, servicios) se reorganiza dentro de `modules/identidad/` y `shared/` siguiendo este esquema — no se reescribe, se reubica (ver plan de implementación, §10, que incluye limpiar los archivos duplicados detectados en el repo actual).

---

## 6. Arquitectura de autorización (RBAC + ABAC híbrido)

### Qué vive en Keycloak vs. qué vive en la base de datos del ERP

| Responsabilidad | Dónde vive | Por qué |
|---|---|---|
| Autenticación (login, contraseña, MFA a futuro, sesión, tokens) | **Keycloak** | Es su función específica; no se reimplementa. |
| Identidad del usuario (quién es, email, si está activo/deshabilitado) | **Keycloak**, reflejado en la tabla `identidad.usuarios` como caché local sincronizada | Ya es el patrón actual (`SyncUserRbacUseCase`); se mantiene. |
| Roles **globales/gruesos** (ej. `ADMIN_SISTEMA`, `EMPLEADO`, `CONSULTOR_EXTERNO`) | **Keycloak** (`realm_access.roles`) | Son roles de identidad institucional, estables, pocos, y ya es donde Keycloak los coloca de forma nativa vía JWT. |
| Roles/perfiles **internos del ERP** (ej. "Editor de Catastro", "Supervisor de Avalúos") | **Base de datos del ERP** (schema `identidad`) | Cambian con frecuencia, son específicos de módulos de negocio que Keycloak no conoce ni debería conocer. |
| Permisos granulares (recurso + acción, ej. `catastro:videos:eliminar`) | **Base de datos del ERP** | Necesitan resolución rápida, consultas relacionales, y estar acoplados a los recursos reales del ERP — no tiene sentido modelarlos dentro de Keycloak. |
| Excepciones/asignaciones puntuales a un usuario específico (ABAC) | **Base de datos del ERP** | Es exactamente el caso que motivó la pregunta del equipo: dos usuarios con el mismo rol necesitan permisos distintos — se resuelve con una tabla de "permiso directo a usuario" que sobrescribe/añade sobre lo que da su rol. |

**Por qué no usar Keycloak Authorization Services (UMA/fine-grained authorization) para todo esto:** es técnicamente capaz de modelar permisos granulares, pero exige que el equipo administre políticas dentro de Keycloak con una curva de aprendizaje propia, separada del resto del stack (Python/SQL, que el equipo ya domina). Para 6 juniors, tener la autorización de negocio en las mismas tablas SQL que ya manejan con SQLAlchemy es más mantenible y más auditable que dos sistemas de permisos (Keycloak + DB) intentando mantenerse sincronizados. Keycloak se usa para lo que es imprescindible (identidad + roles globales), el resto vive donde el equipo tiene control total.

### Modelo: RBAC como base, ABAC como capa de excepción

1. **RBAC (base, cubre el 90% de los casos):** Usuario → Rol interno (uno o más) → Permisos (recurso + acción). Un rol interno agrupa permisos por módulo (ej. "Editor de Catastro" = `catastro:inmuebles:editar`, `catastro:inmuebles:ver`).
2. **ABAC (excepción, cubre el 10% — el caso que motivó la pregunta):** Asignaciones directas usuario→permiso, que se combinan con lo que da el rol (unión, con posibilidad explícita de revocar un permiso puntual a un usuario aunque su rol se lo dé). Aquí también entra el "ámbito" (scope) si negocio lo requiere: por ejemplo, un permiso de Catastro limitado a un distrito o macrodistrito específico — se modela como un atributo de la asignación (`ambito: {"distrito": 5}`), no como un rol nuevo por cada combinación posible.
3. **Resolución de permisos:** en tiempo de request, `require_permission("recurso:accion")` (shared/security) resuelve: permisos del rol ∪ permisos directos del usuario − revocaciones directas del usuario, filtrado por ámbito si aplica. Se cachea por request, no por sesión completa, para que un cambio de permisos aplique de inmediato sin esperar a que expire el token.

### Herencia, revocación y auditoría de cambios de permisos

- **Herencia:** un rol interno puede "incluir" permisos de otro rol (ej. "Supervisor" incluye todo lo de "Editor" + permisos extra) — jerarquía simple de un nivel, evitar jerarquías profundas (difíciles de razonar para el equipo y para el usuario final que audita).
- **Revocación:** toda asignación (rol→usuario, permiso directo→usuario) tiene baja lógica (`revocado_en`, `revocado_por`), nunca se borra físicamente — es lo que permite reconstruir "quién tenía qué permiso, cuándo".
- **Auditoría de cambios de permisos:** cada alta/baja de rol o permiso genera un evento hacia el módulo de Auditoría (§8) con actor, objetivo, permiso/rol afectado, y timestamp — sin excepción, porque es el tipo de cambio más sensible de todo el ERP.

---

## 7. Diseño de base de datos (modelo conceptual, sin SQL todavía)

### Un solo PostgreSQL, con **schemas por dominio** (no un único `public`, no bases de datos separadas)

| Opción | Evaluación |
|---|---|
| Todo en `public` | Es lo que hay hoy (`usuarios`, `roles`, `permisos` sueltos). Funciona a esta escala, pero mezclar tablas de todos los dominios en un solo namespace es exactamente el acoplamiento implícito que se quiere evitar — con 2+ dominios ya es momento de separar. |
| Una base de datos por dominio | Da el aislamiento más fuerte, pero para 6 juniors sin DevOps dedicado implica gestionar N conexiones, N credenciales, N pipelines de backup — costo operativo injustificado a esta escala, y las consultas cross-dominio (poco frecuentes, pero van a existir) se vuelven mucho más costosas de resolver. |
| **Un PostgreSQL, un schema por dominio** (`identidad`, `catastro`, `auditoria`, `public` para catálogos verdaderamente compartidos) | Aísla lógicamente cada dominio (namespacing real, permisos de DB por schema si algún día se necesita), mantiene una sola conexión/credencial que administrar, y si el día de mañana un dominio se extrae a servicio propio, su schema se convierte directamente en su propia base de datos con un `pg_dump`/`restore` — la costura de extracción existe desde el diseño. |

### Convenciones

- `snake_case` para schemas, tablas y columnas (ya es la convención del proyecto).
- PK: `id_<entidad>` (ya es el patrón actual, ej. `id_usuario`, `id_rol`) — se mantiene por consistencia.
- FK: mismo nombre de columna que la PK referenciada (`id_usuario` en la tabla hija) + `ON DELETE` explícito y pensado (`CASCADE` solo en tablas puramente de relación, `RESTRICT`/`SET NULL` en relaciones de negocio donde borrar en cascada perdería historia).
- **Soft delete por defecto** en todo lo que tenga valor de auditoría o histórico (usuarios, roles, permisos, asignaciones, y previsiblemente los registros de Catastro: un inmueble no se borra físicamente, se da de baja). Hard delete reservado a datos verdaderamente transaccionales sin valor legal/histórico.
- Timestamps estándar en toda tabla de negocio: `creado_en`, `actualizado_en`, `creado_por`, `actualizado_por` — con triggers o manejo en la capa de infraestructura, consistente en todos los módulos.
- Migraciones versionadas con Alembic desde ya (reemplaza `init_db_tables()`), una cadena de migraciones por schema/dominio para que un dominio pueda migrar su propio schema sin coordinarse con los demás en el mismo commit.

### Qué tablas son realmente compartidas vs. propias de un módulo

- **Compartidas (schema `identidad` + `public` para catálogos):** usuarios, roles internos, permisos, asignaciones, y catálogos maestros verdaderamente transversales si aparecen (ej. una tabla de "distritos/macrodistritos municipales" que varios dominios necesitan referenciar — a confirmar si existe tal catálogo).
- **Propias de cada módulo (su propio schema):** todo lo específico del dominio de negocio (en Catastro: inmuebles, propietarios, avalúos, inspecciones — nombres a confirmar con negocio). Ningún otro módulo tiene FK directa hacia estas tablas; si necesita referenciarlas, guarda el identificador como dato plano (no FK física cross-schema) y lo valida a través del puerto del módulo dueño, no con un `JOIN`.
- **Auditoría (schema `auditoria`):** tabla(s) de solo-append, referenciadas por `id_usuario` (FK a `identidad`, permitido porque auditoría es shared kernel) pero nunca referenciada en sentido inverso.

---

## 8. Comunicación entre módulos

| Patrón | Cuándo usarlo | Cuándo evitarlo |
|---|---|---|
| **Llamada directa a un puerto (interfaz) inyectado** | Cuando un módulo necesita una respuesta síncrona de otro en el mismo request (ej. Catastro necesita `AuthorizationPort.tiene_permiso(...)`) | Nunca para comunicación negocio↔negocio si se puede evitar con eventos; sí es el patrón normal para negocio→shared kernel. |
| **Eventos de dominio in-process (pub/sub simple dentro del mismo proceso)** | Para efectos secundarios entre dominios de negocio que no necesitan respuesta inmediata (ej. Catastro publica `InmuebleDadoDeBaja`, otro módulo que guardó una copia mínima del inmueble reacciona) | No usarlo para lo que puede resolverse con un puerto directo simple — no meter eventos donde no aportan desacoplamiento real; con 6 juniors, un bus de eventos mal usado es más confuso que útil. |
| **Cola de mensajes / broker externo (RabbitMQ, Kafka, etc.)** | Solo si en el futuro un módulo se extrae a proceso separado y necesita comunicación asíncrona real entre procesos | **No implementar todavía.** Es exactamente la complejidad operativa que el equipo/infraestructura actual no puede sostener; se documenta como paso futuro, no como parte de este diseño. |
| **Import directo de código de otro módulo de negocio** | Nunca | Es la forma exacta del acoplamiento circular que el requisito prohíbe. |
| **JOIN de SQL cruzando schemas de dos dominios de negocio** | Nunca | Rompe el aislamiento de datos; si hace falta el dato, se pide por el puerto del dominio dueño. |

Contratos: cada puerto (`AuthorizationPort`, `AuditPort`, y los que surjan entre dominios de negocio a futuro) se define como interfaz explícita en `shared/` o en el propio módulo dueño, con su DTO de entrada/salida versionado implícitamente por el propio código (al ser monolito, no hace falta versionado de API entre módulos todavía — sí lo necesitará el día que uno se extraiga a servicio HTTP real).

---

## 9. Seguridad

### 9.1 Corrección necesaria en Keycloak (antes de construir el modelo de permisos)

El backend actual usa `KEYCLOAK_REALM=master` y `KEYCLOAK_CLIENT_ID=admin-cli`. Se recomienda:

1. Crear un **realm de aplicación dedicado** (ej. `municipio-catastro`), distinto del realm `master` que Keycloak reserva para administrar el propio servidor.
2. Crear un **client confidencial propio del ERP** dentro de ese realm (ej. `erp-catastro-backend`), con "Direct Access Grants" habilitado solo si el flujo de login por usuario/contraseña directo al backend sigue siendo el requerido (evaluar si conviene migrar a Authorization Code flow con el frontend redirigiendo a la pantalla de Keycloak, que es más seguro que enviar la contraseña al backend propio — se marca como mejora recomendada, no bloqueante para este diseño).
3. Los roles globales del ERP (`ADMIN_SISTEMA`, `EMPLEADO`, etc.) se definen como roles de ese realm, no se reutilizan roles del realm `master`.

Esto no altera el flujo que "ya funciona" a nivel de experiencia de usuario — sigue siendo login → Keycloak valida → el backend recibe el JWT y lo verifica contra JWKS. Cambia únicamente *contra qué realm/cliente* se emite y valida ese JWT, que es una corrección de configuración, no un rediseño.

### 9.2 Autenticación vs. autorización — dónde vive cada una

- **Autenticación:** exclusivamente Keycloak + verificación de firma JWT contra JWKS en el backend (ya implementado en `KeycloakAdapter.verify_token`, se mantiene).
- **Autorización:** exclusivamente en el ERP (§6), nunca inferida solo del rol de Keycloak. El backend es la única fuente de verdad de autorización — el frontend puede ocultar/mostrar UI según permisos para mejorar UX, pero **nunca** se confía en el frontend como control de seguridad; todo endpoint valida permisos server-side de forma independiente de lo que el frontend muestre u oculte.

### 9.3 Tokens

- Expiración corta de access token (ya gestionado por Keycloak), refresh token manejado por el flujo estándar OIDC.
- El backend nunca extiende la vida de un token ni emite tokens propios — siempre valida el de Keycloak.
- Frontend: el token vive en el almacenamiento que ya usa `storageService`; se recomienda evaluar `httpOnly cookie` en vez de `localStorage` a futuro para mitigar XSS (mejora recomendada, no bloqueante).

### 9.4 Otros controles

- **CORS:** ya restringido a `FRONTEND_ORIGIN` (correcto), debe tener un valor distinto por ambiente (dev/QA/prod) vía variables de entorno, nunca `*`.
- **Rate limiting:** no existe hoy; se recomienda agregarlo al menos en `/api/login` (fuerza bruta) desde el arranque del módulo de Identidad formal.
- **Validación de inputs:** se mantiene con Pydantic (ya es el patrón del proyecto) en cada módulo, sin excepciones.
- **Secretos:** `.env` por ambiente (ya gitignorado, correcto), nunca secretos en el repo; para producción evaluar un vault/gestor de secretos cuando la infraestructura de despliegue se defina (§2).
- **Separación de ambientes:** dev/QA/prod con Keycloak, DB y `.env` propios por ambiente — no compartir realm ni base de datos entre ambientes.
- **Protección de acceso directo a recursos:** todo endpoint que devuelve un recurso por id valida no solo el permiso genérico (`catastro:inmuebles:ver`) sino, si aplica ámbito (§6), que el usuario tenga ese recurso dentro de su ámbito — para no dejar accesible por id un recurso fuera del alcance del usuario aunque tenga el permiso genérico.

---

## 10. Auditoría

### Qué se audita
- Login/logout y login fallido (con usuario intentado, nunca la contraseña).
- Alta, baja, modificación de roles internos y permisos (asignación y revocación) — sin excepción, es lo más sensible del sistema.
- Acciones administrativas (creación/baja de usuarios internos, cambios de configuración sensible).
- Altas/bajas/modificaciones de recursos de negocio que el propio módulo considere sensibles (a definir por cada módulo — Catastro define qué acciones sobre inmuebles/avalúos audita, no se le impone una lista genérica que puede no aplicar).

### Qué se registra por evento
Actor (usuario + rol efectivo en el momento), fecha/hora, IP de origen, recurso afectado (tipo + id), acción, valores antes/después cuando la acción es una modificación (JSON), resultado (éxito/fallo), y de qué módulo proviene el evento.

### Cómo se integra con los módulos de negocio
- El módulo de Auditoría expone un `AuditPort` (shared kernel, §8) con una operación simple: registrar evento.
- Cada módulo de negocio llama a ese puerto cuando ejecuta una acción sensible — la decisión de *qué* auditar la toma el módulo dueño de la acción, la infraestructura de *cómo* almacenarlo la centraliza Auditoría.
- **Escritura:** dado el tamaño de equipo, se recomienda escritura **síncrona dentro de la misma transacción de negocio** cuando la acción es crítica (cambios de permisos, altas/bajas administrativas) — más simple de razonar y garantiza que no exista una acción sensible sin su registro. Para acciones de alto volumen y bajo riesgo (ej. lecturas, si algún día se decide auditar accesos de lectura) se puede evaluar un registro asíncrono vía evento in-process — no es necesario hoy.
- **Inmutabilidad:** la tabla de auditoría es solo-append (sin `UPDATE`/`DELETE` a nivel de aplicación); si se requiere formalmente por normativa municipal, se refuerza con permisos de base de datos que ni siquiera el usuario de aplicación pueda actualizar/borrar filas ya escritas (revisar con el equipo si existe ese requisito legal explícito — no se asume).

---

## 11. Requisitos no funcionales — cómo se cumplen con este diseño

- **Escalabilidad de módulos:** agregar un dominio es agregar una carpeta nueva que sigue el mismo patrón (§3, §4, §5) — no toca código existente.
- **Escalabilidad de datos:** schemas separados permiten indexar/particionar por dominio de forma independiente si algún módulo crece mucho (ej. Catastro con cientos de miles de inmuebles) sin afectar el resto.
- **Escalabilidad de carga:** al ser un monolito modular en un solo proceso, escala verticalmente primero (más recursos al mismo servidor/contenedor) y horizontalmente después (réplicas del mismo monolito detrás de un balanceador) sin cambios de arquitectura — la extracción a servicios independientes queda como palanca adicional, no como requisito de partida.
- **Mantenibilidad/testabilidad:** Clean Architecture por módulo permite testear casos de uso sin DB ni Keycloak (mockeando los puertos), clave para que un equipo junior pueda escribir tests significativos sin necesitar levantar infraestructura completa.
- **Disponibilidad parcial:** el patrón de registro tolerante a fallos (§3) es lo que garantiza el requisito no negociable — un error en la carga de un módulo se loguea y el resto de la app sigue sirviendo tráfico.
- **Observabilidad:** logging estructurado por módulo desde el inicio (ya hay un logger `uvicorn.error` en uso; se recomienda migrar a logging estructurado JSON con contexto de módulo/usuario/request-id), health checks por dependencia (ya existe `/api/health/db`, se replica el patrón para Keycloak), métricas y tracing distribuido se documentan como evolución futura, condicionada a que exista infraestructura real que los consuma (Prometheus/Grafana u similar) — no se instrumenta en el vacío.

---

## 12. Convenciones

### Backend (Python/FastAPI)
- Archivos y carpetas: `snake_case`.
- Clases: `PascalCase`, sufijo por tipo — entidades sin sufijo (`Usuario`), casos de uso `*UseCase`, puertos `*Port`, adaptadores `*Adapter`, DTOs `*DTO`, schemas Pydantic `*Request`/`*Response`.
- Funciones y variables: `snake_case`.
- Endpoints: `/api/<dominio>/<recurso-en-plural>`, verbos HTTP estándar, sin verbos en la URL.
- Tablas: `snake_case`, plural (`usuarios`, `roles`, `permisos` — ya es el patrón actual).
- Columnas: `snake_case`, PK `id_<entidad>` (patrón ya existente, se mantiene).
- Permisos (strings): `<dominio>:<recurso>:<accion>` (ej. `catastro:inmuebles:editar`, `identidad:roles:asignar`).

### Frontend (React)
- Componentes: `PascalCase.jsx` (ya es el patrón actual: `LoginForm.jsx`, `UserProfileCard.jsx`).
- Hooks: `useCamelCase.js` (ya existe `useAuth.js`, `useAsync.js`).
- Servicios: `camelCase.service.js` o `nombre.service.js` por dominio (ya existe el patrón `auth.service.js`, `user.service.js`).
- Carpetas de módulo: `kebab-case` o nombre simple en minúscula (`modules/catastro`, `modules/identidad`) — consistente con dominios del backend para que cualquier dev pueda mapear mentalmente frontend↔backend por nombre.
- Variables/funciones: `camelCase`.
- Config: sufijo `.config.js` (ya es el patrón actual: `env.config.js`, `endpoints.config.js`).

---

## 13. Plan de implementación recomendado

El orden prioriza: primero cerrar deuda de seguridad real, después construir la base compartida (shared kernel) sobre la que todo lo demás se apoya, después formalizar el primer módulo de negocio real, dejando cada paso verificable por el equipo junior antes de avanzar al siguiente.

1. **Corregir configuración de Keycloak** (§9.1): realm y client dedicados al ERP, fuera de `master`/`admin-cli`. Es la deuda de mayor riesgo y menor esfuerzo — se hace primero y sola, sin mezclar con refactors de código.
2. **Limpiar el frontend actual**: eliminar los archivos duplicados detectados (versiones viejas de `ProtectedRoute`, `PublicRoute`, componentes de login, `AuthContext.jsx`, `authService.js` que ya fueron reemplazados por la estructura nueva pero siguen en el repo sin usarse) antes de reorganizar en `modules/`, para no migrar código muerto.
3. **Construir el shared kernel backend**: `shared/db` (Alembic + estrategia de schemas), `shared/security` (dependencia `require_permission`), `shared/errors`, y migrar el módulo de Identidad actual (`usuarios/roles/permisos`) al nuevo modelo RBAC+ABAC (§6–§7) dentro de `shared/identidad`.
4. **Construir el módulo de Auditoría** como segundo pilar del shared kernel, con su `AuditPort`, antes de que exista negocio real que auditar — así todo módulo de negocio nuevo nace ya integrado a auditoría, en vez de agregarla después.
5. **Reorganizar el frontend actual** dentro de `modules/identidad/` + `shared/`, siguiendo el esquema de §5, validando que login/dashboard actuales sigan funcionando igual tras la reubicación (es mover código, no reescribirlo).
6. **Formalizar el patrón de módulo con un caso mínimo**: antes de meterle todo el negocio de Catastro, crear el esqueleto de `modules/catastro` (backend y frontend) con un caso de uso trivial de punta a punta (ej. un recurso simple con CRUD mínimo) para validar que el patrón de registro tolerante a fallos, permisos y auditoría funciona en la práctica — y que los 6 juniors puedan replicarlo sin ambigüedad.
7. **Documentar el patrón como plantilla** ("cómo crear un módulo nuevo paso a paso", backend y frontend) a partir de lo aprendido en el paso 6 — es lo que va a permitir que el equipo junior agregue módulos futuros (Trámites, Finanzas, etc.) de forma consistente sin que cada quien lo resuelva distinto.
8. **Recién ahí, construir el negocio real de Catastro** (inmuebles, propietarios, avalúos, inspecciones u lo que negocio confirme), módulo por módulo, feature por feature, sobre la base ya validada.

---

## Puntos abiertos que siguen dependiendo de negocio (no arquitectura)

Estos no bloquean empezar el plan de implementación de §13, pero sí bloquean modelar las tablas reales de Catastro:

- Lista real y definitiva de módulos de Catastro (el ejemplo dado — Inmuebles, Propietarios, Avalúos, Inspecciones — debe confirmarse o corregirse con el área usuaria).
- Si existe algún catálogo maestro verdaderamente transversal (ej. distritos/macrodistritos) que otros dominios futuros también necesitarán referenciar.
- Requisitos legales/normativos específicos de retención y formato de auditoría para el sector público municipal (Bolivia), si existen, más allá de la buena práctica general aplicada en §10.
