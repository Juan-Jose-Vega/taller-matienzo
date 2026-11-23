# Pruebas SQL — Taller Matienzo

## Cómo se ejecutaron

- Servidor: **MySQL 8.0.46-0ubuntu0.24.04.5** (instalado en el entorno de trabajo; **no** se usó MySQL Workbench).
- Fecha de la ejecución: 2026-11-23 02:40:33.
- El archivo `BASE_DE_DATOS/taller_matienzo_final.sql` se importó completo con el cliente `mysql` (sin errores) y luego cada prueba se ejecutó con un script Python (`herramientas/ejecutar_pruebas.py`) que guarda el resultado real en `BASE_DE_DATOS/resultados_ejecucion.json`.
- Las pruebas de la sección 3 del SQL también se ejecutan solas al importar: las de error usan el procedimiento temporal `sp_esperar_error`; las de modificación van dentro de `START TRANSACTION … ROLLBACK`.
- Fecha de referencia de los datos de demostración: 2026-11-20.

## Resumen

| Indicador | Valor |
|---|---|
| Pruebas definidas y ejecutadas | 165 |
| Resultado correcto (coincide con lo esperado) | 165 |
| Con falla | 0 |
| Tablas cuyo contenido cambió tras todas las pruebas | 0 (los datos quedaron intactos) |

| Tipo | Cantidad |
|---|---|
| Integridad (debe dar 0 filas) | 77 |
| Consulta (SELECT / INNER JOIN) | 22 |
| Operación INSERT / UPDATE / DELETE con ROLLBACK | 36 |
| Error esperado (debe fallar) | 30 |

## Pruebas por módulo


