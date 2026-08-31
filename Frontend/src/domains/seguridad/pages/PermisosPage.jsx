import { Users } from 'lucide-react'
import { Card, SectionHeader, Select, EmptyState } from '@/shared/ui'
import { useSeguridadData, seguridadActions } from '../data/seguridadStore'

/**
 * Lista de usuarios con su rol y área actuales, editables mediante selects que solo
 * ofrecen los roles/áreas que ya existen (se crean en RolesPage) — nunca texto libre acá.
 */
export default function PermisosPage() {
  const { usuarios, roles, areas } = useSeguridadData()

  return (
    <Card>
      <SectionHeader icon={Users} eyebrow="Roles" title="Permisos de usuarios" />

      {usuarios.length === 0 ? (
        <EmptyState icon={Users} title="No hay usuarios para mostrar" />
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-slate-200/70">
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
              {usuarios.map((usuario) => (
                <tr key={usuario.id} className="bg-white/60">
                  <td className="px-4 py-3 font-mono font-medium text-slate-800">{usuario.username}</td>
                  <td className="px-4 py-3 text-slate-600">{usuario.email}</td>
                  <td className="px-4 py-3">
                    <Select
                      value={usuario.rolId || ''}
                      onChange={(event) =>
                        seguridadActions.asignarRolArea(usuario.id, {
                          rolId: event.target.value,
                          areaId: usuario.areaId,
                        })
                      }
                      containerClassName="min-w-[160px]"
                    >
                      <option value="">Sin rol</option>
                      {roles.map((rol) => (
                        <option key={rol.id} value={rol.id}>
                          {rol.nombre}
                        </option>
                      ))}
                    </Select>
                  </td>
                  <td className="px-4 py-3">
                    <Select
                      value={usuario.areaId || ''}
                      onChange={(event) =>
                        seguridadActions.asignarRolArea(usuario.id, {
                          rolId: usuario.rolId,
                          areaId: event.target.value,
                        })
                      }
                      containerClassName="min-w-[160px]"
                    >
                      <option value="">Sin área</option>
                      {areas.map((area) => (
                        <option key={area.id} value={area.id}>
                          {area.nombre}
                        </option>
                      ))}
                    </Select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  )
}
