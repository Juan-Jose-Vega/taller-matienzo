// Lógica del taller: clientes, consultas, presupuestos, órdenes, stock, pagos y mecánicos.
// Todas las funciones validan y devuelven { ok, error }. Trabajan sobre el taller del usuario actual.
import { db, add, get } from './storageService.js';
import { usuario, tallerId, mecanicoActual, claveTemporal, restablecerClave } from './authService.js';
import { log } from './auditService.js';
import { notify } from './notificationService.js';
import { hoy, ahora, addDias } from '../utils/dates.js';
import { money, num, norm, digits, patente as normPat, codigo, vehTxt } from '../utils/formatters.js';
import { hashClave } from '../utils/hash.js';
import { rolId, rolCodigoDe } from './rolesService.js';
import { vUsuario, vTelefono, vEmail, vPatente, vAnio } from '../utils/validators.js';

const T = () => tallerId.value; const U = () => usuario.value;
export const mine = (col) => db[col].filter((x) => x.taller_id === T());
export const getMine = (col, id) => { const x = get(col, id); return x && x.taller_id === T() ? x : null; };
export const nombreUsuario = (id) => { const u = get('usuarios', id); return u ? u.nombre : '—'; };
export const nombreMecanico = (mid) => { const m = get('mecanicos', mid); return m ? nombreUsuario(m.usuario_id) : '—'; };
export const mecanicosDelTaller = () => db.mecanicos.filter((m) => m.taller_id === T());
const ERR = (error) => ({ ok: false, error });

/* ===================== clientes y vehículos ===================== */
export const vehiculosDe = (clienteId) => db.vehiculo_propietarios.filter((p) => p.cliente_id === clienteId && p.es_actual).map((p) => get('vehiculos', p.vehiculo_id)).filter(Boolean);
export const clienteDeVehiculo = (vid) => { const p = db.vehiculo_propietarios.find((x) => x.vehiculo_id === vid && x.es_actual); return p ? get('clientes', p.cliente_id) : null; };
export function validarCliente(d, idActual) {
  if (!d.nombre) return 'Escribí el nombre.'; const e = vTelefono(d.telefono) || vEmail(d.email); if (e) return e;
  const dup = mine('clientes').find((x) => x.id !== idActual && digits(x.telefono).slice(-8) === digits(d.telefono).slice(-8));
  return dup ? `Ya existe un cliente con ese teléfono: ${dup.nombre}. Usá ese registro para no duplicar.` : '';
}
export function guardarCliente(d, id) {
  const e = validarCliente(d, id); if (e) return ERR(e);
  if (id) { const c = getMine('clientes', id); Object.assign(c, { nombre: d.nombre, telefono: d.telefono, email: d.email || null, direccion: d.direccion || null }); log('Editó un cliente', c.nombre, { usuario: U(), entidad: 'clientes', entidad_id: c.id }); return { ok: true, cliente: c }; }
  const c = add('clientes', { taller_id: T(), nombre: d.nombre, telefono: d.telefono, email: d.email || null, direccion: d.direccion || null, created_at: ahora() });
  log('Agregó un cliente', c.nombre, { usuario: U(), entidad: 'clientes', entidad_id: c.id }); return { ok: true, cliente: c };
}
export function validarVehiculo(d, idActual) {
  if (!d.marca || !d.modelo) return 'Indicá marca y modelo.'; const e = vPatente(d.patente, true) || vAnio(d.anio); if (e) return e;
  return mine('vehiculos').some((x) => x.id !== idActual && normPat(x.patente) === normPat(d.patente)) ? 'Ya hay un vehículo registrado con esa patente.' : '';
}
export function guardarVehiculo(d, clienteId, id) {
  const e = validarVehiculo(d, id); if (e) return ERR(e);
  const datos = { marca: d.marca, modelo: d.modelo, anio: d.anio ? parseInt(d.anio, 10) : null, patente: normPat(d.patente), km: d.km ? num(d.km) : null };
  if (id) { const v = getMine('vehiculos', id); Object.assign(v, datos); log('Editó un vehículo', v.patente, { usuario: U(), entidad: 'vehiculos', entidad_id: v.id }); return { ok: true, vehiculo: v }; }
  const v = add('vehiculos', Object.assign({ taller_id: T(), created_at: ahora() }, datos));
  add('vehiculo_propietarios', { vehiculo_id: v.id, cliente_id: clienteId, desde: hoy(), hasta: null, es_actual: 1 });
  log('Agregó un vehículo', `${get('clientes', clienteId).nombre}: ${v.marca} ${v.modelo}`, { usuario: U(), entidad: 'vehiculos', entidad_id: v.id }); return { ok: true, vehiculo: v };
}
// Búsqueda de duplicados mientras se escribe una consulta
export function coincidencias(nombre, tel, pat) {
  const n = norm(nombre); const t = digits(tel); const p = normPat(pat); const ids = new Set();
  mine('clientes').forEach((c) => { if ((n.length >= 3 && norm(c.nombre).includes(n)) || (t.length >= 6 && digits(c.telefono).includes(t))) ids.add(c.id); });
  if (p.length >= 4) mine('vehiculos').forEach((v) => { if (normPat(v.patente).includes(p)) { const c = clienteDeVehiculo(v.id); if (c) ids.add(c.id); } });
  return [...ids].slice(0, 4).map((id) => ({ cliente: get('clientes', id), vehiculos: vehiculosDe(id) }));
}
export function previas(c) { // consultas anteriores de la misma persona (cliente, teléfono o patente)
  const tel = digits(c.telefono_contacto).slice(-8); const pat = normPat(c.patente);
  return mine('consultas').filter((x) => x.id !== c.id && (c.id == null || x.id < c.id) && ((c.cliente_id && x.cliente_id === c.cliente_id) || (tel && digits(x.telefono_contacto).slice(-8) === tel) || (pat && normPat(x.patente) === pat)));
}
// Convierte a la persona de la consulta en cliente formal (reutiliza uno existente: no duplica)
export function asegurarCliente(c) {
  let existente = false; let cl = c.cliente_id ? get('clientes', c.cliente_id) : null;
  if (!cl) { const t = digits(c.telefono_contacto).slice(-8); cl = mine('clientes').find((x) => t && digits(x.telefono).slice(-8) === t); existente = !!cl; }
  if (!cl) cl = add('clientes', { taller_id: c.taller_id, nombre: c.nombre_contacto, telefono: c.telefono_contacto, email: null, direccion: null, created_at: ahora() });
  let v = c.vehiculo_id ? get('vehiculos', c.vehiculo_id) : (c.patente ? mine('vehiculos').find((x) => normPat(x.patente) === normPat(c.patente)) : null);
  if (!v) { v = add('vehiculos', { taller_id: c.taller_id, marca: c.marca, modelo: c.modelo, anio: c.anio, patente: c.patente || null, km: c.km || null, created_at: ahora() }); add('vehiculo_propietarios', { vehiculo_id: v.id, cliente_id: cl.id, desde: hoy(), hasta: null, es_actual: 1 }); }
  c.cliente_id = cl.id; c.vehiculo_id = v.id; log('Agregó un cliente formal', `${cl.nombre} · ${v.marca} ${v.modelo}`, { usuario: U(), entidad: 'clientes', entidad_id: cl.id });
  return { cliente: cl, vehiculo: v, existente };
}

