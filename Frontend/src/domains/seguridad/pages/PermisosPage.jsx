import { useMemo, useState } from 'react'
import { RefreshCw, Search, Users } from 'lucide-react'
import { toast } from 'react-toastify'
import { Card, SectionHeader, Select, Input, EmptyState, Alert, Spinner } from '@/shared/ui'
import { useSeguridadData, seguridadActions } from '../data/seguridadStore'

/**
 * Lista de usuarios con su rol y área actuales, editables mediante selects que solo
 * ofrecen los roles/áreas que ya existen (se crean en RolesPage) — nunca texto libre acá.
 *
 * `usuario_rol_area` exige rol_id y area_id juntos (ambos NOT NULL en la base real, ver
 * CLAUDE.md §6) — no existe una asignación con uno solo de los dos. Como acá son dos
 * selects independientes, la elección se junta en `pendientes` (estado local, no
 * persistido) y solo se manda al backend cuando el par queda completo o completamente
 * vacío (desasignar). Elegir uno solo del par se muestra pendiente hasta completar el otro.
 */
export default function PermisosPage() {
  const { usuarios, roles, areas, loading, error } = useSeguridadData()
  const [pendientes, setPendientes] = useState({})
  const [recargando, setRecargando] = useState(false)
  const [busqueda, setBusqueda] = useState('')
  const [rolFiltro, setRolFiltro] = useState('')

  const usuariosFiltrados = useMemo(() => {
    const termino = busqueda.trim().toLowerCase()

    return usuarios.filter((usuario) => {
      const valores = pendientes[usuario.id] ?? { rolId: usuario.rolId, areaId: usuario.areaId }

      if (rolFiltro && String(valores.rolId || '') !== rolFiltro) return false

      if (!termino) return true
      return (
        usuario.username?.toLowerCase().includes(termino) ||
        usuario.email?.toLowerCase().includes(termino)
      )
    })
  }, [usuarios, pendientes, busqueda, rolFiltro])

  const handleRecargar = async () => {
    setRecargando(true)
    try {
      await seguridadActions.recargar()
    } finally {
      setRecargando(false)
    }
  }

  const valoresDe = (usuario) => pendientes[usuario.id] ?? { rolId: usuario.rolId, areaId: usuario.areaId }

  const handleCambiar = async (usuario, campo, valor) => {
    const siguiente = { ...valoresDe(usuario), [campo]: valor }
    setPendientes((p) => ({ ...p, [usuario.id]: siguiente }))

    const completo = Boolean(siguiente.rolId) === Boolean(siguiente.areaId)
    if (!completo) return

    try {
      await seguridadActions.asignarRolArea(usuario.id, siguiente)
    } catch (err) {
      toast.error(err.message || 'No se pudo actualizar la asignación.')
    } finally {
      setPendientes((p) => {
        const { [usuario.id]: _omit, ...resto } = p
        return resto
      })
    }
  }

  if (loading) {
    return (
      <Card className="flex items-center justify-center gap-2 py-16 text-slate-500">
        <Spinner /> Cargando usuarios…
      </Card>
    )
  }

  if (error) {
    return (
      <Card>
        <Alert type="error" title="No se pudieron cargar los usuarios" message={error.message} />
      </Card>
    )
  }

  return (
    <Card>
      <div className="flex items-start justify-between gap-3">
        <SectionHeader icon={Users} eyebrow="Roles" title="Permisos de usuarios" className="flex-1" />
        <button
          type="button"
          onClick={handleRecargar}
          disabled={recargando}
          title="Vuelve a pedir la lista de usuarios al backend (por si alguien se logueó recién)"
          className="mt-1 flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${recargando ? 'animate-spin' : ''}`} />
          Recargar
        </button>
      </div>

      {usuarios.length === 0 ? (
        <EmptyState icon={Users} title="No hay usuarios para mostrar" />
      ) : (
        <>
          <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-end">
            <Input
              icon={Search}
              placeholder="Buscar por usuario o correo…"
              value={busqueda}
              onChange={(event) => setBusqueda(event.target.value)}
              containerClassName="flex-1"
            />
            <Select
              value={rolFiltro}
              onChange={(event) => setRolFiltro(event.target.value)}
              containerClassName="sm:w-56"
            >
              <option value="">Todos los roles</option>
              {roles.map((rol) => (
                <option key={rol.id} value={rol.id}>
                  {rol.nombre}
                </option>
              ))}
            </Select>
          </div>

          {usuariosFiltrados.length === 0 ? (
            <EmptyState
              icon={Search}
              title="Ningún usuario coincide con el filtro"
              className="py-12"
            />
          ) : (
            <div className="mt-4 overflow-x-auto rounded-2xl border border-slate-200/70">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wider text-slate-500">
                  <tr>
                    <th className="px-4 py-3">Usuario</th>
                    <th className="px-4 py-3">Correo</th>
                    <th className="px-4 py-3">Rol</th>
                    <th className="px-4 py-3">Área</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {usuariosFiltrados.map((usuario) => {
                    const valores = valoresDe(usuario)
                    const pendienteRol = Boolean(valores.areaId) && !valores.rolId
                    const pendienteArea = Boolean(valores.rolId) && !valores.areaId

                    return (
                      <tr key={usuario.id} className="bg-white/60">
                        <td className="px-4 py-3 font-mono font-medium text-slate-800">{usuario.username}</td>
                        <td className="px-4 py-3 text-slate-600">{usuario.email}</td>
                        <td className="px-4 py-3">
                          <Select
                            value={valores.rolId || ''}
                            onChange={(event) => handleCambiar(usuario, 'rolId', event.target.value)}
                            containerClassName="min-w-[160px]"
                          >
                            <option value="">Sin rol</option>
                            {roles.map((rol) => (
                              <option key={rol.id} value={rol.id}>
                                {rol.nombre}
                              </option>
                            ))}
                          </Select>
                          {pendienteRol && (
                            <p className="mt-1 text-xs text-amber-600">Elegí también un rol para guardar.</p>
                          )}
                        </td>
                        <td className="px-4 py-3">
                          <Select
                            value={valores.areaId || ''}
                            onChange={(event) => handleCambiar(usuario, 'areaId', event.target.value)}
                            containerClassName="min-w-[160px]"
                          >
                            <option value="">Sin área</option>
                            {areas.map((area) => (
                              <option key={area.id} value={area.id}>
                                {area.nombre}
                              </option>
                            ))}
                          </Select>
                          {pendienteArea && (
                            <p className="mt-1 text-xs text-amber-600">Elegí también un área para guardar.</p>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </Card>
  )
}
