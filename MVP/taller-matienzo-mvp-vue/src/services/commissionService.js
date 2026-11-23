// Comisiones, adelantos y liquidaciones de mecánicos (MVP con datos locales; el backend hará luego el cálculo definitivo y validará).
// Tablas MySQL equivalentes: movimientos_mecanicos, liquidaciones_mecanicos, detalles_liquidaciones_mecanicos.
import { db, add, get } from './storageService.js';
import { usuario, tallerId } from './authService.js';
import { log } from './auditService.js';
import { notify } from './notificationService.js';
import { hoy, ahora, esFechaIso } from '../utils/dates.js';
import { money } from '../utils/formatters.js';
import { baseComision, calcularComision, porcentajeValido, totalesLiquidacion } from '../utils/comisiones.js';

const T = () => tallerId.value; const U = () => usuario.value; const ERR = (error) => ({ ok: false, error });
const delTaller = (col) => db[col].filter((x) => x.taller_id === T());
const nombreMec = (mid) => { const m = get('mecanicos', mid); const u = m && get('usuarios', m.usuario_id); return u ? u.nombre : '—'; };

/* ---------- consultas ---------- */
export const detallesPresupuestoDe = (o) => db.presupuesto_detalles.filter((d) => d.presupuesto_id === o.presupuesto_id);
export const baseDe = (o) => baseComision(detallesPresupuestoDe(o));
export const comisionDe = (o) => calcularComision(baseDe(o), o.comision_pct || 0);
export const movimientoComision = (o) => db.movimientos_mecanico.find((m) => m.orden_id === o.id && m.tipo === 'comision') || null;
export function fechaFinalizacion(o) { const h = db.orden_estados_historial.filter((x) => x.orden_id === o.id && x.estado === 'finalizado').pop(); return h ? h.created_at : `${o.fecha_creacion} 12:00`; }
// ¿Está el movimiento incluido en una liquidación vigente (pendiente o pagada)? Una liquidación anulada libera sus movimientos.
export const liquidacionDeMovimiento = (movId) => { const d = db.liquidacion_detalles.find((x) => x.movimiento_id === movId); return d ? get('liquidaciones', d.liquidacion_id) : null; };
export const estaLiquidado = (movId) => !!liquidacionDeMovimiento(movId);

// Trabajos finalizados del mecánico (o de todos) con su comisión calculada y si ya fue registrada.
export function trabajosFinalizados(mecId = null) {
  return delTaller('ordenes_trabajo').filter((o) => o.estado === 'finalizado' && o.mecanico_id && (!mecId || o.mecanico_id === mecId))
    .map((o) => { const mov = movimientoComision(o); return { orden: o, base: baseDe(o), pct: o.comision_pct || 0, comision: comisionDe(o), movimiento: mov, registrada: !!mov, liquidada: !!mov && estaLiquidado(mov.id) }; })
    .sort((a, b) => b.orden.id - a.orden.id);
}
export const movimientosDe = (mecId = null) => delTaller('movimientos_mecanico').filter((m) => !mecId || m.mecanico_id === mecId).sort((a, b) => (a.fecha < b.fecha ? 1 : a.fecha > b.fecha ? -1 : b.id - a.id));
// Resumen por mecánico: generadas, adelantos, liquidado, pendiente de liquidar, comisiones por calcular.
export function resumenMecanico(mecId) {
  const movs = movimientosDe(mecId); const c = movs.filter((m) => m.tipo === 'comision'); const a = movs.filter((m) => m.tipo === 'adelanto');
  const sum = (l) => l.reduce((s, m) => s + m.monto, 0);
  const sinLiq = movs.filter((m) => !estaLiquidado(m.id)); const t = totalesLiquidacion(sinLiq);
  const porCalcular = trabajosFinalizados(mecId).filter((x) => !x.registrada && x.comision > 0);
  return { comisiones: sum(c), adelantos: sum(a), pendienteComisiones: t.total_comisiones, pendienteAdelantos: t.total_adelantos, pendienteNeto: t.total_a_pagar,
    pagado: db.liquidaciones.filter((l) => l.mecanico_id === mecId && l.estado === 'pagada').reduce((s, l) => s + l.total_a_pagar, 0), porCalcular: porCalcular.length, montoPorCalcular: porCalcular.reduce((s, x) => s + x.comision, 0) };
}

