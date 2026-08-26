import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { LoginPage } from '@/auth/pages'
import { ProtectedRoute, PublicRoute } from '@/auth/guards'
import { PLACEHOLDER_ROUTES, DOMAIN_SECTIONS } from '@/shared/nav'
import { DOMAIN_ROUTES } from '@/domains'
import { AppShell } from './layout'
import { DashboardPage, DomainHome, ModulePlaceholder } from './pages'

// Paths con pantalla real (ver src/domains/index.js) — se excluyen del placeholder genérico.
const IMPLEMENTED_PATHS = new Set(DOMAIN_ROUTES.map((route) => route.path))

/**
 * Enrutador principal de la aplicación con separación de rutas públicas y protegidas.
 * Toda ruta protegida se monta dentro de <AppShell/> (sidebar + header), que expone
 * el resto del árbol vía <Outlet/>.
 */
export function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Ruta pública de Login (si ya está autenticado, redirige a /dashboard) */}
        <Route
          path="/"
          element={
            <PublicRoute>
              <LoginPage />
            </PublicRoute>
          }
        />

        {/* Área protegida: requiere token válido de Keycloak, se navega desde el sidebar */}
        <Route
          element={
            <ProtectedRoute>
              <AppShell />
            </ProtectedRoute>
          }
        >
          <Route path="dashboard" element={<DashboardPage />} />

          {/* Entrada a cada dominio: muestra sus subsistemas como botones grandes */}
          {DOMAIN_SECTIONS.map((domain) => (
            <Route key={domain.path} path={domain.path.slice(1)} element={<DomainHome />} />
          ))}

          {/* Dominios con pantalla real (ver src/domains/index.js) */}
          {DOMAIN_ROUTES.map((route) => (
            <Route key={route.path} path={route.path.slice(1)} element={route.element} />
          ))}

          {/* Módulos del ERP sin funcionalidad real todavía (ver shared/nav/navConfig.js) */}
          {PLACEHOLDER_ROUTES.filter((route) => !IMPLEMENTED_PATHS.has(route.path)).map((route) => (
            <Route key={route.path} path={route.path.slice(1)} element={<ModulePlaceholder />} />
          ))}
        </Route>

        {/* Redirección para cualquier otra ruta no reconocida */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default AppRoutes
