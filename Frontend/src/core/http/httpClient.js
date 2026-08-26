import { ENV } from '@/core/config/env.config'
import { ApiError } from '@/core/errors/ApiError'
import { storageService } from '@/core/storage/storageService'

/**
 * Cliente HTTP base para comunicación con servicios Backend y Keycloak
 * Encapsula la configuración de cabeceras, interceptores de autenticación y manejo estándar de errores
 */
class HttpClient {
  constructor(baseUrl = ENV.API_BASE_URL) {
    this.baseUrl = baseUrl
  }

  /**
   * Realiza una petición HTTP genérica
   * @param {string} endpoint - Ruta relativa o URL absoluta
   * @param {RequestInit & { requiresAuth?: boolean, token?: string }} [options]
   * @returns {Promise<any>}
   */
  async request(endpoint, options = {}) {
    const { requiresAuth = true, token, headers = {}, body, responseType, ...customConfig } = options

    const url = endpoint.startsWith('http') ? endpoint : `${this.baseUrl}${endpoint}`

    const requestHeaders = new Headers(headers)

    if (!requestHeaders.has('Content-Type') && !(body instanceof FormData)) {
      requestHeaders.set('Content-Type', 'application/json')
    }

    // Inyección de token de autenticación
    if (requiresAuth) {
      const authToken = token || storageService.getToken()
      if (authToken) {
        requestHeaders.set('Authorization', `Bearer ${authToken}`)
      }
    }

    const config = {
      ...customConfig,
      headers: requestHeaders,
    }

    if (body !== undefined) {
      config.body = typeof body === 'object' && !(body instanceof FormData) ? JSON.stringify(body) : body
    }

    let response
    try {
      response = await fetch(url, config)
    } catch (networkError) {
      throw new ApiError(
        'No se pudo conectar con el servidor backend. Verifica que esté en ejecución.',
        null,
        networkError
      )
    }

    // Respuesta binaria (ej. descarga de un ZIP/Shapefile) — no se intenta parsear como JSON/texto
    if (responseType === 'blob') {
      if (!response.ok) {
        if (response.status === 401 && requiresAuth) this._handleUnauthorized()
        throw new ApiError(`Error en la petición: ${response.status} ${response.statusText}`, response.status)
      }
      return response.blob()
    }

    // Procesar respuesta JSON o texto
    let responseData
    const contentType = response.headers.get('content-type')
    if (contentType && contentType.includes('application/json')) {
      try {
        responseData = await response.json()
      } catch {
        responseData = null
      }
    } else {
      try {
        responseData = await response.text()
      } catch {
        responseData = null
      }
    }

    // Manejo de errores HTTP
    if (!response.ok) {
      // Token ausente/expirado/inválido: no hay flujo de refresh, así que la sesión
      // ya no es válida — se limpia y se fuerza volver a Login en vez de dejar que
      // cada pantalla reciba un 401 crudo sin poder recuperarse.
      if (response.status === 401 && requiresAuth) {
        this._handleUnauthorized()
        throw new ApiError('Tu sesión expiró. Vuelve a iniciar sesión.', 401, responseData)
      }

      const errorMessage =
        (typeof responseData === 'object' && (responseData?.detail || responseData?.message)) ||
        (typeof responseData === 'string' && responseData) ||
        `Error en la petición: ${response.status} ${response.statusText}`

      throw new ApiError(errorMessage, response.status, responseData)
    }

    return responseData
  }

  /** Limpia la sesión inválida y redirige a Login (no hay flujo de refresh de token). */
  _handleUnauthorized() {
    storageService.clearAuth()
    if (typeof window !== 'undefined' && window.location.pathname !== '/') {
      window.location.href = '/'
    }
  }

  get(endpoint, options = {}) {
    return this.request(endpoint, { ...options, method: 'GET' })
  }

  post(endpoint, body, options = {}) {
    return this.request(endpoint, { ...options, method: 'POST', body })
  }

  put(endpoint, body, options = {}) {
    return this.request(endpoint, { ...options, method: 'PUT', body })
  }

  delete(endpoint, options = {}) {
    return this.request(endpoint, { ...options, method: 'DELETE' })
  }
}

export const httpClient = new HttpClient()
export { HttpClient }
