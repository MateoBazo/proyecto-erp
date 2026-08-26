/**
 * Catálogo de endpoints de la API (Arquitectura orientada a servicios)
 */
export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/api/login',
  },
  USER: {
    PRIVATE_PROFILE: '/api/private',
  },
  SYSTEM: {
    PUBLIC_HEALTH: '/api/public',
  },
  GEOEXTRACCION: {
    GENERAR_SHAPEFILE: '/api/geoextraccion/shapefiles',
    FUSIONAR_SHAPEFILES: '/api/geoextraccion/shapefiles/fusiones',
  },
}
