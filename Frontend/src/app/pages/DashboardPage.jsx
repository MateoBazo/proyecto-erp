import { NavLink } from 'react-router-dom'
import { LayoutGrid, UserRound } from 'lucide-react'
import { Card, Badge } from '@/shared/ui'
import { useAuth } from '@/auth/hooks/useAuth'
import { NAV_SECTIONS } from '@/shared/nav'

// Todo lo que no sea "Inicio" se muestra como acceso directo a un dominio del ERP.
const MODULES = NAV_SECTIONS.filter((section) => section.path !== '/dashboard')

function ModuleTile({ label, path, icon: Icon }) {
  return (
    <NavLink
      to={path}
      className="group flex flex-col items-center gap-2.5 rounded-2xl border border-slate-200/70 bg-white/60 p-5 text-center shadow-xs backdrop-blur-sm transition-colors duration-150 hover:border-accent-300 hover:bg-white hover:shadow-md"
    >
      <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-slate-100 text-slate-500 transition-colors duration-200 group-hover:bg-accent-500 group-hover:text-white">
        <Icon className="h-6 w-6" />
      </span>
      <span className="text-xs font-semibold text-slate-700 transition-colors duration-200 group-hover:text-slate-900">
        {label}
      </span>
    </NavLink>
  )
}

/**
 * Home de la aplicación: saludo personalizado del usuario logueado y la grilla de módulos
 * del ERP. Al entrar a un módulo desde acá, el sidebar contextual aparece (ver
 * app/layout/Sidebar.jsx) — antes de eso el sidebar no se muestra.
 */
export function DashboardPage() {
  const { user } = useAuth()

  const displayName = user?.username || 'Usuario'
  const roles = user?.roles || []

  return (
    <>
      <Card>
        <div className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-accent-50 text-accent-600 ring-1 ring-accent-200">
            <UserRound className="h-5 w-5" />
          </span>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-accent-600">
              Bienvenido/a
            </p>
            <h2 className="text-lg font-bold text-slate-900">{displayName}</h2>
          </div>
        </div>

        {roles.length > 0 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {roles.map((role) => (
              <Badge key={role} variant="accent">
                {role}
              </Badge>
            ))}
          </div>
        )}
      </Card>

      <Card>
        <div className="mb-5 flex items-center gap-2.5 border-b border-slate-200/60 pb-3.5">
          <LayoutGrid className="h-5 w-5 text-accent-600" />
          <h3 className="text-sm font-semibold uppercase tracking-wider text-slate-800">
            Módulos del ERP
          </h3>
        </div>

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {MODULES.map((module) => (
            <ModuleTile key={module.path} {...module} />
          ))}
        </div>
      </Card>
    </>
  )
}

export default DashboardPage
