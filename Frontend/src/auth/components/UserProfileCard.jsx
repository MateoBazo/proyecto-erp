import { User, Mail, Shield, KeyRound } from 'lucide-react'
import { Card, Badge } from '@/shared/ui'

export function UserProfileCard({ user }) {
  return (
    <Card>
      <div className="mb-5 flex items-center gap-2.5 border-b border-slate-200/60 pb-3.5">
        <User className="h-5 w-5 text-accent-600" />
        <h3 className="text-sm font-semibold uppercase tracking-wider text-slate-800">
          Datos de la Sesión Actual
        </h3>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {/* Usuario */}
        <div className="rounded-2xl border border-slate-200/70 bg-white/60 p-4 shadow-xs backdrop-blur-sm">
          <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mb-1">
            <User className="h-3.5 w-3.5 text-accent-500" />
            <span>Nombre de Usuario</span>
          </div>
          <p className="text-base font-bold text-slate-900 font-mono">
            {user?.username || 'Usuario'}
          </p>
        </div>

        {/* Email */}
        <div className="rounded-2xl border border-slate-200/70 bg-white/60 p-4 shadow-xs backdrop-blur-sm">
          <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mb-1">
            <Mail className="h-3.5 w-3.5 text-accent-500" />
            <span>Correo Electrónico</span>
          </div>
          <p className="text-base font-medium text-slate-800">
            {user?.email || 'Sin correo asociado'}
          </p>
        </div>

        {/* Client ID */}
        <div className="rounded-2xl border border-slate-200/70 bg-white/60 p-4 shadow-xs backdrop-blur-sm">
          <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mb-1">
            <Shield className="h-3.5 w-3.5 text-accent-500" />
            <span>Cliente</span>
          </div>
          <p className="text-base font-mono font-medium text-slate-800">
            {user?.clientId || 'app-erp'}
          </p>
        </div>

        {/* Roles */}
        <div className="rounded-2xl border border-slate-200/70 bg-white/60 p-4 shadow-xs backdrop-blur-sm">
          <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mb-2">
            <KeyRound className="h-3.5 w-3.5 text-accent-500" />
            <span>Roles</span>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {user?.roles && user.roles.length > 0 ? (
              user.roles.map((role) => (
                <Badge key={role} variant="accent" className="font-mono">
                  {role}
                </Badge>
              ))
            ) : (
              <Badge variant="neutral" className="font-mono">
                roles-por-defecto
              </Badge>
            )}
          </div>
        </div>
      </div>
    </Card>
  )
}

export default UserProfileCard