/* ===================== consultas ===================== */
export function crearConsulta(d) {
  const u = U(); const e = !d.nombre ? 'Escribí el nombre y apellido del cliente.' : vTelefono(d.telefono) || (!d.marca || !d.modelo ? 'Indicá la marca y el modelo del vehículo.' : '') || vAnio(d.anio) || vPatente(d.patente) || (!d.problema ? 'Contá qué problema informa el cliente.' : '');
  if (e) return ERR(e);
  const c = { taller_id: T(), cliente_id: d.cliente_id || null, vehiculo_id: d.vehiculo_id || null, creada_por: u.id, fecha: hoy(), nombre_contacto: d.nombre, telefono_contacto: d.telefono, marca: d.marca, modelo: d.modelo, anio: d.anio ? parseInt(d.anio, 10) : null, patente: normPat(d.patente) || null, km: d.km ? num(d.km) : null, problema: d.problema, problema_original: d.problema_original || null, observaciones: d.observaciones || null, estado: 'pendiente', es_gratuita: 1, cobro_decision: null, cobro_importe: null, cobro_por: null, cobro_fecha: null, motivo_cierre: null, created_at: ahora() };
  c.es_gratuita = previas(Object.assign({}, c, { id: null })).length === 0 ? 1 : 0;
  const k = add('consultas', c);
  log('Registró una consulta', `${k.nombre_contacto} · ${k.marca} ${k.modelo}`, { usuario: u, entidad: 'consultas', entidad_id: k.id });
  notify({ tallerId: T(), rol: rolCodigoDe(u) === 'admin' ? 'mecanico' : 'admin', texto: `Nueva consulta: ${k.nombre_contacto} (${k.marca} ${k.modelo}).`, ruta: '/consultas/' + k.id });
  return { ok: true, consulta: k };
}
export const revisionDe = (cid) => db.consulta_revisiones.find((r) => r.consulta_id === cid) || null;
export function guardarRevision(cid, d) {
  const c = getMine('consultas', cid); const u = U();
  if (!d.problemas && !d.tecnicas && !d.trabajo) return ERR('Completá al menos los problemas encontrados, las observaciones o el trabajo recomendado.');
  const datos = { usuario_id: u.id, problemas: d.problemas || '', problemas_original: d.problemas_original || null, tecnicas: d.tecnicas || '', tecnicas_original: d.tecnicas_original || null, repuestos_necesarios: d.repuestos || null, trabajo_recomendado: d.trabajo || null, importe_estimado: num(d.importe), fecha: hoy() };
  const r = revisionDe(cid); if (r) Object.assign(r, datos); else add('consulta_revisiones', Object.assign({ consulta_id: cid }, datos));
  log('Registró la revisión técnica', `${c.nombre_contacto} · ${c.marca} ${c.modelo}`, { usuario: u, entidad: 'consultas', entidad_id: cid });
  notify({ tallerId: c.taller_id, rol: rolCodigoDe(u) === 'admin' ? 'mecanico' : 'admin', texto: `Consulta actualizada: revisión técnica de ${c.nombre_contacto}.`, ruta: '/consultas/' + c.id });
  return { ok: true };
}
export function decidirCobro(cid, decision, importe) {
  const c = getMine('consultas', cid); const imp = num(importe);
  if (decision === 'cobrar' && !(imp > 0)) return ERR('Indicá el importe a cobrar.');
  Object.assign(c, { cobro_decision: decision, cobro_importe: decision === 'cobrar' ? imp : 0, cobro_por: U().id, cobro_fecha: hoy() });
  log('Decidió el cobro de una consulta repetida', `${c.nombre_contacto}: ${decision === 'cobrar' ? money(imp) : 'sin cargo'}`, { usuario: U(), entidad: 'consultas', entidad_id: cid }); return { ok: true };
}
export function finalizarSinTrabajo(cid, motivo) { const c = getMine('consultas', cid); c.estado = 'cerrada'; c.motivo_cierre = motivo || null; log('Finalizó una consulta sin trabajo', c.nombre_contacto, { usuario: U(), entidad: 'consultas', entidad_id: cid }); }

