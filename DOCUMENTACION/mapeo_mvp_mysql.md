# Mapeo MVP ↔ MySQL

El MVP guarda 37 colecciones en `localStorage`; la base tiene 30 tablas (no se agregaron tablas). Tras la segunda corrección, MVP y MySQL coinciden en roles, taller único, plan mensual/anual, comisiones, adelantos, liquidaciones, propuestas de IA, estados y relaciones.

| Colección MVP | Tabla(s) MySQL | Observaciones |
|---|---|---|
| roles | roles | `admin` → Administrador (1), `mecanico` → Mecanico (2). Vue resuelve por **código**, MySQL guarda id y nombre. El SuperAdmin ya no es un rol en ninguno de los dos. |
| permisos, rol_permisos | — (código) | Se resuelven en el frontend/backend futuro; no hace falta tabla. |
| usuarios | usuarios | `tipo_cuenta` ('taller'/'superadmin') ↔ `tipo_cuenta`; `rol_id` nulo para el SuperAdmin. + email, teléfono, especialidad, disponible. `password_hash` bcrypt. |
| superadmins | superadmins | 1 a 1 con usuarios. |
| talleres | taller | Un solo taller (MVP: `crearCuenta` rechaza un segundo; MySQL: CHECK `id = 1`). |
| mecanicos | usuarios (rol Mecánico) | Especialidad y disponibilidad viven en usuarios. `mecanico_id` del MVP = `usuarios.id`. |
| clientes | clientes | |
| vehiculos | vehiculos | Patente y km opcionales (NULL). |
| vehiculo_propietarios | vehiculos.cliente_id | Propietario actual. |
| consultas | consultas | Estados: pendiente→abierta; en_presupuesto→esperando_respuesta; cobro_* y motivo_cierre agregados. |
| consulta_revisiones | detalles_consultas + consultas.observaciones_inspeccion / importe_estimado | Revisión distribuida por tipo (verificado, repuestos_necesarios, trabajo_recomendado). |
| presupuestos | presupuestos | pendiente→enviado. |
| presupuesto_detalles | detalles_presupuestos | `monto` columna generada (cantidad × precio). |
| ordenes_trabajo | ordenes_trabajo | pendiente_aceptacion→ofrecido. `comision_pct` ↔ `comision_pct` (se define por orden; 0 = sin comisión). |
| orden_asignaciones | asignaciones_trabajo | pendiente→ofrecida; con motivo de rechazo. |
| orden_estados_historial | historial_estados_ordenes | |
| orden_avances | avances_ordenes | |
| categorias_repuesto | categorias_catalogo | |
| repuestos | catalogo_items | + historial_precios_catalogo. |
| movimientos_stock | movimientos_stock | |
| orden_repuestos | movimientos_stock (salida con orden_id) | reversión = entrada con orden_id. |
| medios_pago | — (ENUM) | Efectivo, transferencia, Mercado Pago, tarjeta (clientes); efectivo y transferencia (sistema). |
| pagos_cliente / pago_cliente_medios | pagos_clientes / detalles_pagos_clientes | Pago sin orden = venta de mostrador. |
| (plan único) parametros_sistema `importe_mensual` / `importe_anual` | — | Un único plan; la modalidad vive en `periodos_pago_sistema.modalidad` (ENUM mensual/anual). El plan trimestral y la colección `planes_suscripcion` se eliminaron. |
| suscripciones / periodos_suscripcion | periodos_pago_sistema | `modalidad` ↔ `modalidad`; `duracion_meses` (1 o 12) se deduce de ella.  Pago contra el período; al confirmar se marca pagado y nace el siguiente. |
| pagos_suscripcion / pago_suscripcion_medios | pagos_sistema / detalles_pagos_sistema | comprobantes_pagos_sistema: sin uso en el MVP. |
| notificaciones | notificaciones | Las dirigidas a un rol se expanden por destinatario. |
| auditoria | auditoria | detalle JSON. |
| ia_propuestas | propuestas_ia | `entidad`/`campo` → `contexto` (consultas.problema → problema_consulta; consulta_revisiones → inspeccion; orden_avances → observacion_mecanico) y `consulta_id`/`orden_id`. `texto_original`, `texto_propuesto`, `texto_final`, `estado` (aceptada/editada/descartada). Solo reglas locales. |
| parametros_sistema | — | Configuración (código). |
| intentos_acceso | usuarios.intentos_fallidos / bloqueado_hasta | |
| movimientos_mecanico | movimientos_mecanicos | `tipo` comision/adelanto; `mecanico_id` (mecanicos.id) → usuarios.id; comisión con `orden_id` (UNIQUE por orden), adelanto sin orden. |
| liquidaciones | liquidaciones_mecanicos | Estados pendiente/pagada/anulada; totales = comisiones − adelantos. |
| liquidacion_detalles | detalles_liquidaciones_mecanicos | Un movimiento en una sola liquidación (UNIQUE). Anular = borrar los detalles. |
| consulta_fotos | **ELIMINADA** | Junto con `archivos_trabajos`. |

## Tablas de la base sin uso en el MVP
`comprobantes_pagos_sistema` (vacía; el MVP no adjunta comprobantes) e `historial_precios_catalogo` (1 fila de prueba rotulada; el MVP no registra cambios de precio). El resto de las 30 tablas tiene equivalente en el MVP.

## Fórmulas y reglas de MySQL equivalentes a las del MVP
- Comisión = mano de obra (`detalles_presupuestos.tipo = 'mano_obra'`) × `comision_pct` ÷ 100 (prueba SQL 10.3).
- Total a pagar = comisiones − adelantos, `>= 0` (CHECK). Un movimiento en una sola liquidación (UNIQUE). Una comisión por orden (UNIQUE `uq_movmec_orden_tipo`).
- Vencimiento = inicio + 1 mes (mensual) o + 12 meses (anual); tolerancia fija de 3 días (CHECK).
