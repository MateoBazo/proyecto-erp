/**
 * Valida los campos del formulario de inicio de sesión
 * @param {{ username?: string, password?: string }} values
 * @returns {Record<string, string>}
 */
export function validateLoginForm(values) {
  const errors = {}

  if (!values?.username || !values.username.trim()) {
    errors.username = 'Ingresa tu nombre de usuario o correo.'
  }

  if (!values?.password) {
    errors.password = 'Ingresa tu contraseña.'
  }

  return errors
}