/* ===================== presupuestos ===================== */
export const detallesDe = (pid) => db.presupuesto_detalles.filter((d) => d.presupuesto_id === pid).sort((a, b) => a.orden - b.orden);
export const presTotal = (p) => detallesDe(p.id).reduce((s, d) => s + num(d.cantidad) * num(d.precio_unitario), 0);
export const presEstado = (p) => (p.estado === 'pendiente' && p.valido_hasta && p.valido_hasta < hoy() ? 'vencido' : p.estado);
export const presupuestoDe = (cid) => db.presupuestos.find((p) => p.consulta_id === cid) || null;
export function guardarPresupuesto(cid, items, validoHasta, enviar) {
  const c = getMine('consultas', cid);
  if (!items.length || items.some((i) => !i.descripcion)) return ERR('Cada concepto necesita una descripción.');
  if (items.some((i) => !(num(i.cantidad) > 0) || num(i.precio_unitario) < 0)) return ERR('Revisá las cantidades (mayores que cero) y los precios.');
  const total = items.reduce((s, i) => s + num(i.cantidad) * num(i.precio_unitario), 0);
  if (!(total > 0)) return ERR('El total del presupuesto debe ser mayor que cero.');
  if (validoHasta && validoHasta < hoy()) return ERR('La fecha de validez no puede ser anterior a hoy.');
  let p = presupuestoDe(cid);
  if (p && p.estado === 'aceptado') return ERR('El presupuesto ya fue aceptado y no se puede modificar.');
  if (!p) { db.seq.pres = (db.seq.pres || 0) + 1; p = add('presupuestos', { taller_id: c.taller_id, consulta_id: cid, numero: codigo('PRE', db.seq.pres), estado: 'borrador', valido_hasta: validoHasta, fecha_creacion: hoy(), fecha_envio: null, fecha_decision: null, total }); }
  else { p.valido_hasta = validoHasta; p.total = total; }
  for (let i = db.presupuesto_detalles.length - 1; i >= 0; i--) if (db.presupuesto_detalles[i].presupuesto_id === p.id) db.presupuesto_detalles.splice(i, 1);
  items.forEach((i, ix) => add('presupuesto_detalles', { presupuesto_id: p.id, tipo: i.tipo, descripcion: i.descripcion, cantidad: num(i.cantidad), precio_unitario: num(i.precio_unitario), orden: ix + 1 }));
  const era = p.estado;
  if (enviar && p.estado !== 'pendiente') { p.estado = 'pendiente'; p.fecha_envio = hoy(); } else if (!enviar && ['rechazado'].includes(p.estado)) p.estado = 'borrador';
  c.estado = 'en_presupuesto';
  log(enviar ? 'Presentó un presupuesto al cliente' : 'Guardó un borrador de presupuesto', `${p.numero} · ${money(total)}`, { usuario: U(), entidad: 'presupuestos', entidad_id: p.id });
  if (enviar && era !== 'pendiente') notify({ tallerId: c.taller_id, rol: 'admin', texto: `Presupuesto ${p.numero} presentado a ${c.nombre_contacto}: esperando respuesta.`, ruta: '/presupuestos/' + p.id });
  return { ok: true, presupuesto: p };
}
export function decidirPresupuesto(pid, acepta) {
  const p = getMine('presupuestos', pid); const c = get('consultas', p.consulta_id);
  if (['aceptado', 'rechazado'].includes(p.estado)) return ERR('Esa respuesta ya estaba registrada.');
  p.estado = acepta ? 'aceptado' : 'rechazado'; p.fecha_decision = hoy();
  log(acepta ? 'Registró que el cliente aceptó el presupuesto' : 'Registró que el cliente rechazó el presupuesto', p.numero, { usuario: U(), entidad: 'presupuestos', entidad_id: p.id });
  notify({ tallerId: c.taller_id, rol: 'admin', texto: `Presupuesto ${p.numero} ${acepta ? 'aceptado' : 'rechazado'} por ${c.nombre_contacto}.`, ruta: '/consultas/' + c.id, tipo: 'presupuesto' });
  return { ok: true };
}
/* ===================== órdenes de trabajo ===================== */
export const ordenDeConsulta = (cid) => db.ordenes_trabajo.find((o) => o.consulta_id === cid) || null;
export const historialDe = (oid) => db.orden_estados_historial.filter((h) => h.orden_id === oid);
export const avancesDe = (oid) => db.orden_avances.filter((a) => a.orden_id === oid);
export const repuestosUsadosDe = (oid) => db.orden_repuestos.filter((r) => r.orden_id === oid);
export const rechazosDe = (oid) => db.orden_asignaciones.filter((a) => a.orden_id === oid && a.respuesta === 'rechazada');
const cambiarEstado = (o, estado, nota) => { o.estado = estado; add('orden_estados_historial', { orden_id: o.id, estado, usuario_id: U().id, nota: nota || null, created_at: ahora() }); };
const asignacionActiva = (o) => [...db.orden_asignaciones].reverse().find((a) => a.orden_id === o.id && ['pendiente', 'aceptada'].includes(a.respuesta));
export const ordenTotal = (o) => { const p = get('presupuestos', o.presupuesto_id); return p ? presTotal(p) : 0; };
export const ordenPagado = (o) => db.pagos_cliente.filter((x) => x.orden_id === o.id).reduce((s, x) => s + x.importe, 0);
export const ordenSaldo = (o) => Math.max(0, ordenTotal(o) - ordenPagado(o));

