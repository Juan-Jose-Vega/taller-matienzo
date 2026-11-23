// Autenticación SIMULADA (sin servidor). Los accesos de taller y de SuperAdmin están totalmente separados.
// Nada de esto es seguridad real: cualquiera con acceso al navegador puede leer el localStorage.
import { reactive, computed } from 'vue';
import { db, add, get, leerRaw, escribirRaw, KEY_SESION } from './storageService.js';
import { hashClave } from '../utils/hash.js';
import { ahora } from '../utils/dates.js';
import { log } from './auditService.js';
import { ROL_PERMISOS, PERMISOS_SUPERADMIN } from '../config/permisos.js';
import { rolCodigoDe } from './rolesService.js';

function leerSesion() { try { const s = JSON.parse(leerRaw(KEY_SESION) || 'null'); return s && s.usuario_id ? s : { usuario_id: null, ambito: null }; } catch (e) { return { usuario_id: null, ambito: null }; } }
export const sesion = reactive(leerSesion());
const fijar = (u, ambito) => { sesion.usuario_id = u ? u.id : null; sesion.ambito = u ? ambito : null; escribirRaw(KEY_SESION, u ? JSON.stringify({ usuario_id: u.id, ambito }) : null); };

export const usuario = computed(() => { const u = sesion.usuario_id ? db.usuarios.find((x) => x.id === sesion.usuario_id) : null; return u && u.estado !== 'inactivo' ? u : null; });
export const rol = computed(() => rolCodigoDe(usuario.value));
export const esSuperAdmin = computed(() => rol.value === 'superadmin' && sesion.ambito === 'superadmin');
export const esTaller = computed(() => (rol.value === 'admin' || rol.value === 'mecanico') && sesion.ambito === 'taller');
export const tallerId = computed(() => (esTaller.value ? usuario.value.taller_id : null));
export const taller = computed(() => (tallerId.value ? get('talleres', tallerId.value) : null));
export const mecanicoActual = computed(() => (rol.value === 'mecanico' ? db.mecanicos.find((m) => m.usuario_id === usuario.value.id) : null));
export const can = (permiso) => !!rol.value && (rol.value === 'superadmin' ? PERMISOS_SUPERADMIN : ROL_PERMISOS[rol.value] || []).includes(permiso);

function intento(ingresado, exito, ambito) { add('intentos_acceso', { usuario_ingresado: String(ingresado).slice(0, 40), ambito, exito: exito ? 1 : 0, created_at: ahora() }); }
const GENERICO = 'Usuario o contraseña incorrectos. Revisá los datos e intentá de nuevo.';
function buscar(nombre, clave) {
  const u = db.usuarios.find((x) => x.usuario.toLowerCase() === String(nombre).toLowerCase());
  return u && u.password_hash === hashClave(u.usuario, clave) ? u : null;
}
export function ingresarTaller(nombre, clave) {
  if (!nombre) return { ok: false, campo: 'usuario', error: 'Escribí tu usuario.' };
  if (!clave) return { ok: false, campo: 'clave', error: 'Escribí tu contraseña.' };
  const u = buscar(nombre, clave);
  if (!u || u.tipo_cuenta === 'superadmin') { intento(nombre, false, 'taller'); log('Intento de acceso fallido', `Usuario ingresado: ${nombre}`, { ambito: 'sistema', taller_id: null }); return { ok: false, error: GENERICO }; }
  if (u.estado === 'inactivo') return { ok: false, error: 'Tu cuenta está desactivada. Pedile al dueño del taller que la active.' };
  intento(nombre, true, 'taller'); u.ultimo_acceso = ahora(); fijar(u, 'taller'); log('Inicio de sesión', '', { usuario: u }); return { ok: true, usuario: u };
}
export function ingresarSuperAdmin(nombre, clave) {
  if (!nombre) return { ok: false, campo: 'usuario', error: 'Escribí el usuario.' };
  if (!clave) return { ok: false, campo: 'clave', error: 'Escribí la contraseña.' };
  const u = buscar(nombre, clave); const sa = u && db.superadmins.find((s) => s.usuario_id === u.id && s.estado === 'activo');
  if (!u || u.tipo_cuenta !== 'superadmin' || !sa || u.estado !== 'activo') { intento(nombre, false, 'superadmin'); log('Intento de acceso fallido al panel de administración', `Usuario: ${nombre}`, { ambito: 'sistema', taller_id: null }); return { ok: false, error: GENERICO }; }
  intento(nombre, true, 'superadmin'); u.ultimo_acceso = ahora(); fijar(u, 'superadmin'); log('Inicio de sesión (administración)', '', { ambito: 'sistema', usuario: u, taller_id: null }); return { ok: true, usuario: u };
}
export function salir() { const u = usuario.value; if (u) log('Cierre de sesión', '', { ambito: rol.value === 'superadmin' ? 'sistema' : 'taller', usuario: u, taller_id: rol.value === 'superadmin' ? null : u.taller_id }); fijar(null); }
export function cambiarClave(actual, nueva) {
  const u = usuario.value;
  if (!u.debe_cambiar_clave && u.password_hash !== hashClave(u.usuario, actual)) return { ok: false, error: 'La contraseña actual no es correcta.' };
  if (u.password_hash === hashClave(u.usuario, nueva)) return { ok: false, error: 'La nueva contraseña debe ser distinta de la actual.' };
  u.password_hash = hashClave(u.usuario, nueva); u.debe_cambiar_clave = 0; log('Cambió su contraseña', '', { ambito: rol.value === 'superadmin' ? 'sistema' : 'taller', usuario: u, taller_id: rol.value === 'superadmin' ? null : u.taller_id }); return { ok: true };
}
export function claveTemporal() { const a = 'abcdefghjkmnpqrstuvwxyz'; let s = 'Tm'; for (let i = 0; i < 5; i++) s += a[Math.floor(Math.random() * a.length)]; return s + String(Math.floor(1000 + Math.random() * 9000)); }
export function restablecerClave(usuarioId) { const u = get('usuarios', usuarioId); const c = claveTemporal(); u.password_hash = hashClave(u.usuario, c); u.debe_cambiar_clave = 1; return c; }
export { rolCodigoDe };
