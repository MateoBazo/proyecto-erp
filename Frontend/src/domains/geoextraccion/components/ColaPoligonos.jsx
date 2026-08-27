import { Layers, XCircle } from 'lucide-react'
import { Button, IconButton } from '@/shared/ui'

/**
 * Aviso de polígonos en cola pendientes de exportar como capa masiva.
 * Adaptado de la franja ámbar de geo-extract/frontend/src/pages/Capture.jsx.
 */
export function ColaPoligonos({ count, onExportar, onDescartar }) {
  if (count === 0) return null

  return (
    <div className="flex animate-pulse items-center rounded-xl border border-state-amber/30 bg-state-amber/10 px-4 py-2 shadow-xs">
      <Layers size={18} className="mr-2 text-state-amber" />
      <span className="text-[10px] font-black uppercase text-slate-700">{count} Polígonos en cola</span>
      <Button variant="warning" size="sm" onClick={onExportar} className="ml-4">
        EXPORTAR CAPA
      </Button>
      <IconButton icon={XCircle} size={16} tone="dangerActive" onClick={onDescartar} className="ml-2" />
    </div>
  )
}

export default ColaPoligonos
