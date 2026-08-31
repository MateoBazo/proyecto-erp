import { useState } from 'react'
import { Building2 } from 'lucide-react'
import { toast } from 'react-toastify'
import { Modal, Input, Button } from '@/shared/ui'
import { seguridadActions } from '../data/seguridadStore'

/**
 * Crea un área nueva o renombra una existente — el nombre siempre se escribe a mano.
 *
 * El padre debe montar esto con una `key` que cambie en cada apertura (ver RolesPage), así
 * el formulario arranca con el nombre correcto (vacío al crear, el actual al editar) sin
 * necesitar un efecto que resetee el estado.
 */
export function AreaFormModal({ open, onClose, area }) {
  const isEdicion = Boolean(area)
  const [nombre, setNombre] = useState(area?.nombre || '')

  const handleSubmit = (event) => {
    event.preventDefault()

    const limpio = nombre.trim()
    if (!limpio) {
      toast.warn('El área necesita un nombre.')
      return
    }

    if (isEdicion) {
      seguridadActions.actualizarArea(area.id, limpio)
      toast.success(`Área "${limpio}" actualizada.`)
    } else {
      seguridadActions.crearArea(limpio)
      toast.success(`Área "${limpio}" creada.`)
    }

    onClose()
  }

  return (
    <Modal open={open} onClose={onClose} title={isEdicion ? 'Editar área' : 'Nueva área'} icon={Building2}>
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
          <Button type="submit">{isEdicion ? 'Guardar cambios' : 'Crear área'}</Button>
        </div>
      </form>
    </Modal>
  )
}

export default AreaFormModal
