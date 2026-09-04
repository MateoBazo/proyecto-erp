import { NAV_SECTIONS } from '@/shared/nav'

// Módulos del ERP para armar el checklist de permisos, tomados de NAV_SECTIONS
// (así nunca se desincroniza con lo que realmente existe). Las acciones son un
// par genérico ver/editar mientras no haya un catálogo definido por módulo.
export const MODULOS_ERP = NAV_SECTIONS.filter((section) => section.path !== '/dashboard').map(
  (section) => ({
    id: section.path.replace('/', ''),
    label: section.label,
  })
)

export const ACCIONES = [
  { id: 'ver', label: 'Ver' },
  { id: 'editar', label: 'Editar' },
]
