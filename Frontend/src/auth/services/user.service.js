import { API_ENDPOINTS } from '@/core/config/endpoints.config'
import { httpClient } from '@/core/http/httpClient'

/**
 * Servicio de Usuario (User Profile Domain Service)
 * Encapsula la consulta de perfil de usuario y recursos privados protegidos por roles/token
 */
export const userService = {
  /**
   * Obtiene la información del perfil privado desde el backend (/api/private)
   * @param {string} [token] - Token opcional; si no se especifica, httpClient usará el token guardado
   * @returns {Promise<{ message: string, usuario: string, email: string, roles: string[], client_id: string }>}
   */
  async getProfile(token) {
    return httpClient.get(API_ENDPOINTS.USER.PRIVATE_PROFILE, { token })
  },

  /**
   * Cambia la contraseña del usuario autenticado.
   * TODO(equipo): pendiente el endpoint real en el backend (lo está armando otra persona).
   * Cuando exista, agregar su ruta a API_ENDPOINTS.USER y reemplazar este stub por el
   * httpClient.post correspondiente — la forma de la función ya queda lista para ese momento.
   * @param {{ currentPassword: string, newPassword: string }} _payload
   * @returns {Promise<void>}
   */
  async changePassword(_payload) {
    throw new Error('El cambio de contraseña todavía no está disponible: falta integrar el backend.')
  },
}
