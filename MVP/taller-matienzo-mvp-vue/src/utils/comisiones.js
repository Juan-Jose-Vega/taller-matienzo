// Reglas PURAS del cálculo de comisiones (sin base de datos). El backend futuro debe replicarlas.
//
// FÓRMULA (propuesta, coherente con el esquema: detalles_presupuestos.tipo distingue mano de obra de repuestos):
//   base de cálculo = suma de (cantidad × precio unitario) de las líneas del presupuesto aceptado de tipo 'mano_obra'
//   comisión        = base × comision_pct / 100, redondeada a 2 decimales
// Los repuestos, servicios de terceros y otros conceptos NO integran la base.
// El porcentaje es ordenes_trabajo.comision_pct (0 a 100). Si es 0 no se genera comisión; no existe ningún valor por defecto inventado.
export const TIPO_BASE_COMISION = 'mano_obra';
const num = (v) => { const n = Number(String(v ?? '').replace(',', '.')); return Number.isFinite(n) ? n : 0; };
export const redondear2 = (n) => Math.round((n + Number.EPSILON) * 100) / 100;
export const baseComision = (detalles) => redondear2(detalles.filter((d) => d.tipo === TIPO_BASE_COMISION).reduce((s, d) => s + num(d.cantidad) * num(d.precio_unitario), 0));
export const calcularComision = (base, pct) => redondear2(Math.round(num(base) * num(pct)) / 100);
export const porcentajeValido = (v) => { const n = Number(String(v).replace(',', '.')); return String(v).trim() !== '' && Number.isFinite(n) && n >= 0 && n <= 100; };
// Totales de una liquidación: total a pagar = comisiones − adelantos (nunca negativo: si los adelantos superan las comisiones no se liquida).
export function totalesLiquidacion(movimientos) {
  const c = redondear2(movimientos.filter((m) => m.tipo === 'comision').reduce((s, m) => s + m.monto, 0));
  const a = redondear2(movimientos.filter((m) => m.tipo === 'adelanto').reduce((s, m) => s + m.monto, 0));
  return { total_comisiones: c, total_adelantos: a, total_a_pagar: redondear2(c - a) };
}