// Aprueba la consulta y crea UNA orden (si ya existe, no crea otra: protección contra doble clic)
export function aprobarConsulta(cid, f) {
  const c = getMine('consultas', cid);
  const ya = ordenDeConsulta(cid); if (ya) return { ok: true, orden: ya, repetida: true };
  const p = presupuestoDe(cid); if (!p || p.estado !== 'aceptado') return ERR('El presupuesto todavía no fue aceptado.');
  if (f.inicio && f.entrega && f.entrega < f.inicio) return ERR('La entrega no puede ser anterior al inicio.');
  if (!f.descripcion) return ERR('Describí el trabajo a realizar.');
  const rr = asegurarCliente(c); const mid = f.mecanico_id ? Number(f.mecanico_id) : null;
  db.seq.ot = (db.seq.ot || 0) + 1;
  const o = add('ordenes_trabajo', { taller_id: c.taller_id, numero: codigo('OT', db.seq.ot), cliente_id: rr.cliente.id, vehiculo_id: rr.vehiculo.id, consulta_id: c.id, presupuesto_id: p.id, mecanico_id: mid, estado: mid ? 'pendiente_aceptacion' : 'sin_asignar', descripcion: f.descripcion, repuestos_previstos: f.repuestos || null, observaciones: f.obs || null, fecha_creacion: hoy(), inicio_previsto: f.inicio || null, entrega_prevista: f.entrega || null });
  add('orden_estados_historial', { orden_id: o.id, estado: o.estado, usuario_id: U().id, nota: mid ? 'Asignado a ' + nombreMecanico(mid) : 'Creada sin asignar', created_at: ahora() });
  if (mid) add('orden_asignaciones', { orden_id: o.id, mecanico_id: mid, asignado_por: U().id, fecha_asignacion: ahora(), respuesta: 'pendiente', fecha_respuesta: null, motivo_rechazo: null });
  c.estado = 'aprobada';
  log('Aprobó la consulta y creó la orden de trabajo', `${o.numero} · ${c.nombre_contacto}`, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id });
  if (mid) notify({ tallerId: c.taller_id, usuarioId: get('mecanicos', mid).usuario_id, texto: `Nuevo trabajo asignado: ${o.numero} (${c.marca} ${c.modelo}).`, ruta: '/trabajos/' + o.id, tipo: 'trabajo' });
  return { ok: true, orden: o };
}
export function aceptarTrabajo(oid) {
  const o = getMine('ordenes_trabajo', oid); if (o.estado !== 'pendiente_aceptacion') return ERR('Este trabajo ya no está pendiente de aceptación.');
  cambiarEstado(o, 'aceptado'); const a = asignacionActiva(o); if (a) { a.respuesta = 'aceptada'; a.fecha_respuesta = ahora(); }
  log('Aceptó el trabajo', o.numero, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id });
  notify({ tallerId: o.taller_id, rol: 'admin', texto: `${U().nombre} aceptó el trabajo ${o.numero}.`, ruta: '/trabajos/' + o.id, tipo: 'trabajo' }); return { ok: true };
}
export function rechazarTrabajo(oid, motivo) {
  const o = getMine('ordenes_trabajo', oid); if (!motivo || motivo.trim().length < 3) return ERR('Escribí el motivo del rechazo.');
  if (o.estado !== 'pendiente_aceptacion') return ERR('Este trabajo ya no está pendiente de aceptación.');
  const a = asignacionActiva(o); if (a) { a.respuesta = 'rechazada'; a.fecha_respuesta = ahora(); a.motivo_rechazo = motivo.trim(); }
  o.mecanico_id = null; cambiarEstado(o, 'sin_asignar', `${U().nombre} rechazó: ${motivo.trim()}`);
  log('Rechazó el trabajo', `${o.numero}: ${motivo.trim()}`, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id });
  notify({ tallerId: o.taller_id, rol: 'admin', texto: `${U().nombre} rechazó el trabajo ${o.numero}: ${motivo.trim()}. Reasignalo.`, ruta: '/trabajos/' + o.id, tipo: 'trabajo' }); return { ok: true };
}
export function iniciarTrabajo(oid) { const o = getMine('ordenes_trabajo', oid); if (o.estado !== 'aceptado') return ERR('El trabajo no está aceptado.'); cambiarEstado(o, 'en_proceso'); log('Inició el trabajo', o.numero, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id }); notify({ tallerId: o.taller_id, rol: 'admin', texto: `${U().nombre} inició el trabajo ${o.numero}.`, ruta: '/trabajos/' + o.id, tipo: 'trabajo' }); return { ok: true }; }
export function finalizarTrabajo(oid) {
  const o = getMine('ordenes_trabajo', oid); if (o.estado !== 'en_proceso') return ERR('El trabajo no está en proceso.'); cambiarEstado(o, 'finalizado');
  const v = get('vehiculos', o.vehiculo_id); log('Finalizó el trabajo', o.numero, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id });
  notify({ tallerId: o.taller_id, rol: 'admin', texto: `Trabajo ${o.numero} finalizado (${vehTxt(v)}). Avisá al cliente.`, ruta: '/trabajos/' + o.id, tipo: 'trabajo' }); return { ok: true };
}
export function asignarTrabajo(oid, mecId) {
  const o = getMine('ordenes_trabajo', oid); const mid = Number(mecId); if (mid === o.mecanico_id) return ERR('Ya está asignado a ese mecánico.');
  const ant = o.mecanico_id; const a = asignacionActiva(o); if (a) { a.respuesta = 'reasignada'; a.fecha_respuesta = ahora(); }
  o.mecanico_id = mid; add('orden_asignaciones', { orden_id: o.id, mecanico_id: mid, asignado_por: U().id, fecha_asignacion: ahora(), respuesta: 'pendiente', fecha_respuesta: null, motivo_rechazo: null });
  cambiarEstado(o, 'pendiente_aceptacion', (ant ? `Reasignado de ${nombreMecanico(ant)} a ` : 'Asignado a ') + nombreMecanico(mid));
  log(ant ? 'Reasignó el trabajo' : 'Asignó el trabajo', `${o.numero} → ${nombreMecanico(mid)}`, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id });
  notify({ tallerId: o.taller_id, usuarioId: get('mecanicos', mid).usuario_id, texto: `Nuevo trabajo asignado: ${o.numero} (${vehTxt(get('vehiculos', o.vehiculo_id))}).`, ruta: '/trabajos/' + o.id, tipo: 'trabajo' });
  if (ant) notify({ tallerId: o.taller_id, usuarioId: get('mecanicos', ant).usuario_id, texto: `El trabajo ${o.numero} fue reasignado a otro mecánico.`, ruta: '/trabajos', tipo: 'trabajo' });
  return { ok: true };
}
export function editarOrden(oid, f) {
  const o = getMine('ordenes_trabajo', oid); if (!f.descripcion) return ERR('La descripción no puede quedar vacía.'); if (f.inicio && f.entrega && f.entrega < f.inicio) return ERR('La entrega no puede ser anterior al inicio.');
  Object.assign(o, { inicio_previsto: f.inicio || null, entrega_prevista: f.entrega || null, descripcion: f.descripcion, observaciones: f.obs || null }); log('Editó la orden de trabajo', o.numero, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id }); return { ok: true };
}
export function cancelarOrden(oid) {
  const o = getMine('ordenes_trabajo', oid); if (['finalizado', 'cancelado'].includes(o.estado)) return ERR('Este trabajo ya está cerrado.');
  repuestosUsadosDe(o.id).filter((r) => !r.anulado).forEach((r) => { stockMover(get('repuestos', r.repuesto_id), 'reversion', r.cantidad, { orden_id: o.id, nota: 'Reversión por cancelación de ' + o.numero }); r.anulado = 1; });
  const mid = o.mecanico_id; cambiarEstado(o, 'cancelado', 'Cancelado por el dueño'); log('Canceló el trabajo', o.numero, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id });
  if (mid) notify({ tallerId: o.taller_id, usuarioId: get('mecanicos', mid).usuario_id, texto: `El trabajo ${o.numero} fue cancelado por el dueño.`, ruta: '/trabajos/' + o.id, tipo: 'trabajo' }); return { ok: true };
}
export function agregarAvance(oid, texto, original) {
  const o = getMine('ordenes_trabajo', oid); if (!texto) return ERR('Escribí el avance u observación.');
  const a = add('orden_avances', { orden_id: oid, usuario_id: U().id, texto, texto_original: original || null, created_at: ahora() }); log('Registró un avance', o.numero, { usuario: U(), entidad: 'orden_avances', entidad_id: a.id }); return { ok: true, avance: a };
}
export function usarRepuesto(oid, repuestoId, cantidad) {
  const o = getMine('ordenes_trabajo', oid); const it = getMine('repuestos', repuestoId); if (!it) return ERR('Elegí un repuesto del stock.');
  const r = stockMover(it, 'uso_orden', cantidad, { orden_id: oid, nota: 'Usado en ' + o.numero }); if (!r.ok) return r;
  add('orden_repuestos', { orden_id: oid, repuesto_id: it.id, cantidad: Math.abs(num(cantidad)), usuario_id: U().id, movimiento_id: r.movimiento.id, anulado: 0, created_at: ahora() });
  log('Registró un repuesto usado', `${o.numero}: ${it.nombre} x${num(cantidad)}`, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: oid }); return { ok: true };
}

