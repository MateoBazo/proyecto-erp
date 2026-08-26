# Cómo agregar un dominio nuevo al ERP

Receta paso a paso, escrita a partir de la migración real de `geoextraccion` (ver
`CLAUDE.md` y `ARQUITECTURA.md` para las reglas de fondo — esto es la aplicación mecánica
de esas reglas). Sirve tanto para un dominio de negocio nuevo (ej. Catastro) como para
"traer" un proyecto externo que ya existía como app independiente.

No hace falta decidir nada de arquitectura otra vez: seguir estos pasos alcanza.

---

## 1. Backend (`backend/app/domains/<nombre>/`)

Copiar el esqueleto de un dominio existente (`domains/seguridad/` o `domains/geoextraccion/`,
este último es más simple si el dominio nuevo no necesita base de datos):

```
domain/
  entities/       # entidades y value objects — sin FastAPI, sin SQLAlchemy, sin librerías externas
  ports/           # interfaces que application/ usa y infrastructure/ implementa
  exceptions.py    # heredan de app.core.errors.exceptions.DomainException (define http_status)
application/
  use_cases/       # una clase por caso de uso de negocio; recibe puertos por constructor
  dtos/            # si el caso de uso necesita una forma de entrada distinta a la entidad (opcional)
infrastructure/    # implementación concreta de los puertos (SQLAlchemy, librerías externas, APIs)
presentation/
  deps.py          # inyección de dependencias (patrón lru_cache + Depends, ver seguridad/presentation/deps.py)
  router.py        # agrupa los endpoints del dominio
  endpoints/
  schemas/         # Pydantic, solo para request/response HTTP
contracts/         # lo único que OTRO dominio puede importar de este (ver CLAUDE.md §2)
tests/
```

**Reglas que no se negocian** (`CLAUDE.md` §2, checklist §9):
- Nunca importar `domain/`, `application/` o `infrastructure/` de otro dominio de negocio. Si necesitás algo de `seguridad` (ej. el usuario autenticado), importalo de `app.domains.seguridad.contracts`, nunca de `.presentation.deps`.
- Las excepciones de negocio heredan de `DomainException` (`app/core/errors/exceptions.py`) y se lanzan directamente desde `application/` — el handler genérico en `core/errors/handlers.py` ya las traduce a HTTP. No envolver a mano con `try/except HTTPException` en el endpoint.
- Si el dominio no necesita base de datos (como `geoextraccion`), no crear un schema — no inventar persistencia que no hace falta.

**Registrar el dominio** — única línea a tocar fuera de la carpeta nueva, en `backend/app/registry.py`:

```python
try:
    from app.domains.<nombre>.presentation.router import router as <nombre>_router
    api_router.include_router(<nombre>_router, prefix="/<nombre>")
except Exception as exc:
    logger.warning(f"No se pudo cargar el dominio '<nombre>': {exc}")
```

El `try/except` es intencional: si al dominio nuevo le falta una dependencia (ej. una librería pesada
que no instaló todavía en ese ambiente), el resto del ERP arranca igual con un warning en el log.

Si el dominio trae dependencias nuevas (librerías Python), agregarlas a `backend/requirements.txt`.

---

## 2. Frontend (`Frontend/src/domains/<nombre>/`)

```
pages/        # una pantalla = un archivo (PascalCase)
components/   # piezas reutilizables SOLO dentro de este dominio
api/          # llamadas HTTP de este dominio, sobre httpClient de @/core/http
utils/        # lógica pura del dominio (parsers, formateo) sin JSX
routes.jsx    # exporta el array de rutas reales de este dominio
```

**Reglas:**
- Un dominio de `domains/` puede importar de `@/core` y `@/shared` libremente, pero nunca de otro `domains/*` directamente.
- HTTP: usar `httpClient` de `@/core/http` (ya inyecta el JWT de Keycloak), nunca `axios`/`fetch` suelto salvo que sea un servicio externo real fuera del ERP (documentarlo como tal, ver `domains/geoextraccion/api/geoextraccion.api.js`).
- Diseño: usar los componentes de `@/shared/ui` (`Card`, `Button`, `Alert`, `Badge`, `Spinner`) y los tokens de color de `index.css` (`brand-*` para acciones primarias, `accent-*` para íconos/resaltados, `state-*` solo para badges/indicadores — nunca como fondo estructural de un botón). Sin dark mode: el ERP tiene un único tema.

**Registrar la navegación** — en `Frontend/src/shared/nav/navConfig.js`, agregar una entrada a `NAV_SECTIONS` con `children` (esto agrega automáticamente el botón en el home, la entrada de `DomainHome` y el sidebar contextual — no hay que tocar esos tres archivos a mano):

```js
{
  label: 'Nombre visible',
  icon: MiIcono, // de lucide-react
  path: '/<nombre>',
  children: [
    { label: 'Pantalla A', path: '/<nombre>/pantalla-a', icon: OtroIcono },
  ],
},
```

**Registrar las rutas reales** — única línea a tocar fuera de la carpeta nueva, en `Frontend/src/domains/index.js`:

```js
import { <nombre>Routes } from './<nombre>/routes'

export const DOMAIN_ROUTES = [...geoextraccionRoutes, ...<nombre>Routes]
```

Mientras un `children` de `navConfig.js` no tenga una entrada correspondiente en `DOMAIN_ROUTES`,
`app/routes.jsx` lo sirve automáticamente con `ModulePlaceholder` — así se puede anunciar un
módulo en la navegación antes de terminar de construirlo, sin pantallas rotas.

Si una pantalla necesita más ancho que el `max-w-4xl` por defecto del `AppShell` (ej. un visor +
tabla lado a lado), marcarla con `wide: true` en su entrada de `routes.jsx` — no tocar `AppShell.jsx`.

---

## 3. Verificar

1. Backend: `uvicorn app.main:app --reload` → confirmar en `/docs` que el router nuevo aparece bajo su prefijo, y que si se desinstala una dependencia del dominio, el resto de la app sigue arrancando (log de warning, no crash).
2. Frontend: `npm run dev` → el nuevo dominio aparece en el home, el sidebar contextual lista sus pantallas, y las rutas no registradas todavía muestran el placeholder genérico.
3. `npm run lint` sin errores.
