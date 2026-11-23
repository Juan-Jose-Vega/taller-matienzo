// Notificaciones sin duplicados (clave_unica). Cada una lleva la ruta de la pantalla relacionada.
import { db, add } from './storageService.js';
import { ahora } from '../utils/dates.js';
import { rolCodigoDe } from './rolesService.js';

export function notify({ clave, tallerId = null, usuarioId = null, rol = null, texto, ruta = '/', tipo = 'info' }) {
  if (clave && db.notificaciones.some((n) => n.clave_unica === clave)) return false;
  add('notificaciones', { clave_unica: clave || null, taller_id: tallerId, usuario_id: usuarioId, rol_destino: rol, texto, ruta, tipo, leida: 0, created_at: ahora() });
  if (db.notificaciones.length > 500) db.notificaciones.splice(0, db.notificaciones.length - 500);
  return true;
}
export const delUsuario = (u) => (!u ? [] : db.notificaciones.filter((n) => n.usuario_id === u.id || (!n.usuario_id && n.rol_destino === rolCodigoDe(u) && (u.tipo_cuenta === 'superadmin' || n.taller_id === u.taller_id))).slice().sort((a, b) => b.id - a.id));
export const noLeidas = (u) => delUsuario(u).filter((n) => !n.leida).length;
export const marcarLeida = (id) => { const n = db.notificaciones.find((x) => x.id === Number(id)); if (n) n.leida = 1; return n; };
export const marcarTodas = (u) => delUsuario(u).forEach((n) => { n.leida = 1; });
