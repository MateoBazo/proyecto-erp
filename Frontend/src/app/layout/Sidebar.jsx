import { NavLink, useLocation } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { NAV_SECTIONS, getCurrentDomain } from '@/shared/nav'

const INICIO = NAV_SECTIONS.find((section) => section.path === '/dashboard')

const linkBase =
  'group relative flex items-center gap-2.5 overflow-hidden rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200'
const linkActive = 'bg-brand-800 text-white shadow-md shadow-brand-900/20'
const linkInactive = 'text-brand-600 hover:translate-x-0.5 hover:bg-white/50 hover:text-brand-800'

/**
 * Sidebar contextual que muestra las secciones del dominio actual y enlace a Inicio.
 */
export function Sidebar({ open = true }) {
  const { pathname } = useLocation()
  const currentDomain = getCurrentDomain(pathname)

  if (!currentDomain) return null

  const DomainIcon = currentDomain.icon

  return (
    <div
      className={`shrink-0 overflow-hidden transition-[width] duration-200 ease-out will-change-[width] ${
        open ? 'w-64' : 'w-0'
      }`}
    >
      <aside className="flex h-dvh w-64 flex-col border-r border-brand-600/15 bg-gradient-to-b from-accent-300 to-accent-200 shadow-lg">
        <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-5">
          <NavLink
            to={INICIO.path}
            className="group mb-4 flex items-center gap-2.5 rounded-xl border border-brand-600/15 bg-white/40 px-3 py-2.5 text-sm font-medium text-brand-600 shadow-sm transition-all duration-200 hover:bg-white/70 hover:text-brand-800 hover:shadow"
          >
            <ArrowLeft className="h-[18px] w-[18px] shrink-0 transition-transform duration-200 group-hover:-translate-x-1" />
            <span>Volver a Inicio</span>
          </NavLink>

          <div className="mb-2 flex items-center gap-2.5 px-1 pb-1">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-brand-800/10 text-brand-800">
              <DomainIcon className="h-4 w-4" />
            </div>
            <span className="text-xs font-semibold uppercase tracking-wider text-brand-600/70">
              {currentDomain.label}
            </span>
          </div>

          {currentDomain.children?.map((child, index) => {
            const ChildIcon = child.icon
            return (
              <NavLink
                key={child.path}
                to={child.path}
                style={{ animationDelay: `${index * 40}ms` }}
                className={({ isActive }) =>
                  `${linkBase} animate-sidebar-item ${isActive ? linkActive : linkInactive}`
                }
              >
                {({ isActive }) => (
                  <>
                    <span
                      className={`absolute left-0 top-1/2 h-5 w-1 -translate-y-1/2 rounded-r-full bg-white transition-opacity duration-200 ${
                        isActive ? 'opacity-100' : 'opacity-0'
                      }`}
                    />
                    <ChildIcon
                      className={`h-[18px] w-[18px] shrink-0 transition-transform duration-200 ${
                        isActive ? '' : 'group-hover:scale-110'
                      }`}
                    />
                    <span>{child.label}</span>
                  </>
                )}
              </NavLink>
            )
          })}
        </nav>
      </aside>
    </div>
  )
}

export default Sidebar
