// Estado de la interfaz: avisos (toasts), confirmaciones, clave temporal y tema claro/oscuro.
import { reactive } from 'vue';
import { leerRaw, escribirRaw, KEY_TEMA } from './storageService.js';
export const ui = reactive({ toasts: [], confirmacion: null, clave: null, bell: false, tema: leerRaw(KEY_TEMA) || 'claro', wa: null });
let n = 0;
export function toast(texto, tipo = '') { const id = ++n; ui.toasts.push({ id, texto, tipo }); setTimeout(() => { const i = ui.toasts.findIndex((t) => t.id === id); if (i >= 0) ui.toasts.splice(i, 1); }, tipo === 'error' ? 5200 : 3200); }
// confirmar({mensaje, ok, cls}) -> Promise<boolean>
export function confirmar({ mensaje, ok = 'Confirmar', cls = '', titulo = 'Confirmá la acción' }) { return new Promise((res) => { ui.confirmacion = { mensaje, ok, cls, titulo, res }; }); }
export function responderConfirmacion(v) { const c = ui.confirmacion; ui.confirmacion = null; if (c) c.res(v); }
export const mostrarClave = (titulo, usuario, clave) => { ui.clave = { titulo, usuario, clave }; };
export function aplicarTema() { document.documentElement.setAttribute('data-tema', ui.tema); }
export function alternarTema() { ui.tema = ui.tema === 'oscuro' ? 'claro' : 'oscuro'; escribirRaw(KEY_TEMA, ui.tema); aplicarTema(); }
export const abrirWhatsapp = (tel, texto, titulo) => { ui.wa = { tel, texto, titulo: titulo || 'Mensaje de WhatsApp' }; };
