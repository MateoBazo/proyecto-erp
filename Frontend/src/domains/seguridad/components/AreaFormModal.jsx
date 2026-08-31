import { useState } from 'react'
import { Building2 } from 'lucide-react'
import { toast } from 'react-toastify'
import { Modal, Input, Button } from '@/shared/ui'
import { seguridadActions } from '../data/seguridadStore'

/** Crea un área nueva — el nombre siempre se escribe a mano. */
export function AreaFormModal({ open, onClose }) {
  const [nombre, setNombre] = useState('')

  const handleSubmit = (event) => {
    event.preventDefault()

    if (!nombre.trim()) {
      toast.warn('El área necesita un nombre.')
      return
    }

    seguridadActions.crearArea(nombre.trim())
    toast.success(`Área "${nombre.trim()}" creada.`)
    setNombre('')
    onClose()
  }

  return (
    <Modal open={open} onClose={onClose} title="Nueva área" icon={Building2}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label="Nombre del área"
          value={nombre}
          onChange={(event) => setNombre(event.target.value)}
          placeholder="Ej. Recursos Humanos"
          autoFocus
        />

        <div className="flex justify-end gap-2 pt-1">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancelar
          </Button>
          <Button type="submit">Crear área</Button>
        </div>
      </form>
    </Modal>
  )
}

export default AreaFormModal