/* ===================== stock ===================== */
// ÚNICO lugar que modifica cantidades: nunca baja de cero y siempre deja un movimiento (el historial no se borra).
export function stockMover(item, tipo, cantidad, extra = {}) {
  const cant = Math.abs(num(cantidad)); if (!(cant > 0)) return ERR('La cantidad debe ser mayor que cero.');
  const resta = tipo === 'salida' || tipo === 'uso_orden';
  if (resta && cant > item.cantidad) return ERR(`No hay stock suficiente de "${item.nombre}": disponible ${item.cantidad}.`);
  item.cantidad += resta ? -cant : cant;
  const m = add('movimientos_stock', { repuesto_id: item.id, tipo, cantidad: cant, orden_id: extra.orden_id || null, usuario_id: U().id, nota: extra.nota || null, created_at: ahora() });
  const bajo = item.cantidad <= item.minimo;
  if (bajo && !item.alerta_stock) { item.alerta_stock = 1; notify({ tallerId: item.taller_id, rol: 'admin', texto: `Stock bajo: ${item.nombre} (quedan ${item.cantidad}, mínimo ${item.minimo}).`, ruta: '/stock', tipo: 'stock' }); }
  if (!bajo) item.alerta_stock = 0;
  return { ok: true, movimiento: m };
}
export function guardarArticulo(d, id) {
  if (!d.codigo || !d.nombre || !d.categoria) return ERR('Completá código, nombre y categoría.');
  if (mine('repuestos').some((x) => x.id !== id && x.codigo.toLowerCase() === d.codigo.toLowerCase())) return ERR('Ya existe un artículo con ese código.');
  if (num(d.cantidad) < 0 || num(d.minimo) < 0 || num(d.costo) < 0) return ERR('Los valores no pueden ser negativos.');
  let cat = mine('categorias_repuesto').find((c) => norm(c.nombre) === norm(d.categoria)); if (!cat) cat = add('categorias_repuesto', { taller_id: T(), nombre: d.categoria.trim() });
  const datos = { categoria_id: cat.id, codigo: d.codigo, nombre: d.nombre, marca: d.marca || null, minimo: Math.floor(num(d.minimo)), costo: num(d.costo), precio_referencia: d.precio ? num(d.precio) : null, ubicacion: d.ubicacion || null };
  if (id) { const s = getMine('repuestos', id); Object.assign(s, datos); s.alerta_stock = s.cantidad <= s.minimo ? s.alerta_stock : 0; log('Editó un artículo del stock', s.nombre, { usuario: U(), entidad: 'repuestos', entidad_id: id }); return { ok: true }; }
  const s = add('repuestos', Object.assign({ taller_id: T(), cantidad: 0, alerta_stock: 0 }, datos)); const ini = Math.floor(num(d.cantidad));
  if (ini > 0) stockMover(s, 'entrada', ini, { nota: 'Stock inicial' }); log('Agregó un artículo al stock', s.nombre, { usuario: U(), entidad: 'repuestos', entidad_id: s.id }); return { ok: true };
}
export function moverStock(id, tipo, cantidad, nota) { const s = getMine('repuestos', id); const r = stockMover(s, tipo, cantidad, { nota }); if (r.ok) log(tipo === 'entrada' ? 'Registró una entrada de stock' : 'Registró una salida de stock', `${s.nombre} x${num(cantidad)}`, { usuario: U(), entidad: 'repuestos', entidad_id: id }); return r; }

