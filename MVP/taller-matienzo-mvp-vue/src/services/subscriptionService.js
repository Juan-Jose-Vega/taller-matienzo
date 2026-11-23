// Suscripciones y pagos DEL SISTEMA (no confundir con los pagos que cobra el taller a sus clientes).
import { db, add, get } from './storageService.js';
import { hoy, addMeses, addDias, fecha } from '../utils/dates.js';
import { money, num } from '../utils/formatters.js';
import { estadoSuscripcion, hitoAviso, renovar } from './subscriptionRules.js';
import { notify } from './notificationService.js';
import { log } from './auditService.js';
import { ahora } from '../utils/dates.js';
import { hashClave } from '../utils/hash.js';
import { MODALIDADES } from '../config/permisos.js';
import { rolId } from './rolesService.js';

export const param = (clave, def) => { const p = db.parametros_sistema.find((x) => x.clave === clave); return p ? Number(p.valor) : def; };
export const suscripcionDe = (tallerId) => db.suscripciones.find((s) => s.taller_id === Number(tallerId)) || null;
export function estadoTaller(tallerId, hoyIso = hoy()) {
  const s = suscripcionDe(tallerId); const t = get('talleres', tallerId); if (!s || !t) return null;
  return Object.assign(estadoSuscripcion({ vencimiento: s.fecha_vencimiento, hoy: hoyIso, suspendida: t.estado === 'suspendido', gracia: param('dias_gracia', 3), aviso: param('dias_aviso', 7) }), { suscripcion: s });
}
export const tallerBloqueado = (tallerId) => { const e = estadoTaller(tallerId); return !!(e && e.bloqueado); };

// Genera avisos UNA sola vez por hito (clave única). Se llama al abrir la app y al iniciar sesión.
export function sincronizar() {
  db.talleres.forEach((t) => {
    const e = estadoTaller(t.id); if (!e || e.estado === 'suspendida') return;
    const hito = hitoAviso(e, param('dias_aviso', 7)); if (!hito) return;
    const key = `sub:${t.id}:${e.vencimiento}:${hito}`;
    notify({ clave: key, tallerId: t.id, rol: 'admin', texto: e.msg, ruta: '/suscripcion', tipo: hito === 'vencido' || hito === 'bloqueado' ? 'vencida' : 'porvencer' });
    if (['hoy', 'vencido', 'bloqueado'].includes(hito)) notify({ clave: key + ':sa', rol: 'superadmin', texto: `${t.nombre}: ${hito === 'bloqueado' ? 'acceso restringido por falta de pago' : hito === 'hoy' ? 'su plan vence hoy' : 'plan vencido, en período de gracia'}.`, ruta: '/superadmin/cuentas/' + t.id, tipo: 'vencida' });
  });
}

const sumaMedios = (m) => m.reduce((s, x) => s + x.importe, 0);
// medios: [{medio_id, importe}]
function validarMedios(importePlan, medioCodigo, efectivo, transferencia, referencia) {
  let medios;
  if (medioCodigo === 'efectivo') medios = [{ medio_id: 1, importe: importePlan }];
  else if (medioCodigo === 'transferencia') medios = [{ medio_id: 2, importe: importePlan }];
  else {
    const e = num(efectivo); const tr = num(transferencia);
    if (e <= 0 || tr <= 0) return { error: 'En un pago combinado indicá un importe en efectivo y otro por transferencia.' };
    if (Math.abs(e + tr - importePlan) > 0.009) return { error: `La suma (${money(e + tr)}) debe ser igual al importe del plan (${money(importePlan)}).` };
    medios = [{ medio_id: 1, importe: e }, { medio_id: 2, importe: tr }];
  }
  if (medios.some((m) => m.medio_id === 2) && !referencia) return { error: 'Indicá la referencia de la transferencia.' };
  return { medios };
}
export const mediosDePago = (pagoId) => db.pago_suscripcion_medios.filter((m) => m.pago_id === pagoId);
export const pendienteDe = (tallerId) => db.pagos_suscripcion.find((p) => p.taller_id === Number(tallerId) && ['pendiente', 'registrado'].includes(p.estado));

