import { db, add } from './storageService.js';
import { ahora } from '../utils/dates.js';
// ambito 'sistema': lo ve el SuperAdmin. ambito 'taller': solo el taller (el SuperAdmin NO ve datos privados de talleres).
export function log(accion, detalle = '', { ambito = 'taller', entidad = null, entidad_id = null, usuario = null, taller_id } = {}) {
  add('auditoria', { usuario_id: usuario ? usuario.id : null, taller_id: taller_id !== undefined ? taller_id : (usuario ? usuario.taller_id : null), ambito, accion, entidad, entidad_id, detalle, created_at: ahora() });
  if (db.auditoria.length > 800) db.auditoria.splice(0, db.auditoria.length - 800);
}
