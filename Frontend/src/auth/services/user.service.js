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
}