function nuevoPago(tallerId, origen, estado, v, usuario) {
  const s = suscripcionDe(tallerId);
  const p = add('pagos_suscripcion', { taller_id: s.taller_id, suscripcion_id: s.id, importe: s.importe, estado, origen, referencia: v.referencia || null, periodo_venc: s.fecha_vencimiento, fecha: hoy(), registrado_por: usuario.id, decidido_por: null, fecha_decision: null, nuevo_vencimiento: null, motivo_rechazo: null });
  v.medios.forEach((m) => add('pago_suscripcion_medios', { pago_id: p.id, medio_id: m.medio_id, importe: m.importe }));
  return p;
}
// El dueño informa un pago: queda PENDIENTE hasta que el SuperAdmin lo confirme.
export function informarPago(usuario, f) {
  const s = suscripcionDe(usuario.taller_id);
  if (pendienteDe(usuario.taller_id)) return { ok: false, error: 'Ya hay un pago pendiente de confirmación.' };
  const v = validarMedios(s.importe, f.medio, f.efectivo, f.transferencia, f.referencia); if (v.error) return { ok: false, error: v.error };
  const p = nuevoPago(usuario.taller_id, 'dueno', 'pendiente', { medios: v.medios, referencia: f.referencia }, usuario);
  log('Informó el pago de su suscripción', money(s.importe), { usuario, entidad: 'pagos_suscripcion', entidad_id: p.id });
  log('Un taller informó un pago', `${get('talleres', usuario.taller_id).nombre}: ${money(s.importe)}`, { ambito: 'sistema', usuario, taller_id: null, entidad: 'pagos_suscripcion', entidad_id: p.id });
  notify({ rol: 'superadmin', texto: `${get('talleres', usuario.taller_id).nombre} informó un pago de ${money(s.importe)} pendiente de confirmación.`, ruta: '/superadmin/pagos', tipo: 'pago' });
  return { ok: true, pago: p };
}
// El SuperAdmin registra un pago (efectivo en mano, etc.): queda REGISTRADO; después se confirma.
export function registrarPagoSA(superadmin, tallerId, f) {
  const s = suscripcionDe(tallerId); const v = validarMedios(s.importe, f.medio, f.efectivo, f.transferencia, f.referencia); if (v.error) return { ok: false, error: v.error };
  const p = nuevoPago(tallerId, 'superadmin', 'registrado', { medios: v.medios, referencia: f.referencia }, superadmin);
  log('Registró un pago de suscripción', `${get('talleres', tallerId).nombre}: ${money(s.importe)}`, { ambito: 'sistema', usuario: superadmin, taller_id: null, entidad: 'pagos_suscripcion', entidad_id: p.id });
  return { ok: true, pago: p };
}
// Confirma y renueva UNA sola vez (idempotente): un pago confirmado nunca renueva dos veces.
export function confirmarPago(superadmin, pagoId) {
  const p = get('pagos_suscripcion', pagoId); if (!p) return { ok: false, error: 'No se encontró el pago.' };
  if (p.estado === 'confirmado') return { ok: false, error: 'Este pago ya estaba confirmado.' };
  if (p.estado === 'rechazado') return { ok: false, error: 'Este pago fue rechazado.' };
  if (db.periodos_suscripcion.some((x) => x.pago_id === p.id)) return { ok: false, error: 'Este pago ya renovó la suscripción.' };
  const s = get('suscripciones', p.suscripcion_id); const e = estadoTaller(p.taller_id);
  if (p.periodo_venc !== s.fecha_vencimiento) return { ok: false, error: 'Este pago corresponde a un período que ya fue renovado. Rechazalo o ignoralo.' };
  const n = renovar({ inicio: s.fecha_inicio, vencimiento: s.fecha_vencimiento, diaAncla: s.dia_ancla, duracionMeses: s.duracion_meses, bloqueado: e.estado === 'bloqueado', hoy: hoy() });
  add('periodos_suscripcion', { suscripcion_id: s.id, pago_id: p.id, desde: n.inicio, hasta: n.vencimiento, created_at: ahora() });
  s.fecha_inicio = n.inicio; s.fecha_vencimiento = n.vencimiento; s.dia_ancla = n.diaAncla;
  p.estado = 'confirmado'; p.decidido_por = db.superadmins.find((x) => x.usuario_id === superadmin.id).id; p.fecha_decision = hoy(); p.nuevo_vencimiento = n.vencimiento;
  const t = get('talleres', p.taller_id);
  notify({ clave: `pagosis:${p.id}:conf`, tallerId: t.id, rol: 'admin', texto: `Tu pago de ${money(p.importe)} fue confirmado. Tu plan vence el ${fecha(n.vencimiento)}.`, ruta: '/suscripcion', tipo: 'pago' });
  log('Confirmó un pago de suscripción', `${t.nombre}: ${money(p.importe)} → vence ${fecha(n.vencimiento)}`, { ambito: 'sistema', usuario: superadmin, taller_id: null, entidad: 'pagos_suscripcion', entidad_id: p.id });
  return { ok: true };
}
export function rechazarPago(superadmin, pagoId, motivo) {
  const p = get('pagos_suscripcion', pagoId); if (!p) return { ok: false, error: 'No se encontró el pago.' };
  if (['confirmado', 'rechazado'].includes(p.estado)) return { ok: false, error: 'Ese pago ya estaba resuelto.' };
  if (!motivo || motivo.trim().length < 3) return { ok: false, error: 'Escribí el motivo.' };
  p.estado = 'rechazado'; p.motivo_rechazo = motivo.trim(); p.fecha_decision = hoy(); p.decidido_por = db.superadmins.find((x) => x.usuario_id === superadmin.id).id;
  const t = get('talleres', p.taller_id);
  notify({ clave: `pagosis:${p.id}:rech`, tallerId: t.id, rol: 'admin', texto: `Tu pago de ${money(p.importe)} fue rechazado: ${p.motivo_rechazo}.`, ruta: '/suscripcion', tipo: 'pago' });
  log('Rechazó un pago de suscripción', `${t.nombre}: ${p.motivo_rechazo}`, { ambito: 'sistema', usuario: superadmin, taller_id: null, entidad: 'pagos_suscripcion', entidad_id: p.id });
  return { ok: true };
}

