import { useSyncExternalStore } from 'react'
import { ROLES_INICIALES, AREAS_INICIALES, USUARIOS_INICIALES } from './mockSeguridad'

/**
 * Store en memoria del dominio seguridad — mock local mientras no exista el backend real
 * (roles, áreas y usuario_rol_area en la base). Vive como singleton de módulo, fuera del
 * árbol de React, para que PermisosPage y RolesPage compartan el mismo estado aunque el
 * router desmonte una página al navegar a la otra. Se pierde al recargar la pestaña — es
 * intencional, es solo para poder trabajar el front antes de que el backend exista.
 */
let state = {
  roles: ROLES_INICIALES,
  areas: AREAS_INICIALES,
  usuarios: USUARIOS_INICIALES,
}
const listeners = new Set()

function setState(updater) {
  state = { ...state, ...updater(state) }
  listeners.forEach((listener) => listener())
}

function subscribe(listener) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

export function useSeguridadData() {
  return useSyncExternalStore(subscribe, () => state)
}

export const seguridadActions = {
  crearRol(nombre, permisos = []) {
    setState((s) => ({
      roles: [...s.roles, { id: crypto.randomUUID(), nombre, permisos }],
    }))
  },
  actualizarPermisosRol(rolId, permisos) {
    setState((s) => ({
      roles: s.roles.map((r) => (r.id === rolId ? { ...r, permisos } : r)),
    }))
  },
  eliminarRol(rolId) {
    setState((s) => ({
      roles: s.roles.filter((r) => r.id !== rolId),
      // Limpia el rol de cualquier usuario que lo tuviera asignado para no dejar
      // referencias colgadas (PermisosPage lo mostraría como "Sin rol").
      usuarios: s.usuarios.map((u) => (u.rolId === rolId ? { ...u, rolId: '' } : u)),
    }))
  },
  crearArea(nombre) {
    setState((s) => ({
      areas: [...s.areas, { id: crypto.randomUUID(), nombre }],
    }))
  },
  actualizarArea(areaId, nombre) {
    setState((s) => ({
      areas: s.areas.map((a) => (a.id === areaId ? { ...a, nombre } : a)),
    }))
  },
  eliminarArea(areaId) {
    setState((s) => ({
      areas: s.areas.filter((a) => a.id !== areaId),
      // Limpia el área de cualquier usuario que la tuviera asignada para no dejar
      // referencias colgadas (PermisosPage la mostraría como "Sin área").
      usuarios: s.usuarios.map((u) => (u.areaId === areaId ? { ...u, areaId: '' } : u)),
    }))
  },
  asignarRolArea(usuarioId, { rolId, areaId }) {
    setState((s) => ({
      usuarios: s.usuarios.map((u) => (u.id === usuarioId ? { ...u, rolId, areaId } : u)),
    }))
  },
}
