import { useEffect, useState, useMemo } from 'react'
import { AuthContext } from './AuthContext'
import { authService } from '@/auth/services/auth.service'
import { userService } from '@/auth/services/user.service'

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => authService.getCurrentSession().token)
  const [user, setUser] = useState(() => authService.getCurrentSession().user)
  const [isLoading, setIsLoading] = useState(true)

  // Sincronizar estado inicial y validar token con el backend al montar
  useEffect(() => {
    let isMounted = true

    async function initAuth() {
      const session = authService.getCurrentSession()

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
        }
      } catch {
        if (isMounted) {
          if (session.user) {
            setUser(session.user)
            setToken(session.token)
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
    }
  }, [])

  const login = async ({ username, password }) => {
    const result = await authService.login({ username, password })
    setToken(result.access_token)
    setUser(result.user)
    return result
  }

  const logout = () => {
    authService.logout()
    setToken(null)
    setUser(null)
  }

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
    [user, token, isLoading]
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export default AuthProvider
