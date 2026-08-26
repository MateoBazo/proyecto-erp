import { API_ENDPOINTS } from '@/core/config/endpoints.config'
import { httpClient } from '@/core/http/httpClient'
import { storageService } from '@/core/storage/storageService'
import { extractUserFromToken, isTokenExpired } from '@/shared/utils/jwt.util'

/**
 * Servicio de Autenticación (Auth Domain Service)
 * Encapsula la lógica de negocio para autenticación, inicio de sesión y gestión de sesiones OIDC/Keycloak
 */
export const authService = {
  /**
   * Autentica al usuario contra el backend y Keycloak
   * @param {{ username: string, password: string }} credentials
   * @returns {Promise<{ access_token: string, token_type?: string, expires_in?: number, message?: string, user: object }>}
   */
  async login({ username, password }) {
    const trimmedUsername = username?.trim()

    const data = await httpClient.post(
      API_ENDPOINTS.AUTH.LOGIN,
      {
        username: trimmedUsername,
        password,
      },
      { requiresAuth: false }
    )

    const accessToken = data.access_token

    if (!accessToken) {
      throw new Error('No se recibió el token de acceso desde el servidor de autenticación.')
    }

    // Persistir token y username
    storageService.setToken(accessToken)
    if (trimmedUsername) {
      storageService.setUsername(trimmedUsername)
    }

    const user = extractUserFromToken(accessToken, trimmedUsername)

    return {
      ...data,
      user,
    }
  },

  /**
   * Cierra la sesión activa y elimina las credenciales locales
   */
  logout() {
    storageService.clearAuth()
  },

  /**
   * Obtiene y valida la sesión almacenada actualmente
   * @returns {{ token: string | null, user: object | null, isValid: boolean }}
   */
  getCurrentSession() {
    const token = storageService.getToken()
    const savedUsername = storageService.getUsername()

    if (!token || isTokenExpired(token)) {
      if (token) {
        storageService.clearAuth()
      }
      return { token: null, user: null, isValid: false }
    }

    const user = extractUserFromToken(token, savedUsername)
    return { token, user, isValid: true }
  },

  /**
   * Verifica si existe un token y no ha expirado
   * @returns {boolean}
   */
  isAuthenticated() {
    const token = storageService.getToken()
    return Boolean(token && !isTokenExpired(token))
  },
}