/* ===================== pagos de clientes ===================== */
export const mediosDePagoCliente = (pid) => db.pago_cliente_medios.filter((m) => m.pago_id === pid);
export function registrarPagoCliente(d) {
  const imp = num(d.importe);
  if (!d.cliente_id) return ERR('Elegí el cliente que paga.'); if (!(imp > 0)) return ERR('El importe debe ser mayor que cero.'); if (d.fecha && d.fecha > hoy()) return ERR('La fecha del pago no puede ser futura.');
  const o = d.orden_id ? getMine('ordenes_trabajo', d.orden_id) : null;
  if (o && o.cliente_id !== Number(d.cliente_id)) return ERR('Esa orden no pertenece al cliente elegido.');
  if (o && imp > ordenSaldo(o) + 0.001) return ERR(`El importe supera el saldo pendiente de la orden (${money(ordenSaldo(o))}).`);
  let medios;
  if (d.medio === 'combinado') {
    medios = [[1, num(d.d_efectivo)], [2, num(d.d_transferencia)], [3, num(d.d_mercadopago)]].filter((m) => m[1] > 0);
    const s = medios.reduce((a, m) => a + m[1], 0); if (Math.abs(s - imp) > 0.009) return ERR(`La suma por medio (${money(s)}) no coincide con el importe total (${money(imp)}).`);
    if (medios.length < 2) return ERR('Un pago combinado necesita al menos dos medios con importe.');
  } else medios = [[db.medios_pago.find((m) => m.codigo === d.medio).id, imp]];
  const p = add('pagos_cliente', { taller_id: T(), cliente_id: Number(d.cliente_id), orden_id: o ? o.id : null, importe: imp, fecha: d.fecha || hoy(), es_combinado: medios.length > 1 ? 1 : 0, observaciones: d.obs || null, registrado_por: U().id, created_at: ahora() });
  medios.forEach(([medio_id, importe]) => add('pago_cliente_medios', { pago_id: p.id, medio_id, importe }));
  const cl = get('clientes', p.cliente_id); log('Registró un pago de cliente', `${cl.nombre}: ${money(imp)}`, { usuario: U(), entidad: 'pagos_cliente', entidad_id: p.id });
  notify({ tallerId: T(), rol: 'admin', texto: `Pago registrado: ${cl.nombre} abonó ${money(imp)}.`, ruta: '/pagos', tipo: 'pago' }); return { ok: true, pago: p };
}
export const textoMedios = (pid) => mediosDePagoCliente(pid).map((m) => `${get('medios_pago', m.medio_id).nombre} ${money(m.importe)}`).join(' + ');

