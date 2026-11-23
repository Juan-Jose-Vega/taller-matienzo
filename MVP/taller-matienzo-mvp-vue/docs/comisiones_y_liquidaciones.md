# Comisiones y liquidaciones de mecánicos (MVP)

Implementado en `src/utils/comisiones.js` (reglas puras), `src/services/commissionService.js` y las pantallas «Comisiones» (dueño) y «Mis comisiones» (mecánico). Usa datos locales; el backend futuro debe repetir el cálculo y validar.

## Fórmula
```
base      = suma de (cantidad × precio unitario) de las líneas de tipo «mano_obra» del presupuesto aceptado de la orden
comisión  = base × comision_pct ÷ 100        (redondeo a 2 decimales)
total a pagar de una liquidación = total de comisiones − total de adelantos
```
Los repuestos y otros conceptos **no** integran la base. Esta base es una **propuesta**: si el taller decide otra (p. ej. sobre el precio total), solo cambia `baseComision()` en `comisiones.js`.

## Cómo se establece el porcentaje
`ordenes_trabajo.comision_pct` (0 a 100). **No hay un valor por defecto**: una orden nueva queda en 0 % y no genera comisión. El dueño define el porcentaje de cada trabajo en Comisiones → «Comisiones por trabajo» (campo «% comisión» + «Guardar %»). Queda fijo cuando la comisión se registra. Los 30 % de la demostración son datos de ejemplo.

## Flujo
1. **Registrar comisión:** trabajo finalizado, con mecánico, % > 0 y mano de obra > 0. Crea un movimiento `comision` (fecha = fecha de finalización del trabajo). Una sola por trabajo (UNIQUE en MySQL).
2. **Adelantos:** movimiento `adelanto` (importe > 0, fecha no futura, sin orden). Solo se elimina si no está liquidado.
3. **Liquidar:** mecánico + período. Toma los movimientos del período **que no estén en otra liquidación**, muestra comisiones, adelantos y total a pagar, y genera la liquidación en estado `pendiente`. No se genera si no hay comisiones o si los adelantos superan a las comisiones.
4. **Pagar:** `pendiente` → `pagada` con fecha de pago (avisa al mecánico).
5. **Anular:** solo `pendiente`; borra sus detalles y libera los movimientos para volver a liquidarlos.
6. **Evitar doble liquidación:** un movimiento pertenece a una sola liquidación (el servicio lo controla y MySQL lo exige con `uq_detliq_movimiento`).

## Mapeo
`movimientos_mecanico` → `movimientos_mecanicos`; `liquidaciones` → `liquidaciones_mecanicos`; `liquidacion_detalles` → `detalles_liquidaciones_mecanicos` (`importe_incluido` = monto del movimiento).