/* ---------- comisión de un trabajo ---------- */
export function establecerPorcentaje(oid, pct) {
  const o = get('ordenes_trabajo', oid); if (!o || o.taller_id !== T()) return ERR('No se encontró el trabajo.');
  if (!porcentajeValido(pct)) return ERR('El porcentaje debe ser un número entre 0 y 100.');
  if (movimientoComision(o)) return ERR('Este trabajo ya tiene su comisión registrada: el porcentaje no se puede cambiar.');
  if (o.estado === 'cancelado') return ERR('El trabajo está cancelado.');
  const antes = o.comision_pct || 0; o.comision_pct = Number(String(pct).replace(',', '.'));
  log('Cambió el porcentaje de comisión', `${o.numero}: ${antes} % → ${o.comision_pct} %`, { usuario: U(), entidad: 'ordenes_trabajo', entidad_id: o.id }); return { ok: true };
}
export function registrarComision(oid) {
  const o = get('ordenes_trabajo', oid); if (!o || o.taller_id !== T()) return ERR('No se encontró el trabajo.');
  if (o.estado !== 'finalizado') return ERR('La comisión se calcula cuando el trabajo está finalizado.');
  if (!o.mecanico_id) return ERR('El trabajo no tiene mecánico asignado.');
  if (movimientoComision(o)) return ERR('La comisión de este trabajo ya fue registrada.');
  const pct = o.comision_pct || 0; if (!(pct > 0)) return ERR('Definí un porcentaje de comisión mayor que cero para este trabajo.');
  const base = baseDe(o); const monto = calcularComision(base, pct);
  if (!(monto > 0)) return ERR('El trabajo no tiene mano de obra en su presupuesto: no genera comisión.');
  const m = add('movimientos_mecanico', { taller_id: T(), mecanico_id: o.mecanico_id, tipo: 'comision', monto, orden_id: o.id, fecha: fechaFinalizacion(o), descripcion: `Comisión ${pct} % sobre la mano de obra (${money(base)}) de ${o.numero}`, registrado_por: U().id });
  log('Registró una comisión', `${o.numero} · ${nombreMec(o.mecanico_id)}: ${money(monto)}`, { usuario: U(), entidad: 'movimientos_mecanico', entidad_id: m.id });
  notify({ tallerId: T(), usuarioId: get('mecanicos', o.mecanico_id).usuario_id, texto: `Se registró tu comisión de ${money(monto)} por el trabajo ${o.numero}.`, ruta: '/mis-comisiones', tipo: 'comision' });
  return { ok: true, movimiento: m };
}
export function registrarComisionesPendientes(mecId = null) {
  let n = 0; let total = 0; const omitidas = [];
  trabajosFinalizados(mecId).filter((x) => !x.registrada).reverse().forEach((x) => { const r = registrarComision(x.orden.id); if (r.ok) { n += 1; total += r.movimiento.monto; } else omitidas.push(`${x.orden.numero}: ${r.error}`); });
  return { ok: true, registradas: n, total, omitidas };
}

/* ---------- adelantos ---------- */
export function registrarAdelanto(f) {
  const m = get('mecanicos', f.mecanico_id); if (!m || m.taller_id !== T()) return ERR('Elegí un mecánico.');
  const monto = Number(String(f.monto).replace(',', '.')); if (!(monto > 0)) return ERR('El importe del adelanto debe ser mayor que cero.');
  const fecha = f.fecha || hoy(); if (!esFechaIso(fecha)) return ERR('La fecha no es válida.'); if (fecha > hoy()) return ERR('La fecha del adelanto no puede ser futura.');
  const a = add('movimientos_mecanico', { taller_id: T(), mecanico_id: m.id, tipo: 'adelanto', monto, orden_id: null, fecha: fecha === hoy() ? ahora() : `${fecha} 09:00`, descripcion: (f.descripcion || '').trim() || 'Adelanto', registrado_por: U().id });
  log('Registró un adelanto', `${nombreMec(m.id)}: ${money(monto)}`, { usuario: U(), entidad: 'movimientos_mecanico', entidad_id: a.id }); return { ok: true, movimiento: a };
}
export function eliminarAdelanto(id) {
  const a = get('movimientos_mecanico', id); if (!a || a.taller_id !== T() || a.tipo !== 'adelanto') return ERR('No se encontró el adelanto.');
  if (estaLiquidado(a.id)) return ERR('Este adelanto ya está incluido en una liquidación: anulá la liquidación primero.');
  db.movimientos_mecanico.splice(db.movimientos_mecanico.indexOf(a), 1);
  log('Eliminó un adelanto', `${nombreMec(a.mecanico_id)}: ${money(a.monto)}`, { usuario: U(), entidad: 'movimientos_mecanico', entidad_id: id }); return { ok: true };
}

