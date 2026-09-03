import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { LoginPage } from '@/auth/pages'
import { ProtectedRoute, PublicRoute } from '@/auth/guards'
import { useAuth } from '@/auth/hooks/useAuth'
import { PLACEHOLDER_ROUTES, DOMAIN_SECTIONS, getCurrentDomain, puedeVerModulo } from '@/shared/nav'
import { DOMAIN_ROUTES } from '@/domains'
import { AppShell } from './layout'
import { DashboardPage, DomainHome, ModulePlaceholder } from './pages'

// Rutas implementadas con pantalla propia
const IMPLEMENTED_PATHS = new Set(DOMAIN_ROUTES.map((route) => route.path))

/**
 * Protege el acceso por URL verificando los permisos del usuario.
 */
function ModuleGuard({ section, children }) {
  const { user } = useAuth()
  if (!puedeVerModulo(user?.permisos, section)) {
    return <Navigate to="/dashboard" replace />
  }
  return children
}

/**
 * Enrutador principal de la aplicación.
 */
export function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Ruta pública de Login */}
        <Route
          path="/"
          element={
            <PublicRoute>
              <LoginPage />
            </PublicRoute>
          }
        />

        {/* Rutas protegidas */}
        <Route
          element={
            <ProtectedRoute>
              <AppShell />
            </ProtectedRoute>
          }
        >
          <Route path="dashboard" element={<DashboardPage />} />

          {/* Pantallas de inicio de dominio */}
          {DOMAIN_SECTIONS.map((domain) => (
            <Route
              key={domain.path}
              path={domain.path.slice(1)}
              element={
                <ModuleGuard section={domain}>
                  <DomainHome />
                </ModuleGuard>
              }
            />
          ))}

          {/* Rutas de dominios implementados */}
          {DOMAIN_ROUTES.map((route) => (
            <Route
              key={route.path}
              path={route.path.slice(1)}
              element={<ModuleGuard section={getCurrentDomain(route.path)}>{route.element}</ModuleGuard>}
            />
          ))}

          {/* Módulos pendientes de implementación */}
          {PLACEHOLDER_ROUTES.filter((route) => !IMPLEMENTED_PATHS.has(route.path)).map((route) => (
            <Route
              key={route.path}
              path={route.path.slice(1)}
              element={
                <ModuleGuard section={getCurrentDomain(route.path)}>
                  <ModulePlaceholder />
                </ModuleGuard>
              }
            />
          ))}
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default AppRoutes