/* ---------- cuentas de dueños (SuperAdmin) ---------- */
// Un único plan con dos modalidades (mensual o anual). El importe sale de los parámetros del sistema.
export const modalidadValida = (m) => Object.prototype.hasOwnProperty.call(MODALIDADES, m);
export const mesesDe = (m) => MODALIDADES[m].meses;
export const importeDe = (m) => param(m === 'anual' ? 'importe_anual' : 'importe_mensual', 0);
export const textoModalidad = (m) => (modalidadValida(m) ? MODALIDADES[m].nombre : '—');
export const vencimientoDe = (inicio, m) => addMeses(inicio, mesesDe(m));
/* ---------- cuenta del dueño (SuperAdmin): el sistema administra UN SOLO taller ---------- */
export function crearCuenta(superadmin, f, claveTmp) {
  if (db.talleres.length >= 1) return { ok: false, error: 'Ya existe la cuenta del taller. El sistema administra un único taller y no permite crear otra.' };
  if (!modalidadValida(f.modalidad)) return { ok: false, error: 'La modalidad debe ser mensual o anual.' };
  const u = add('usuarios', { tipo_cuenta: 'taller', rol_id: rolId('admin'), taller_id: null, nombre: f.nombre, usuario: f.usuario, email: f.email || null, telefono: f.telefono || null, password_hash: hashClave(f.usuario, claveTmp), estado: 'activo', debe_cambiar_clave: 1, ultimo_acceso: null, created_at: ahora(), updated_at: ahora() });
  const t = add('talleres', { nombre: f.taller, dueno_id: u.id, telefono: f.telefono || null, direccion: null, estado: 'activo', created_at: ahora() });
  u.taller_id = t.id;
  const venc = vencimientoDe(f.inicio, f.modalidad);
  const s = add('suscripciones', { taller_id: t.id, modalidad: f.modalidad, importe: importeDe(f.modalidad), duracion_meses: mesesDe(f.modalidad), fecha_inicio: f.inicio, fecha_vencimiento: venc, dia_ancla: Number(f.inicio.slice(8, 10)), created_at: ahora() });
  add('periodos_suscripcion', { suscripcion_id: s.id, pago_id: null, desde: f.inicio, hasta: venc, created_at: ahora() });
  log('Creó la cuenta del dueño', `${u.nombre} · ${t.nombre}`, { ambito: 'sistema', usuario: superadmin, taller_id: null, entidad: 'talleres', entidad_id: t.id });
  sincronizar(); return { ok: true, taller: t, dueno: u };
}
export function guardarSuscripcion(superadmin, tallerId, f) {
  if (!modalidadValida(f.modalidad)) return { ok: false, error: 'La modalidad debe ser mensual o anual.' };
  if (!f.inicio) return { ok: false, error: 'Indicá la fecha de inicio.' };
  const s = suscripcionDe(tallerId); const antes = `${textoModalidad(s.modalidad)} ${money(s.importe)}, ${fecha(s.fecha_inicio)}→${fecha(s.fecha_vencimiento)}`;
  Object.assign(s, { modalidad: f.modalidad, importe: importeDe(f.modalidad), duracion_meses: mesesDe(f.modalidad), fecha_inicio: f.inicio, fecha_vencimiento: vencimientoDe(f.inicio, f.modalidad), dia_ancla: Number(f.inicio.slice(8, 10)) });
  log('Cambió la suscripción de la cuenta', `${get('talleres', tallerId).nombre}: antes ${antes}; ahora ${textoModalidad(s.modalidad)} ${money(s.importe)}, ${fecha(s.fecha_inicio)}→${fecha(s.fecha_vencimiento)}`, { ambito: 'sistema', usuario: superadmin, taller_id: null, entidad: 'suscripciones', entidad_id: s.id });
  sincronizar(); return { ok: true };
}
export function suspenderOReactivar(superadmin, tallerId) {
  const t = get('talleres', tallerId); const susp = t.estado === 'activo'; t.estado = susp ? 'suspendido' : 'activo';
  log(susp ? 'Suspendió una cuenta' : 'Reactivó una cuenta', t.nombre, { ambito: 'sistema', usuario: superadmin, taller_id: null, entidad: 'talleres', entidad_id: t.id }); return susp;
}
/* ---------- demostración: simular el paso del tiempo ---------- */
export function simularVencimiento(superadmin, tallerId, dias) {
  const s = suscripcionDe(tallerId); s.fecha_vencimiento = addDias(hoy(), dias); s.fecha_inicio = addMeses(s.fecha_vencimiento, -s.duracion_meses); s.dia_ancla = Number(s.fecha_inicio.slice(8, 10));
  log('Simuló un estado de suscripción (demo)', `${get('talleres', tallerId).nombre}: vence ${fecha(s.fecha_vencimiento)}`, { ambito: 'sistema', usuario: superadmin, taller_id: null }); sincronizar(); return estadoTaller(tallerId);
}
export function simularUnDia(tallerId) { const s = suscripcionDe(tallerId); s.fecha_vencimiento = addDias(s.fecha_vencimiento, -1); s.fecha_inicio = addDias(s.fecha_inicio, -1); sincronizar(); return estadoTaller(tallerId); }
/* ---------- plan único: importes de las dos modalidades ---------- */
export function guardarPrecios(superadmin, f) {
  const m = Number(String(f.mensual).replace(',', '.')); const a = Number(String(f.anual).replace(',', '.'));
  if (!(m > 0) || !(a > 0)) return { ok: false, error: 'Los dos importes deben ser mayores que cero.' };
  const set = (clave, v) => { const p = db.parametros_sistema.find((x) => x.clave === clave); if (p) p.valor = String(v); };
  set('importe_mensual', m); set('importe_anual', a);
  log('Actualizó los importes del plan', `Mensual ${money(m)} · Anual ${money(a)}`, { ambito: 'sistema', usuario: superadmin, taller_id: null });
  return { ok: true };
}
export function editarCuenta(superadmin, tallerId, f) {
  const t = get('talleres', tallerId); const u = get('usuarios', t.dueno_id);
  if (!f.nombre || !f.taller) return { ok: false, error: 'Completá el nombre del dueño y el del taller.' };
  Object.assign(u, { nombre: f.nombre, telefono: f.telefono || null, email: f.email || null, updated_at: ahora() }); Object.assign(t, { nombre: f.taller, telefono: f.telefono || null });
  log('Editó los datos de una cuenta', t.nombre, { ambito: 'sistema', usuario: superadmin, taller_id: null, entidad: 'talleres', entidad_id: t.id }); return { ok: true };
}