/* ===================== mecánicos ===================== */
export const ESTADOS_ACTIVOS = ['pendiente_aceptacion', 'aceptado', 'en_proceso'];
export function crearMecanico(d) {
  if (!d.nombre) return ERR('Escribí el nombre.'); const e = vUsuario(d.usuario); if (e) return ERR(e);
  if (db.usuarios.some((x) => x.usuario.toLowerCase() === d.usuario.toLowerCase())) return ERR('Ese nombre de usuario ya está en uso.');
  const clave = claveTemporal();
  const u = add('usuarios', { tipo_cuenta: 'taller', rol_id: rolId('mecanico'), taller_id: T(), nombre: d.nombre, usuario: d.usuario, email: null, telefono: d.telefono || null, password_hash: hashClave(d.usuario, clave), estado: 'activo', debe_cambiar_clave: 1, ultimo_acceso: null, created_at: ahora(), updated_at: ahora() });
  add('mecanicos', { usuario_id: u.id, taller_id: T(), disponible: 1, especialidad: d.especialidad || null, fecha_alta: hoy() });
  log('Creó la cuenta de un mecánico', d.nombre, { usuario: U(), entidad: 'usuarios', entidad_id: u.id }); return { ok: true, usuario: u, clave };
}
export function editarMecanico(mid, d) {
  const m = get('mecanicos', mid); const u = get('usuarios', m.usuario_id);
  if (!d.nombre) return ERR('El nombre es obligatorio.'); const e = vUsuario(d.usuario); if (e) return ERR(e);
  if (db.usuarios.some((x) => x.id !== u.id && x.usuario.toLowerCase() === d.usuario.toLowerCase())) return ERR('Ese usuario ya está en uso.');
  if (u.usuario.toLowerCase() !== d.usuario.toLowerCase()) return ERR('El nombre de usuario no se puede cambiar (la contraseña depende de él). Creá otra cuenta si hace falta.');
  u.nombre = d.nombre; u.telefono = d.telefono || null; m.especialidad = d.especialidad || null; log('Editó los datos de un mecánico', u.nombre, { usuario: U(), entidad: 'mecanicos', entidad_id: m.id }); return { ok: true };
}
export const trabajosActivosDe = (mid) => mine('ordenes_trabajo').filter((o) => o.mecanico_id === mid && ESTADOS_ACTIVOS.includes(o.estado)).length;
export function alternarCuentaMecanico(mid) { const m = get('mecanicos', mid); const u = get('usuarios', m.usuario_id); const des = u.estado === 'activo'; u.estado = des ? 'inactivo' : 'activo'; if (!des) m.disponible = 1; log(des ? 'Desactivó la cuenta de un mecánico' : 'Activó la cuenta de un mecánico', u.nombre, { usuario: U(), entidad: 'mecanicos', entidad_id: mid }); }
export function alternarDisponibilidad(mid) { const m = get('mecanicos', mid); m.disponible = m.disponible ? 0 : 1; log('Cambió la disponibilidad de un mecánico', `${nombreMecanico(mid)}: ${m.disponible ? 'disponible' : 'no disponible'}`, { usuario: U(), entidad: 'mecanicos', entidad_id: mid }); }
export function resetClaveMecanico(mid) { const m = get('mecanicos', mid); const c = restablecerClave(m.usuario_id); log('Restableció la contraseña de un mecánico', nombreMecanico(mid), { usuario: U(), entidad: 'usuarios', entidad_id: m.usuario_id }); return { clave: c, usuario: get('usuarios', m.usuario_id).usuario }; }
export const _mecanicoActual = mecanicoActual; export { addDias };

