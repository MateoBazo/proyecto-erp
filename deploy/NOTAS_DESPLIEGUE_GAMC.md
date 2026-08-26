# Notas de despliegue — ERP Catastro (GAMC)

Registro de la configuración de despliegue actual, para que quede en el repo
y no dependa de memoria de una sola persona. Actualizar este archivo cuando
cambie algo de lo de abajo (IPs, credenciales, pendientes de seguridad).

## Servidores de destino

| Componente | Servidor | Ruta | Puerto |
|---|---|---|---|
| Backend (FastAPI/Uvicorn) | `172.16.65.40` | `/usr/src/conexionkeycloak/backend` | `8080` |
| Frontend (build servido con `serve`) | `172.16.65.40` | `/usr/src/conexionkeycloak/Frontend` | `3000` |
| Venv del backend | `172.16.65.40` | `/usr/src/conexionkeycloak/venv` | — |
| PostgreSQL (`gis_seguridad`) | `172.16.66.103` | — | `5432` |

Los servicios systemd (`deploy/systemd/erp-backend.service`,
`erp-frontend.service`) corren como usuario **`root`** porque es el único
usuario disponible en ese servidor. Ideal a futuro sería un usuario de
servicio dedicado sin privilegios de root, pero no es requisito de este
despliegue.

## Pendientes críticos de seguridad (Keycloak)

Ambos ya están marcados como `TODO(equipo)` directamente en `backend/.env`.
Ver también `CLAUDE.md` sección "Pendiente crítico de seguridad" y
`ARQUITECTURA.md` §9.1.

1. **`KEYCLOAK_REALM="master"`** — el realm `master` es exclusivo para
   administrar el propio Keycloak, nunca para autenticar usuarios de una
   aplicación de negocio. Falta crear un realm dedicado (ej.
   `alcaldia-erp` / `municipio-catastro`) y migrar el client ahí.
2. **`KEYCLOAK_CLIENT_ID="admin-cli"`** — `admin-cli` es el client
   administrativo de Keycloak, no un client de aplicación. Falta crear un
   client confidencial propio del ERP (ej. `app-erp`) dentro del realm
   dedicado del punto anterior.

Ninguno de los dos bloquea que el sistema funcione hoy (el login ya
funciona contra `master`/`admin-cli`), pero **sí es la deuda de mayor riesgo
de seguridad del proyecto** y debe resolverse antes de producción real —
mezclar identidades administrativas de Keycloak con usuarios de negocio del
ERP no es aceptable como estado final.

## Archivos de configuración de este despliegue

- `backend/.env` — no está versionado en git (agregado a `.gitignore` en este
  mismo cambio, ver nota de seguridad abajo). Contiene las credenciales reales
  de `172.16.66.103` y el `FRONTEND_ORIGIN` apuntando a `172.16.65.40:3000`.
- `Frontend/.env.production` — no está versionado en git. Contiene
  `VITE_API_URL=http://172.16.65.40:8080`, usado por `vite build` para que el
  frontend apunte al backend real en vez de `localhost`.

## Nota de seguridad encontrada durante este despliegue

`.gitignore` en la raíz del repo **solo** tenía `node_modules/` — `backend/.env`
nunca estuvo efectivamente ignorado por git (nunca se había commiteado, pero
un `git add .` sin revisar lo habría subido con la contraseña real de
`172.16.66.103` incluida). Se agregaron `backend/.env` y
`Frontend/.env.production` a `.gitignore` en este mismo cambio. Verificar con
`git status` antes de cualquier commit futuro que ninguno de los dos archivos
aparezca en el staging.

## Cómo desplegar (referencia rápida)

1. Copiar el repo a `/usr/src/conexionkeycloak` en `172.16.65.40` (WinSCP u
   otro medio).
2. Crear el venv en `/usr/src/conexionkeycloak/venv` e instalar
   `backend/requirements.txt`.
3. Generar el build de producción una vez (`cd Frontend && npm install &&
   npm run build`) — y repetir cada vez que se despliegue código nuevo,
   como ya indica el comentario de `erp-frontend.service`.
4. Instalar los dos `.service` de `deploy/systemd/` en
   `/etc/systemd/system/`, `daemon-reload`, `enable` y `start` — instrucciones
   completas en los comentarios de cada archivo.
5. Confirmar que PostgreSQL en `172.16.66.103` acepta conexiones remotas desde
   `172.16.65.40` (usuario `UserCatBD`, base `gis_seguridad`) antes de arrancar
   el backend.
