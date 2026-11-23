import test from 'node:test'; import assert from 'node:assert/strict';
globalThis.localStorage = { getItem: () => null, setItem() {}, removeItem() {} };
const { fijarHoy } = await import('../src/utils/dates.js'); fijarHoy('2026-11-20');
const R = await import('../src/utils/comisiones.js');
const { db, get } = await import('../src/services/storageService.js');
const A = await import('../src/services/authService.js');
const C = await import('../src/services/commissionService.js');
const W = await import('../src/services/workshopService.js');
assert.equal(A.ingresarTaller('roberto', 'Dueno123').ok, true);
const juan = db.mecanicos.find((m) => db.usuarios.find((u) => u.id === m.usuario_id).usuario === 'juan');
const pedro = db.mecanicos.find((m) => db.usuarios.find((u) => u.id === m.usuario_id).usuario === 'pedro');

test('fórmula pura: la base es SOLO la mano de obra', () => {
  const det = [{ tipo: 'mano_obra', cantidad: 1, precio_unitario: 12000 }, { tipo: 'repuesto', cantidad: 4, precio_unitario: 14000 }, { tipo: 'otro', cantidad: 1, precio_unitario: 500 }];
  assert.equal(R.baseComision(det), 12000);
  assert.equal(R.calcularComision(12000, 30), 3600);
  assert.equal(R.calcularComision(12345.67, 12.5), 1543.21);
  assert.equal(R.calcularComision(10000, 0), 0);
});
test('porcentaje válido solo de 0 a 100', () => { for (const v of [0, '0', 100, '12,5', 30.25]) assert.equal(R.porcentajeValido(v), true); for (const v of [-1, 101, '', 'abc', null]) assert.equal(R.porcentajeValido(v), false); });
test('total a pagar = comisiones − adelantos', () => { const t = R.totalesLiquidacion([{ tipo: 'comision', monto: 3600 }, { tipo: 'comision', monto: 7500 }, { tipo: 'adelanto', monto: 5000 }]); assert.deepEqual(t, { total_comisiones: 11100, total_adelantos: 5000, total_a_pagar: 6100 }); });
test('la comisión de la demo (OT-0001) = 30 % de la mano de obra, sin repuestos', () => {
  const o = db.ordenes_trabajo.find((x) => x.numero === 'OT-0001'); assert.equal(C.baseDe(o), 12000); assert.equal(C.comisionDe(o), 3600);
  assert.equal(C.movimientoComision(o).monto, 3600);
});
test('registrar comisión: calcula, crea el movimiento y no se duplica', () => {
  const x = C.trabajosFinalizados(juan.id).find((t) => !t.registrada); assert.ok(x, 'hay un trabajo de Juan sin comisión');
  const esperado = Math.round(C.baseDe(x.orden) * x.orden.comision_pct) / 100;
  const r = C.registrarComision(x.orden.id); assert.equal(r.ok, true); assert.equal(r.movimiento.monto, esperado); assert.equal(r.movimiento.tipo, 'comision'); assert.equal(r.movimiento.orden_id, x.orden.id);
  const r2 = C.registrarComision(x.orden.id); assert.equal(r2.ok, false); assert.match(r2.error, /ya fue registrada/);
  assert.equal(db.movimientos_mecanico.filter((m) => m.orden_id === x.orden.id && m.tipo === 'comision').length, 1);
});
test('no se registra comisión con 0 %, ni en trabajos no finalizados, y el % se bloquea después de registrar', () => {
  const o3 = db.ordenes_trabajo.find((x) => x.numero === 'OT-0003'); assert.notEqual(o3.estado, 'finalizado'); assert.equal(C.registrarComision(o3.id).ok, false);
  const x = C.trabajosFinalizados(pedro.id).find((t) => !t.registrada); assert.equal(C.establecerPorcentaje(x.orden.id, 0).ok, true); assert.equal(C.registrarComision(x.orden.id).ok, false);
  assert.equal(C.establecerPorcentaje(x.orden.id, 150).ok, false); assert.equal(C.establecerPorcentaje(x.orden.id, 20).ok, true); assert.equal(C.registrarComision(x.orden.id).ok, true);
  assert.equal(C.establecerPorcentaje(x.orden.id, 40).ok, false);
});
test('adelantos: importe positivo, sin fechas futuras y se descuentan en la liquidación', () => {
  assert.equal(C.registrarAdelanto({ mecanico_id: juan.id, monto: 0 }).ok, false); assert.equal(C.registrarAdelanto({ mecanico_id: juan.id, monto: 100, fecha: '2026-12-31' }).ok, false);
  const a = C.registrarAdelanto({ mecanico_id: juan.id, monto: 1000, fecha: '2026-11-19', descripcion: 'prueba' }); assert.equal(a.ok, true);
  const p = C.previsualizarLiquidacion(juan.id, '2026-11-15', '2026-11-20'); assert.equal(p.ok, true);
  assert.equal(p.total_a_pagar, Math.round((p.total_comisiones - p.total_adelantos) * 100) / 100); assert.ok(p.adelantos.some((m) => m.id === a.movimiento.id)); assert.ok(p.total_adelantos >= 1000);
});
test('liquidación: se genera, queda pendiente y NO se puede liquidar dos veces la misma comisión', () => {
  const p = C.previsualizarLiquidacion(juan.id, '2026-10-01', '2026-11-20'); assert.equal(p.ok, true); assert.equal(p.puedeGenerar, true);
  const r = C.generarLiquidacion({ mecanico_id: juan.id, desde: '2026-10-01', hasta: '2026-11-20' }); assert.equal(r.ok, true); assert.equal(r.liquidacion.estado, 'pendiente');
  assert.equal(r.liquidacion.total_a_pagar, p.total_a_pagar); assert.equal(C.detalleDeLiquidacion(r.liquidacion.id).length, p.movimientos.length);
  const otra = C.generarLiquidacion({ mecanico_id: juan.id, desde: '2026-10-01', hasta: '2026-11-20' }); assert.equal(otra.ok, false); // ya no quedan movimientos sin liquidar
  const ids = db.liquidacion_detalles.map((d) => d.movimiento_id); assert.equal(new Set(ids).size, ids.length, 'ningún movimiento aparece dos veces');
  assert.equal(C.pagarLiquidacion(r.liquidacion.id).ok, true); assert.equal(get('liquidaciones', r.liquidacion.id).estado, 'pagada'); assert.ok(get('liquidaciones', r.liquidacion.id).fecha_pago);
  assert.equal(C.pagarLiquidacion(r.liquidacion.id).ok, false); assert.equal(C.anularLiquidacion(r.liquidacion.id).ok, false);
});
test('anular una liquidación pendiente libera sus movimientos para volver a liquidarlos', () => {
  const l = db.liquidaciones.find((x) => x.estado === 'pendiente'); assert.ok(l); const movs = C.detalleDeLiquidacion(l.id).map((x) => x.movimiento.id); assert.ok(movs.length);
  assert.equal(C.anularLiquidacion(l.id).ok, true); assert.equal(l.estado, 'anulada'); movs.forEach((id) => assert.equal(C.estaLiquidado(id), false));
  const r = C.generarLiquidacion({ mecanico_id: l.mecanico_id, desde: l.periodo_desde, hasta: l.periodo_hasta }); assert.equal(r.ok, true);
});
test('si los adelantos superan las comisiones no se genera la liquidación', () => {
  const x = C.trabajosFinalizados(pedro.id).find((t) => !t.registrada && t.comision > 0);
  C.registrarAdelanto({ mecanico_id: pedro.id, monto: 9999999, fecha: '2026-11-20' });
  const p = C.previsualizarLiquidacion(pedro.id, '2026-11-20', '2026-11-20'); assert.equal(p.ok, true); assert.equal(p.puedeGenerar, false);
  assert.equal(C.generarLiquidacion({ mecanico_id: pedro.id, desde: '2026-11-20', hasta: '2026-11-20' }).ok, false);
});
test('un adelanto ya liquidado no se puede eliminar; uno libre sí', () => {
  const ad = db.movimientos_mecanico.find((m) => m.tipo === 'adelanto' && C.estaLiquidado(m.id)); assert.equal(C.eliminarAdelanto(ad.id).ok, false);
  const libre = db.movimientos_mecanico.find((m) => m.tipo === 'adelanto' && !C.estaLiquidado(m.id)); assert.equal(C.eliminarAdelanto(libre.id).ok, true);
});
test('período inválido', () => { assert.equal(C.previsualizarLiquidacion(juan.id, '2026-11-20', '2026-11-01').ok, false); assert.equal(C.previsualizarLiquidacion(juan.id, '2026-11-01', '2027-01-01').ok, false); assert.equal(C.previsualizarLiquidacion(juan.id, '', '').ok, false); });
