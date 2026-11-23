# Diccionario de datos — Taller Matienzo (MySQL 8)

Generado automáticamente desde `information_schema` de la base cargada con `taller_matienzo_final.sql`. Cada tabla incluye columnas, tipo, nulabilidad, valor por defecto, claves y restricciones.

**Total: 30 tablas.**

## Índice

- [asignaciones_trabajo](#asignaciones_trabajo) — Ofrecimientos y respuestas de mecánicos para cada orden.
- [auditoria](#auditoria) — Registro de acciones (ámbito taller o sistema).
- [avances_ordenes](#avances_ordenes) — Avances escritos por el mecánico en una orden.
- [catalogo_items](#catalogo_items) — Catálogo de repuestos (stock, mínimos, precios).
- [categorias_catalogo](#categorias_catalogo) — Categorías de repuestos.
- [clientes](#clientes) — Clientes del taller.
- [comprobantes_pagos_sistema](#comprobantes_pagos_sistema) — Comprobantes adjuntos de pagos al sistema. Sin uso en el MVP (decisión pendiente).
- [consultas](#consultas) — Consultas/recepciones del cliente, con decisión de cobro y cierre.
- [detalles_consultas](#detalles_consultas) — Revisión técnica de la consulta (verificado, repuestos necesarios, trabajo recomendado).
- [detalles_liquidaciones_mecanicos](#detalles_liquidaciones_mecanicos) — Movimientos incluidos en cada liquidación.
- [detalles_pagos_clientes](#detalles_pagos_clientes) — Medios con que se pagó cada cobro (efectivo, transferencia, etc.).
- [detalles_pagos_sistema](#detalles_pagos_sistema) — Medios de cada pago al sistema (efectivo, transferencia).
- [detalles_presupuestos](#detalles_presupuestos) — Líneas del presupuesto (monto calculado = cantidad × precio).
- [historial_estados_ordenes](#historial_estados_ordenes) — Historial de cambios de estado de cada orden.
- [historial_precios_catalogo](#historial_precios_catalogo) — Cambios de precio de los artículos.
- [liquidaciones_mecanicos](#liquidaciones_mecanicos) — Liquidaciones por período de un mecánico.
- [movimientos_mecanicos](#movimientos_mecanicos) — Comisiones y adelantos de mecánicos.
- [movimientos_stock](#movimientos_stock) — Entradas y salidas de stock (incluye repuestos usados en órdenes).
- [notificaciones](#notificaciones) — Avisos para usuarios del taller o SuperAdmin.
- [ordenes_trabajo](#ordenes_trabajo) — Órdenes de trabajo nacidas de presupuestos aceptados.
- [pagos_clientes](#pagos_clientes) — Cobros del taller a sus clientes (trabajos y ventas de mostrador).
- [pagos_sistema](#pagos_sistema) — Pagos del taller al sistema, confirmados por el SuperAdmin. Separados de los cobros a clientes.
- [periodos_pago_sistema](#periodos_pago_sistema) — Períodos de la suscripción del taller al sistema (plan mensual o anual, 3 días de tolerancia).
- [presupuestos](#presupuestos) — Presupuesto único por consulta, con precio final y comisión.
- [propuestas_ia](#propuestas_ia) — Propuestas de redacción asistida (reglas locales; solo texto).
- [roles](#roles) — Roles operativos del taller (Administrador, Mecánico). El SuperAdmin no es un rol.
- [superadmins](#superadmins) — Datos propios del SuperAdmin (cuenta oculta de la plataforma).
- [taller](#taller) — El único taller que administra el sistema, con su estado de acceso.
- [usuarios](#usuarios) — Cuentas de acceso: administrador, mecánicos y SuperAdmin (tipo_cuenta).
- [vehiculos](#vehiculos) — Vehículos; el propietario actual es clientes (cliente_id).

## asignaciones_trabajo

Ofrecimientos y respuestas de mecánicos para cada orden.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| orden_id | int unsigned | no |  | índice, FK → ordenes_trabajo.id |  |
| mecanico_id | int unsigned | no |  | índice, FK → usuarios.id |  |
| asignado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| resultado | enum('ofrecida','aceptada','rechazada','reasignada','completada') | no | `ofrecida` |  |  |
| motivo_rechazo | varchar(250) | sí |  |  |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| resuelto_en | datetime | sí |  |  |  |

## auditoria

Registro de acciones (ámbito taller o sistema).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | bigint unsigned | no |  | PK | auto_increment |
| usuario_id | int unsigned | sí |  | índice, FK → usuarios.id |  |
| superadmin_id | int unsigned | sí |  | índice, FK → superadmins.id |  |
| actor_login | varchar(40) | no |  |  |  |
| ambito | enum('taller','sistema') | no | `taller` | índice |  |
| accion | varchar(120) | no |  |  |  |
| entidad | varchar(40) | sí |  |  |  |
| entidad_id | int unsigned | sí |  |  |  |
| detalle | json | sí |  |  |  |
| ip | varchar(45) | sí |  |  |  |
| fecha | datetime | no | `CURRENT_TIMESTAMP` | índice |  |

**Restricciones CHECK:**

- `ck_auditoria_actor`: `(((`ambito` = _utf8mb4\'taller\') and (`usuario_id` is not null) and (`superadmin_id` is null)) or ((`ambito` = _utf8mb4\'sistema\') and (`usuario_id` is null) and (`superadmin_id` is not null)))`

## avances_ordenes

Avances escritos por el mecánico en una orden.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| orden_id | int unsigned | no |  | índice, FK → ordenes_trabajo.id |  |
| usuario_id | int unsigned | no |  | índice, FK → usuarios.id |  |
| texto | text | no |  |  |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

## catalogo_items

Catálogo de repuestos (stock, mínimos, precios).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| categoria_id | int unsigned | sí |  | índice, FK → categorias_catalogo.id |  |
| tipo | enum('servicio','repuesto') | no |  | índice |  |
| nombre | varchar(120) | no |  |  |  |
| codigo | varchar(40) | sí |  | UNIQUE |  |
| marca | varchar(60) | sí |  |  |  |
| ubicacion | varchar(60) | sí |  |  |  |
| precio_compra | decimal(12,2) | no | `0.00` |  |  |
| precio_venta | decimal(12,2) | no | `0.00` |  |  |
| cantidad | int | no | `0` |  |  |
| stock_minimo | int | no | `0` |  |  |
| activo | tinyint(1) | no | `1` |  |  |

**Restricciones CHECK:**

- `ck_catalogo_importes`: `((`precio_compra` >= 0) and (`precio_venta` >= 0))`
- `ck_catalogo_stock`: `((`cantidad` >= 0) and (`stock_minimo` >= 0))`

**Restricciones UNIQUE:**

- `uq_catalogo_codigo` (codigo)

## categorias_catalogo

Categorías de repuestos.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| nombre | varchar(60) | no |  | UNIQUE |  |
| descripcion | varchar(200) | sí |  |  |  |
| activo | tinyint(1) | no | `1` |  |  |

**Restricciones UNIQUE:**

- `uq_categorias_nombre` (nombre)

## clientes

Clientes del taller.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| nombre | varchar(100) | no |  | índice |  |
| dni | varchar(15) | sí |  | UNIQUE |  |
| telefono | varchar(30) | sí |  |  |  |
| email | varchar(120) | sí |  |  |  |
| direccion | varchar(150) | sí |  |  |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

**Restricciones UNIQUE:**

- `uq_clientes_dni` (dni)

## comprobantes_pagos_sistema

Comprobantes adjuntos de pagos al sistema. Sin uso en el MVP (decisión pendiente).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| pago_sistema_id | int unsigned | no |  | índice, FK → pagos_sistema.id |  |
| nombre_archivo | varchar(180) | no |  |  |  |
| ruta_archivo | varchar(255) | no |  |  |  |
| tipo_archivo | varchar(80) | sí |  |  |  |
| subido_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

## consultas

Consultas/recepciones del cliente, con decisión de cobro y cierre.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| cliente_id | int unsigned | sí |  | índice, FK → clientes.id |  |
| vehiculo_id | int unsigned | sí |  | índice, FK → vehiculos.id |  |
| contacto_nombre | varchar(100) | no |  |  |  |
| contacto_dni | varchar(15) | sí |  |  |  |
| contacto_telefono | varchar(30) | sí |  |  |  |
| veh_patente | varchar(10) | sí |  |  |  |
| veh_marca | varchar(40) | sí |  |  |  |
| veh_modelo | varchar(40) | sí |  |  |  |
| veh_anio | smallint unsigned | sí |  |  |  |
| veh_kilometraje | int unsigned | sí |  |  |  |
| motivo | varchar(200) | no |  |  |  |
| descripcion_problema | text | sí |  |  |  |
| observaciones | text | sí |  |  |  |
| observaciones_inspeccion | text | sí |  |  |  |
| importe_estimado | decimal(12,2) | sí |  |  |  |
| estado | enum('abierta','esperando_respuesta','aprobada','rechazada','cerrada') | no | `abierta` | índice |  |
| es_gratuita | tinyint(1) | no | `0` |  |  |
| cobro_decision | enum('cobrar','gratis') | sí |  |  |  |
| cobro_importe | decimal(12,2) | sí |  |  |  |
| cobro_por | int unsigned | sí |  | índice, FK → usuarios.id |  |
| cobro_fecha | date | sí |  |  |  |
| motivo_cierre | varchar(200) | sí |  |  |  |
| creado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` | índice |  |
| actualizado_en | datetime | no | `CURRENT_TIMESTAMP` |  | on update CURRENT_TIMESTAMP |

**Restricciones CHECK:**

- `ck_consultas_cobro`: `(((`cobro_decision` is null) and (`cobro_importe` is null)) or ((`cobro_decision` = _utf8mb4\'gratis\') and (coalesce(`cobro_importe`,0) = 0)) or ((`cobro_decision` = _utf8mb4\'cobrar\') and (`cobro_importe` is not null) and (`cobro_importe` > 0)))`

## detalles_consultas

Revisión técnica de la consulta (verificado, repuestos necesarios, trabajo recomendado).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| consulta_id | int unsigned | no |  | índice, FK → consultas.id |  |
| descripcion | text | no |  |  |  |
| tipo | enum('sintoma_informado','verificado','repuestos_necesarios','trabajo_recomendado') | no | `verificado` |  |  |
| registrado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

## detalles_liquidaciones_mecanicos

Movimientos incluidos en cada liquidación.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| liquidacion_id | int unsigned | no |  | índice, FK → liquidaciones_mecanicos.id |  |
| movimiento_mecanico_id | int unsigned | no |  | UNIQUE, FK → movimientos_mecanicos.id |  |
| importe_incluido | decimal(12,2) | no |  |  |  |

**Restricciones CHECK:**

- `ck_detliq_importe`: `(`importe_incluido` > 0)`

**Restricciones UNIQUE:**

- `uq_detliq_movimiento` (movimiento_mecanico_id)

## detalles_pagos_clientes

Medios con que se pagó cada cobro (efectivo, transferencia, etc.).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| pago_cliente_id | int unsigned | no |  | índice, FK → pagos_clientes.id |  |
| medio | enum('efectivo','transferencia','mercadopago','tarjeta') | no |  |  |  |
| importe | decimal(12,2) | no |  |  |  |
| referencia | varchar(120) | sí |  |  |  |

**Restricciones CHECK:**

- `ck_detpagcli_importe`: `(`importe` > 0)`

**Restricciones UNIQUE:**

- `uq_detpagcli_medio` (pago_cliente_id, medio)

## detalles_pagos_sistema

Medios de cada pago al sistema (efectivo, transferencia).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| pago_id | int unsigned | no |  | índice, FK → pagos_sistema.id |  |
| medio | enum('efectivo','transferencia') | no |  |  |  |
| importe | decimal(12,2) | no |  |  |  |
| referencia | varchar(120) | sí |  |  |  |

**Restricciones CHECK:**

- `ck_detpagsis_importe`: `(`importe` > 0)`

**Restricciones UNIQUE:**

- `uq_detpagsis_medio` (pago_id, medio)

## detalles_presupuestos

Líneas del presupuesto (monto calculado = cantidad × precio).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| presupuesto_id | int unsigned | no |  | índice, FK → presupuestos.id |  |
| concepto | varchar(200) | no |  |  |  |
| tipo | enum('mano_obra','repuesto','servicio','otro') | no | `mano_obra` |  |  |
| cantidad | decimal(8,2) | no | `1.00` |  |  |
| precio_unitario | decimal(12,2) | no |  |  |  |
| monto | decimal(12,2) | sí |  |  | STORED GENERATED |
| catalogo_item_id | int unsigned | sí |  | índice, FK → catalogo_items.id |  |

**Restricciones CHECK:**

- `ck_detpres_valores`: `((`cantidad` > 0) and (`precio_unitario` >= 0))`

## historial_estados_ordenes

Historial de cambios de estado de cada orden.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| orden_id | int unsigned | no |  | índice, FK → ordenes_trabajo.id |  |
| estado_anterior | varchar(30) | sí |  |  |  |
| estado_nuevo | varchar(30) | no |  |  |  |
| cambiado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| observacion | varchar(250) | sí |  |  |  |
| fecha | datetime | no | `CURRENT_TIMESTAMP` |  |  |

## historial_precios_catalogo

Cambios de precio de los artículos.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| catalogo_item_id | int unsigned | no |  | índice, FK → catalogo_items.id |  |
| precio_compra_anterior | decimal(12,2) | no |  |  |  |
| precio_compra_nuevo | decimal(12,2) | no |  |  |  |
| precio_venta_anterior | decimal(12,2) | no |  |  |  |
| precio_venta_nuevo | decimal(12,2) | no |  |  |  |
| cambiado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| fecha | datetime | no | `CURRENT_TIMESTAMP` |  |  |

## liquidaciones_mecanicos

Liquidaciones por período de un mecánico.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| mecanico_id | int unsigned | no |  | índice, FK → usuarios.id |  |
| periodo_desde | date | no |  |  |  |
| periodo_hasta | date | no |  |  |  |
| total_comisiones | decimal(12,2) | no | `0.00` |  |  |
| total_adelantos | decimal(12,2) | no | `0.00` |  |  |
| total_a_pagar | decimal(12,2) | no | `0.00` |  |  |
| estado | enum('pendiente','pagada','anulada') | no | `pendiente` |  |  |
| creado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| fecha_creacion | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| fecha_pago | datetime | sí |  |  |  |
| observaciones | varchar(250) | sí |  |  |  |

**Restricciones CHECK:**

- `ck_liq_fechas`: `(`periodo_hasta` >= `periodo_desde`)`
- `ck_liq_importes`: `((`total_comisiones` >= 0) and (`total_adelantos` >= 0) and (`total_a_pagar` >= 0))`

## movimientos_mecanicos

Comisiones y adelantos de mecánicos.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| mecanico_id | int unsigned | no |  | índice, FK → usuarios.id |  |
| tipo | enum('comision','adelanto') | no |  |  |  |
| monto | decimal(12,2) | no |  |  |  |
| orden_id | int unsigned | sí |  | índice, FK → ordenes_trabajo.id |  |
| registrado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| fecha | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| descripcion | varchar(200) | sí |  |  |  |

**Restricciones CHECK:**

- `ck_movmec_monto`: `(`monto` > 0)`
- `ck_movmec_tipo_orden`: `(((`tipo` = _utf8mb4\'comision\') and (`orden_id` is not null)) or ((`tipo` = _utf8mb4\'adelanto\') and (`orden_id` is null)))`

**Restricciones UNIQUE:**

- `uq_movmec_orden_tipo` (orden_id, tipo)

## movimientos_stock

Entradas y salidas de stock (incluye repuestos usados en órdenes).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| catalogo_item_id | int unsigned | sí |  | índice, FK → catalogo_items.id |  |
| descripcion_libre | varchar(150) | sí |  |  |  |
| tipo | enum('entrada','salida') | no |  |  |  |
| cantidad | int unsigned | no |  |  |  |
| estado | enum('pendiente','confirmado','rechazado') | no | `confirmado` | índice |  |
| aportado_cliente | tinyint(1) | no | `0` |  |  |
| motivo | varchar(150) | no |  |  |  |
| orden_id | int unsigned | sí |  | índice, FK → ordenes_trabajo.id |  |
| pago_cliente_id | int unsigned | sí |  | índice, FK → pagos_clientes.id |  |
| solicitado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| resuelto_por | int unsigned | sí |  | índice, FK → usuarios.id |  |
| fecha | datetime | no | `CURRENT_TIMESTAMP` |  |  |

**Restricciones CHECK:**

- `ck_movstock_cantidad`: `(`cantidad` > 0)`
- `ck_movstock_descripcion`: `((`catalogo_item_id` is not null) or (`descripcion_libre` is not null))`

## notificaciones

Avisos para usuarios del taller o SuperAdmin.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| usuario_id | int unsigned | sí |  | índice, FK → usuarios.id |  |
| superadmin_id | int unsigned | sí |  | índice, FK → superadmins.id |  |
| texto | varchar(300) | no |  |  |  |
| enlace | varchar(120) | sí |  |  |  |
| tipo | varchar(30) | no | `general` |  |  |
| clave_unica | varchar(100) | sí |  | UNIQUE |  |
| leida | tinyint(1) | no | `0` |  |  |
| creada_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

**Restricciones CHECK:**

- `ck_notif_destino`: `(((`usuario_id` is not null) and (`superadmin_id` is null)) or ((`usuario_id` is null) and (`superadmin_id` is not null)))`

**Restricciones UNIQUE:**

- `uq_notif_clave` (clave_unica)

## ordenes_trabajo

Órdenes de trabajo nacidas de presupuestos aceptados.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| numero | varchar(20) | no |  | UNIQUE |  |
| presupuesto_id | int unsigned | no |  | UNIQUE, FK → presupuestos.id |  |
| cliente_id | int unsigned | no |  | índice, FK → clientes.id |  |
| vehiculo_id | int unsigned | no |  | índice, FK → vehiculos.id |  |
| mecanico_id | int unsigned | sí |  | índice, FK → usuarios.id |  |
| descripcion | varchar(200) | no |  |  |  |
| repuestos_previstos | varchar(250) | sí |  |  |  |
| observaciones | varchar(250) | sí |  |  |  |
| estado | enum('sin_asignar','ofrecido','aceptado','en_proceso','finalizado','cancelado') | no | `sin_asignar` | índice |  |
| precio_final | decimal(12,2) | no |  |  |  |
| comision_pct | decimal(5,2) | no | `0.00` |  |  |
| observaciones_mecanico | text | sí |  |  |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| inicio_previsto | date | sí |  |  |  |
| entrega_prevista | date | sí |  |  |  |
| fecha_inicio | datetime | sí |  |  |  |
| fecha_fin | datetime | sí |  |  |  |

**Restricciones CHECK:**

- `ck_ordenes_importes`: `((`precio_final` >= 0) and (`comision_pct` >= 0) and (`comision_pct` <= 100))`
- `ck_ordenes_fechas_previstas`: `((`inicio_previsto` is null) or (`entrega_prevista` is null) or (`entrega_prevista` >= `inicio_previsto`))`

**Restricciones UNIQUE:**

- `uq_ordenes_numero` (numero)
- `uq_ordenes_presupuesto` (presupuesto_id)

## pagos_clientes

Cobros del taller a sus clientes (trabajos y ventas de mostrador).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| tipo | enum('trabajo','venta_mostrador') | no | `trabajo` |  |  |
| orden_id | int unsigned | sí |  | índice, FK → ordenes_trabajo.id |  |
| cliente_id | int unsigned | sí |  | índice, FK → clientes.id |  |
| monto | decimal(12,2) | no |  |  |  |
| metodo | enum('efectivo','transferencia','mercadopago','tarjeta','combinado') | no | `efectivo` |  |  |
| registrado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| fecha | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| observaciones | varchar(250) | sí |  |  |  |

**Restricciones CHECK:**

- `ck_pagcli_monto`: `(`monto` > 0)`

## pagos_sistema

Pagos del taller al sistema, confirmados por el SuperAdmin. Separados de los cobros a clientes.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| periodo_id | int unsigned | no |  | índice, FK → periodos_pago_sistema.id |  |
| importe_total | decimal(12,2) | no |  |  |  |
| metodo | enum('efectivo','transferencia','combinado') | no |  |  |  |
| estado | enum('informado','confirmado','rechazado') | no | `informado` | índice |  |
| registrado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| confirmado_por | int unsigned | sí |  | índice, FK → superadmins.id |  |
| fecha_registro | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| fecha_confirmacion | datetime | sí |  |  |  |
| motivo_rechazo | varchar(250) | sí |  |  |  |
| observaciones | varchar(250) | sí |  |  |  |

**Restricciones CHECK:**

- `ck_pagos_sistema_importe`: `(`importe_total` > 0)`

## periodos_pago_sistema

Períodos de la suscripción del taller al sistema (plan mensual o anual, 3 días de tolerancia).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| taller_id | tinyint unsigned | no | `1` | índice, FK → taller.id |  |
| numero | int unsigned | no |  |  |  |
| modalidad | enum('mensual','anual') | no |  |  |  |
| fecha_inicio | date | no |  |  |  |
| fecha_vencimiento | date | no |  | índice |  |
| importe | decimal(12,2) | no |  |  |  |
| dias_tolerancia | tinyint unsigned | no | `3` |  |  |
| fecha_fin_tolerancia | date | no |  |  |  |
| estado | enum('vigente','por_vencer','en_tolerancia','en_mora','pagado') | no | `vigente` | índice |  |
| fecha_pago_confirmado | datetime | sí |  |  |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

**Restricciones CHECK:**

- `ck_periodo_fechas`: `((`fecha_vencimiento` > `fecha_inicio`) and (`fecha_fin_tolerancia` >= `fecha_vencimiento`))`
- `ck_periodo_tolerancia`: `(`dias_tolerancia` = 3)`
- `ck_periodo_importe`: `(`importe` > 0)`

**Restricciones UNIQUE:**

- `uq_periodo_numero` (taller_id, numero)

## presupuestos

Presupuesto único por consulta, con precio final y comisión.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| consulta_id | int unsigned | no |  | UNIQUE, FK → consultas.id |  |
| numero | varchar(20) | no |  | UNIQUE |  |
| total_calculado | decimal(12,2) | no | `0.00` |  |  |
| precio_final | decimal(12,2) | no | `0.00` |  |  |
| comision_pct | decimal(5,2) | no | `0.00` |  |  |
| estado | enum('borrador','enviado','aceptado','rechazado') | no | `borrador` |  |  |
| valido_hasta | date | sí |  |  |  |
| fecha_envio | datetime | sí |  |  |  |
| fecha_respuesta | datetime | sí |  |  |  |
| creado_por | int unsigned | no |  | índice, FK → usuarios.id |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

**Restricciones CHECK:**

- `ck_presup_pct`: `((`comision_pct` >= 0) and (`comision_pct` <= 100))`
- `ck_presup_importes`: `((`total_calculado` >= 0) and (`precio_final` >= 0))`

**Restricciones UNIQUE:**

- `uq_presupuestos_consulta` (consulta_id)
- `uq_presupuestos_numero` (numero)

## propuestas_ia

Propuestas de redacción asistida (reglas locales; solo texto).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| usuario_id | int unsigned | no |  | índice, FK → usuarios.id |  |
| contexto | enum('problema_consulta','inspeccion','observacion_mecanico') | no |  |  |  |
| consulta_id | int unsigned | sí |  | índice, FK → consultas.id |  |
| orden_id | int unsigned | sí |  | índice, FK → ordenes_trabajo.id |  |
| texto_original | text | no |  |  |  |
| texto_propuesto | text | no |  |  |  |
| texto_final | text | sí |  |  |  |
| estado | enum('generada','aceptada','editada','descartada') | no | `generada` |  |  |
| proveedor | varchar(30) | no |  |  |  |
| modelo | varchar(60) | sí |  |  |  |
| creada_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| resuelta_en | datetime | sí |  |  |  |

## roles

Roles operativos del taller (Administrador, Mecánico). El SuperAdmin no es un rol.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | tinyint unsigned | no |  | PK | auto_increment |
| nombre | varchar(40) | no |  | UNIQUE |  |
| descripcion | varchar(200) | sí |  |  |  |

**Restricciones UNIQUE:**

- `uq_roles_nombre` (nombre)

## superadmins

Datos propios del SuperAdmin (cuenta oculta de la plataforma).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| usuario_id | int unsigned | no |  | UNIQUE, FK → usuarios.id |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| observaciones | varchar(250) | sí |  |  |  |

**Restricciones UNIQUE:**

- `uq_superadmins_usuario` (usuario_id)

## taller

El único taller que administra el sistema, con su estado de acceso.

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | tinyint unsigned | no | `1` | PK |  |
| nombre | varchar(120) | no |  |  |  |
| razon_social | varchar(150) | sí |  |  |  |
| cuit | varchar(20) | sí |  |  |  |
| telefono | varchar(30) | sí |  |  |  |
| email | varchar(120) | sí |  |  |  |
| direccion | varchar(180) | sí |  |  |  |
| admin_usuario_id | int unsigned | no |  | UNIQUE, FK → usuarios.id |  |
| estado_acceso | enum('activo','bloqueado') | no | `activo` |  |  |
| bloqueado_en | datetime | sí |  |  |  |
| motivo_bloqueo | varchar(200) | sí |  |  |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |
| actualizado_en | datetime | no | `CURRENT_TIMESTAMP` |  | on update CURRENT_TIMESTAMP |

**Restricciones CHECK:**

- `ck_taller_unico`: `(`id` = 1)`

**Restricciones UNIQUE:**

- `uq_taller_admin` (admin_usuario_id)

## usuarios

Cuentas de acceso: administrador, mecánicos y SuperAdmin (tipo_cuenta).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| tipo_cuenta | enum('taller','superadmin') | no | `taller` |  |  |
| rol_id | tinyint unsigned | sí |  | índice, FK → roles.id |  |
| nombre | varchar(100) | no |  |  |  |
| usuario | varchar(40) | no |  | UNIQUE |  |
| password_hash | varchar(255) | no |  |  |  |
| email | varchar(120) | sí |  |  |  |
| telefono | varchar(30) | sí |  |  |  |
| especialidad | varchar(80) | sí |  |  |  |
| disponible | tinyint(1) | no | `1` |  |  |
| estado | enum('activo','pausado','suspendido') | no | `activo` |  |  |
| debe_cambiar_password | tinyint(1) | no | `0` |  |  |
| intentos_fallidos | tinyint unsigned | no | `0` |  |  |
| bloqueado_hasta | datetime | sí |  |  |  |
| ultimo_ingreso | datetime | sí |  |  |  |
| creado_en | datetime | no | `CURRENT_TIMESTAMP` |  |  |

**Restricciones CHECK:**

- `ck_usuarios_tipo_rol`: `(((`tipo_cuenta` = _utf8mb4\'taller\') and (`rol_id` is not null)) or ((`tipo_cuenta` = _utf8mb4\'superadmin\') and (`rol_id` is null)))`

**Restricciones UNIQUE:**

- `uq_usuarios_usuario` (usuario)

## vehiculos

Vehículos; el propietario actual es clientes (cliente_id).

| Columna | Tipo | Nulo | Defecto | Clave | Observación |
|---|---|---|---|---|---|
| id | int unsigned | no |  | PK | auto_increment |
| cliente_id | int unsigned | no |  | índice, FK → clientes.id |  |
| patente | varchar(10) | sí |  | UNIQUE |  |
| marca | varchar(40) | no |  |  |  |
| modelo | varchar(40) | sí |  |  |  |
| anio | smallint unsigned | sí |  |  |  |
| color | varchar(30) | sí |  |  |  |
| kilometraje | int unsigned | sí |  |  |  |
| observaciones | varchar(250) | sí |  |  |  |

**Restricciones UNIQUE:**

- `uq_vehiculos_patente` (patente)
