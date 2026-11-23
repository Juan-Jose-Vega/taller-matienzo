// Interfaz de "mejora de redacción". HOY solo existe el proveedor LOCAL (reglas en el navegador, sin internet).
// El proveedor remoto es una interfaz preparada para el futuro y NO está configurado: no se simula ninguna llamada externa.
// IMPORTANTE: nunca colocar claves de IA en el código del navegador. Una IA real exige un backend que guarde la clave
// (ver docs/arquitectura.md, sección "IA real").
import { mejorarConReglas } from './ai/reglasLocales.js';
import { db, add } from './storageService.js';
import { ahora } from '../utils/dates.js';

export const proveedorLocal = {
  id: 'reglas_locales', tipo: 'local', nombre: 'Reglas locales (modo demostración)',
  descripcion: 'La corrección se hace con reglas en tu navegador. No se usa inteligencia artificial real ni se envía nada a internet.',
  disponible: true,
  async mejorar(texto, opciones) { return mejorarConReglas(texto, opciones); },
};
// Contrato para un proveedor real: { id, tipo:'remoto', nombre, disponible, mejorar(texto, opciones) -> Promise<{propuesta, ...}> }
// que llame a TU backend (POST /api/ia/mejorar). Mientras no exista backend, queda deshabilitado.
export const proveedorRemoto = {
  id: 'api_ia', tipo: 'remoto', nombre: 'Proveedor de IA real', descripcion: 'No configurado: requiere un backend.', disponible: false,
  async mejorar() { throw new Error('El proveedor de IA real no está configurado en este MVP.'); },
};
let activo = proveedorLocal;
export const proveedorActivo = () => activo;
export function usarProveedor(p) { if (p && p.disponible) activo = p; }

export async function mejorarTexto(texto, opciones = {}) {
  const t = String(texto || '').trim();
  if (!t) return { ok: false, error: 'Escribí un texto para mejorar.' };
  if (t.length > 2000) return { ok: false, error: 'El texto es demasiado largo (máximo 2000 caracteres).' };
  try { const r = await activo.mejorar(t, opciones); return Object.assign({ ok: true, original: t, proveedor: { id: activo.id, tipo: activo.tipo, nombre: activo.nombre } }, r); }
  catch (e) { return { ok: false, error: e.message || 'No se pudo mejorar el texto. Seguí escribiendo a mano.' }; }
}
// Guarda la decisión del usuario (aceptada / editada / descartada). El texto original NUNCA se pierde.
export function registrarPropuesta({ usuario, entidad, campo, original, propuesta, final, estado }) {
  return add('ia_propuestas', { taller_id: usuario.taller_id || null, usuario_id: usuario.id, entidad, entidad_id: null, campo, texto_original: original, texto_propuesto: propuesta, texto_final: final || null, estado, proveedor: activo.id, created_at: ahora() });
}
export function vincularPropuestas(ids, entidad, entidadId) { (ids || []).forEach((id) => { const p = db.ia_propuestas.find((x) => x.id === id); if (p) { p.entidad = entidad; p.entidad_id = entidadId; } }); }