/* ===================== eliminación de registros (con reglas para no dejar datos huérfanos) ===================== */
const quitar = (col, fn) => { for (let i = db[col].length - 1; i >= 0; i--) if (fn(db[col][i])) db[col].splice(i, 1); };
export function eliminarVehiculo(id) {
  const v = getMine('vehiculos', id); if (!v) return ERR('No se encontró el vehículo.');
  if (db.consultas.some((c) => c.vehiculo_id === id) || db.ordenes_trabajo.some((o) => o.vehiculo_id === id)) return ERR('No se puede eliminar: el vehículo tiene consultas o trabajos registrados.');
  quitar('vehiculo_propietarios', (p) => p.vehiculo_id === id); quitar('vehiculos', (x) => x.id === id);
  log('Eliminó un vehículo', `${v.marca} ${v.modelo} ${v.patente || ''}`.trim(), { usuario: U(), entidad: 'vehiculos', entidad_id: id }); return { ok: true };
}
export function eliminarCliente(id) {
  const c = getMine('clientes', id); if (!c) return ERR('No se encontró el cliente.');
  if (db.consultas.some((x) => x.cliente_id === id) || db.ordenes_trabajo.some((o) => o.cliente_id === id) || db.pagos_cliente.some((p) => p.cliente_id === id)) return ERR('No se puede eliminar: el cliente tiene consultas, trabajos o pagos registrados.');
  const propios = db.vehiculo_propietarios.filter((p) => p.cliente_id === id).map((p) => p.vehiculo_id);
  for (const vid of propios) { const r = eliminarVehiculo(vid); if (!r.ok) return r; }
  quitar('vehiculo_propietarios', (p) => p.cliente_id === id); quitar('clientes', (x) => x.id === id);
  log('Eliminó un cliente', c.nombre, { usuario: U(), entidad: 'clientes', entidad_id: id }); return { ok: true };
}
export function eliminarPresupuesto(id) {
  const p = getMine('presupuestos', id); if (!p) return ERR('No se encontró el presupuesto.');
  if (db.ordenes_trabajo.some((o) => o.presupuesto_id === id)) return ERR('No se puede eliminar: ya generó una orden de trabajo.');
  quitar('presupuesto_detalles', (d) => d.presupuesto_id === id); quitar('presupuestos', (x) => x.id === id);
  const c = get('consultas', p.consulta_id); if (c && c.estado === 'en_presupuesto') c.estado = 'pendiente';
  log('Eliminó un presupuesto', p.numero, { usuario: U(), entidad: 'presupuestos', entidad_id: id }); return { ok: true };
}
export function eliminarConsulta(id) {
  const c = getMine('consultas', id); if (!c) return ERR('No se encontró la consulta.');
  if (ordenDeConsulta(id)) return ERR('No se puede eliminar: la consulta ya generó una orden de trabajo.');
  const p = presupuestoDe(id); if (p) { const r = eliminarPresupuesto(p.id); if (!r.ok) return r; }
  quitar('consulta_revisiones', (r) => r.consulta_id === id); quitar('consultas', (x) => x.id === id);
  log('Eliminó una consulta', `${c.nombre_contacto} · ${c.marca} ${c.modelo}`, { usuario: U(), entidad: 'consultas', entidad_id: id }); return { ok: true };
}
export function eliminarArticulo(id) {
  const s = getMine('repuestos', id); if (!s) return ERR('No se encontró el artículo.');
  if (db.orden_repuestos.some((r) => r.repuesto_id === id)) return ERR('No se puede eliminar: el artículo se usó en trabajos. Dejá su stock en cero si ya no se vende.');
  quitar('movimientos_stock', (m) => m.repuesto_id === id); quitar('repuestos', (x) => x.id === id);
  log('Eliminó un artículo del stock', s.nombre, { usuario: U(), entidad: 'repuestos', entidad_id: id }); return { ok: true };
}
export function eliminarMecanico(mid) {
  const m = get('mecanicos', mid); if (!m || m.taller_id !== T()) return ERR('No se encontró el mecánico.');
  if (db.ordenes_trabajo.some((o) => o.mecanico_id === mid) || db.orden_asignaciones.some((a) => a.mecanico_id === mid)) return ERR('No se puede eliminar: tiene trabajos asignados o historial. Desactivá su cuenta en su lugar.');
  const u = get('usuarios', m.usuario_id); quitar('notificaciones', (n) => n.usuario_id === u.id); quitar('mecanicos', (x) => x.id === mid); quitar('usuarios', (x) => x.id === u.id);
  log('Eliminó un mecánico', u.nombre, { usuario: U(), entidad: 'mecanicos', entidad_id: mid }); return { ok: true };
}