/* ---------- liquidaciones ---------- */
const enPeriodo = (m, desde, hasta) => m.fecha.slice(0, 10) >= desde && m.fecha.slice(0, 10) <= hasta;
export function previsualizarLiquidacion(mecId, desde, hasta) {
  const m = get('mecanicos', mecId); if (!m || m.taller_id !== T()) return ERR('Elegí un mecánico.');
  if (!esFechaIso(desde) || !esFechaIso(hasta)) return ERR('Indicá las dos fechas del período.');
  if (hasta < desde) return ERR('El final del período no puede ser anterior al inicio.'); if (hasta > hoy()) return ERR('El período no puede terminar en el futuro.');
  const movs = movimientosDe(m.id).filter((x) => !estaLiquidado(x.id) && enPeriodo(x, desde, hasta)).sort((a, b) => a.id - b.id);
  const t = totalesLiquidacion(movs); const comisiones = movs.filter((x) => x.tipo === 'comision'); const adelantos = movs.filter((x) => x.tipo === 'adelanto');
  const r = Object.assign({ ok: true, movimientos: movs, comisiones, adelantos, mecanico_id: m.id, desde, hasta }, t);
  if (!comisiones.length) r.aviso = 'No hay comisiones sin liquidar en ese período.';
  else if (adelantos.length && t.total_adelantos > t.total_comisiones) r.aviso = 'Los adelantos superan las comisiones del período: no se puede generar la liquidación. Ampliá el período o revisá los adelantos.';
  r.puedeGenerar = !r.aviso; return r;
}
export function generarLiquidacion({ mecanico_id, desde, hasta, observaciones }) {
  const p = previsualizarLiquidacion(Number(mecanico_id), desde, hasta); if (!p.ok) return p; if (!p.puedeGenerar) return ERR(p.aviso);
  if (p.movimientos.some((x) => estaLiquidado(x.id))) return ERR('Alguna comisión o adelanto ya fue liquidado.'); // defensa: nunca se liquida dos veces
  const l = add('liquidaciones', { taller_id: T(), mecanico_id: p.mecanico_id, periodo_desde: desde, periodo_hasta: hasta, total_comisiones: p.total_comisiones, total_adelantos: p.total_adelantos, total_a_pagar: p.total_a_pagar, estado: 'pendiente', creado_por: U().id, fecha_creacion: ahora(), fecha_pago: null, observaciones: (observaciones || '').trim() || null });
  p.movimientos.forEach((x) => add('liquidacion_detalles', { liquidacion_id: l.id, movimiento_id: x.id, importe_incluido: x.monto }));
  log('Generó una liquidación', `${nombreMec(l.mecanico_id)} · ${desde} a ${hasta}: a pagar ${money(l.total_a_pagar)}`, { usuario: U(), entidad: 'liquidaciones', entidad_id: l.id }); return { ok: true, liquidacion: l };
}
export function pagarLiquidacion(id) {
  const l = get('liquidaciones', id); if (!l || l.taller_id !== T()) return ERR('No se encontró la liquidación.');
  if (l.estado === 'pagada') return ERR('Esta liquidación ya está pagada.'); if (l.estado === 'anulada') return ERR('Esta liquidación está anulada.');
  l.estado = 'pagada'; l.fecha_pago = ahora();
  log('Registró el pago de una liquidación', `${nombreMec(l.mecanico_id)}: ${money(l.total_a_pagar)}`, { usuario: U(), entidad: 'liquidaciones', entidad_id: l.id });
  notify({ tallerId: T(), usuarioId: get('mecanicos', l.mecanico_id).usuario_id, texto: `Se pagó tu liquidación de ${money(l.total_a_pagar)}.`, ruta: '/mis-comisiones', tipo: 'comision' }); return { ok: true };
}
export function anularLiquidacion(id) {
  const l = get('liquidaciones', id); if (!l || l.taller_id !== T()) return ERR('No se encontró la liquidación.');
  if (l.estado === 'pagada') return ERR('No se puede anular una liquidación ya pagada.'); if (l.estado === 'anulada') return ERR('Esta liquidación ya está anulada.');
  for (let i = db.liquidacion_detalles.length - 1; i >= 0; i--) if (db.liquidacion_detalles[i].liquidacion_id === l.id) db.liquidacion_detalles.splice(i, 1); // libera los movimientos
  l.estado = 'anulada';
  log('Anuló una liquidación', `${nombreMec(l.mecanico_id)}: ${money(l.total_a_pagar)}`, { usuario: U(), entidad: 'liquidaciones', entidad_id: l.id }); return { ok: true };
}
export const liquidacionesDe = (mecId = null, estado = '') => delTaller('liquidaciones').filter((l) => (!mecId || l.mecanico_id === mecId) && (!estado || l.estado === estado)).sort((a, b) => b.id - a.id);
export const detalleDeLiquidacion = (id) => db.liquidacion_detalles.filter((d) => d.liquidacion_id === id).map((d) => ({ detalle: d, movimiento: get('movimientos_mecanico', d.movimiento_id) }));
export const ordenNumero = (oid) => { const o = get('ordenes_trabajo', oid); return o ? o.numero : '—'; };
export { nombreMec };