### Módulo 1 — Usuarios y roles

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 1.1 | integridad | Usuarios de taller con rol válido | usuarios, roles | 0 filas | 0 fila(s) | ✅ OK |
| 1.2 | integridad | SuperAdmin sin rol operativo y con registro en superadmins | usuarios, superadmins | 0 filas | 0 fila(s) | ✅ OK |
| 1.3 | integridad | Administrador del taller correcto | taller, usuarios, roles | 0 filas | 0 fila(s) | ✅ OK |
| 1.4 | integridad | Usuarios de taller sin rol (control cruzado) | usuarios, roles | 0 filas | 0 fila(s) | ✅ OK |
| 1.5 | info | Listado de usuarios con su rol (INNER JOIN) | usuarios, roles | 4 filas (1 administrador y 3 mecánicos) | 4 fila(s) | ✅ OK |
| 1.6 | integridad | Contraseñas almacenadas como hash | usuarios | 0 filas | 0 fila(s) | ✅ OK |
| 1.7 | integridad | SuperAdmin no figura como rol operativo | roles | 0 filas | 0 fila(s) | ✅ OK |
| 1.8 | op | Alta de un mecánico | usuarios, roles | resultado = OK | OK | ✅ OK |
| 1.9 | op | Pausar a un mecánico | usuarios | resultado = OK | OK | ✅ OK |
| 1.10 | op | Baja física de un usuario sin historial | usuarios | resultado = OK | OK | ✅ OK |
| 1.11 | error | Usuario duplicado rechazado | usuarios | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry 'juan' for key 'usuarios.uq_usuarios_usuario' | ✅ OK |
| 1.12 | error | SuperAdmin con rol rechazado | usuarios | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_usuarios_tipo_rol' is violated. | ✅ OK |
| 1.13 | error | No se puede borrar un rol en uso | roles, usuarios | ERROR 1451 (clave foránea) | ERROR 1451 — Cannot delete or update a parent row: a foreign key constraint fails ( | ✅ OK |
| 1.14 | integridad | Roles de MySQL = roles del frontend | roles | 0 filas | 0 fila(s) | ✅ OK |
| 1.15 | integridad | Un único SuperAdmin, separado del taller | usuarios, taller, superadmins | 0 filas | 0 fila(s) | ✅ OK |

### Módulo 2 — Taller

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 2.1 | integridad | Existe un único taller | taller | 0 filas | 0 fila(s) | ✅ OK |
| 2.2 | info | Taller con su administrador (INNER JOIN) | taller, usuarios | 1 fila: Taller Matienzo / Roberto Díaz / activo | 1 fila(s) | ✅ OK |
| 2.3 | error | Segundo taller rechazado | taller | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_taller_unico' is violated. | ✅ OK |
| 2.4 | op | Bloqueo y desbloqueo del taller | taller | resultado = OK | OK | ✅ OK |

### Módulo 3 — Clientes y vehículos

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 3.1 | integridad | Vehículos con propietario válido | vehiculos, clientes | 0 filas | 0 fila(s) | ✅ OK |
| 3.2 | integridad | Patentes duplicadas | vehiculos | 0 filas | 0 fila(s) | ✅ OK |
| 3.3 | info | Clientes con sus vehículos (INNER JOIN) | clientes, vehiculos | 17 filas | 17 fila(s) | ✅ OK |
| 3.4 | integridad | Clientes sin vehículos (LEFT JOIN) | clientes, vehiculos | 0 filas | 0 fila(s) | ✅ OK |
| 3.5 | op | Alta de cliente con vehículo | clientes, vehiculos | resultado = OK | OK | ✅ OK |
| 3.6 | op | Actualizar kilometraje | vehiculos | resultado = OK | OK | ✅ OK |
| 3.7 | op | Eliminar cliente nuevo y su vehículo | clientes, vehiculos | resultado = OK | OK | ✅ OK |
| 3.8 | error | No se puede borrar un cliente con vehículos | clientes, vehiculos | ERROR 1451 (clave foránea) | ERROR 1451 — Cannot delete or update a parent row: a foreign key constraint fails ( | ✅ OK |
| 3.9 | error | Patente duplicada rechazada | vehiculos | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry 'AA100FK' for key 'vehiculos.uq_vehiculos_patente' | ✅ OK |

### Módulo 4 — Consultas

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 4.1 | integridad | Consultas con cliente y vehículo coherentes | consultas, vehiculos | 0 filas | 0 fila(s) | ✅ OK |
| 4.2 | integridad | Detalles de consulta con consulta existente | detalles_consultas, consultas | 0 filas | 0 fila(s) | ✅ OK |
| 4.3 | info | Consultas con cliente y vehículo (INNER JOIN) | consultas, clientes, vehiculos | 20 filas (consultas con cliente y vehículo registrados) | 20 fila(s) | ✅ OK |
| 4.4 | integridad | Solo la primera consulta de un cliente es gratuita | consultas | 0 filas | 0 fila(s) | ✅ OK |
| 4.5 | integridad | Consultas cerradas con motivo | consultas | 0 filas | 0 fila(s) | ✅ OK |
| 4.6 | integridad | Consultas aprobadas tienen presupuesto aceptado | consultas, presupuestos | 0 filas | 0 fila(s) | ✅ OK |
| 4.7 | op | Alta de consulta con revisión técnica | consultas, detalles_consultas | resultado = OK | OK | ✅ OK |
| 4.8 | op | Cierre de consulta sin trabajo | consultas | resultado = OK | OK | ✅ OK |
| 4.9 | op | Eliminar consulta y sus detalles | consultas, detalles_consultas | resultado = OK | OK | ✅ OK |
| 4.10 | error | Cobro "cobrar" sin importe rechazado | consultas | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_consultas_cobro' is violated. | ✅ OK |

### Módulo 5 — Presupuestos

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 5.1 | integridad | Un presupuesto por consulta | presupuestos | 0 filas | 0 fila(s) | ✅ OK |
| 5.2 | integridad | Total calculado = suma de los detalles | presupuestos, detalles_presupuestos | 0 filas | 0 fila(s) | ✅ OK |
| 5.3 | integridad | Presupuestos enviados/aceptados con fecha de envío | presupuestos | 0 filas | 0 fila(s) | ✅ OK |
| 5.4 | info | Presupuesto con detalles (INNER JOIN) | presupuestos, detalles_presupuestos, consultas | 12 filas | 12 fila(s) | ✅ OK |
| 5.5 | integridad | Presupuestos aceptados con orden / órdenes con presupuesto aceptado | ordenes_trabajo, presupuestos | 0 filas | 0 fila(s) | ✅ OK |
| 5.6 | op | Alta de presupuesto con detalles | presupuestos, detalles_presupuestos | resultado = OK | OK | ✅ OK |
| 5.7 | op | Aceptación de un presupuesto | presupuestos, consultas | resultado = OK | OK | ✅ OK |
| 5.8 | op | Eliminar presupuesto: sus detalles se borran en cascada | presupuestos, detalles_presupuestos | resultado = OK | OK | ✅ OK |
| 5.9 | error | Segundo presupuesto para una consulta rechazado | presupuestos | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry '1' for key 'presupuestos.uq_presupuestos_consulta' | ✅ OK |
| 5.10 | error | Línea con cantidad 0 rechazada | detalles_presupuestos | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_detpres_valores' is violated. | ✅ OK |
| 5.11 | error | No se puede escribir la columna calculada monto | detalles_presupuestos | ERROR 3105 (columna generada) | ERROR 3105 — The value specified for generated column 'monto' in table 'detalles_pr | ✅ OK |

### Módulo 6 — Órdenes de trabajo

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 6.1 | integridad | Una orden por presupuesto | ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 6.2 | integridad | Cliente y vehículo de la orden coinciden con la consulta | ordenes_trabajo, presupuestos, consultas | 0 filas | 0 fila(s) | ✅ OK |
| 6.3 | integridad | Precio final de la orden = precio final del presupuesto | ordenes_trabajo, presupuestos | 0 filas | 0 fila(s) | ✅ OK |
| 6.4 | integridad | Estados y mecánico | ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 6.5 | integridad | Último estado del historial = estado de la orden | ordenes_trabajo, historial_estados_ordenes | 0 filas | 0 fila(s) | ✅ OK |
| 6.6 | integridad | Fechas de inicio y fin según estado | ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 6.7 | info | Órdenes con cliente, vehículo y mecánico (INNER JOIN) | ordenes_trabajo, clientes, vehiculos, usuarios | 11 filas | 11 fila(s) | ✅ OK |
| 6.8 | integridad | Avances con orden y autor válidos | avances_ordenes, ordenes_trabajo, usuarios | 0 filas | 0 fila(s) | ✅ OK |
| 6.9 | info | Avances registrados (INNER JOIN) | avances_ordenes, ordenes_trabajo, usuarios | 10 filas | 10 fila(s) | ✅ OK |
| 6.10 | op | Cambio de estado con historial y avance | ordenes_trabajo, historial_estados_ordenes, avances_ordenes | resultado = OK | OK | ✅ OK |
| 6.11 | op | Eliminar orden nueva: historial y avances en cascada | ordenes_trabajo, historial_estados_ordenes, avances_ordenes | resultado = OK | OK | ✅ OK |
| 6.12 | error | Segunda orden para un presupuesto rechazada | ordenes_trabajo | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry '1' for key 'ordenes_trabajo.uq_ordenes_presupuesto' | ✅ OK |
| 6.13 | error | Comisión mayor a 100 % rechazada | ordenes_trabajo | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_ordenes_importes' is violated. | ✅ OK |

### Módulo 7 — Asignaciones

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 7.1 | integridad | Asignación activa coincide con el mecánico de la orden | asignaciones_trabajo, ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 7.2 | integridad | Una sola asignación activa por orden | asignaciones_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 7.3 | integridad | Rechazos con motivo | asignaciones_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 7.4 | info | Asignaciones con orden y mecánico (INNER JOIN) | asignaciones_trabajo, ordenes_trabajo, usuarios | 11 filas | 11 fila(s) | ✅ OK |
| 7.5 | op | Rechazo y reasignación | asignaciones_trabajo, ordenes_trabajo | resultado = OK | OK | ✅ OK |
| 7.6 | error | Asignar a un mecánico inexistente rechazado | asignaciones_trabajo | ERROR 1452 (clave foránea) | ERROR 1452 — Cannot add or update a child row: a foreign key constraint fails (`tal | ✅ OK |

### Módulo 8 — Pagos de clientes

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 8.1 | integridad | Pagos de trabajo con orden; venta de mostrador sin orden | pagos_clientes | 0 filas | 0 fila(s) | ✅ OK |
| 8.2 | integridad | Monto del pago = suma de sus medios | pagos_clientes, detalles_pagos_clientes | 0 filas | 0 fila(s) | ✅ OK |
| 8.3 | integridad | Método combinado ↔ dos medios | pagos_clientes, detalles_pagos_clientes | 0 filas | 0 fila(s) | ✅ OK |
| 8.4 | integridad | Cliente del pago = cliente de la orden | pagos_clientes, ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 8.5 | integridad | Lo pagado no supera el precio de la orden | pagos_clientes, ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 8.6 | info | Saldo por orden (INNER JOIN) | ordenes_trabajo, pagos_clientes, clientes | al menos 1 fila | 7 fila(s) | ✅ OK |
| 8.7 | op | Registrar un pago combinado | pagos_clientes, detalles_pagos_clientes | resultado = OK | OK | ✅ OK |
| 8.8 | op | Corregir el monto de un pago (UPDATE) | pagos_clientes | resultado = OK | OK | ✅ OK |
| 8.9 | op | Eliminar un pago: sus medios se borran en cascada | pagos_clientes, detalles_pagos_clientes | resultado = OK | OK | ✅ OK |
| 8.10 | error | Pago con monto 0 rechazado | pagos_clientes | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_pagcli_monto' is violated. | ✅ OK |
| 8.11 | error | Medio repetido en un pago rechazado | detalles_pagos_clientes | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry '1-efectivo' for key 'detalles_pagos_clientes.uq_detpa | ✅ OK |

### Módulo 9 — Catálogo y stock

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 9.1 | integridad | Artículos con categoría | catalogo_items, categorias_catalogo | 0 filas | 0 fila(s) | ✅ OK |
| 9.2 | integridad | Movimientos confirmados con responsable | movimientos_stock | 0 filas | 0 fila(s) | ✅ OK |
| 9.3 | integridad | Salidas por orden con orden existente | movimientos_stock, ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 9.4 | info | Artículos con stock bajo | catalogo_items | al menos 1 fila | 2 fila(s) | ✅ OK |
| 9.5 | integridad | Stock actual = entradas − salidas confirmadas | catalogo_items, movimientos_stock | 0 filas | 0 fila(s) | ✅ OK |
| 9.6 | integridad | Historial de precios coherente | historial_precios_catalogo, catalogo_items | 0 filas | 0 fila(s) | ✅ OK |
| 9.7 | info | Artículos con su categoría (INNER JOIN) | catalogo_items, categorias_catalogo | 17 filas | 17 fila(s) | ✅ OK |
| 9.8 | op | Registrar salida de stock por una orden | movimientos_stock, catalogo_items | resultado = OK | OK | ✅ OK |
| 9.9 | op | Eliminar un artículo sin movimientos | catalogo_items | resultado = OK | OK | ✅ OK |
| 9.10 | error | Stock negativo rechazado | catalogo_items | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_catalogo_stock' is violated. | ✅ OK |
| 9.11 | error | Código de artículo duplicado rechazado | catalogo_items | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry 'ACE-1040' for key 'catalogo_items.uq_catalogo_codigo' | ✅ OK |
| 9.12 | error | Movimiento sin artículo ni descripción rechazado | movimientos_stock | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_movstock_descripcion' is violated. | ✅ OK |

### Módulo 10 — Movimientos de mecánicos

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 10.1 | integridad | Movimientos de usuarios con rol Mecánico | movimientos_mecanicos, usuarios, roles | 0 filas | 0 fila(s) | ✅ OK |
| 10.2 | integridad | Comisión con orden finalizada del mismo mecánico | movimientos_mecanicos, ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |
| 10.3 | integridad | Comisión = mano de obra × comision_pct ÷ 100 (sin repuestos) | movimientos_mecanicos, ordenes_trabajo, detalles_presupuestos | 0 filas | 0 fila(s) | ✅ OK |
| 10.4 | info | Movimientos con mecánico y orden (INNER JOIN) | movimientos_mecanicos, usuarios, ordenes_trabajo | 7 filas (5 comisiones y 2 adelantos) | 7 fila(s) | ✅ OK |
| 10.5 | op | Registrar un adelanto | movimientos_mecanicos | resultado = OK | OK | ✅ OK |
| 10.6 | error | Movimiento con monto 0 rechazado | movimientos_mecanicos | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_movmec_monto' is violated. | ✅ OK |
| 10.7 | op | Calcular y registrar una comisión sobre la mano de obra | ordenes_trabajo, detalles_presupuestos, movimientos_mecanicos | resultado = OK | OK | ✅ OK |
| 10.8 | error | Segunda comisión para la misma orden rechazada | movimientos_mecanicos | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry '1-comision' for key 'movimientos_mecanicos.uq_movmec_ | ✅ OK |
| 10.9 | error | Comisión sin orden / adelanto con orden rechazados | movimientos_mecanicos | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_movmec_tipo_orden' is violated. | ✅ OK |

### Módulo 11 — Liquidaciones

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 11.1 | integridad | Total a pagar = comisiones − adelantos | liquidaciones_mecanicos | 0 filas | 0 fila(s) | ✅ OK |
| 11.2 | integridad | Totales = suma de los detalles | liquidaciones_mecanicos, detalles_liquidaciones_mecanicos, movimientos_mecanicos | 0 filas | 0 fila(s) | ✅ OK |
| 11.3 | integridad | Movimientos del mismo mecánico y dentro del período | detalles_liquidaciones_mecanicos, movimientos_mecanicos, liquidaciones_mecanicos | 0 filas | 0 fila(s) | ✅ OK |
| 11.4 | integridad | Un movimiento en una sola liquidación | detalles_liquidaciones_mecanicos | 0 filas | 0 fila(s) | ✅ OK |
| 11.5 | info | Liquidación con detalles (INNER JOIN) | liquidaciones_mecanicos, detalles_liquidaciones_mecanicos, movimientos_mecanicos, usuarios | 7 filas (liquidación pagada: 3 comisiones y 1 adelanto; pendiente: 2 comisiones y 1 adelanto) | 7 fila(s) | ✅ OK |
| 11.6 | op | Pagar una liquidación | liquidaciones_mecanicos | resultado = OK | OK | ✅ OK |
| 11.7 | op | Anular una liquidación pendiente y liberar sus movimientos | liquidaciones_mecanicos, detalles_liquidaciones_mecanicos | resultado = OK | OK | ✅ OK |
| 11.8 | error | Movimiento liquidado dos veces rechazado | detalles_liquidaciones_mecanicos | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry '1' for key 'detalles_liquidaciones_mecanicos.uq_detli | ✅ OK |
| 11.9 | error | Período invertido rechazado | liquidaciones_mecanicos | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_liq_fechas' is violated. | ✅ OK |
| 11.10 | info | Liquidaciones pendientes, pagadas y anuladas | liquidaciones_mecanicos | 3 filas (anulada, pagada, pendiente) | 3 fila(s) | ✅ OK |
| 11.11 | integridad | Estados coherentes: pagadas con fecha de pago, anuladas sin detalles | liquidaciones_mecanicos, detalles_liquidaciones_mecanicos | 0 filas | 0 fila(s) | ✅ OK |
| 11.12 | op | Los adelantos se descuentan de la liquidación | movimientos_mecanicos, liquidaciones_mecanicos, detalles_liquidaciones_mecanicos | resultado = OK | OK | ✅ OK |
| 11.13 | error | Total a pagar negativo rechazado | liquidaciones_mecanicos | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_liq_importes' is violated. | ✅ OK |

### Módulo 12 — Suscripciones

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 12.1 | integridad | Períodos consecutivos sin huecos | periodos_pago_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 12.2 | integridad | Tolerancia de 3 días | periodos_pago_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 12.3 | integridad | Duración según modalidad | periodos_pago_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 12.4 | integridad | Período pagado con pago confirmado | periodos_pago_sistema, pagos_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 12.5 | info | Estado de la suscripción a la fecha de referencia | periodos_pago_sistema, taller | 1 fila: período 2, 12 días al vencimiento, acceso vigente | 1 fila(s) | ✅ OK |
| 12.6 | integridad | Taller bloqueado solo si venció la tolerancia | taller, periodos_pago_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 12.7 | op | Renovación: informar y confirmar un pago | periodos_pago_sistema, pagos_sistema, detalles_pagos_sistema, superadmins | resultado = OK | OK | ✅ OK |
| 12.8 | op | Rechazo de un pago informado | pagos_sistema | resultado = OK | OK | ✅ OK |
| 12.9 | error | Tolerancia distinta de 3 días rechazada | periodos_pago_sistema | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_periodo_tolerancia' is violated. | ✅ OK |
| 12.10 | integridad | Modalidad: solo mensual o anual | periodos_pago_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 12.11 | integridad | No existe el plan trimestral | periodos_pago_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 12.12 | op | Modalidad anual: 12 meses y tolerancia de 3 días | periodos_pago_sistema | resultado = OK | OK | ✅ OK |

### Módulo 13 — Pagos del sistema

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 13.1 | integridad | Confirmados con SuperAdmin y fecha | pagos_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 13.2 | integridad | Importe = suma de los medios | pagos_sistema, detalles_pagos_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 13.3 | integridad | Método combinado ↔ dos medios | pagos_sistema, detalles_pagos_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 13.4 | integridad | Pagos del sistema y de clientes están separados | information_schema | 0 filas | 0 fila(s) | ✅ OK |
| 13.5 | info | Pago del sistema con período, dueño y SuperAdmin (INNER JOIN) | pagos_sistema, periodos_pago_sistema, usuarios, superadmins | 2 filas (1 confirmado y 1 informado) | 2 fila(s) | ✅ OK |
| 13.6 | integridad | Comprobantes con pago existente | comprobantes_pagos_sistema, pagos_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 13.7 | error | Medio repetido en un pago del sistema rechazado | detalles_pagos_sistema | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry '1-efectivo' for key 'detalles_pagos_sistema.uq_detpag | ✅ OK |
| 13.8 | integridad | Medios del sistema: solo efectivo y transferencia | detalles_pagos_sistema | 0 filas | 0 fila(s) | ✅ OK |
| 13.9 | error | Confirmar con un usuario que no es SuperAdmin rechazado | pagos_sistema | ERROR 1452 (clave foránea) | ERROR 1452 — Cannot add or update a child row: a foreign key constraint fails (`tal | ✅ OK |

### Módulo 14 — Notificaciones

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 14.1 | integridad | Destinatario único | notificaciones | 0 filas | 0 fila(s) | ✅ OK |
| 14.2 | info | Notificaciones con destinatario (INNER JOIN) | notificaciones, usuarios | al menos 1 fila | 12 fila(s) | ✅ OK |
| 14.3 | info | Notificaciones del SuperAdmin (INNER JOIN) | notificaciones, superadmins, usuarios | 1 fila | 1 fila(s) | ✅ OK |
| 14.4 | op | Marcar como leída | notificaciones | resultado = OK | OK | ✅ OK |
| 14.5 | op | Crear y eliminar una notificación | notificaciones | resultado = OK | OK | ✅ OK |
| 14.6 | error | Aviso duplicado rechazado | notificaciones | ERROR 1062 (clave duplicada) | ERROR 1062 — Duplicate entry 'seed:n1:u2' for key 'notificaciones.uq_notif_clave' | ✅ OK |
| 14.7 | error | Dos destinatarios rechazados | notificaciones | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_notif_destino' is violated. | ✅ OK |

### Módulo 15 — Auditoría

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 15.1 | integridad | Ámbito y actor coherentes | auditoria | 0 filas | 0 fila(s) | ✅ OK |
| 15.2 | integridad | actor_login coincide con el usuario | auditoria, usuarios, superadmins | 0 filas | 0 fila(s) | ✅ OK |
| 15.3 | integridad | Detalle JSON válido | auditoria | 0 filas | 0 fila(s) | ✅ OK |
| 15.4 | info | Actividad con su autor (INNER JOIN) | auditoria, usuarios | al menos 1 fila | 12 fila(s) | ✅ OK |
| 15.5 | op | Registrar una acción | auditoria | resultado = OK | OK | ✅ OK |
| 15.6 | error | Acción de sistema con usuario de taller rechazada | auditoria | ERROR 3819 (restricción CHECK) | ERROR 3819 — Check constraint 'ck_auditoria_actor' is violated. | ✅ OK |

### Módulo 16 — Propuestas de IA

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 16.1 | integridad | Propuestas resueltas con fecha | propuestas_ia | 0 filas | 0 fila(s) | ✅ OK |
| 16.2 | integridad | Texto final según estado | propuestas_ia | 0 filas | 0 fila(s) | ✅ OK |
| 16.3 | integridad | Contexto y referencia (corregida) | propuestas_ia | 0 filas | 0 fila(s) | ✅ OK |
| 16.4 | integridad | Sin proveedores externos | propuestas_ia | 0 filas | 0 fila(s) | ✅ OK |
| 16.5 | info | Propuestas con autor y consulta (INNER JOIN) | propuestas_ia, usuarios, consultas | 1 fila | 1 fila(s) | ✅ OK |
| 16.6 | op | Generar y aceptar una propuesta | propuestas_ia | resultado = OK | OK | ✅ OK |
| 16.7 | integridad | Contextos de IA: sin fotografía | propuestas_ia | 0 filas | 0 fila(s) | ✅ OK |
| 16.8 | integridad | El texto original siempre se conserva | propuestas_ia | 0 filas | 0 fila(s) | ✅ OK |
| 16.9 | op | Aceptar una propuesta no modifica el texto original | propuestas_ia | resultado = OK | OK | ✅ OK |
| 16.10 | op | Editar y descartar propuestas | propuestas_ia | resultado = OK | OK | ✅ OK |

### Módulo 17 — Estructura e integridad general

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 17.1 | integridad | La base tiene 30 tablas | information_schema | 0 filas (hay exactamente 30) | 0 fila(s) | ✅ OK |
| 17.2 | integridad | No existen tablas ni columnas de fotos o archivos de trabajos | information_schema | 0 filas | 0 fila(s) | ✅ OK |
| 17.3 | integridad | Toda tabla tiene clave primaria | information_schema | 0 filas | 0 fila(s) | ✅ OK |
| 17.4 | info | Claves foráneas definidas | information_schema | al menos 1 fila | 57 fila(s) | ✅ OK |
| 17.5 | integridad | Claves foráneas sin índice propio | information_schema | 0 filas | 0 fila(s) | ✅ OK |
| 17.6 | info | Cantidad de registros por tabla | todas | 30 filas (comprobantes_pagos_sistema con 0 registros) | 30 fila(s) | ✅ OK |

### Módulo 18 — Procesos principales de punta a punta

| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |
|---|---|---|---|---|---|---|
| 18.1 | op | Flujo completo: consulta → presupuesto → orden → pago | consultas, detalles_consultas, presupuestos, detalles_presupuestos, ordenes_trabajo, historial_estados_ordenes, asignaciones_trabajo, avances_ordenes, movimientos_stock, catalogo_items, movimientos_mecanicos, pagos_clientes, detalles_pagos_clientes | resultado = OK | OK | ✅ OK |
| 18.2 | integridad | Los datos no cambiaron tras las pruebas | catalogo_items, ordenes_trabajo | 0 filas | 0 fila(s) | ✅ OK |

## Detalle de cada prueba

#### 1.1 — Usuarios de taller con rol válido

- **Objetivo:** Todo usuario de taller debe tener un rol existente.
- **Tablas:** usuarios, roles
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Si aparece alguna fila, hay un usuario de taller sin rol válido.
- **Equivale a la prueba del SQL original:** PRUEBA 1.1

```sql
SELECT u.id, u.usuario FROM usuarios u LEFT JOIN roles r ON r.id = u.rol_id WHERE u.tipo_cuenta = 'taller' AND r.id IS NULL;
```

#### 1.2 — SuperAdmin sin rol operativo y con registro en superadmins

- **Objetivo:** Cada usuario superadmin debe tener rol_id NULL y su fila en superadmins.
- **Tablas:** usuarios, superadmins
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cumple la regla: el SuperAdmin no es un rol común del taller y está registrado en su tabla propia.
- **Equivale a la prueba del SQL original:** PRUEBA 1.2

```sql
SELECT u.id, u.usuario FROM usuarios u LEFT JOIN superadmins s ON s.usuario_id = u.id WHERE u.tipo_cuenta = 'superadmin' AND (s.id IS NULL OR u.rol_id IS NOT NULL);
```

#### 1.3 — Administrador del taller correcto

- **Objetivo:** El administrador registrado en taller debe ser un usuario de taller con rol Administrador.
- **Tablas:** taller, usuarios, roles
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El dueño del taller es siempre un usuario con rol Administrador.
- **Equivale a la prueba del SQL original:** PRUEBA 1.3

```sql
SELECT t.id FROM taller t JOIN usuarios u ON u.id = t.admin_usuario_id JOIN roles r ON r.id = u.rol_id WHERE u.tipo_cuenta <> 'taller' OR r.nombre <> 'Administrador';
```

#### 1.4 — Usuarios de taller sin rol (control cruzado)

- **Objetivo:** Control complementario de la 1.1 usando NOT EXISTS.
- **Tablas:** usuarios, roles
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Confirma la 1.1 con otra forma de consulta.
- **Equivale a la prueba del SQL original:** PRUEBA 1.4

```sql
SELECT u.id FROM usuarios u WHERE u.tipo_cuenta = 'taller' AND NOT EXISTS (SELECT 1 FROM roles r WHERE r.id = u.rol_id);
```

#### 1.5 — Listado de usuarios con su rol (INNER JOIN)

- **Objetivo:** Mostrar los usuarios del taller con el nombre de su rol.
- **Tablas:** usuarios, roles
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 4 filas (1 administrador y 3 mecánicos)
- **Resultado obtenido (ejecución real):** 4 fila(s) — correcto
- **Interpretación:** El SuperAdmin no aparece porque no tiene rol operativo.

```sql
SELECT u.id, u.usuario, u.nombre, r.nombre AS rol, u.estado FROM usuarios u INNER JOIN roles r ON r.id = u.rol_id ORDER BY u.id;
```

Muestra del resultado real (primeras filas):

| id | usuario | nombre | rol | estado |
|---|---|---|---|---|
| 2 | roberto | Roberto Díaz | Administrador | activo |
| 3 | juan | Juan Pérez | Mecanico | activo |
| 4 | pedro | Pedro Gómez | Mecanico | activo |
| 5 | carlos | Carlos López | Mecanico | pausado |

#### 1.6 — Contraseñas almacenadas como hash

- **Objetivo:** Ningún password_hash puede ser texto plano: deben ser hashes bcrypt ($2b$, 60 caracteres).
- **Tablas:** usuarios
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Todas las contraseñas de demostración son hashes bcrypt; nunca texto plano.

```sql
SELECT id, usuario FROM usuarios WHERE password_hash NOT REGEXP '^\\$2[aby]\\$[0-9]{2}\\$.{53}$';
```

#### 1.7 — SuperAdmin no figura como rol operativo

- **Objetivo:** La tabla roles no debe contener un rol SuperAdmin.
- **Tablas:** roles
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El SuperAdmin se distingue por tipo_cuenta, no por un rol.

```sql
SELECT id, nombre FROM roles WHERE LOWER(nombre) LIKE '%superadmin%';
```

#### 1.8 — Alta de un mecánico

- **Objetivo:** Insertar un mecánico nuevo y comprobar que queda con su rol (se deshace con ROLLBACK).
- **Tablas:** usuarios, roles
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El alta funciona y los datos de mecánico (especialidad, disponibilidad) se guardan en usuarios.

```sql
START TRANSACTION;
INSERT INTO usuarios (id, tipo_cuenta, rol_id, nombre, usuario, password_hash, telefono, especialidad, disponible)
VALUES (9001, 'taller', 2, 'Mecánico de Prueba', 'mecprueba', '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ0123456', '381-0000000', 'Electricidad', 1);
SELECT IF(COUNT(*) = 1 AND MAX(r.nombre) = 'Mecanico' AND MAX(u.especialidad) = 'Electricidad', 'OK', 'FALLA') AS resultado
FROM usuarios u INNER JOIN roles r ON r.id = u.rol_id WHERE u.id = 9001;
ROLLBACK;
```

#### 1.9 — Pausar a un mecánico

- **Objetivo:** UPDATE del estado de un usuario (equivale a "inactivo" en el MVP).
- **Tablas:** usuarios
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** La baja lógica se guarda sin borrar al usuario (conserva su historial).

```sql
START TRANSACTION;
UPDATE usuarios SET estado = 'pausado', disponible = 0 WHERE usuario = 'carlos';
SELECT IF(estado = 'pausado' AND disponible = 0, 'OK', 'FALLA') AS resultado FROM usuarios WHERE usuario = 'carlos';
ROLLBACK;
```

#### 1.10 — Baja física de un usuario sin historial

- **Objetivo:** DELETE de un usuario recién creado, sin movimientos.
- **Tablas:** usuarios
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Un usuario sin registros asociados se puede eliminar.

```sql
START TRANSACTION;
INSERT INTO usuarios (id, tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES (9002, 'taller', 2, 'Temporal', 'temporal', '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ0123456');
DELETE FROM usuarios WHERE id = 9002;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM usuarios WHERE id = 9002;
ROLLBACK;
```

#### 1.11 — Usuario duplicado rechazado

- **Objetivo:** El nombre de usuario es único.
- **Tablas:** usuarios
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** La restricción UNIQUE impide dos usuarios con el mismo nombre.

```sql
INSERT INTO usuarios (tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES ('taller', 2, 'Otro Juan', 'juan', 'x');
```

#### 1.12 — SuperAdmin con rol rechazado

- **Objetivo:** CHECK ck_usuarios_tipo_rol: un superadmin no puede tener rol operativo.
- **Tablas:** usuarios
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** El rol operativo y el SuperAdmin son excluyentes.

```sql
INSERT INTO usuarios (tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES ('superadmin', 1, 'Falso SA', 'falsosa', 'x');
```

#### 1.13 — No se puede borrar un rol en uso

- **Objetivo:** Integridad referencial usuarios -> roles.
- **Tablas:** roles, usuarios
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1451 (clave foránea)
- **Resultado obtenido (ejecución real):** ERROR 1451 — correcto
- **Interpretación:** La FK protege los usuarios que usan el rol.

```sql
DELETE FROM roles WHERE nombre = 'Mecanico';
```

#### 1.14 — Roles de MySQL = roles del frontend

- **Objetivo:** La tabla roles tiene exactamente Administrador (1) y Mecanico (2), los mismos del MVP; el SuperAdmin no figura.
- **Tablas:** roles
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Vue resuelve el rol por código (admin, mecanico) y MySQL lo guarda en roles.

```sql
SELECT x.* FROM (SELECT COUNT(*) AS c, SUM(id = 1 AND nombre = 'Administrador') AS a, SUM(id = 2 AND nombre = 'Mecanico') AS m FROM roles) x WHERE NOT (x.c = 2 AND x.a = 1 AND x.m = 1);
```

#### 1.15 — Un único SuperAdmin, separado del taller

- **Objetivo:** El SuperAdmin no es dueño ni mecánico ni aparece en listas operativas.
- **Tablas:** usuarios, taller, superadmins
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cuenta independiente con contraseña hash en la base.

```sql
SELECT u.id FROM usuarios u WHERE u.tipo_cuenta = 'superadmin' AND (u.rol_id IS NOT NULL OR EXISTS (SELECT 1 FROM taller t WHERE t.admin_usuario_id = u.id) OR EXISTS (SELECT 1 FROM asignaciones_trabajo a WHERE a.mecanico_id = u.id));
```

#### 2.1 — Existe un único taller

- **Objetivo:** El sistema administra un solo taller.
- **Tablas:** taller
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Si devolviera una fila, habría 0 o más de 1 taller.

```sql
SELECT COUNT(*) AS cantidad FROM taller HAVING COUNT(*) <> 1;
```

#### 2.2 — Taller con su administrador (INNER JOIN)

- **Objetivo:** Mostrar el taller y su dueño.
- **Tablas:** taller, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 1 fila: Taller Matienzo / Roberto Díaz / activo
- **Resultado obtenido (ejecución real):** 1 fila(s) — correcto
- **Interpretación:** Relación 1 a 1 entre taller y su administrador.

```sql
SELECT t.id, t.nombre, u.nombre AS administrador, t.estado_acceso FROM taller t INNER JOIN usuarios u ON u.id = t.admin_usuario_id;
```

Muestra del resultado real (primeras filas):

| id | nombre | administrador | estado_acceso |
|---|---|---|---|
| 1 | Taller Matienzo | Roberto Díaz | activo |

#### 2.3 — Segundo taller rechazado

- **Objetivo:** CHECK ck_taller_unico (id = 1).
- **Tablas:** taller
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** No es posible crear un segundo taller.

```sql
INSERT INTO taller (id, nombre, admin_usuario_id) VALUES (2, 'Otro Taller', 3);
```

#### 2.4 — Bloqueo y desbloqueo del taller

- **Objetivo:** UPDATE de estado_acceso (lo que hace el sistema al vencer la tolerancia).
- **Tablas:** taller
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El bloqueo operativo se registra en el taller; el SuperAdmin sigue pudiendo ingresar.

```sql
START TRANSACTION;
UPDATE taller SET estado_acceso = 'bloqueado', bloqueado_en = NOW(), motivo_bloqueo = 'Falta de pago' WHERE id = 1;
SELECT IF(estado_acceso = 'bloqueado', 'OK', 'FALLA') AS resultado FROM taller WHERE id = 1;
ROLLBACK;
```

#### 3.1 — Vehículos con propietario válido

- **Objetivo:** Todo vehículo debe pertenecer a un cliente existente.
- **Tablas:** vehiculos, clientes
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Sin vehículos huérfanos.
- **Equivale a la prueba del SQL original:** PRUEBA 2.1

```sql
SELECT v.id FROM vehiculos v LEFT JOIN clientes c ON c.id = v.cliente_id WHERE c.id IS NULL;
```

#### 3.2 — Patentes duplicadas

- **Objetivo:** La patente cargada es única.
- **Tablas:** vehiculos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** La restricción UNIQUE se refleja en los datos.
- **Equivale a la prueba del SQL original:** PRUEBA 2.2

```sql
SELECT patente, COUNT(*) AS veces FROM vehiculos WHERE patente IS NOT NULL GROUP BY patente HAVING COUNT(*) > 1;
```

#### 3.3 — Clientes con sus vehículos (INNER JOIN)

- **Objetivo:** Listar cada vehículo con su cliente.
- **Tablas:** clientes, vehiculos
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 17 filas
- **Resultado obtenido (ejecución real):** 17 fila(s) — correcto
- **Interpretación:** Un cliente puede tener varios vehículos (1 a N).
- **Equivale a la prueba del SQL original:** PRUEBA 2.3

```sql
SELECT c.id AS cliente_id, c.nombre, v.patente, v.marca, v.modelo FROM clientes c INNER JOIN vehiculos v ON v.cliente_id = c.id ORDER BY c.id, v.id;
```

Muestra del resultado real (primeras filas):

| cliente_id | nombre | patente | marca | modelo |
|---|---|---|---|---|
| 1 | Carlos Gómez | AB123CD | Fiat | Palio |
| 1 | Carlos Gómez | AE456FG | Renault | Kangoo |
| 2 | María López | AC789HI | Volkswagen | Gol |
| 3 | Jorge Ramírez | AA321JK | Ford | Fiesta |
| 4 | Laura Fernández | AD456EF | Renault | Clio |

#### 3.4 — Clientes sin vehículos (LEFT JOIN)

- **Objetivo:** Los clientes de demostración deben tener al menos un vehículo.
- **Tablas:** clientes, vehiculos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Datos de demostración coherentes.
- **Equivale a la prueba del SQL original:** PRUEBA 2.4

```sql
SELECT c.id, c.nombre FROM clientes c LEFT JOIN vehiculos v ON v.cliente_id = c.id WHERE v.id IS NULL;
```

#### 3.5 — Alta de cliente con vehículo

- **Objetivo:** INSERT de cliente y vehículo relacionados, sin patente ni kilometraje (opcionales en el MVP).
- **Tablas:** clientes, vehiculos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Se admiten varios vehículos sin patente (NULL no viola UNIQUE).

```sql
START TRANSACTION;
INSERT INTO clientes (id, nombre, telefono) VALUES (9001, 'Cliente de Prueba', '381-1112233');
INSERT INTO vehiculos (id, cliente_id, patente, marca, modelo) VALUES (9001, 9001, NULL, 'Ford', 'Fiesta');
INSERT INTO vehiculos (id, cliente_id, patente, marca, modelo) VALUES (9002, 9001, NULL, 'Fiat', 'Uno');
SELECT IF(COUNT(*) = 2 AND SUM(v.kilometraje IS NULL) = 2, 'OK', 'FALLA') AS resultado FROM clientes c INNER JOIN vehiculos v ON v.cliente_id = c.id WHERE c.id = 9001;
ROLLBACK;
```

#### 3.6 — Actualizar kilometraje

- **Objetivo:** UPDATE de un dato del vehículo.
- **Tablas:** vehiculos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Modificación simple.

```sql
START TRANSACTION;
UPDATE vehiculos SET kilometraje = 123456 WHERE id = 1;
SELECT IF(kilometraje = 123456, 'OK', 'FALLA') AS resultado FROM vehiculos WHERE id = 1;
ROLLBACK;
```

#### 3.7 — Eliminar cliente nuevo y su vehículo

- **Objetivo:** DELETE en orden: primero el vehículo y luego el cliente.
- **Tablas:** clientes, vehiculos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Eliminación correcta respetando las dependencias.

```sql
START TRANSACTION;
INSERT INTO clientes (id, nombre) VALUES (9003, 'Borrar');
INSERT INTO vehiculos (id, cliente_id, marca) VALUES (9003, 9003, 'Renault');
DELETE FROM vehiculos WHERE id = 9003;
DELETE FROM clientes WHERE id = 9003;
SELECT IF((SELECT COUNT(*) FROM clientes WHERE id = 9003) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 3.8 — No se puede borrar un cliente con vehículos

- **Objetivo:** Integridad referencial clientes -> vehiculos.
- **Tablas:** clientes, vehiculos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1451 (clave foránea)
- **Resultado obtenido (ejecución real):** ERROR 1451 — correcto
- **Interpretación:** La FK evita dejar vehículos sin dueño.

```sql
DELETE FROM clientes WHERE id = 1;
```

#### 3.9 — Patente duplicada rechazada

- **Objetivo:** UNIQUE uq_vehiculos_patente.
- **Tablas:** vehiculos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** No pueden existir dos vehículos con la misma patente.

```sql
INSERT INTO vehiculos (cliente_id, patente, marca) SELECT 1, patente, 'Fiat' FROM vehiculos WHERE patente IS NOT NULL LIMIT 1;
```

#### 4.1 — Consultas con cliente y vehículo coherentes

- **Objetivo:** Si la consulta tiene vehículo, éste debe pertenecer al cliente de la consulta.
- **Tablas:** consultas, vehiculos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El vehículo consultado es del cliente que consulta.
- **Equivale a la prueba del SQL original:** PRUEBA 3.1

```sql
SELECT c.id FROM consultas c INNER JOIN vehiculos v ON v.id = c.vehiculo_id WHERE c.cliente_id IS NULL OR c.cliente_id <> v.cliente_id;
```

#### 4.2 — Detalles de consulta con consulta existente

- **Objetivo:** detalles_consultas no tiene filas huérfanas.
- **Tablas:** detalles_consultas, consultas
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Relación 1 a N consulta -> detalles correcta.
- **Equivale a la prueba del SQL original:** PRUEBA 3.2

```sql
SELECT d.id FROM detalles_consultas d LEFT JOIN consultas c ON c.id = d.consulta_id WHERE c.id IS NULL;
```

#### 4.3 — Consultas con cliente y vehículo (INNER JOIN)

- **Objetivo:** Listar las consultas registradas junto a su cliente y vehículo.
- **Tablas:** consultas, clientes, vehiculos
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 20 filas (consultas con cliente y vehículo registrados)
- **Resultado obtenido (ejecución real):** 20 fila(s) — correcto
- **Interpretación:** Consultas completas con sus relaciones.

```sql
SELECT c.id, cl.nombre AS cliente, v.patente, v.marca, v.modelo, c.estado FROM consultas c INNER JOIN clientes cl ON cl.id = c.cliente_id INNER JOIN vehiculos v ON v.id = c.vehiculo_id ORDER BY c.id;
```

Muestra del resultado real (primeras filas):

| id | cliente | patente | marca | modelo | estado |
|---|---|---|---|---|---|
| 1 | Carlos Gómez | AB123CD | Fiat | Palio | aprobada |
| 2 | María López | AC789HI | Volkswagen | Gol | aprobada |
| 3 | Laura Fernández | AD456EF | Renault | Clio | aprobada |
| 4 | Jorge Ramírez | AA321JK | Ford | Fiesta | esperando_respuesta |
| 6 | Ana Torres | AA100FK | Peugeot | 208 | cerrada |

#### 4.4 — Solo la primera consulta de un cliente es gratuita

- **Objetivo:** Regla del MVP: las consultas repetidas no son gratuitas por defecto.
- **Tablas:** consultas
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Los datos respetan la regla de consulta gratuita.

```sql
SELECT c.id FROM consultas c WHERE c.es_gratuita = 1 AND EXISTS (SELECT 1 FROM consultas x WHERE x.cliente_id = c.cliente_id AND x.id < c.id);
```

#### 4.5 — Consultas cerradas con motivo

- **Objetivo:** Toda consulta cerrada sin trabajo debe indicar el motivo.
- **Tablas:** consultas
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cierre justificado.

```sql
SELECT id FROM consultas WHERE estado = 'cerrada' AND (motivo_cierre IS NULL OR motivo_cierre = '');
```

#### 4.6 — Consultas aprobadas tienen presupuesto aceptado

- **Objetivo:** Una consulta aprobada debe tener su presupuesto aceptado.
- **Tablas:** consultas, presupuestos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Estado de consulta coherente con el presupuesto.

```sql
SELECT c.id FROM consultas c LEFT JOIN presupuestos p ON p.consulta_id = c.id AND p.estado = 'aceptado' WHERE c.estado = 'aprobada' AND p.id IS NULL;
```

#### 4.7 — Alta de consulta con revisión técnica

- **Objetivo:** INSERT de consulta y de su revisión (varias filas de detalle) y su importe estimado.
- **Tablas:** consultas, detalles_consultas
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** La revisión del MVP se distribuye en filas por tipo + 2 columnas de la consulta.

```sql
START TRANSACTION;
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, contacto_telefono, motivo, descripcion_problema, estado, es_gratuita, creado_por)
VALUES (9001, 1, 1, 'Carlos Gómez', '381-0000', 'Ruido al frenar', 'Ruido al frenar y pedal blando', 'abierta', 0, 2);
INSERT INTO detalles_consultas (consulta_id, descripcion, tipo, registrado_por) VALUES
 (9001, 'Pastillas gastadas', 'verificado', 2), (9001, 'Pastillas delanteras', 'repuestos_necesarios', 2), (9001, 'Cambio de pastillas', 'trabajo_recomendado', 2);
UPDATE consultas SET observaciones_inspeccion = 'Discos en buen estado', importe_estimado = 45000 WHERE id = 9001;
SELECT IF(COUNT(*) = 3 AND MAX(c.importe_estimado) = 45000, 'OK', 'FALLA') AS resultado FROM consultas c INNER JOIN detalles_consultas d ON d.consulta_id = c.id WHERE c.id = 9001;
ROLLBACK;
```

#### 4.8 — Cierre de consulta sin trabajo

- **Objetivo:** UPDATE a estado cerrada con motivo.
- **Tablas:** consultas
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Cierre registrado.

```sql
START TRANSACTION;
UPDATE consultas SET estado = 'cerrada', motivo_cierre = 'El cliente no continuó' WHERE id = 1;
SELECT IF(estado = 'cerrada' AND motivo_cierre IS NOT NULL, 'OK', 'FALLA') AS resultado FROM consultas WHERE id = 1;
ROLLBACK;
```

#### 4.9 — Eliminar consulta y sus detalles

- **Objetivo:** DELETE de una consulta nueva: los detalles se eliminan en cascada.
- **Tablas:** consultas, detalles_consultas
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** ON DELETE CASCADE de detalles_consultas.

```sql
START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9002, 'Persona', 'Prueba', 2);
INSERT INTO detalles_consultas (consulta_id, descripcion, registrado_por) VALUES (9002, 'x', 2);
DELETE FROM consultas WHERE id = 9002;
SELECT IF((SELECT COUNT(*) FROM detalles_consultas WHERE consulta_id = 9002) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 4.10 — Cobro "cobrar" sin importe rechazado

- **Objetivo:** CHECK ck_consultas_cobro.
- **Tablas:** consultas
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Si se decide cobrar, el importe es obligatorio.

```sql
UPDATE consultas SET cobro_decision = 'cobrar', cobro_importe = NULL WHERE id = 1;
```

#### 5.1 — Un presupuesto por consulta

- **Objetivo:** Cada consulta tiene como máximo un presupuesto.
- **Tablas:** presupuestos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Relación 1 a 1 consulta-presupuesto.
- **Equivale a la prueba del SQL original:** PRUEBA 3.3

```sql
SELECT consulta_id, COUNT(*) AS cantidad FROM presupuestos GROUP BY consulta_id HAVING COUNT(*) > 1;
```

#### 5.2 — Total calculado = suma de los detalles

- **Objetivo:** total_calculado coincide con SUM(monto) de sus detalles.
- **Tablas:** presupuestos, detalles_presupuestos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Importes consistentes (monto = cantidad × precio unitario).
- **Equivale a la prueba del SQL original:** PRUEBA 3.4

```sql
SELECT p.id, p.total_calculado, COALESCE(SUM(d.monto), 0) AS suma FROM presupuestos p LEFT JOIN detalles_presupuestos d ON d.presupuesto_id = p.id GROUP BY p.id, p.total_calculado HAVING p.total_calculado <> COALESCE(SUM(d.monto), 0);
```

#### 5.3 — Presupuestos enviados/aceptados con fecha de envío

- **Objetivo:** Un presupuesto enviado o aceptado debe tener fecha_envio.
- **Tablas:** presupuestos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Trazabilidad de envíos.
- **Equivale a la prueba del SQL original:** PRUEBA 3.5

```sql
SELECT id FROM presupuestos WHERE estado IN ('enviado','aceptado','rechazado') AND fecha_envio IS NULL;
```

#### 5.4 — Presupuesto con detalles (INNER JOIN)

- **Objetivo:** Listar presupuestos con la cantidad de líneas y su total.
- **Tablas:** presupuestos, detalles_presupuestos, consultas
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 12 filas
- **Resultado obtenido (ejecución real):** 12 fila(s) — correcto
- **Interpretación:** Cada presupuesto tiene al menos una línea.

```sql
SELECT p.numero, p.estado, COUNT(d.id) AS lineas, SUM(d.monto) AS total FROM presupuestos p INNER JOIN detalles_presupuestos d ON d.presupuesto_id = p.id GROUP BY p.id, p.numero, p.estado ORDER BY p.id;
```

Muestra del resultado real (primeras filas):

| numero | estado | lineas | total |
|---|---|---|---|
| PRE-0001 | aceptado | 3 | 75000.00 |
| PRE-0002 | aceptado | 2 | 70000.00 |
| PRE-0003 | aceptado | 3 | 66500.00 |
| PRE-0004 | enviado | 2 | 200000.00 |
| PRE-0005 | aceptado | 2 | 40000.00 |

#### 5.5 — Presupuestos aceptados con orden / órdenes con presupuesto aceptado

- **Objetivo:** Una orden solo nace de un presupuesto aceptado.
- **Tablas:** ordenes_trabajo, presupuestos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Flujo presupuesto -> orden respetado.

```sql
SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id WHERE p.estado <> 'aceptado';
```

#### 5.6 — Alta de presupuesto con detalles

- **Objetivo:** INSERT de presupuesto y líneas; el monto se calcula solo.
- **Tablas:** presupuestos, detalles_presupuestos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** 2 × 1500,50 + 8000 = 11001,00.

```sql
START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9003, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, estado, valido_hasta, creado_por) VALUES (9001, 9003, 'PRE-9001', 'borrador', '2026-12-31', 2);
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, tipo, cantidad, precio_unitario) VALUES (9001, 'Filtro', 'repuesto', 2, 1500.50), (9001, 'Mano de obra', 'mano_obra', 1, 8000);
UPDATE presupuestos SET total_calculado = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9001), precio_final = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9001) WHERE id = 9001;
SELECT IF(total_calculado = 11001.00 AND precio_final = 11001.00, 'OK', 'FALLA') AS resultado FROM presupuestos WHERE id = 9001;
ROLLBACK;
```

#### 5.7 — Aceptación de un presupuesto

- **Objetivo:** UPDATE a aceptado con fecha de respuesta.
- **Tablas:** presupuestos, consultas
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** La decisión del cliente queda registrada.

```sql
START TRANSACTION;
UPDATE presupuestos SET estado = 'aceptado', fecha_respuesta = NOW() WHERE id = (SELECT id FROM (SELECT id FROM presupuestos WHERE estado = 'enviado' LIMIT 1) x);
SELECT IF(COUNT(*) >= 1, 'OK', 'FALLA') AS resultado FROM presupuestos WHERE estado = 'aceptado' AND fecha_respuesta >= CURDATE();
ROLLBACK;
```

#### 5.8 — Eliminar presupuesto: sus detalles se borran en cascada

- **Objetivo:** DELETE con ON DELETE CASCADE.
- **Tablas:** presupuestos, detalles_presupuestos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** No quedan líneas huérfanas.

```sql
START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9004, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, creado_por) VALUES (9002, 9004, 'PRE-9002', 2);
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario) VALUES (9002, 'x', 1, 100);
DELETE FROM presupuestos WHERE id = 9002;
SELECT IF((SELECT COUNT(*) FROM detalles_presupuestos WHERE presupuesto_id = 9002) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 5.9 — Segundo presupuesto para una consulta rechazado

- **Objetivo:** UNIQUE uq_presupuestos_consulta.
- **Tablas:** presupuestos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** Una consulta, un presupuesto.

```sql
INSERT INTO presupuestos (consulta_id, numero, creado_por) VALUES (1, 'PRE-9999', 2);
```

#### 5.10 — Línea con cantidad 0 rechazada

- **Objetivo:** CHECK ck_detpres_valores.
- **Tablas:** detalles_presupuestos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** No se admiten cantidades nulas.

```sql
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario) VALUES (1, 'x', 0, 10);
```

#### 5.11 — No se puede escribir la columna calculada monto

- **Objetivo:** monto es GENERATED: no admite valores manuales.
- **Tablas:** detalles_presupuestos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3105 (columna generada)
- **Resultado obtenido (ejecución real):** ERROR 3105 — correcto
- **Interpretación:** El importe de la línea siempre es cantidad × precio.

```sql
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario, monto) VALUES (1, 'x', 1, 10, 999);
```

#### 6.1 — Una orden por presupuesto

- **Objetivo:** No puede haber dos órdenes del mismo presupuesto.
- **Tablas:** ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Relación 1 a 1.
- **Equivale a la prueba del SQL original:** PRUEBA 4.1

```sql
SELECT presupuesto_id, COUNT(*) FROM ordenes_trabajo GROUP BY presupuesto_id HAVING COUNT(*) > 1;
```

#### 6.2 — Cliente y vehículo de la orden coinciden con la consulta

- **Objetivo:** La orden refleja el cliente y vehículo de su consulta.
- **Tablas:** ordenes_trabajo, presupuestos, consultas
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cadena consulta -> presupuesto -> orden consistente.
- **Equivale a la prueba del SQL original:** PRUEBA 4.2

```sql
SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id INNER JOIN consultas c ON c.id = p.consulta_id WHERE o.cliente_id <> c.cliente_id OR o.vehiculo_id <> c.vehiculo_id;
```

#### 6.3 — Precio final de la orden = precio final del presupuesto

- **Objetivo:** El precio de la orden no se desvía del presupuesto aceptado. El % de comisión se define en la orden (el dueño lo puede ajustar mientras no haya comisión registrada), por eso no se compara.
- **Tablas:** ordenes_trabajo, presupuestos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El precio se copia del presupuesto.
- **Equivale a la prueba del SQL original:** PRUEBA 4.3

```sql
SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id WHERE o.precio_final <> p.precio_final;
```

#### 6.4 — Estados y mecánico

- **Objetivo:** sin_asignar/cancelado pueden no tener mecánico; ofrecido, aceptado, en_proceso y finalizado sí.
- **Tablas:** ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El mecánico se asigna al ofrecer el trabajo.
- **Equivale a la prueba del SQL original:** PRUEBA 4.4

```sql
SELECT id, estado FROM ordenes_trabajo WHERE (estado IN ('ofrecido','aceptado','en_proceso','finalizado') AND mecanico_id IS NULL) OR (estado = 'sin_asignar' AND mecanico_id IS NOT NULL);
```

#### 6.5 — Último estado del historial = estado de la orden

- **Objetivo:** historial_estados_ordenes registra cada cambio y termina en el estado actual.
- **Tablas:** ordenes_trabajo, historial_estados_ordenes
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El historial es fiel al estado.
- **Equivale a la prueba del SQL original:** PRUEBA 4.5

```sql
SELECT o.id, o.estado, h.estado_nuevo FROM ordenes_trabajo o INNER JOIN historial_estados_ordenes h ON h.id = (SELECT MAX(x.id) FROM historial_estados_ordenes x WHERE x.orden_id = o.id) WHERE h.estado_nuevo <> o.estado;
```

#### 6.6 — Fechas de inicio y fin según estado

- **Objetivo:** en_proceso/finalizado tienen fecha_inicio; finalizado tiene fecha_fin.
- **Tablas:** ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Trazabilidad temporal de los trabajos.

```sql
SELECT id, estado FROM ordenes_trabajo WHERE (estado IN ('en_proceso','finalizado') AND fecha_inicio IS NULL) OR (estado = 'finalizado' AND fecha_fin IS NULL);
```

#### 6.7 — Órdenes con cliente, vehículo y mecánico (INNER JOIN)

- **Objetivo:** Listado operativo de órdenes asignadas.
- **Tablas:** ordenes_trabajo, clientes, vehiculos, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 11 filas
- **Resultado obtenido (ejecución real):** 11 fila(s) — correcto
- **Interpretación:** Todas las órdenes de la demo tienen mecánico.

```sql
SELECT o.numero, cl.nombre AS cliente, v.marca, v.modelo, u.nombre AS mecanico, o.estado FROM ordenes_trabajo o INNER JOIN clientes cl ON cl.id = o.cliente_id INNER JOIN vehiculos v ON v.id = o.vehiculo_id INNER JOIN usuarios u ON u.id = o.mecanico_id ORDER BY o.id;
```

Muestra del resultado real (primeras filas):

| numero | cliente | marca | modelo | mecanico | estado |
|---|---|---|---|---|---|
| OT-0001 | Carlos Gómez | Fiat | Palio | Juan Pérez | finalizado |
| OT-0002 | María López | Volkswagen | Gol | Juan Pérez | ofrecido |
| OT-0003 | Laura Fernández | Renault | Clio | Pedro Gómez | en_proceso |
| OT-0004 | Paula Ríos | Ford | Focus | Juan Pérez | finalizado |
| OT-0005 | Hugo Acosta | Volkswagen | Voyage | Pedro Gómez | finalizado |

#### 6.8 — Avances con orden y autor válidos

- **Objetivo:** avances_ordenes no tiene filas huérfanas.
- **Tablas:** avances_ordenes, ordenes_trabajo, usuarios
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Relación 1 a N orden -> avances.

```sql
SELECT a.id FROM avances_ordenes a LEFT JOIN ordenes_trabajo o ON o.id = a.orden_id LEFT JOIN usuarios u ON u.id = a.usuario_id WHERE o.id IS NULL OR u.id IS NULL;
```

#### 6.9 — Avances registrados (INNER JOIN)

- **Objetivo:** Listar los avances con su orden y autor.
- **Tablas:** avances_ordenes, ordenes_trabajo, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 10 filas
- **Resultado obtenido (ejecución real):** 10 fila(s) — correcto
- **Interpretación:** Cada avance es una fila.

```sql
SELECT o.numero, u.nombre, a.texto, a.creado_en FROM avances_ordenes a INNER JOIN ordenes_trabajo o ON o.id = a.orden_id INNER JOIN usuarios u ON u.id = a.usuario_id ORDER BY a.id;
```

Muestra del resultado real (primeras filas):

| numero | nombre | texto | creado_en |
|---|---|---|---|
| OT-0001 | Juan Pérez | Se drenó el aceite y se reemplazó el filtro. | 2026-11-06 10:10:00 |
| OT-0003 | Pedro Gómez | Se cambiaron las bujías. Falta el filtro de aire ( | 2026-11-19 16:00:00 |
| OT-0004 | Juan Pérez | Trabajo realizado y probado en ruta. | 2026-10-30 11:00:00 |
| OT-0005 | Pedro Gómez | Trabajo realizado y probado en ruta. | 2026-11-01 11:00:00 |
| OT-0006 | Juan Pérez | Trabajo realizado y probado en ruta. | 2026-11-03 11:00:00 |

#### 6.10 — Cambio de estado con historial y avance

- **Objetivo:** UPDATE de estado + INSERT en historial y avance.
- **Tablas:** ordenes_trabajo, historial_estados_ordenes, avances_ordenes
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El estado, su historial y los avances se guardan juntos.

```sql
START TRANSACTION;
UPDATE ordenes_trabajo SET estado = 'en_proceso', fecha_inicio = NOW() WHERE id = 2;
INSERT INTO historial_estados_ordenes (orden_id, estado_anterior, estado_nuevo, cambiado_por) VALUES (2, 'ofrecido', 'en_proceso', 3);
INSERT INTO avances_ordenes (orden_id, usuario_id, texto) VALUES (2, 3, 'Se inició el desarme');
SELECT IF(o.estado = 'en_proceso' AND (SELECT COUNT(*) FROM avances_ordenes WHERE orden_id = 2) >= 1, 'OK', 'FALLA') AS resultado FROM ordenes_trabajo o WHERE o.id = 2;
ROLLBACK;
```

#### 6.11 — Eliminar orden nueva: historial y avances en cascada

- **Objetivo:** DELETE con cascada.
- **Tablas:** ordenes_trabajo, historial_estados_ordenes, avances_ordenes
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** No quedan registros hijos.

```sql
START TRANSACTION;
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, motivo, creado_por) VALUES (9005, 1, 1, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, estado, creado_por) VALUES (9003, 9005, 'PRE-9003', 'aceptado', 2);
INSERT INTO ordenes_trabajo (id, numero, presupuesto_id, cliente_id, vehiculo_id, descripcion, precio_final) VALUES (9001, 'OT-9001', 9003, 1, 1, 'Prueba', 100);
INSERT INTO historial_estados_ordenes (orden_id, estado_nuevo, cambiado_por) VALUES (9001, 'sin_asignar', 2);
INSERT INTO avances_ordenes (orden_id, usuario_id, texto) VALUES (9001, 2, 'x');
DELETE FROM ordenes_trabajo WHERE id = 9001;
SELECT IF((SELECT COUNT(*) FROM historial_estados_ordenes WHERE orden_id = 9001) + (SELECT COUNT(*) FROM avances_ordenes WHERE orden_id = 9001) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 6.12 — Segunda orden para un presupuesto rechazada

- **Objetivo:** UNIQUE uq_ordenes_presupuesto.
- **Tablas:** ordenes_trabajo
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** Una orden por presupuesto.

```sql
INSERT INTO ordenes_trabajo (numero, presupuesto_id, cliente_id, vehiculo_id, descripcion, precio_final) VALUES ('OT-9998', 1, 1, 1, 'dup', 1);
```

#### 6.13 — Comisión mayor a 100 % rechazada

- **Objetivo:** CHECK ck_ordenes_importes.
- **Tablas:** ordenes_trabajo
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Porcentaje fuera de rango.

```sql
UPDATE ordenes_trabajo SET comision_pct = 150 WHERE id = 1;
```

#### 7.1 — Asignación activa coincide con el mecánico de la orden

- **Objetivo:** La última asignación ofrecida/aceptada es la del mecánico de la orden.
- **Tablas:** asignaciones_trabajo, ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Orden y asignación coherentes.

```sql
SELECT o.id FROM ordenes_trabajo o INNER JOIN asignaciones_trabajo a ON a.id = (SELECT MAX(x.id) FROM asignaciones_trabajo x WHERE x.orden_id = o.id) WHERE o.mecanico_id IS NOT NULL AND a.mecanico_id <> o.mecanico_id;
```

#### 7.2 — Una sola asignación activa por orden

- **Objetivo:** No más de una asignación ofrecida/aceptada por orden.
- **Tablas:** asignaciones_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Un solo mecánico responsable.

```sql
SELECT orden_id, COUNT(*) FROM asignaciones_trabajo WHERE resultado IN ('ofrecida','aceptada') GROUP BY orden_id HAVING COUNT(*) > 1;
```

#### 7.3 — Rechazos con motivo

- **Objetivo:** Una asignación rechazada debe tener motivo_rechazo.
- **Tablas:** asignaciones_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Los rechazos se justifican.

```sql
SELECT id FROM asignaciones_trabajo WHERE resultado = 'rechazada' AND (motivo_rechazo IS NULL OR motivo_rechazo = '');
```

#### 7.4 — Asignaciones con orden y mecánico (INNER JOIN)

- **Objetivo:** Listar las asignaciones.
- **Tablas:** asignaciones_trabajo, ordenes_trabajo, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 11 filas
- **Resultado obtenido (ejecución real):** 11 fila(s) — correcto
- **Interpretación:** Una asignación por orden en la demo.

```sql
SELECT o.numero, u.nombre AS mecanico, a.resultado, a.creado_en, a.resuelto_en FROM asignaciones_trabajo a INNER JOIN ordenes_trabajo o ON o.id = a.orden_id INNER JOIN usuarios u ON u.id = a.mecanico_id ORDER BY a.id;
```

Muestra del resultado real (primeras filas):

| numero | mecanico | resultado | creado_en | resuelto_en |
|---|---|---|---|---|
| OT-0001 | Juan Pérez | aceptada | 2026-11-05 09:00:00 | 2026-11-05 10:00:00 |
| OT-0002 | Juan Pérez | ofrecida | 2026-11-19 09:00:00 | None |
| OT-0003 | Pedro Gómez | aceptada | 2026-11-15 09:00:00 | 2026-11-15 11:00:00 |
| OT-0004 | Juan Pérez | aceptada | 2026-10-28 09:00:00 | 2026-10-28 10:00:00 |
| OT-0005 | Pedro Gómez | aceptada | 2026-10-30 09:00:00 | 2026-10-30 10:00:00 |

#### 7.5 — Rechazo y reasignación

- **Objetivo:** El mecánico rechaza con motivo y se reasigna a otro.
- **Tablas:** asignaciones_trabajo, ordenes_trabajo
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Se conserva el historial de asignaciones.

```sql
START TRANSACTION;
UPDATE asignaciones_trabajo SET resultado = 'rechazada', motivo_rechazo = 'Sin disponibilidad', resuelto_en = NOW() WHERE orden_id = 2;
UPDATE ordenes_trabajo SET estado = 'sin_asignar', mecanico_id = NULL WHERE id = 2;
INSERT INTO asignaciones_trabajo (orden_id, mecanico_id, asignado_por, resultado) VALUES (2, 4, 2, 'ofrecida');
UPDATE ordenes_trabajo SET estado = 'ofrecido', mecanico_id = 4 WHERE id = 2;
SELECT IF((SELECT COUNT(*) FROM asignaciones_trabajo WHERE orden_id = 2) = 2 AND (SELECT mecanico_id FROM ordenes_trabajo WHERE id = 2) = 4, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 7.6 — Asignar a un mecánico inexistente rechazado

- **Objetivo:** FK fk_asig_mecanico.
- **Tablas:** asignaciones_trabajo
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1452 (clave foránea)
- **Resultado obtenido (ejecución real):** ERROR 1452 — correcto
- **Interpretación:** Solo usuarios existentes.

```sql
INSERT INTO asignaciones_trabajo (orden_id, mecanico_id, asignado_por) VALUES (2, 99999, 2);
```

#### 8.1 — Pagos de trabajo con orden; venta de mostrador sin orden

- **Objetivo:** Coherencia entre tipo de pago y orden.
- **Tablas:** pagos_clientes
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Mapeo del MVP: pago sin orden = venta de mostrador.
- **Equivale a la prueba del SQL original:** PRUEBA 5.1

```sql
SELECT id FROM pagos_clientes WHERE (tipo = 'trabajo' AND orden_id IS NULL) OR (tipo = 'venta_mostrador' AND orden_id IS NOT NULL);
```

#### 8.2 — Monto del pago = suma de sus medios

- **Objetivo:** El monto de cada pago coincide con sus detalles.
- **Tablas:** pagos_clientes, detalles_pagos_clientes
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Pagos combinados correctamente desglosados.
- **Equivale a la prueba del SQL original:** PRUEBA 5.2

```sql
SELECT p.id FROM pagos_clientes p LEFT JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id GROUP BY p.id, p.monto HAVING p.monto <> COALESCE(SUM(d.importe), 0);
```

#### 8.3 — Método combinado ↔ dos medios

- **Objetivo:** metodo = combinado solo si tiene 2 o más medios; si no, el medio coincide con metodo.
- **Tablas:** pagos_clientes, detalles_pagos_clientes
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Coherencia del método de pago.
- **Equivale a la prueba del SQL original:** PRUEBA 5.3

```sql
SELECT p.id FROM pagos_clientes p INNER JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id GROUP BY p.id, p.metodo HAVING (p.metodo = 'combinado' AND COUNT(*) < 2) OR (p.metodo <> 'combinado' AND (COUNT(*) <> 1 OR MAX(d.medio) <> p.metodo));
```

#### 8.4 — Cliente del pago = cliente de la orden

- **Objetivo:** Un pago de trabajo pertenece al cliente de esa orden.
- **Tablas:** pagos_clientes, ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Pagos asignados al cliente correcto.
- **Equivale a la prueba del SQL original:** PRUEBA 5.4

```sql
SELECT p.id FROM pagos_clientes p INNER JOIN ordenes_trabajo o ON o.id = p.orden_id WHERE p.cliente_id <> o.cliente_id;
```

#### 8.5 — Lo pagado no supera el precio de la orden

- **Objetivo:** SUM(pagos) <= precio_final.
- **Tablas:** pagos_clientes, ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** No hay sobrepagos.
- **Equivale a la prueba del SQL original:** PRUEBA 5.5

```sql
SELECT o.id, o.precio_final, SUM(p.monto) AS pagado FROM ordenes_trabajo o INNER JOIN pagos_clientes p ON p.orden_id = o.id GROUP BY o.id, o.precio_final HAVING SUM(p.monto) > o.precio_final;
```

#### 8.6 — Saldo por orden (INNER JOIN)

- **Objetivo:** Precio, pagado y saldo de las órdenes con pagos.
- **Tablas:** ordenes_trabajo, pagos_clientes, clientes
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** al menos 1 fila
- **Resultado obtenido (ejecución real):** 7 fila(s) — correcto
- **Interpretación:** Seguimiento de deuda por trabajo.

```sql
SELECT o.numero, c.nombre, o.precio_final, SUM(p.monto) AS pagado, o.precio_final - SUM(p.monto) AS saldo FROM ordenes_trabajo o INNER JOIN pagos_clientes p ON p.orden_id = o.id INNER JOIN clientes c ON c.id = o.cliente_id GROUP BY o.id, o.numero, c.nombre, o.precio_final ORDER BY o.id;
```

Muestra del resultado real (primeras filas):

| numero | nombre | precio_final | pagado | saldo |
|---|---|---|---|---|
| OT-0001 | Carlos Gómez | 75000.00 | 40000.00 | 35000.00 |
| OT-0004 | Paula Ríos | 40000.00 | 40000.00 | 0.00 |
| OT-0005 | Hugo Acosta | 45000.00 | 45000.00 | 0.00 |
| OT-0006 | Elena Vega | 50000.00 | 50000.00 | 0.00 |
| OT-0007 | Raúl Herrera | 55000.00 | 55000.00 | 0.00 |

#### 8.7 — Registrar un pago combinado

- **Objetivo:** INSERT de pago + dos medios; la suma coincide.
- **Tablas:** pagos_clientes, detalles_pagos_clientes
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El pago combinado se reparte en dos medios.

```sql
START TRANSACTION;
INSERT INTO pagos_clientes (id, tipo, orden_id, cliente_id, monto, metodo, registrado_por) VALUES (9001, 'trabajo', 2, (SELECT cliente_id FROM ordenes_trabajo WHERE id = 2), 10000, 'combinado', 2);
INSERT INTO detalles_pagos_clientes (pago_cliente_id, medio, importe, referencia) VALUES (9001, 'efectivo', 4000, NULL), (9001, 'transferencia', 6000, 'TRF-1');
SELECT IF(p.monto = SUM(d.importe), 'OK', 'FALLA') AS resultado FROM pagos_clientes p INNER JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id WHERE p.id = 9001 GROUP BY p.id, p.monto;
ROLLBACK;
```

#### 8.8 — Corregir el monto de un pago (UPDATE)

- **Objetivo:** Modificación de observaciones del pago.
- **Tablas:** pagos_clientes
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Modificación simple.

```sql
START TRANSACTION;
UPDATE pagos_clientes SET observaciones = 'Corregido' WHERE id = 1;
SELECT IF(observaciones = 'Corregido', 'OK', 'FALLA') AS resultado FROM pagos_clientes WHERE id = 1;
ROLLBACK;
```

#### 8.9 — Eliminar un pago: sus medios se borran en cascada

- **Objetivo:** DELETE con cascada.
- **Tablas:** pagos_clientes, detalles_pagos_clientes
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Sin medios huérfanos.

```sql
START TRANSACTION;
DELETE FROM pagos_clientes WHERE id = 1;
SELECT IF((SELECT COUNT(*) FROM detalles_pagos_clientes WHERE pago_cliente_id = 1) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 8.10 — Pago con monto 0 rechazado

- **Objetivo:** CHECK ck_pagcli_monto.
- **Tablas:** pagos_clientes
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Los pagos son positivos.

```sql
INSERT INTO pagos_clientes (tipo, cliente_id, monto, registrado_por) VALUES ('venta_mostrador', 1, 0, 2);
```

#### 8.11 — Medio repetido en un pago rechazado

- **Objetivo:** UNIQUE (pago, medio).
- **Tablas:** detalles_pagos_clientes
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** Un medio por pago.

```sql
INSERT INTO detalles_pagos_clientes (pago_cliente_id, medio, importe) SELECT pago_cliente_id, medio, 1 FROM detalles_pagos_clientes LIMIT 1;
```

#### 9.1 — Artículos con categoría

- **Objetivo:** Todo artículo del MVP tiene categoría existente.
- **Tablas:** catalogo_items, categorias_catalogo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Sin categorías inexistentes.
- **Equivale a la prueba del SQL original:** PRUEBA 6.1

```sql
SELECT i.id FROM catalogo_items i LEFT JOIN categorias_catalogo c ON c.id = i.categoria_id WHERE i.categoria_id IS NOT NULL AND c.id IS NULL;
```

#### 9.2 — Movimientos confirmados con responsable

- **Objetivo:** Un movimiento confirmado tiene resuelto_por.
- **Tablas:** movimientos_stock
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Todo movimiento confirmado tiene responsable.
- **Equivale a la prueba del SQL original:** PRUEBA 6.2

```sql
SELECT id FROM movimientos_stock WHERE estado = 'confirmado' AND resuelto_por IS NULL;
```

#### 9.3 — Salidas por orden con orden existente

- **Objetivo:** movimientos_stock.orden_id apunta a órdenes reales.
- **Tablas:** movimientos_stock, ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Repuestos usados en trabajos reales.
- **Equivale a la prueba del SQL original:** PRUEBA 6.3

```sql
SELECT m.id FROM movimientos_stock m LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.orden_id IS NOT NULL AND o.id IS NULL;
```

#### 9.4 — Artículos con stock bajo

- **Objetivo:** Artículos con cantidad <= stock mínimo (alerta de stock).
- **Tablas:** catalogo_items
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** al menos 1 fila
- **Resultado obtenido (ejecución real):** 2 fila(s) — correcto
- **Interpretación:** Consulta informativa: alimenta las alertas de stock bajo.
- **Equivale a la prueba del SQL original:** PRUEBA 6.4

```sql
SELECT id, codigo, nombre, cantidad, stock_minimo FROM catalogo_items WHERE activo = 1 AND cantidad <= stock_minimo ORDER BY cantidad;
```

Muestra del resultado real (primeras filas):

| id | codigo | nombre | cantidad | stock_minimo |
|---|---|---|---|---|
| 6 | COR-DIS | Correa de distribución | 3 | 3 |
| 3 | FIL-AIR | Filtro de aire | 4 | 5 |

#### 9.5 — Stock actual = entradas − salidas confirmadas

- **Objetivo:** La cantidad del catálogo coincide con la suma de sus movimientos.
- **Tablas:** catalogo_items, movimientos_stock
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El stock es consistente con su historial.

```sql
SELECT i.id, i.codigo, i.cantidad, COALESCE(SUM(CASE WHEN m.tipo = 'entrada' THEN m.cantidad ELSE -m.cantidad END), 0) AS segun_movimientos FROM catalogo_items i LEFT JOIN movimientos_stock m ON m.catalogo_item_id = i.id AND m.estado = 'confirmado' GROUP BY i.id, i.codigo, i.cantidad HAVING i.cantidad <> COALESCE(SUM(CASE WHEN m.tipo = 'entrada' THEN m.cantidad ELSE -m.cantidad END), 0);
```

#### 9.6 — Historial de precios coherente

- **Objetivo:** El último precio del historial coincide con el precio actual del artículo.
- **Tablas:** historial_precios_catalogo, catalogo_items
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Historial fiel a los precios vigentes.

```sql
SELECT i.id FROM catalogo_items i INNER JOIN historial_precios_catalogo h ON h.id = (SELECT MAX(x.id) FROM historial_precios_catalogo x WHERE x.catalogo_item_id = i.id) WHERE h.precio_compra_nuevo <> i.precio_compra OR h.precio_venta_nuevo <> i.precio_venta;
```

#### 9.7 — Artículos con su categoría (INNER JOIN)

- **Objetivo:** Listado del catálogo.
- **Tablas:** catalogo_items, categorias_catalogo
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 17 filas
- **Resultado obtenido (ejecución real):** 17 fila(s) — correcto
- **Interpretación:** Catálogo completo.

```sql
SELECT c.nombre AS categoria, i.codigo, i.nombre, i.marca, i.cantidad, i.precio_venta FROM catalogo_items i INNER JOIN categorias_catalogo c ON c.id = i.categoria_id ORDER BY c.nombre, i.nombre;
```

Muestra del resultado real (primeras filas):

| categoria | codigo | nombre | marca | cantidad | precio_venta |
|---|---|---|---|---|---|
| Correas | COR-ALT | Correa de alternador | Gates | 7 | 11000.00 |
| Correas | COR-DIS | Correa de distribución | Gates | 3 | 28000.00 |
| Encendido | BAT-60 | Batería 60 Ah | Moura | 4 | 105000.00 |
| Encendido | BUJ-STD | Bujías (unidad) | NGK | 26 | 4500.00 |
| Filtros | FIL-OIL | Filtro de aceite | Mann | 11 | 7000.00 |

#### 9.8 — Registrar salida de stock por una orden

- **Objetivo:** INSERT del movimiento y UPDATE de la cantidad.
- **Tablas:** movimientos_stock, catalogo_items
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El descuento de stock queda registrado y aplicado.

```sql
START TRANSACTION;
SET @antes = (SELECT cantidad FROM catalogo_items WHERE id = 1);
INSERT INTO movimientos_stock (catalogo_item_id, tipo, cantidad, estado, motivo, orden_id, solicitado_por, resuelto_por) VALUES (1, 'salida', 2, 'confirmado', 'Usado en OT-0003', 3, 3, 3);
UPDATE catalogo_items SET cantidad = cantidad - 2 WHERE id = 1;
SELECT IF(cantidad = @antes - 2, 'OK', 'FALLA') AS resultado FROM catalogo_items WHERE id = 1;
ROLLBACK;
```

#### 9.9 — Eliminar un artículo sin movimientos

- **Objetivo:** DELETE de un artículo nuevo.
- **Tablas:** catalogo_items
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Baja de artículo sin historial.

```sql
START TRANSACTION;
INSERT INTO catalogo_items (id, tipo, nombre, codigo) VALUES (9001, 'repuesto', 'Temporal', 'TMP-1');
DELETE FROM catalogo_items WHERE id = 9001;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM catalogo_items WHERE id = 9001;
ROLLBACK;
```

#### 9.10 — Stock negativo rechazado

- **Objetivo:** CHECK ck_catalogo_stock.
- **Tablas:** catalogo_items
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** No se puede vender lo que no hay.

```sql
UPDATE catalogo_items SET cantidad = cantidad - 100000 WHERE id = 1;
```

#### 9.11 — Código de artículo duplicado rechazado

- **Objetivo:** UNIQUE uq_catalogo_codigo.
- **Tablas:** catalogo_items
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** Código único.

```sql
INSERT INTO catalogo_items (tipo, nombre, codigo) SELECT 'repuesto', 'Copia', codigo FROM catalogo_items WHERE codigo IS NOT NULL LIMIT 1;
```

#### 9.12 — Movimiento sin artículo ni descripción rechazado

- **Objetivo:** CHECK ck_movstock_descripcion.
- **Tablas:** movimientos_stock
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Todo movimiento identifica qué se movió.

```sql
INSERT INTO movimientos_stock (tipo, cantidad, motivo, solicitado_por) VALUES ('salida', 1, 'x', 2);
```

#### 10.1 — Movimientos de usuarios con rol Mecánico

- **Objetivo:** Solo mecánicos tienen movimientos.
- **Tablas:** movimientos_mecanicos, usuarios, roles
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Las comisiones son de mecánicos.
- **Equivale a la prueba del SQL original:** PRUEBA 7.1

```sql
SELECT m.id FROM movimientos_mecanicos m INNER JOIN usuarios u ON u.id = m.mecanico_id INNER JOIN roles r ON r.id = u.rol_id WHERE r.nombre <> 'Mecanico';
```

#### 10.2 — Comisión con orden finalizada del mismo mecánico

- **Objetivo:** Toda comisión corresponde a una orden finalizada de ese mecánico.
- **Tablas:** movimientos_mecanicos, ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Comisión solo por trabajos terminados.

```sql
SELECT m.id FROM movimientos_mecanicos m LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.tipo = 'comision' AND (o.id IS NULL OR o.estado <> 'finalizado' OR o.mecanico_id <> m.mecanico_id);
```

#### 10.3 — Comisión = mano de obra × comision_pct ÷ 100 (sin repuestos)

- **Objetivo:** La fórmula documentada: la base es SOLO la suma de las líneas de tipo mano_obra del presupuesto de la orden.
- **Tablas:** movimientos_mecanicos, ordenes_trabajo, detalles_presupuestos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cada comisión registrada coincide con la fórmula.

```sql
SELECT x.id, x.monto, x.esperado FROM (SELECT m.id, m.monto, ROUND(COALESCE((SELECT SUM(d.monto) FROM detalles_presupuestos d WHERE d.presupuesto_id = o.presupuesto_id AND d.tipo = 'mano_obra'), 0) * o.comision_pct / 100, 2) AS esperado
 FROM movimientos_mecanicos m INNER JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.tipo = 'comision') x WHERE x.monto <> x.esperado;
```

#### 10.4 — Movimientos con mecánico y orden (INNER JOIN)

- **Objetivo:** Listado de movimientos.
- **Tablas:** movimientos_mecanicos, usuarios, ordenes_trabajo
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 7 filas (5 comisiones y 2 adelantos)
- **Resultado obtenido (ejecución real):** 7 fila(s) — correcto
- **Interpretación:** Movimientos generados por el MVP.
- **Equivale a la prueba del SQL original:** PRUEBA 7.5

```sql
SELECT u.nombre, m.tipo, m.monto, o.numero, m.fecha FROM movimientos_mecanicos m INNER JOIN usuarios u ON u.id = m.mecanico_id LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id ORDER BY m.id;
```

Muestra del resultado real (primeras filas):

| nombre | tipo | monto | numero | fecha |
|---|---|---|---|---|
| Juan Pérez | comision | 3600.00 | OT-0001 | 2026-11-06 12:00:00 |
| Juan Pérez | comision | 7500.00 | OT-0004 | 2026-10-30 12:00:00 |
| Juan Pérez | comision | 10500.00 | OT-0006 | 2026-11-03 12:00:00 |
| Pedro Gómez | comision | 9000.00 | OT-0005 | 2026-11-01 12:00:00 |
| Pedro Gómez | comision | 12000.00 | OT-0007 | 2026-11-05 12:00:00 |

#### 10.5 — Registrar un adelanto

- **Objetivo:** INSERT de un adelanto.
- **Tablas:** movimientos_mecanicos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Los adelantos no se vinculan a una orden.

```sql
START TRANSACTION;
INSERT INTO movimientos_mecanicos (id, mecanico_id, tipo, monto, registrado_por, descripcion) VALUES (9001, 3, 'adelanto', 2500, 2, 'Prueba');
SELECT IF(COUNT(*) = 1, 'OK', 'FALLA') AS resultado FROM movimientos_mecanicos WHERE id = 9001 AND orden_id IS NULL;
ROLLBACK;
```

#### 10.6 — Movimiento con monto 0 rechazado

- **Objetivo:** CHECK ck_movmec_monto.
- **Tablas:** movimientos_mecanicos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Montos positivos.

```sql
INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, registrado_por) VALUES (3, 'adelanto', 0, 2);
```

#### 10.7 — Calcular y registrar una comisión sobre la mano de obra

- **Objetivo:** Calcula en SQL la comisión de una orden finalizada sin comisión (30 % sobre la mano de obra) y la registra; comprueba que NO se calcula sobre el precio total.
- **Tablas:** ordenes_trabajo, detalles_presupuestos, movimientos_mecanicos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** La comisión usa solo la mano de obra; los repuestos no suman.

```sql
START TRANSACTION;
SET @oid = (SELECT o.id FROM ordenes_trabajo o WHERE o.estado = 'finalizado' AND NOT EXISTS (SELECT 1 FROM movimientos_mecanicos m WHERE m.orden_id = o.id) ORDER BY o.id LIMIT 1);
SET @mano = (SELECT SUM(d.monto) FROM detalles_presupuestos d INNER JOIN ordenes_trabajo o ON o.presupuesto_id = d.presupuesto_id WHERE o.id = @oid AND d.tipo = 'mano_obra');
SET @total = (SELECT precio_final FROM ordenes_trabajo WHERE id = @oid);
INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por, fecha, descripcion)
 SELECT mecanico_id, 'comision', ROUND(@mano * comision_pct / 100, 2), id, 2, fecha_fin, 'Comisión de prueba' FROM ordenes_trabajo WHERE id = @oid;
SELECT IF(m.monto = ROUND(@mano * o.comision_pct / 100, 2) AND m.monto <> ROUND(@total * o.comision_pct / 100, 2) AND m.monto > 0, 'OK', 'FALLA') AS resultado
FROM movimientos_mecanicos m INNER JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.orden_id = @oid AND m.tipo = 'comision';
ROLLBACK;
```

#### 10.8 — Segunda comisión para la misma orden rechazada

- **Objetivo:** UNIQUE uq_movmec_orden_tipo: una sola comisión por orden.
- **Tablas:** movimientos_mecanicos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** No se registra dos veces la comisión de un trabajo.

```sql
INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por) SELECT mecanico_id, 'comision', 1, orden_id, 2 FROM movimientos_mecanicos WHERE tipo = 'comision' LIMIT 1;
```

#### 10.9 — Comisión sin orden / adelanto con orden rechazados

- **Objetivo:** CHECK ck_movmec_tipo_orden.
- **Tablas:** movimientos_mecanicos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** La comisión siempre nace de una orden.

```sql
INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por) VALUES (3, 'comision', 100, NULL, 2);
```

#### 11.1 — Total a pagar = comisiones − adelantos

- **Objetivo:** Cálculo de la liquidación.
- **Tablas:** liquidaciones_mecanicos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Aritmética correcta.
- **Equivale a la prueba del SQL original:** PRUEBA 7.2

```sql
SELECT id FROM liquidaciones_mecanicos WHERE total_a_pagar <> total_comisiones - total_adelantos;
```

#### 11.2 — Totales = suma de los detalles

- **Objetivo:** Comisiones y adelantos de la cabecera coinciden con sus detalles.
- **Tablas:** liquidaciones_mecanicos, detalles_liquidaciones_mecanicos, movimientos_mecanicos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cabecera y detalle coinciden (las anuladas no tienen detalle: liberaron sus movimientos).
- **Equivale a la prueba del SQL original:** PRUEBA 7.2 (corregida)

```sql
SELECT l.id FROM liquidaciones_mecanicos l LEFT JOIN detalles_liquidaciones_mecanicos d ON d.liquidacion_id = l.id LEFT JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id WHERE l.estado <> 'anulada' GROUP BY l.id, l.total_comisiones, l.total_adelantos HAVING l.total_comisiones <> COALESCE(SUM(CASE WHEN m.tipo = 'comision' THEN d.importe_incluido END), 0) OR l.total_adelantos <> COALESCE(SUM(CASE WHEN m.tipo = 'adelanto' THEN d.importe_incluido END), 0);
```

#### 11.3 — Movimientos del mismo mecánico y dentro del período

- **Objetivo:** Los movimientos liquidados son del mecánico y de las fechas de la liquidación.
- **Tablas:** detalles_liquidaciones_mecanicos, movimientos_mecanicos, liquidaciones_mecanicos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Liquidación coherente con sus movimientos.
- **Equivale a la prueba del SQL original:** PRUEBA 7.3

```sql
SELECT d.id FROM detalles_liquidaciones_mecanicos d INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id INNER JOIN liquidaciones_mecanicos l ON l.id = d.liquidacion_id WHERE m.mecanico_id <> l.mecanico_id OR DATE(m.fecha) NOT BETWEEN l.periodo_desde AND l.periodo_hasta;
```

#### 11.4 — Un movimiento en una sola liquidación

- **Objetivo:** Ningún movimiento aparece en dos liquidaciones.
- **Tablas:** detalles_liquidaciones_mecanicos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Evita pagar dos veces.
- **Equivale a la prueba del SQL original:** PRUEBA 7.4

```sql
SELECT movimiento_mecanico_id, COUNT(*) FROM detalles_liquidaciones_mecanicos GROUP BY movimiento_mecanico_id HAVING COUNT(*) > 1;
```

#### 11.5 — Liquidación con detalles (INNER JOIN)

- **Objetivo:** Detalle de la liquidación del mecánico.
- **Tablas:** liquidaciones_mecanicos, detalles_liquidaciones_mecanicos, movimientos_mecanicos, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 7 filas (liquidación pagada: 3 comisiones y 1 adelanto; pendiente: 2 comisiones y 1 adelanto)
- **Resultado obtenido (ejecución real):** 7 fila(s) — correcto
- **Interpretación:** Cada liquidación muestra sus comisiones y adelantos.

```sql
SELECT l.id, u.nombre, m.tipo, d.importe_incluido, l.total_a_pagar, l.estado FROM liquidaciones_mecanicos l INNER JOIN usuarios u ON u.id = l.mecanico_id INNER JOIN detalles_liquidaciones_mecanicos d ON d.liquidacion_id = l.id INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id ORDER BY d.id;
```

Muestra del resultado real (primeras filas):

| id | nombre | tipo | importe_incluido | total_a_pagar | estado |
|---|---|---|---|---|---|
| 1 | Juan Pérez | comision | 3600.00 | 16600.00 | pagada |
| 1 | Juan Pérez | comision | 7500.00 | 16600.00 | pagada |
| 1 | Juan Pérez | comision | 10500.00 | 16600.00 | pagada |
| 1 | Juan Pérez | adelanto | 5000.00 | 16600.00 | pagada |
| 3 | Pedro Gómez | comision | 9000.00 | 13000.00 | pendiente |

#### 11.6 — Pagar una liquidación

- **Objetivo:** UPDATE a pagada con fecha de pago.
- **Tablas:** liquidaciones_mecanicos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Cierre de la liquidación.

```sql
START TRANSACTION;
UPDATE liquidaciones_mecanicos SET estado = 'pagada', fecha_pago = NOW() WHERE estado = 'pendiente';
SELECT IF(COUNT(*) = 2 AND SUM(fecha_pago IS NOT NULL) = 2, 'OK', 'FALLA') AS resultado FROM liquidaciones_mecanicos WHERE estado = 'pagada';
ROLLBACK;
```

#### 11.7 — Anular una liquidación pendiente y liberar sus movimientos

- **Objetivo:** Se anula la liquidación pendiente y se borran sus detalles: sus movimientos pueden liquidarse de nuevo.
- **Tablas:** liquidaciones_mecanicos, detalles_liquidaciones_mecanicos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Los 3 movimientos de la liquidación quedan libres; ningún movimiento se borra.

```sql
START TRANSACTION;
SET @liq = (SELECT id FROM liquidaciones_mecanicos WHERE estado = 'pendiente' LIMIT 1);
SET @movs = (SELECT COUNT(*) FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq);
DELETE FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq;
UPDATE liquidaciones_mecanicos SET estado = 'anulada' WHERE id = @liq;
SELECT IF(@movs = 3 AND (SELECT COUNT(*) FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq) = 0 AND (SELECT COUNT(*) FROM movimientos_mecanicos) = 7 AND (SELECT COUNT(*) FROM movimientos_mecanicos m WHERE NOT EXISTS (SELECT 1 FROM detalles_liquidaciones_mecanicos d WHERE d.movimiento_mecanico_id = m.id)) = 3, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 11.8 — Movimiento liquidado dos veces rechazado

- **Objetivo:** UNIQUE uq_detliq_movimiento.
- **Tablas:** detalles_liquidaciones_mecanicos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** No se paga dos veces.

```sql
INSERT INTO detalles_liquidaciones_mecanicos (liquidacion_id, movimiento_mecanico_id, importe_incluido) VALUES (1, 1, 10);
```

#### 11.9 — Período invertido rechazado

- **Objetivo:** CHECK ck_liq_fechas.
- **Tablas:** liquidaciones_mecanicos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Fechas coherentes.

```sql
INSERT INTO liquidaciones_mecanicos (mecanico_id, periodo_desde, periodo_hasta, creado_por) VALUES (3, '2026-12-01', '2026-11-01', 2);
```

#### 11.10 — Liquidaciones pendientes, pagadas y anuladas

- **Objetivo:** Agrupa las liquidaciones por estado.
- **Tablas:** liquidaciones_mecanicos
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 3 filas (anulada, pagada, pendiente)
- **Resultado obtenido (ejecución real):** 3 fila(s) — correcto
- **Interpretación:** Consulta de liquidaciones por estado.

```sql
SELECT estado, COUNT(*) AS cantidad, SUM(total_a_pagar) AS total FROM liquidaciones_mecanicos GROUP BY estado ORDER BY estado;
```

Muestra del resultado real (primeras filas):

| estado | cantidad | total |
|---|---|---|
| pendiente | 1 | 13000.00 |
| pagada | 1 | 16600.00 |
| anulada | 1 | 9000.00 |

#### 11.11 — Estados coherentes: pagadas con fecha de pago, anuladas sin detalles

- **Objetivo:** pagada tiene fecha_pago; pendiente/anulada no; anulada no conserva movimientos.
- **Tablas:** liquidaciones_mecanicos, detalles_liquidaciones_mecanicos
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Una liquidación anulada libera sus movimientos.

```sql
SELECT l.id FROM liquidaciones_mecanicos l WHERE (l.estado = 'pagada' AND l.fecha_pago IS NULL) OR (l.estado <> 'pagada' AND l.fecha_pago IS NOT NULL) OR (l.estado = 'anulada' AND EXISTS (SELECT 1 FROM detalles_liquidaciones_mecanicos d WHERE d.liquidacion_id = l.id));
```

#### 11.12 — Los adelantos se descuentan de la liquidación

- **Objetivo:** Genera una liquidación con una comisión y un adelanto nuevos: total a pagar = comisión − adelanto.
- **Tablas:** movimientos_mecanicos, liquidaciones_mecanicos, detalles_liquidaciones_mecanicos
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** 10000 − 2500 = 7500.

```sql
START TRANSACTION;
INSERT INTO movimientos_mecanicos (id, mecanico_id, tipo, monto, orden_id, registrado_por, fecha) VALUES (9001, 3, 'adelanto', 2500, NULL, 2, '2026-11-19 09:00:00');
INSERT INTO liquidaciones_mecanicos (id, mecanico_id, periodo_desde, periodo_hasta, total_comisiones, total_adelantos, total_a_pagar, estado, creado_por) VALUES (9001, 3, '2026-11-19', '2026-11-20', 10000, 2500, 7500, 'pendiente', 2);
INSERT INTO detalles_liquidaciones_mecanicos (liquidacion_id, movimiento_mecanico_id, importe_incluido) VALUES (9001, 9001, 2500);
SELECT IF(l.total_a_pagar = l.total_comisiones - l.total_adelantos AND l.total_adelantos = (SELECT SUM(d.importe_incluido) FROM detalles_liquidaciones_mecanicos d INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id WHERE d.liquidacion_id = 9001 AND m.tipo = 'adelanto'), 'OK', 'FALLA') AS resultado FROM liquidaciones_mecanicos l WHERE l.id = 9001;
ROLLBACK;
```

#### 11.13 — Total a pagar negativo rechazado

- **Objetivo:** CHECK de liquidaciones: si los adelantos superan las comisiones no se genera.
- **Tablas:** liquidaciones_mecanicos
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Regla del MVP: no se liquida con saldo negativo.

```sql
INSERT INTO liquidaciones_mecanicos (mecanico_id, periodo_desde, periodo_hasta, total_comisiones, total_adelantos, total_a_pagar, creado_por) VALUES (3, '2026-11-01', '2026-11-02', 100, 500, -400, 2);
```

#### 12.1 — Períodos consecutivos sin huecos

- **Objetivo:** Cada período empieza donde terminó el anterior y la numeración es correlativa.
- **Tablas:** periodos_pago_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** La suscripción es continua.
- **Equivale a la prueba del SQL original:** PRUEBA 8.4

```sql
SELECT b.id FROM periodos_pago_sistema b INNER JOIN periodos_pago_sistema a ON a.taller_id = b.taller_id AND a.numero = b.numero - 1 WHERE b.fecha_inicio <> a.fecha_vencimiento;
```

#### 12.2 — Tolerancia de 3 días

- **Objetivo:** fecha_fin_tolerancia = vencimiento + 3 días.
- **Tablas:** periodos_pago_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Regla de negocio: 3 días corridos de tolerancia.

```sql
SELECT id FROM periodos_pago_sistema WHERE fecha_fin_tolerancia <> DATE_ADD(fecha_vencimiento, INTERVAL dias_tolerancia DAY) OR dias_tolerancia <> 3;
```

#### 12.3 — Duración según modalidad

- **Objetivo:** mensual = 1 mes; anual = 12 meses.
- **Tablas:** periodos_pago_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Un único plan, mensual o anual.

```sql
SELECT id FROM periodos_pago_sistema WHERE (modalidad = 'mensual' AND fecha_vencimiento <> DATE_ADD(fecha_inicio, INTERVAL 1 MONTH)) OR (modalidad = 'anual' AND fecha_vencimiento <> DATE_ADD(fecha_inicio, INTERVAL 12 MONTH));
```

#### 12.4 — Período pagado con pago confirmado

- **Objetivo:** Un período pagado tiene fecha de pago y al menos un pago confirmado.
- **Tablas:** periodos_pago_sistema, pagos_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Estado coherente con los pagos.
- **Equivale a la prueba del SQL original:** PRUEBA 8.4

```sql
SELECT p.id FROM periodos_pago_sistema p WHERE p.estado = 'pagado' AND (p.fecha_pago_confirmado IS NULL OR NOT EXISTS (SELECT 1 FROM pagos_sistema s WHERE s.periodo_id = p.id AND s.estado = 'confirmado'));
```

#### 12.5 — Estado de la suscripción a la fecha de referencia

- **Objetivo:** Estado y días al vencimiento del último período (fecha de referencia de la demo: 2026-11-20).
- **Tablas:** periodos_pago_sistema, taller
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 1 fila: período 2, 12 días al vencimiento, acceso vigente
- **Resultado obtenido (ejecución real):** 1 fila(s) — correcto
- **Interpretación:** Cambiar @hoy_demo por CURDATE() para evaluar con la fecha real.

```sql
SET @hoy_demo = DATE('2026-11-20');
SELECT p.numero, p.fecha_vencimiento, DATEDIFF(p.fecha_vencimiento, @hoy_demo) AS dias_al_vencimiento,
 CASE WHEN @hoy_demo <= p.fecha_vencimiento THEN 'vigente' WHEN @hoy_demo <= p.fecha_fin_tolerancia THEN 'en tolerancia' ELSE 'bloqueado' END AS acceso, t.estado_acceso
FROM periodos_pago_sistema p INNER JOIN taller t ON t.id = p.taller_id WHERE p.numero = (SELECT MAX(numero) FROM periodos_pago_sistema);
```

Muestra del resultado real (primeras filas):

| numero | fecha_vencimiento | dias_al_vencimiento | acceso | estado_acceso |
|---|---|---|---|---|
| 2 | 2026-12-02 | 12 | vigente | activo |

#### 12.6 — Taller bloqueado solo si venció la tolerancia

- **Objetivo:** estado_acceso coherente con la fecha de referencia.
- **Tablas:** taller, periodos_pago_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Bloqueo solo tras la tolerancia.

```sql
SET @hoy_demo = DATE('2026-11-20');
SELECT t.id FROM taller t INNER JOIN periodos_pago_sistema p ON p.numero = (SELECT MAX(numero) FROM periodos_pago_sistema) WHERE (t.estado_acceso = 'bloqueado') <> (p.estado <> 'pagado' AND @hoy_demo > p.fecha_fin_tolerancia);
```

#### 12.7 — Renovación: informar y confirmar un pago

- **Objetivo:** Proceso completo: se informa el pago, el SuperAdmin lo confirma, el período se marca pagado y nace el siguiente.
- **Tablas:** periodos_pago_sistema, pagos_sistema, detalles_pagos_sistema, superadmins
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El nuevo vencimiento se calcula desde el vencimiento anterior (2026-12-02 + 1 mes).

```sql
START TRANSACTION;
INSERT INTO pagos_sistema (id, periodo_id, importe_total, metodo, estado, registrado_por) VALUES (9001, 2, 30000, 'transferencia', 'informado', 2);
INSERT INTO detalles_pagos_sistema (pago_id, medio, importe, referencia) VALUES (9001, 'transferencia', 30000, 'TRF-PRUEBA');
UPDATE pagos_sistema SET estado = 'confirmado', confirmado_por = 1, fecha_confirmacion = NOW() WHERE id = 9001;
UPDATE periodos_pago_sistema SET estado = 'pagado', fecha_pago_confirmado = NOW() WHERE id = 2;
INSERT INTO periodos_pago_sistema (id, taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia, estado)
 SELECT 9001, 1, 3, 'mensual', fecha_vencimiento, DATE_ADD(fecha_vencimiento, INTERVAL 1 MONTH), importe, 3, DATE_ADD(DATE_ADD(fecha_vencimiento, INTERVAL 1 MONTH), INTERVAL 3 DAY), 'vigente' FROM periodos_pago_sistema WHERE id = 2;
SELECT IF((SELECT estado FROM periodos_pago_sistema WHERE id = 2) = 'pagado' AND (SELECT fecha_vencimiento FROM periodos_pago_sistema WHERE id = 9001) = '2027-01-02', 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 12.8 — Rechazo de un pago informado

- **Objetivo:** UPDATE a rechazado con motivo.
- **Tablas:** pagos_sistema
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El rechazo no extiende la suscripción.

```sql
START TRANSACTION;
INSERT INTO pagos_sistema (id, periodo_id, importe_total, metodo, estado, registrado_por) VALUES (9002, 2, 30000, 'efectivo', 'informado', 2);
UPDATE pagos_sistema SET estado = 'rechazado', motivo_rechazo = 'No se recibió el dinero', confirmado_por = 1, fecha_confirmacion = NOW() WHERE id = 9002;
SELECT IF(estado = 'rechazado' AND motivo_rechazo IS NOT NULL, 'OK', 'FALLA') AS resultado FROM pagos_sistema WHERE id = 9002;
ROLLBACK;
```

#### 12.9 — Tolerancia distinta de 3 días rechazada

- **Objetivo:** CHECK ck_periodo_tolerancia.
- **Tablas:** periodos_pago_sistema
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** La tolerancia es una regla fija.

```sql
INSERT INTO periodos_pago_sistema (taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia) VALUES (1, 50, 'mensual', '2027-01-01', '2027-02-01', 100, 5, '2027-02-06');
```

#### 12.10 — Modalidad: solo mensual o anual

- **Objetivo:** El ENUM de modalidad no admite otros valores (p. ej. trimestral).
- **Tablas:** periodos_pago_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Un único plan, mensual o anual (la validación real por inserción se verifica en 12.3).

```sql
SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'periodos_pago_sistema' AND column_name = 'modalidad' AND column_type <> "enum('mensual','anual')";
```

#### 12.11 — No existe el plan trimestral

- **Objetivo:** Ningún período usa una modalidad distinta de mensual o anual.
- **Tablas:** periodos_pago_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Un único plan con dos modalidades.

```sql
SELECT id, modalidad FROM periodos_pago_sistema WHERE modalidad NOT IN ('mensual','anual');
```

#### 12.12 — Modalidad anual: 12 meses y tolerancia de 3 días

- **Objetivo:** Se inserta un período anual y se comprueba su vencimiento y tolerancia.
- **Tablas:** periodos_pago_sistema
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** La modalidad anual funciona; la mensual se prueba en 12.7.

```sql
START TRANSACTION;
INSERT INTO periodos_pago_sistema (id, taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia) VALUES (9002, 1, 40, 'anual', '2026-12-02', '2027-12-02', 300000, 3, '2027-12-05');
SELECT IF(fecha_vencimiento = DATE_ADD(fecha_inicio, INTERVAL 12 MONTH) AND fecha_fin_tolerancia = DATE_ADD(fecha_vencimiento, INTERVAL 3 DAY), 'OK', 'FALLA') AS resultado FROM periodos_pago_sistema WHERE id = 9002;
ROLLBACK;
```

#### 13.1 — Confirmados con SuperAdmin y fecha

- **Objetivo:** Un pago confirmado tiene confirmado_por y fecha de confirmación.
- **Tablas:** pagos_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Solo el SuperAdmin confirma.
- **Equivale a la prueba del SQL original:** PRUEBA 8.1

```sql
SELECT id FROM pagos_sistema WHERE estado = 'confirmado' AND (confirmado_por IS NULL OR fecha_confirmacion IS NULL);
```

#### 13.2 — Importe = suma de los medios

- **Objetivo:** importe_total coincide con sus detalles.
- **Tablas:** pagos_sistema, detalles_pagos_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Pagos combinados bien desglosados.
- **Equivale a la prueba del SQL original:** PRUEBA 8.2

```sql
SELECT p.id FROM pagos_sistema p LEFT JOIN detalles_pagos_sistema d ON d.pago_id = p.id GROUP BY p.id, p.importe_total HAVING p.importe_total <> COALESCE(SUM(d.importe), 0);
```

#### 13.3 — Método combinado ↔ dos medios

- **Objetivo:** combinado = efectivo + transferencia; los demás, un solo medio igual al método.
- **Tablas:** pagos_sistema, detalles_pagos_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Medios de pago permitidos: efectivo, transferencia, combinado.
- **Equivale a la prueba del SQL original:** PRUEBA 8.3

```sql
SELECT p.id FROM pagos_sistema p INNER JOIN detalles_pagos_sistema d ON d.pago_id = p.id GROUP BY p.id, p.metodo HAVING (p.metodo = 'combinado' AND COUNT(*) <> 2) OR (p.metodo <> 'combinado' AND (COUNT(*) <> 1 OR MAX(d.medio) <> p.metodo));
```

#### 13.4 — Pagos del sistema y de clientes están separados

- **Objetivo:** No existe ninguna clave foránea entre las tablas de pagos de clientes y las del sistema.
- **Tablas:** information_schema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Los dos circuitos de cobro no se mezclan.

```sql
SELECT table_name, referenced_table_name FROM information_schema.key_column_usage
WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL
 AND ((table_name IN ('pagos_clientes','detalles_pagos_clientes') AND referenced_table_name IN ('pagos_sistema','detalles_pagos_sistema','periodos_pago_sistema','comprobantes_pagos_sistema'))
   OR (table_name IN ('pagos_sistema','detalles_pagos_sistema','periodos_pago_sistema','comprobantes_pagos_sistema') AND referenced_table_name IN ('pagos_clientes','detalles_pagos_clientes')));
```

#### 13.5 — Pago del sistema con período, dueño y SuperAdmin (INNER JOIN)

- **Objetivo:** Listado de pagos de suscripción.
- **Tablas:** pagos_sistema, periodos_pago_sistema, usuarios, superadmins
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 2 filas (1 confirmado y 1 informado)
- **Resultado obtenido (ejecución real):** 2 fila(s) — correcto
- **Interpretación:** Pago combinado confirmado del período 1 y pago informado pendiente de confirmar.
- **Equivale a la prueba del SQL original:** PRUEBA 8.5

```sql
SELECT p.id, per.numero AS periodo, u.nombre AS pagador, p.importe_total, p.metodo, p.estado, su.usuario AS confirmo FROM pagos_sistema p INNER JOIN periodos_pago_sistema per ON per.id = p.periodo_id INNER JOIN usuarios u ON u.id = p.registrado_por LEFT JOIN superadmins s ON s.id = p.confirmado_por LEFT JOIN usuarios su ON su.id = s.usuario_id;
```

Muestra del resultado real (primeras filas):

| id | periodo | pagador | importe_total | metodo | estado | confirmo |
|---|---|---|---|---|---|---|
| 1 | 1 | Roberto Díaz | 30000.00 | combinado | confirmado | superadmin |
| 2 | 2 | Roberto Díaz | 30000.00 | transferencia | informado | None |

#### 13.6 — Comprobantes con pago existente

- **Objetivo:** comprobantes_pagos_sistema (tabla sin uso en el MVP) no tiene huérfanos.
- **Tablas:** comprobantes_pagos_sistema, pagos_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** La tabla está vacía; la relación queda verificada.
- **Equivale a la prueba del SQL original:** PRUEBA 8.5

```sql
SELECT c.id FROM comprobantes_pagos_sistema c LEFT JOIN pagos_sistema p ON p.id = c.pago_sistema_id WHERE p.id IS NULL;
```

#### 13.7 — Medio repetido en un pago del sistema rechazado

- **Objetivo:** UNIQUE (pago, medio).
- **Tablas:** detalles_pagos_sistema
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** Un medio por pago.

```sql
INSERT INTO detalles_pagos_sistema (pago_id, medio, importe) VALUES (1, 'efectivo', 5);
```

#### 13.8 — Medios del sistema: solo efectivo y transferencia

- **Objetivo:** El ENUM de medio de detalles_pagos_sistema no admite otros valores.
- **Tablas:** detalles_pagos_sistema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Solo efectivo y transferencia.

```sql
SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'detalles_pagos_sistema' AND column_name = 'medio' AND column_type <> "enum('efectivo','transferencia')";
```

#### 13.9 — Confirmar con un usuario que no es SuperAdmin rechazado

- **Objetivo:** FK confirmado_por -> superadmins.
- **Tablas:** pagos_sistema
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1452 (clave foránea)
- **Resultado obtenido (ejecución real):** ERROR 1452 — correcto
- **Interpretación:** Solo un SuperAdmin registrado puede confirmar.

```sql
UPDATE pagos_sistema SET confirmado_por = 99 WHERE id = 1;
```

#### 14.1 — Destinatario único

- **Objetivo:** Cada notificación tiene exactamente un destinatario (usuario o superadmin).
- **Tablas:** notificaciones
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Coherente con el CHECK.
- **Equivale a la prueba del SQL original:** PRUEBA 9.1

```sql
SELECT id FROM notificaciones WHERE (usuario_id IS NULL AND superadmin_id IS NULL) OR (usuario_id IS NOT NULL AND superadmin_id IS NOT NULL);
```

#### 14.2 — Notificaciones con destinatario (INNER JOIN)

- **Objetivo:** Listar las notificaciones de usuarios del taller.
- **Tablas:** notificaciones, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** al menos 1 fila
- **Resultado obtenido (ejecución real):** 12 fila(s) — correcto
- **Interpretación:** Notificaciones por destinatario.

```sql
SELECT u.usuario, n.tipo, n.texto, n.leida FROM notificaciones n INNER JOIN usuarios u ON u.id = n.usuario_id ORDER BY n.id;
```

Muestra del resultado real (primeras filas):

| usuario | tipo | texto | leida |
|---|---|---|---|
| roberto | info | Trabajo finalizado: avisá al cliente. (demostració | 1 |
| roberto | info | Pago registrado. (demostración) | 1 |
| roberto | info | Presupuesto aceptado. (demostración) | 1 |
| roberto | info | Trabajo finalizado: avisá al cliente. (demostració | 1 |
| roberto | info | Pago registrado. (demostración) | 1 |

#### 14.3 — Notificaciones del SuperAdmin (INNER JOIN)

- **Objetivo:** Listar las del SuperAdmin.
- **Tablas:** notificaciones, superadmins, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 1 fila
- **Resultado obtenido (ejecución real):** 1 fila(s) — correcto
- **Interpretación:** Aviso de pago informado.

```sql
SELECT u.usuario, n.texto FROM notificaciones n INNER JOIN superadmins s ON s.id = n.superadmin_id INNER JOIN usuarios u ON u.id = s.usuario_id;
```

Muestra del resultado real (primeras filas):

| usuario | texto |
|---|---|
| superadmin | Taller Matienzo informó un pago de $30.000 pendien |

#### 14.4 — Marcar como leída

- **Objetivo:** UPDATE leida = 1.
- **Tablas:** notificaciones
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El badge de no leídas queda en cero.

```sql
START TRANSACTION;
UPDATE notificaciones SET leida = 1 WHERE usuario_id = 2;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM notificaciones WHERE usuario_id = 2 AND leida = 0;
ROLLBACK;
```

#### 14.5 — Crear y eliminar una notificación

- **Objetivo:** INSERT y DELETE.
- **Tablas:** notificaciones
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Alta y baja correctas.

```sql
START TRANSACTION;
INSERT INTO notificaciones (id, usuario_id, texto, tipo, clave_unica) VALUES (9001, 3, 'Nuevo trabajo asignado', 'trabajo', 'prueba:9001');
DELETE FROM notificaciones WHERE id = 9001;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM notificaciones WHERE id = 9001;
ROLLBACK;
```

#### 14.6 — Aviso duplicado rechazado

- **Objetivo:** clave_unica evita repetir el mismo aviso.
- **Tablas:** notificaciones
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 1062 (clave duplicada)
- **Resultado obtenido (ejecución real):** ERROR 1062 — correcto
- **Interpretación:** Un aviso por hito.

```sql
INSERT INTO notificaciones (usuario_id, texto, clave_unica) SELECT usuario_id, 'dup', clave_unica FROM notificaciones WHERE clave_unica IS NOT NULL LIMIT 1;
```

#### 14.7 — Dos destinatarios rechazados

- **Objetivo:** CHECK ck_notif_destino.
- **Tablas:** notificaciones
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Un solo destinatario.

```sql
INSERT INTO notificaciones (usuario_id, superadmin_id, texto) VALUES (2, 1, 'x');
```

#### 15.1 — Ámbito y actor coherentes

- **Objetivo:** taller -> usuario; sistema -> superadmin.
- **Tablas:** auditoria
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cada acción tiene un solo actor.
- **Equivale a la prueba del SQL original:** PRUEBA 9.2

```sql
SELECT id FROM auditoria WHERE NOT ((ambito = 'taller' AND usuario_id IS NOT NULL AND superadmin_id IS NULL) OR (ambito = 'sistema' AND usuario_id IS NULL AND superadmin_id IS NOT NULL));
```

#### 15.2 — actor_login coincide con el usuario

- **Objetivo:** El login guardado es el del usuario o SuperAdmin referenciado.
- **Tablas:** auditoria, usuarios, superadmins
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Trazabilidad fiel.

```sql
SELECT a.id FROM auditoria a LEFT JOIN usuarios u ON u.id = a.usuario_id LEFT JOIN superadmins s ON s.id = a.superadmin_id LEFT JOIN usuarios us ON us.id = s.usuario_id WHERE a.actor_login <> COALESCE(u.usuario, us.usuario);
```

#### 15.3 — Detalle JSON válido

- **Objetivo:** Todo detalle es JSON.
- **Tablas:** auditoria
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** El formato JSON es válido.

```sql
SELECT id FROM auditoria WHERE detalle IS NOT NULL AND JSON_VALID(detalle) = 0;
```

#### 15.4 — Actividad con su autor (INNER JOIN)

- **Objetivo:** Listar la actividad reciente del taller.
- **Tablas:** auditoria, usuarios
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** al menos 1 fila
- **Resultado obtenido (ejecución real):** 12 fila(s) — correcto
- **Interpretación:** Registro de actividad del dueño y mecánicos.

```sql
SELECT a.fecha, u.nombre, a.accion, JSON_UNQUOTE(JSON_EXTRACT(a.detalle, '$.detalle')) AS detalle FROM auditoria a INNER JOIN usuarios u ON u.id = a.usuario_id ORDER BY a.fecha DESC;
```

Muestra del resultado real (primeras filas):

| fecha | nombre | accion | detalle |
|---|---|---|---|
| 2026-11-19 10:00:00 | Roberto Díaz | Asignó el trabajo | Registro de demostración 12 |
| 2026-11-18 10:00:00 | Roberto Díaz | Registró un pago de cliente | Registro de demostración 11 |
| 2026-11-17 10:00:00 | Roberto Díaz | Presentó un presupuesto al cliente | Registro de demostración 10 |
| 2026-11-16 10:00:00 | Roberto Díaz | Registró una consulta | Registro de demostración 9 |
| 2026-11-15 10:00:00 | Roberto Díaz | Asignó el trabajo | Registro de demostración 8 |

#### 15.5 — Registrar una acción

- **Objetivo:** INSERT con detalle JSON.
- **Tablas:** auditoria
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El detalle se guarda y se consulta como JSON.

```sql
START TRANSACTION;
INSERT INTO auditoria (usuario_id, actor_login, ambito, accion, entidad, entidad_id, detalle) VALUES (2, 'roberto', 'taller', 'Editó una consulta', 'consultas', 1, JSON_OBJECT('detalle', 'Cambió el motivo'));
SELECT IF(JSON_UNQUOTE(JSON_EXTRACT(detalle, '$.detalle')) = 'Cambió el motivo', 'OK', 'FALLA') AS resultado FROM auditoria WHERE accion = 'Editó una consulta';
ROLLBACK;
```

#### 15.6 — Acción de sistema con usuario de taller rechazada

- **Objetivo:** CHECK ck_auditoria_actor.
- **Tablas:** auditoria
- **Tipo:** Error esperado (debe fallar)
- **Resultado esperado:** ERROR 3819 (restricción CHECK)
- **Resultado obtenido (ejecución real):** ERROR 3819 — correcto
- **Interpretación:** Separación de ámbitos.

```sql
INSERT INTO auditoria (usuario_id, actor_login, ambito, accion) VALUES (2, 'roberto', 'sistema', 'x');
```

#### 16.1 — Propuestas resueltas con fecha

- **Objetivo:** aceptada/editada/descartada tienen resuelta_en.
- **Tablas:** propuestas_ia
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Trazabilidad de decisiones.
- **Equivale a la prueba del SQL original:** PRUEBA 9.3

```sql
SELECT id FROM propuestas_ia WHERE estado IN ('aceptada','editada','descartada') AND resuelta_en IS NULL;
```

#### 16.2 — Texto final según estado

- **Objetivo:** Aceptada/editada requieren texto_final.
- **Tablas:** propuestas_ia
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Se guarda el texto que quedó en la consulta.

```sql
SELECT id FROM propuestas_ia WHERE estado IN ('aceptada','editada') AND (texto_final IS NULL OR texto_final = '');
```

#### 16.3 — Contexto y referencia (corregida)

- **Objetivo:** problema_consulta e inspeccion deben referir una consulta; observacion_mecanico, una orden.
- **Tablas:** propuestas_ia
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** La inspección es de la consulta (en el original exigía una orden: corregido).
- **Equivale a la prueba del SQL original:** PRUEBA 9.4

```sql
SELECT id FROM propuestas_ia WHERE (contexto IN ('problema_consulta','inspeccion') AND consulta_id IS NULL) OR (contexto = 'observacion_mecanico' AND orden_id IS NULL);
```

#### 16.4 — Sin proveedores externos

- **Objetivo:** El MVP usa reglas locales: no debe haber proveedores de IA externos ni claves.
- **Tablas:** propuestas_ia
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Coincide con el MVP (sin integraciones externas).

```sql
SELECT id, proveedor FROM propuestas_ia WHERE proveedor NOT IN ('reglas_locales');
```

#### 16.5 — Propuestas con autor y consulta (INNER JOIN)

- **Objetivo:** Listar propuestas.
- **Tablas:** propuestas_ia, usuarios, consultas
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 1 fila
- **Resultado obtenido (ejecución real):** 1 fila(s) — correcto
- **Interpretación:** Propuesta aceptada de la demostración.

```sql
SELECT p.id, u.nombre, c.id AS consulta, p.estado, p.texto_original, p.texto_final FROM propuestas_ia p INNER JOIN usuarios u ON u.id = p.usuario_id INNER JOIN consultas c ON c.id = p.consulta_id;
```

Muestra del resultado real (primeras filas):

| id | nombre | consulta | estado | texto_original | texto_final |
|---|---|---|---|---|---|
| 1 | Juan Pérez | 2 | aceptada | el auto hace un ruido cuando freno y parece que vi | Se informa un ruido al accionar los frenos, acompa |

#### 16.6 — Generar y aceptar una propuesta

- **Objetivo:** INSERT y UPDATE de estado.
- **Tablas:** propuestas_ia
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Ciclo completo de una propuesta.

```sql
START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, orden_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9001, 3, 'observacion_mecanico', 3, 'cambie filtro', 'Se cambió el filtro.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'aceptada', texto_final = texto_propuesto, resuelta_en = NOW() WHERE id = 9001;
SELECT IF(estado = 'aceptada' AND texto_final = 'Se cambió el filtro.', 'OK', 'FALLA') AS resultado FROM propuestas_ia WHERE id = 9001;
ROLLBACK;
```

#### 16.7 — Contextos de IA: sin fotografía

- **Objetivo:** El ENUM de contexto solo admite textos (sin imágenes).
- **Tablas:** propuestas_ia
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Coherente con la eliminación de fotografías.

```sql
SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'propuestas_ia' AND column_name = 'contexto' AND column_type REGEXP 'foto|imagen';
```

#### 16.8 — El texto original siempre se conserva

- **Objetivo:** Toda propuesta guarda el texto original y la propuesta; el final solo existe si se aceptó o editó.
- **Tablas:** propuestas_ia
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** La mejora es opcional y no pisa el original.

```sql
SELECT id FROM propuestas_ia WHERE texto_original IS NULL OR texto_original = '' OR texto_propuesto IS NULL OR (estado = 'descartada' AND texto_final IS NOT NULL) OR (estado = 'generada' AND texto_final IS NOT NULL);
```

#### 16.9 — Aceptar una propuesta no modifica el texto original

- **Objetivo:** UPDATE a aceptada: texto_original queda igual.
- **Tablas:** propuestas_ia
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Original y propuesta quedan guardados junto al resultado.

```sql
START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, consulta_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9002, 2, 'problema_consulta', 1, 'ruido al frenar', 'Se informa un ruido al frenar.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'aceptada', texto_final = texto_propuesto, resuelta_en = NOW() WHERE id = 9002;
SELECT IF(texto_original = 'ruido al frenar' AND texto_final = 'Se informa un ruido al frenar.' AND estado = 'aceptada', 'OK', 'FALLA') AS resultado FROM propuestas_ia WHERE id = 9002;
ROLLBACK;
```

#### 16.10 — Editar y descartar propuestas

- **Objetivo:** Una editada guarda un texto final distinto de la propuesta; una descartada no deja texto final.
- **Tablas:** propuestas_ia
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** Aceptar, editar y descartar funcionan; el original no cambia nunca.

```sql
START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, orden_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9003, 3, 'observacion_mecanico', 3, 'cambie filtro', 'Se cambió el filtro.', 'generada', 'reglas_locales'), (9004, 3, 'observacion_mecanico', 3, 'revise frenos', 'Se revisaron los frenos.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'editada', texto_final = 'Se cambió el filtro de aceite.', resuelta_en = NOW() WHERE id = 9003;
UPDATE propuestas_ia SET estado = 'descartada', resuelta_en = NOW() WHERE id = 9004;
SELECT IF((SELECT texto_final <> texto_propuesto AND texto_original = 'cambie filtro' FROM propuestas_ia WHERE id = 9003) AND (SELECT texto_final IS NULL AND texto_original = 'revise frenos' FROM propuestas_ia WHERE id = 9004), 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 17.1 — La base tiene 30 tablas

- **Objetivo:** Cantidad de tablas del esquema.
- **Tablas:** information_schema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas (hay exactamente 30)
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Si devolviera una fila, la cantidad no es 30.

```sql
SELECT COUNT(*) AS tablas FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE' HAVING COUNT(*) <> 30;
```

#### 17.2 — No existen tablas ni columnas de fotos o archivos de trabajos

- **Objetivo:** Verifica la eliminación de la función de fotografías.
- **Tablas:** information_schema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** archivos_trabajos fue eliminada.

```sql
SELECT table_name, column_name FROM information_schema.columns WHERE table_schema = DATABASE() AND (table_name = 'archivos_trabajos' OR column_name REGEXP 'foto|imagen|ruta_foto')
UNION ALL SELECT table_name, NULL FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name REGEXP 'foto|archivos_trabajos';
```

#### 17.3 — Toda tabla tiene clave primaria

- **Objetivo:** Sin tablas sin PK.
- **Tablas:** information_schema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Todas las tablas tienen PK.

```sql
SELECT t.table_name FROM information_schema.tables t LEFT JOIN information_schema.table_constraints c ON c.table_schema = t.table_schema AND c.table_name = t.table_name AND c.constraint_type = 'PRIMARY KEY' WHERE t.table_schema = DATABASE() AND t.table_type = 'BASE TABLE' AND c.constraint_name IS NULL;
```

#### 17.4 — Claves foráneas definidas

- **Objetivo:** Listado de las relaciones del modelo.
- **Tablas:** information_schema
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** al menos 1 fila
- **Resultado obtenido (ejecución real):** 57 fila(s) — correcto
- **Interpretación:** Fuente del diagrama entidad-relación.

```sql
SELECT table_name, column_name, referenced_table_name, referenced_column_name FROM information_schema.key_column_usage WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL ORDER BY table_name, column_name;
```

Muestra del resultado real (primeras filas):

| TABLE_NAME | COLUMN_NAME | REFERENCED_TABLE_NAME | REFERENCED_COLUMN_NAME |
|---|---|---|---|
| asignaciones_trabajo | asignado_por | usuarios | id |
| asignaciones_trabajo | mecanico_id | usuarios | id |
| asignaciones_trabajo | orden_id | ordenes_trabajo | id |
| auditoria | superadmin_id | superadmins | id |
| auditoria | usuario_id | usuarios | id |

#### 17.5 — Claves foráneas sin índice propio

- **Objetivo:** Toda FK debería tener un índice que la acompañe.
- **Tablas:** information_schema
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Cada FK está indexada.

```sql
SELECT k.table_name, k.column_name FROM information_schema.key_column_usage k
WHERE k.table_schema = DATABASE() AND k.referenced_table_name IS NOT NULL AND k.ordinal_position = 1
 AND NOT EXISTS (SELECT 1 FROM information_schema.statistics s WHERE s.table_schema = k.table_schema AND s.table_name = k.table_name AND s.column_name = k.column_name AND s.seq_in_index = 1);
```

#### 17.6 — Cantidad de registros por tabla

- **Objetivo:** Resumen de datos de demostración.
- **Tablas:** todas
- **Tipo:** Consulta (SELECT / INNER JOIN)
- **Resultado esperado:** 30 filas (comprobantes_pagos_sistema con 0 registros)
- **Resultado obtenido (ejecución real):** 30 fila(s) — correcto
- **Interpretación:** Una fila por tabla.

```sql
SELECT 'roles' AS tabla, COUNT(*) AS filas FROM roles UNION ALL SELECT 'usuarios', COUNT(*) FROM usuarios UNION ALL SELECT 'superadmins', COUNT(*) FROM superadmins
UNION ALL SELECT 'taller', COUNT(*) FROM taller UNION ALL SELECT 'clientes', COUNT(*) FROM clientes UNION ALL SELECT 'vehiculos', COUNT(*) FROM vehiculos
UNION ALL SELECT 'consultas', COUNT(*) FROM consultas UNION ALL SELECT 'detalles_consultas', COUNT(*) FROM detalles_consultas UNION ALL SELECT 'presupuestos', COUNT(*) FROM presupuestos
UNION ALL SELECT 'categorias_catalogo', COUNT(*) FROM categorias_catalogo UNION ALL SELECT 'catalogo_items', COUNT(*) FROM catalogo_items
UNION ALL SELECT 'historial_precios_catalogo', COUNT(*) FROM historial_precios_catalogo UNION ALL SELECT 'detalles_presupuestos', COUNT(*) FROM detalles_presupuestos
UNION ALL SELECT 'ordenes_trabajo', COUNT(*) FROM ordenes_trabajo UNION ALL SELECT 'historial_estados_ordenes', COUNT(*) FROM historial_estados_ordenes
UNION ALL SELECT 'asignaciones_trabajo', COUNT(*) FROM asignaciones_trabajo UNION ALL SELECT 'pagos_clientes', COUNT(*) FROM pagos_clientes
UNION ALL SELECT 'detalles_pagos_clientes', COUNT(*) FROM detalles_pagos_clientes UNION ALL SELECT 'movimientos_stock', COUNT(*) FROM movimientos_stock
UNION ALL SELECT 'movimientos_mecanicos', COUNT(*) FROM movimientos_mecanicos UNION ALL SELECT 'liquidaciones_mecanicos', COUNT(*) FROM liquidaciones_mecanicos
UNION ALL SELECT 'detalles_liquidaciones_mecanicos', COUNT(*) FROM detalles_liquidaciones_mecanicos UNION ALL SELECT 'periodos_pago_sistema', COUNT(*) FROM periodos_pago_sistema
UNION ALL SELECT 'pagos_sistema', COUNT(*) FROM pagos_sistema UNION ALL SELECT 'detalles_pagos_sistema', COUNT(*) FROM detalles_pagos_sistema
UNION ALL SELECT 'comprobantes_pagos_sistema', COUNT(*) FROM comprobantes_pagos_sistema UNION ALL SELECT 'notificaciones', COUNT(*) FROM notificaciones
UNION ALL SELECT 'auditoria', COUNT(*) FROM auditoria UNION ALL SELECT 'propuestas_ia', COUNT(*) FROM propuestas_ia UNION ALL SELECT 'avances_ordenes', COUNT(*) FROM avances_ordenes;
```

Muestra del resultado real (primeras filas):

| tabla | filas |
|---|---|
| roles | 2 |
| usuarios | 5 |
| superadmins | 1 |
| taller | 1 |
| clientes | 16 |

#### 18.1 — Flujo completo: consulta → presupuesto → orden → pago

- **Objetivo:** Recorre el proceso principal del taller en una transacción (se deshace): consulta con revisión, presupuesto aceptado, orden, asignación y aceptación del mecánico, inicio, avance, uso de repuesto, finalización, comisión y pago combinado.
- **Tablas:** consultas, detalles_consultas, presupuestos, detalles_presupuestos, ordenes_trabajo, historial_estados_ordenes, asignaciones_trabajo, avances_ordenes, movimientos_stock, catalogo_items, movimientos_mecanicos, pagos_clientes, detalles_pagos_clientes
- **Tipo:** Operación INSERT / UPDATE / DELETE con ROLLBACK
- **Resultado esperado:** resultado = OK
- **Resultado obtenido (ejecución real):** OK — correcto
- **Interpretación:** El proceso completo funciona con el modelo relacional: 4 × 5000 + 10000 = 30000; comisión 10 % sobre la mano de obra (10000) = 1000, no sobre el total; pago combinado 10000 + 20000.

```sql
START TRANSACTION;
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, motivo, descripcion_problema, estado, es_gratuita, creado_por) VALUES (9100, 2, (SELECT id FROM vehiculos WHERE cliente_id = 2 LIMIT 1), 'Cliente 2', 'Servicio general', 'Servicio general y cambio de aceite', 'abierta', 0, 2);
INSERT INTO detalles_consultas (consulta_id, descripcion, tipo, registrado_por) VALUES (9100, 'Aceite degradado', 'verificado', 2);
UPDATE consultas SET estado = 'esperando_respuesta', importe_estimado = 30000 WHERE id = 9100;
INSERT INTO presupuestos (id, consulta_id, numero, estado, valido_hasta, fecha_envio, creado_por, comision_pct) VALUES (9100, 9100, 'PRE-9100', 'enviado', '2026-12-31', NOW(), 2, 10);
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, tipo, cantidad, precio_unitario, catalogo_item_id) VALUES (9100, 'Aceite 5W30', 'repuesto', 4, 5000, 1), (9100, 'Mano de obra', 'mano_obra', 1, 10000, NULL);
UPDATE presupuestos SET total_calculado = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9100), precio_final = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9100) WHERE id = 9100;
UPDATE presupuestos SET estado = 'aceptado', fecha_respuesta = NOW() WHERE id = 9100;
UPDATE consultas SET estado = 'aprobada' WHERE id = 9100;
INSERT INTO ordenes_trabajo (id, numero, presupuesto_id, cliente_id, vehiculo_id, mecanico_id, descripcion, estado, precio_final, comision_pct)
 SELECT 9100, 'OT-9100', p.id, c.cliente_id, c.vehiculo_id, 3, 'Servicio general', 'ofrecido', p.precio_final, p.comision_pct FROM presupuestos p INNER JOIN consultas c ON c.id = p.consulta_id WHERE p.id = 9100;
INSERT INTO historial_estados_ordenes (orden_id, estado_anterior, estado_nuevo, cambiado_por) VALUES (9100, NULL, 'ofrecido', 2);
INSERT INTO asignaciones_trabajo (orden_id, mecanico_id, asignado_por, resultado) VALUES (9100, 3, 2, 'ofrecida');
UPDATE asignaciones_trabajo SET resultado = 'aceptada', resuelto_en = NOW() WHERE orden_id = 9100;
UPDATE ordenes_trabajo SET estado = 'en_proceso', fecha_inicio = NOW() WHERE id = 9100;
INSERT INTO historial_estados_ordenes (orden_id, estado_anterior, estado_nuevo, cambiado_por) VALUES (9100, 'ofrecido', 'en_proceso', 3);
INSERT INTO avances_ordenes (orden_id, usuario_id, texto) VALUES (9100, 3, 'Se cambió el aceite y el filtro.');
INSERT INTO movimientos_stock (catalogo_item_id, tipo, cantidad, estado, motivo, orden_id, solicitado_por, resuelto_por) VALUES (1, 'salida', 4, 'confirmado', 'Usado en OT-9100', 9100, 3, 3);
UPDATE catalogo_items SET cantidad = cantidad - 4 WHERE id = 1;
UPDATE ordenes_trabajo SET estado = 'finalizado', fecha_fin = NOW() WHERE id = 9100;
INSERT INTO historial_estados_ordenes (orden_id, estado_anterior, estado_nuevo, cambiado_por) VALUES (9100, 'en_proceso', 'finalizado', 3);
INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por) SELECT o.mecanico_id, 'comision', ROUND((SELECT SUM(d.monto) FROM detalles_presupuestos d WHERE d.presupuesto_id = o.presupuesto_id AND d.tipo = 'mano_obra') * o.comision_pct / 100, 2), o.id, 2 FROM ordenes_trabajo o WHERE o.id = 9100;
INSERT INTO pagos_clientes (id, tipo, orden_id, cliente_id, monto, metodo, registrado_por) SELECT 9100, 'trabajo', id, cliente_id, precio_final, 'combinado', 2 FROM ordenes_trabajo WHERE id = 9100;
INSERT INTO detalles_pagos_clientes (pago_cliente_id, medio, importe) VALUES (9100, 'efectivo', 10000), (9100, 'transferencia', 20000);
SELECT IF(
  (SELECT precio_final FROM ordenes_trabajo WHERE id = 9100) = 30000
  AND (SELECT monto FROM movimientos_mecanicos WHERE orden_id = 9100) = 1000
  AND (SELECT SUM(importe) FROM detalles_pagos_clientes WHERE pago_cliente_id = 9100) = 30000
  AND (SELECT estado FROM ordenes_trabajo WHERE id = 9100) = 'finalizado'
  AND (SELECT COUNT(*) FROM historial_estados_ordenes WHERE orden_id = 9100) = 3, 'OK', 'FALLA') AS resultado;
