import { useEffect, useState, useMemo, useRef, useCallback } from 'react'
import { AuthContext } from './AuthContext'
import { authService } from '@/auth/services/auth.service'
import { userService } from '@/auth/services/user.service'
import { storageService } from '@/core/storage/storageService'
import { parseJwt } from '@/shared/utils/jwt.util'

// Margen antes del `exp` del access_token para disparar el refresh silencioso
const REFRESH_MARGIN_MS = 60_000
// Piso de seguridad: nunca reintentar más seguido que esto (evita loops si expires_in es muy corto)
const MIN_REFRESH_DELAY_MS = 5_000

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => authService.getCurrentSession().token)
  const [user, setUser] = useState(() => authService.getCurrentSession().user)
  const [isLoading, setIsLoading] = useState(true)
  const refreshTimerRef = useRef(null)
  // Contiene la última versión de scheduleSilentRefresh para poder invocarla
  // recursivamente desde dentro del propio setTimeout sin una referencia circular.
  const scheduleSilentRefreshRef = useRef(() => {})

  const clearRefreshTimer = useCallback(() => {
    if (refreshTimerRef.current) {
      clearTimeout(refreshTimerRef.current)
      refreshTimerRef.current = null
    }
  }, [])

  // Programa una renovación silenciosa del access_token un poco antes de que expire,
  // para que sesiones largas sin llamadas al backend (ej. digitalizando polígonos)
  // no terminen expulsando al usuario a mitad de camino.
  const scheduleSilentRefresh = useCallback(
    (currentToken) => {
      clearRefreshTimer()

      const payload = parseJwt(currentToken)
      if (!payload?.exp) return

      const msUntilExpiry = payload.exp * 1000 - Date.now()
      const delay = Math.max(msUntilExpiry - REFRESH_MARGIN_MS, MIN_REFRESH_DELAY_MS)

      refreshTimerRef.current = setTimeout(async () => {
        try {
          const result = await authService.refreshSession()
          setToken(result.access_token)
          setUser((prev) => result.user || prev)
          scheduleSilentRefreshRef.current(result.access_token)
        } catch {
          // El refresh_token también expiró o no hay conectividad: se deja que la
          // próxima petición real al backend dispare el flujo reactivo de httpClient.
        }
      }, delay)
    },
    [clearRefreshTimer]
  )

  useEffect(() => {
    scheduleSilentRefreshRef.current = scheduleSilentRefresh
  }, [scheduleSilentRefresh])

  // Sincronizar estado inicial y validar token con el backend al montar
  useEffect(() => {
    let isMounted = true

    async function initAuth() {
      let session = authService.getCurrentSession()

      // El access_token expiró (ej. la pestaña estuvo cerrada/inactiva) pero puede
      // que el refresh_token siga vigente: se intenta restaurar la sesión sin pedir login.
      if (!session.isValid && storageService.getRefreshToken()) {
        try {
          const result = await authService.refreshSession()
          session = { token: result.access_token, user: result.user, isValid: true }
        } catch {
          authService.logout()
        }
      }

      if (!session.isValid || !session.token) {
        authService.logout()
        if (isMounted) {
          setToken(null)
          setUser(null)
          setIsLoading(false)
        }
        return
      }

      try {
        const profile = await userService.getProfile(session.token)
        if (isMounted) {
          setUser({
            username: profile.usuario || session.user?.username || 'Usuario',
            email: profile.email || '',
            roles: profile.roles || [],
            clientId: profile.client_id || session.user?.clientId || 'app-erp',
          })
          setToken(session.token)
          scheduleSilentRefresh(session.token)
        }
      } catch {
        if (isMounted) {
          if (session.user) {
            setUser(session.user)
            setToken(session.token)
            scheduleSilentRefresh(session.token)
          } else {
            authService.logout()
            setToken(null)
            setUser(null)
          }
        }
      } finally {
        if (isMounted) {
          setIsLoading(false)
        }
      }
    }

    initAuth()

    return () => {
      isMounted = false
      clearRefreshTimer()
    }
  }, [scheduleSilentRefresh, clearRefreshTimer])

  const login = useCallback(
    async ({ username, password }) => {
      const result = await authService.login({ username, password })
      setToken(result.access_token)
      setUser(result.user)
      scheduleSilentRefresh(result.access_token)
      return result
    },
    [scheduleSilentRefresh]
  )

  const logout = useCallback(() => {
    clearRefreshTimer()
    authService.logout()
    setToken(null)
    setUser(null)
  }, [clearRefreshTimer])

  const value = useMemo(
    () => ({
      user,
      token,
      isAuthenticated: Boolean(token && authService.isAuthenticated()),
      isLoading,
      login,
      logout,
      setUser,
    }),
    [user, token, isLoading, login, logout]
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export default AuthProvider
