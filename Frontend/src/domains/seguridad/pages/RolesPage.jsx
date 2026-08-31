import { useState } from 'react'
import { KeyRound, Plus, Pencil, Trash2, Building2 } from 'lucide-react'
import { toast } from 'react-toastify'
import { Card, SectionHeader, Button, Badge, IconButton, EmptyState } from '@/shared/ui'
import { useSeguridadData, seguridadActions } from '../data/seguridadStore'
import { RolFormModal } from '../components/RolFormModal'
import { AreaFormModal } from '../components/AreaFormModal'

/**
 * Catálogo de roles y áreas del ERP. Crear rol: nombre libre + permisos por checkbox.
 * Editar rol existente: solo permisos (checkbox), el nombre no se toca. Áreas: solo alta,
 * nombre libre (ver PermisosPage para asignar rol+área a cada usuario).
 */
export default function RolesPage() {
  const { roles, areas } = useSeguridadData()
  // undefined = modal cerrado, null = crear rol nuevo, objeto = editar permisos de ese rol
  const [rolEnEdicion, setRolEnEdicion] = useState(undefined)
  // Se incrementa en cada apertura para forzar un remount de RolFormModal (ver su comentario)
  // y que arranque limpio, sin necesitar un efecto que resetee el estado del formulario.
  const [modalToken, setModalToken] = useState(0)
  const [areaModalAbierto, setAreaModalAbierto] = useState(false)

  const abrirModalRol = (rol) => {
    setRolEnEdicion(rol)
    setModalToken((token) => token + 1)
  }

  const handleEliminarRol = (rol) => {
    seguridadActions.eliminarRol(rol.id)
    toast.info(`Rol "${rol.nombre}" eliminado.`)
  }

  return (
    <>
      <Card>
        <SectionHeader icon={KeyRound} eyebrow="Roles" title="Roles y áreas" />

        <div className="mb-8">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="text-xs font-bold uppercase tracking-widest text-slate-500">
              Roles ({roles.length})
            </h3>
            <Button size="sm" icon={Plus} onClick={() => abrirModalRol(null)}>
              Nuevo rol
            </Button>
          </div>

          {roles.length === 0 ? (
            <EmptyState
              icon={KeyRound}
              title="Todavía no hay roles"
              subtitle="Creá el primero con el botón de arriba."
            />
          ) : (
            <ul className="space-y-2.5">
              {roles.map((rol) => (
                <li
                  key={rol.id}
                  className="flex items-start justify-between gap-3 rounded-2xl border border-slate-200/70 bg-white/60 p-4 shadow-xs backdrop-blur-sm"
                >
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold text-slate-800">{rol.nombre}</p>
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      {rol.permisos.length === 0 ? (
                        <span className="text-xs text-slate-400">Sin permisos asignados</span>
                      ) : (
                        rol.permisos.map((permiso) => (
                          <Badge key={permiso} variant="accent" className="font-mono">
                            {permiso}
                          </Badge>
                        ))
                      )}
                    </div>
                  </div>
                  <div className="flex shrink-0 gap-1">
                    <IconButton
                      icon={Pencil}
                      onClick={() => abrirModalRol(rol)}
                      aria-label={`Editar permisos de ${rol.nombre}`}
                    />
                    <IconButton
                      icon={Trash2}
                      tone="danger"
                      onClick={() => handleEliminarRol(rol)}
                      aria-label={`Eliminar ${rol.nombre}`}
                    />
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div>
          <div className="mb-4 flex items-center justify-between">
            <h3 className="text-xs font-bold uppercase tracking-widest text-slate-500">
              Áreas ({areas.length})
            </h3>
            <Button size="sm" variant="secondary" icon={Plus} onClick={() => setAreaModalAbierto(true)}>
              Nueva área
            </Button>
          </div>

          {areas.length === 0 ? (
            <EmptyState
              icon={Building2}
              title="Todavía no hay áreas"
              subtitle="Creá la primera con el botón de arriba."
            />
          ) : (
            <div className="flex flex-wrap gap-2">
              {areas.map((area) => (
                <Badge key={area.id} variant="neutral">
                  {area.nombre}
                </Badge>
              ))}
            </div>
          )}
        </div>
      </Card>

      <RolFormModal
        key={modalToken}
        open={rolEnEdicion !== undefined}
        onClose={() => setRolEnEdicion(undefined)}
        rol={rolEnEdicion || undefined}
      />
      <AreaFormModal open={areaModalAbierto} onClose={() => setAreaModalAbierto(false)} />
    </>
  )
}