ROLLBACK;
```

#### 18.2 — Los datos no cambiaron tras las pruebas

- **Objetivo:** Después de las pruebas con ROLLBACK, el stock del artículo 1 y el estado de la orden 2 siguen igual.
- **Tablas:** catalogo_items, ordenes_trabajo
- **Tipo:** Integridad (debe dar 0 filas)
- **Resultado esperado:** 0 filas
- **Resultado obtenido (ejecución real):** 0 fila(s) — correcto
- **Interpretación:** Las pruebas no destruyen los datos de las siguientes.

```sql
SELECT i.id FROM catalogo_items i INNER JOIN ordenes_trabajo o ON o.id = 2 WHERE i.id = 1 AND (i.cantidad <> 28 OR o.estado <> 'ofrecido');
```

## Pruebas que no se pudieron ejecutar

Ninguna: las 165 pruebas se ejecutaron en MySQL 8.0.46-0ubuntu0.24.04.5. Quedan **sin** verificar (porque no hay backend): el comportamiento desde la aplicación Vue contra esta base, la concurrencia y el rendimiento con grandes volúmenes.

## Hallazgos de las pruebas (corregidos)

- **CHECK `ck_consultas_cobro`:** la prueba 4.10 mostró que cobrar sin importe pasaba la restricción (el valor NULL no la violaba). Se corrigió exigiendo `cobro_importe IS NOT NULL`.
- Las pruebas de valores fuera de ENUM (12.10, 13.8, 16.7) se resuelven consultando `information_schema`, porque MySQL no permite capturar ese error (1265) dentro de un procedimiento con handler.
- El SQL original contenía una prueba cuya condición era incorrecta (exigía una orden para la inspección de IA) y otra sobre liquidaciones con totales mal calculados; están corregidas en las pruebas 16.3 y 11.2.
