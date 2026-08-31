import escudoGamc from '@/assets/escudo-gamc.png'

/**
 * Identidad institucional (logo) del ERP — fuente única de verdad para que Header,
 * LoginPage y cualquier otra pantalla que necesite mostrar el escudo lo hagan desde
 * un solo lugar. Nombre de app/organización van en core/config/env.config (ENV).
 * Cambiar el logo (archivo, alt) se hace acá una sola vez.
 */
export const BRAND = {
  logoSrc: escudoGamc,
  logoAlt: 'Escudo del Gobierno Autónomo Municipal de Cochabamba',
}
