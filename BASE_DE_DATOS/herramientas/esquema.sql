-- ============================================================================
-- SECCIÓN 1. ESTRUCTURA (30 tablas, en orden de dependencia)
-- ============================================================================
-- Las tablas marcadas con [MOD] respecto del SQL original fueron modificadas y
-- las marcadas con [NUEVA] fueron agregadas; el motivo de cada cambio está en
-- DOCUMENTACION/registro_cambios.md. [ELIMINADA]: archivos_trabajos (fotografías).
-- ============================================================================

-- 01. roles -----------------------------------------------------------------
-- Roles OPERATIVOS del taller. El SuperAdmin no es un rol: se identifica con
-- usuarios.tipo_cuenta = 'superadmin' (y rol_id NULL).
CREATE TABLE roles (
  id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(40) NOT NULL,
  descripcion VARCHAR(200) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_nombre (nombre)
) ENGINE=InnoDB;

-- 02. usuarios [MOD: + email, telefono, especialidad, disponible] ------------
CREATE TABLE usuarios (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_cuenta ENUM('taller','superadmin') NOT NULL DEFAULT 'taller',
  rol_id TINYINT UNSIGNED NULL,
  nombre VARCHAR(100) NOT NULL,
  usuario VARCHAR(40) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email VARCHAR(120) NULL,
  telefono VARCHAR(30) NULL,
  especialidad VARCHAR(80) NULL,
  disponible TINYINT(1) NOT NULL DEFAULT 1,
  estado ENUM('activo','pausado','suspendido') NOT NULL DEFAULT 'activo',
  debe_cambiar_password TINYINT(1) NOT NULL DEFAULT 0,
  intentos_fallidos TINYINT UNSIGNED NOT NULL DEFAULT 0,
  bloqueado_hasta DATETIME NULL,
  ultimo_ingreso DATETIME NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_usuario (usuario),
  KEY ix_usuarios_rol (rol_id),
  CONSTRAINT fk_usuarios_rol FOREIGN KEY (rol_id) REFERENCES roles(id),
  CONSTRAINT ck_usuarios_tipo_rol CHECK (
    (tipo_cuenta = 'taller' AND rol_id IS NOT NULL) OR
    (tipo_cuenta = 'superadmin' AND rol_id IS NULL)
  )
) ENGINE=InnoDB;

-- 03. superadmins -----------------------------------------------------------
CREATE TABLE superadmins (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_superadmins_usuario (usuario_id),
  CONSTRAINT fk_superadmins_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 04. taller (único: id = 1) ------------------------------------------------
CREATE TABLE taller (
  id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  nombre VARCHAR(120) NOT NULL,
  razon_social VARCHAR(150) NULL,
  cuit VARCHAR(20) NULL,
  telefono VARCHAR(30) NULL,
  email VARCHAR(120) NULL,
  direccion VARCHAR(180) NULL,
  admin_usuario_id INT UNSIGNED NOT NULL,
  estado_acceso ENUM('activo','bloqueado') NOT NULL DEFAULT 'activo',
  bloqueado_en DATETIME NULL,
  motivo_bloqueo VARCHAR(200) NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_taller_admin (admin_usuario_id),
  CONSTRAINT ck_taller_unico CHECK (id = 1),
  CONSTRAINT fk_taller_admin FOREIGN KEY (admin_usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 05. clientes --------------------------------------------------------------
CREATE TABLE clientes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  dni VARCHAR(15) NULL,
  telefono VARCHAR(30) NULL,
  email VARCHAR(120) NULL,
  direccion VARCHAR(150) NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_clientes_dni (dni),
  KEY ix_clientes_nombre (nombre)
) ENGINE=InnoDB;

-- 06. vehiculos [MOD: patente y kilometraje admiten NULL] --------------------
-- En el MVP la patente y el kilometraje son opcionales al cargar una consulta.
-- UNIQUE permite varios NULL, por lo que la unicidad se conserva para patentes cargadas.
CREATE TABLE vehiculos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cliente_id INT UNSIGNED NOT NULL,
  patente VARCHAR(10) NULL,
  marca VARCHAR(40) NOT NULL,
  modelo VARCHAR(40) NULL,
  anio SMALLINT UNSIGNED NULL,
  color VARCHAR(30) NULL,
  kilometraje INT UNSIGNED NULL,
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vehiculos_patente (patente),
  KEY ix_vehiculos_cliente (cliente_id),
  CONSTRAINT fk_vehiculos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) ENGINE=InnoDB;

-- 07. consultas [MOD: + observaciones, importe_estimado, cobro_*, motivo_cierre] -
CREATE TABLE consultas (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cliente_id INT UNSIGNED NULL,
  vehiculo_id INT UNSIGNED NULL,
  contacto_nombre VARCHAR(100) NOT NULL,
  contacto_dni VARCHAR(15) NULL,
  contacto_telefono VARCHAR(30) NULL,
  veh_patente VARCHAR(10) NULL,
  veh_marca VARCHAR(40) NULL,
  veh_modelo VARCHAR(40) NULL,
  veh_anio SMALLINT UNSIGNED NULL,
  veh_kilometraje INT UNSIGNED NULL,
  motivo VARCHAR(200) NOT NULL,
  descripcion_problema TEXT NULL,
  observaciones TEXT NULL,
  observaciones_inspeccion TEXT NULL,
  importe_estimado DECIMAL(12,2) NULL,
  estado ENUM('abierta','esperando_respuesta','aprobada','rechazada','cerrada') NOT NULL DEFAULT 'abierta',
  es_gratuita TINYINT(1) NOT NULL DEFAULT 0,
  cobro_decision ENUM('cobrar','gratis') NULL,
  cobro_importe DECIMAL(12,2) NULL,
  cobro_por INT UNSIGNED NULL,
  cobro_fecha DATE NULL,
  motivo_cierre VARCHAR(200) NULL,
  creado_por INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_consultas_cliente (cliente_id),
  KEY ix_consultas_vehiculo (vehiculo_id),
  KEY ix_consultas_estado (estado),
  KEY ix_consultas_fecha (creado_en),
  CONSTRAINT ck_consultas_cobro CHECK (
    (cobro_decision IS NULL AND cobro_importe IS NULL) OR
    (cobro_decision = 'gratis' AND COALESCE(cobro_importe, 0) = 0) OR
    (cobro_decision = 'cobrar' AND cobro_importe IS NOT NULL AND cobro_importe > 0)
  ),
  CONSTRAINT fk_consultas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  CONSTRAINT fk_consultas_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id),
  CONSTRAINT fk_consultas_creador FOREIGN KEY (creado_por) REFERENCES usuarios(id),
  CONSTRAINT fk_consultas_cobro_por FOREIGN KEY (cobro_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 08. detalles_consultas [MOD: tipo ampliado, descripcion TEXT] ----------------
-- Distribuye la "revisión técnica" del MVP (colección consulta_revisiones):
--   problemas encontrados -> 'verificado' | repuestos necesarios -> 'repuestos_necesarios'
--   trabajo recomendado   -> 'trabajo_recomendado'
-- (las observaciones técnicas van a consultas.observaciones_inspeccion y el importe a consultas.importe_estimado)
CREATE TABLE detalles_consultas (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  consulta_id INT UNSIGNED NOT NULL,
  descripcion TEXT NOT NULL,
  tipo ENUM('sintoma_informado','verificado','repuestos_necesarios','trabajo_recomendado') NOT NULL DEFAULT 'verificado',
  registrado_por INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_detcons_consulta (consulta_id),
  CONSTRAINT fk_detcons_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id) ON DELETE CASCADE,
  CONSTRAINT fk_detcons_usuario FOREIGN KEY (registrado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 09. presupuestos [MOD: + numero, valido_hasta] -----------------------------
CREATE TABLE presupuestos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  consulta_id INT UNSIGNED NOT NULL,
  numero VARCHAR(20) NOT NULL,
  total_calculado DECIMAL(12,2) NOT NULL DEFAULT 0,
  precio_final DECIMAL(12,2) NOT NULL DEFAULT 0,
  comision_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
  estado ENUM('borrador','enviado','aceptado','rechazado') NOT NULL DEFAULT 'borrador',
  valido_hasta DATE NULL,
  fecha_envio DATETIME NULL,
  fecha_respuesta DATETIME NULL,
  creado_por INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_presupuestos_consulta (consulta_id),
  UNIQUE KEY uq_presupuestos_numero (numero),
  CONSTRAINT ck_presup_pct CHECK (comision_pct >= 0 AND comision_pct <= 100),
  CONSTRAINT ck_presup_importes CHECK (total_calculado >= 0 AND precio_final >= 0),
  CONSTRAINT fk_presup_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id),
  CONSTRAINT fk_presup_creador FOREIGN KEY (creado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 10. categorias_catalogo ---------------------------------------------------
CREATE TABLE categorias_catalogo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL,
  descripcion VARCHAR(200) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categorias_nombre (nombre)
) ENGINE=InnoDB;

-- 11. catalogo_items [MOD: + marca, ubicacion] --------------------------------
CREATE TABLE catalogo_items (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id INT UNSIGNED NULL,
  tipo ENUM('servicio','repuesto') NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  codigo VARCHAR(40) NULL,
  marca VARCHAR(60) NULL,
  ubicacion VARCHAR(60) NULL,
  precio_compra DECIMAL(12,2) NOT NULL DEFAULT 0,
  precio_venta DECIMAL(12,2) NOT NULL DEFAULT 0,
  cantidad INT NOT NULL DEFAULT 0,
  stock_minimo INT NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_catalogo_codigo (codigo),
  KEY ix_catalogo_tipo (tipo),
  KEY ix_catalogo_categoria (categoria_id),
  CONSTRAINT ck_catalogo_importes CHECK (precio_compra >= 0 AND precio_venta >= 0),
  CONSTRAINT ck_catalogo_stock CHECK (cantidad >= 0 AND stock_minimo >= 0),
  CONSTRAINT fk_catalogo_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_catalogo(id)
) ENGINE=InnoDB;

-- 12. historial_precios_catalogo ---------------------------------------------
CREATE TABLE historial_precios_catalogo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  catalogo_item_id INT UNSIGNED NOT NULL,
  precio_compra_anterior DECIMAL(12,2) NOT NULL,
  precio_compra_nuevo DECIMAL(12,2) NOT NULL,
  precio_venta_anterior DECIMAL(12,2) NOT NULL,
  precio_venta_nuevo DECIMAL(12,2) NOT NULL,
  cambiado_por INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_histprecio_item (catalogo_item_id),
  CONSTRAINT fk_histprecio_item FOREIGN KEY (catalogo_item_id) REFERENCES catalogo_items(id),
  CONSTRAINT fk_histprecio_usuario FOREIGN KEY (cambiado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 13. detalles_presupuestos [MOD: + precio_unitario; monto pasa a columna calculada] -
-- El MVP guarda precio_unitario y calcula cantidad x precio. "monto" (importe de la línea) es ahora
-- una columna GENERADA (cantidad * precio_unitario): elimina la ambigüedad del original y evita inconsistencias.
CREATE TABLE detalles_presupuestos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  presupuesto_id INT UNSIGNED NOT NULL,
  concepto VARCHAR(200) NOT NULL,
  tipo ENUM('mano_obra','repuesto','servicio','otro') NOT NULL DEFAULT 'mano_obra',
  cantidad DECIMAL(8,2) NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(12,2) NOT NULL,
  monto DECIMAL(12,2) GENERATED ALWAYS AS (ROUND(cantidad * precio_unitario, 2)) STORED,
  catalogo_item_id INT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY ix_detpres_presupuesto (presupuesto_id),
  KEY ix_detpres_item (catalogo_item_id),
  CONSTRAINT ck_detpres_valores CHECK (cantidad > 0 AND precio_unitario >= 0),
  CONSTRAINT fk_detpres_presupuesto FOREIGN KEY (presupuesto_id) REFERENCES presupuestos(id) ON DELETE CASCADE,
  CONSTRAINT fk_detpres_item FOREIGN KEY (catalogo_item_id) REFERENCES catalogo_items(id)
) ENGINE=InnoDB;

-- 14. ordenes_trabajo [MOD: + numero, repuestos_previstos, inicio_previsto, entrega_prevista, observaciones] -
CREATE TABLE ordenes_trabajo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero VARCHAR(20) NOT NULL,
  presupuesto_id INT UNSIGNED NOT NULL,
  cliente_id INT UNSIGNED NOT NULL,
  vehiculo_id INT UNSIGNED NOT NULL,
  mecanico_id INT UNSIGNED NULL,
  descripcion VARCHAR(200) NOT NULL,
  repuestos_previstos VARCHAR(250) NULL,
  observaciones VARCHAR(250) NULL,
  estado ENUM('sin_asignar','ofrecido','aceptado','en_proceso','finalizado','cancelado') NOT NULL DEFAULT 'sin_asignar',
  precio_final DECIMAL(12,2) NOT NULL,
  comision_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
  observaciones_mecanico TEXT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  inicio_previsto DATE NULL,
  entrega_prevista DATE NULL,
  fecha_inicio DATETIME NULL,
  fecha_fin DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ordenes_presupuesto (presupuesto_id),
  UNIQUE KEY uq_ordenes_numero (numero),
  KEY ix_ordenes_estado (estado),
  KEY ix_ordenes_mecanico (mecanico_id),
  KEY ix_ordenes_cliente (cliente_id),
  KEY ix_ordenes_vehiculo (vehiculo_id),
  CONSTRAINT ck_ordenes_importes CHECK (precio_final >= 0 AND comision_pct >= 0 AND comision_pct <= 100),
  CONSTRAINT ck_ordenes_fechas_previstas CHECK (inicio_previsto IS NULL OR entrega_prevista IS NULL OR entrega_prevista >= inicio_previsto),
  CONSTRAINT fk_ordenes_presupuesto FOREIGN KEY (presupuesto_id) REFERENCES presupuestos(id),
  CONSTRAINT fk_ordenes_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  CONSTRAINT fk_ordenes_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id),
  CONSTRAINT fk_ordenes_mecanico FOREIGN KEY (mecanico_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 15. historial_estados_ordenes ----------------------------------------------
CREATE TABLE historial_estados_ordenes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id INT UNSIGNED NOT NULL,
  estado_anterior VARCHAR(30) NULL,
  estado_nuevo VARCHAR(30) NOT NULL,
  cambiado_por INT UNSIGNED NOT NULL,
  observacion VARCHAR(250) NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_histestado_orden (orden_id),
  CONSTRAINT fk_histestado_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
  CONSTRAINT fk_histestado_usuario FOREIGN KEY (cambiado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 16. asignaciones_trabajo [MOD: + motivo_rechazo] ----------------------------
CREATE TABLE asignaciones_trabajo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id INT UNSIGNED NOT NULL,
  mecanico_id INT UNSIGNED NOT NULL,
  asignado_por INT UNSIGNED NOT NULL,
  resultado ENUM('ofrecida','aceptada','rechazada','reasignada','completada') NOT NULL DEFAULT 'ofrecida',
  motivo_rechazo VARCHAR(250) NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resuelto_en DATETIME NULL,
  PRIMARY KEY (id),
  KEY ix_asig_orden (orden_id),
  KEY ix_asig_mecanico (mecanico_id),
  CONSTRAINT fk_asig_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id),
  CONSTRAINT fk_asig_mecanico FOREIGN KEY (mecanico_id) REFERENCES usuarios(id),
  CONSTRAINT fk_asig_por FOREIGN KEY (asignado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 17. pagos_clientes (pagos que los CLIENTES hacen al TALLER) ------------------
CREATE TABLE pagos_clientes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo ENUM('trabajo','venta_mostrador') NOT NULL DEFAULT 'trabajo',
  orden_id INT UNSIGNED NULL,
  cliente_id INT UNSIGNED NULL,
  monto DECIMAL(12,2) NOT NULL,
  metodo ENUM('efectivo','transferencia','mercadopago','tarjeta','combinado') NOT NULL DEFAULT 'efectivo',
  registrado_por INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  KEY ix_pagcli_orden (orden_id),
  KEY ix_pagcli_cliente (cliente_id),
  CONSTRAINT ck_pagcli_monto CHECK (monto > 0),
  CONSTRAINT fk_pagcli_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id),
  CONSTRAINT fk_pagcli_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  CONSTRAINT fk_pagcli_usuario FOREIGN KEY (registrado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 18. detalles_pagos_clientes ------------------------------------------------
CREATE TABLE detalles_pagos_clientes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pago_cliente_id INT UNSIGNED NOT NULL,
  medio ENUM('efectivo','transferencia','mercadopago','tarjeta') NOT NULL,
  importe DECIMAL(12,2) NOT NULL,
  referencia VARCHAR(120) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_detpagcli_medio (pago_cliente_id, medio),
  CONSTRAINT ck_detpagcli_importe CHECK (importe > 0),
  CONSTRAINT fk_detpagcli_pago FOREIGN KEY (pago_cliente_id) REFERENCES pagos_clientes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 19. movimientos_stock ------------------------------------------------------
CREATE TABLE movimientos_stock (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  catalogo_item_id INT UNSIGNED NULL,
  descripcion_libre VARCHAR(150) NULL,
  tipo ENUM('entrada','salida') NOT NULL,
  cantidad INT UNSIGNED NOT NULL,
  estado ENUM('pendiente','confirmado','rechazado') NOT NULL DEFAULT 'confirmado',
  aportado_cliente TINYINT(1) NOT NULL DEFAULT 0,
  motivo VARCHAR(150) NOT NULL,
  orden_id INT UNSIGNED NULL,
  pago_cliente_id INT UNSIGNED NULL,
  solicitado_por INT UNSIGNED NOT NULL,
  resuelto_por INT UNSIGNED NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_movstock_item (catalogo_item_id),
  KEY ix_movstock_orden (orden_id),
  KEY ix_movstock_estado (estado),
  KEY ix_movstock_pago (pago_cliente_id),
  CONSTRAINT ck_movstock_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_movstock_descripcion CHECK (catalogo_item_id IS NOT NULL OR descripcion_libre IS NOT NULL),
  CONSTRAINT fk_movstock_item FOREIGN KEY (catalogo_item_id) REFERENCES catalogo_items(id),
  CONSTRAINT fk_movstock_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id),
  CONSTRAINT fk_movstock_pago FOREIGN KEY (pago_cliente_id) REFERENCES pagos_clientes(id),
  CONSTRAINT fk_movstock_solicitante FOREIGN KEY (solicitado_por) REFERENCES usuarios(id),
  CONSTRAINT fk_movstock_resolutor FOREIGN KEY (resuelto_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 20. movimientos_mecanicos --------------------------------------------------
CREATE TABLE movimientos_mecanicos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  mecanico_id INT UNSIGNED NOT NULL,
  tipo ENUM('comision','adelanto') NOT NULL,
  monto DECIMAL(12,2) NOT NULL,
  orden_id INT UNSIGNED NULL,
  registrado_por INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  descripcion VARCHAR(200) NULL,
  PRIMARY KEY (id),
  KEY ix_movmec_mecanico (mecanico_id),
  KEY ix_movmec_orden (orden_id),
  UNIQUE KEY uq_movmec_orden_tipo (orden_id, tipo),   -- [MOD] una sola comisión por orden (NULL en adelantos no choca)
  CONSTRAINT ck_movmec_monto CHECK (monto > 0),
  CONSTRAINT ck_movmec_tipo_orden CHECK ((tipo = 'comision' AND orden_id IS NOT NULL) OR (tipo = 'adelanto' AND orden_id IS NULL)),  -- [MOD]
  CONSTRAINT fk_movmec_mecanico FOREIGN KEY (mecanico_id) REFERENCES usuarios(id),
  CONSTRAINT fk_movmec_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id),
  CONSTRAINT fk_movmec_usuario FOREIGN KEY (registrado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 21. liquidaciones_mecanicos ------------------------------------------------
CREATE TABLE liquidaciones_mecanicos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  mecanico_id INT UNSIGNED NOT NULL,
  periodo_desde DATE NOT NULL,
  periodo_hasta DATE NOT NULL,
  total_comisiones DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_adelantos DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_a_pagar DECIMAL(12,2) NOT NULL DEFAULT 0,
  estado ENUM('pendiente','pagada','anulada') NOT NULL DEFAULT 'pendiente',
  creado_por INT UNSIGNED NOT NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_pago DATETIME NULL,
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  KEY ix_liq_mecanico (mecanico_id),
  CONSTRAINT ck_liq_fechas CHECK (periodo_hasta >= periodo_desde),
  CONSTRAINT ck_liq_importes CHECK (total_comisiones >= 0 AND total_adelantos >= 0 AND total_a_pagar >= 0),
  CONSTRAINT fk_liq_mecanico FOREIGN KEY (mecanico_id) REFERENCES usuarios(id),
  CONSTRAINT fk_liq_creador FOREIGN KEY (creado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- 22. detalles_liquidaciones_mecanicos ---------------------------------------
CREATE TABLE detalles_liquidaciones_mecanicos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  liquidacion_id INT UNSIGNED NOT NULL,
  movimiento_mecanico_id INT UNSIGNED NOT NULL,
  importe_incluido DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_detliq_movimiento (movimiento_mecanico_id),
  KEY ix_detliq_liquidacion (liquidacion_id),
  CONSTRAINT ck_detliq_importe CHECK (importe_incluido > 0),
  CONSTRAINT fk_detliq_liquidacion FOREIGN KEY (liquidacion_id) REFERENCES liquidaciones_mecanicos(id) ON DELETE CASCADE,
  CONSTRAINT fk_detliq_movimiento FOREIGN KEY (movimiento_mecanico_id) REFERENCES movimientos_mecanicos(id)
) ENGINE=InnoDB;

-- 23. periodos_pago_sistema (suscripción del taller al sistema) ----------------
-- Cada fila es un ciclo del plan (inicio -> vencimiento). El pago de renovación se informa/confirma contra
-- el período cuyo vencimiento se está renovando; al confirmarlo se crea el ciclo siguiente.
CREATE TABLE periodos_pago_sistema (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  taller_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  numero INT UNSIGNED NOT NULL,
  modalidad ENUM('mensual','anual') NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  importe DECIMAL(12,2) NOT NULL,
  dias_tolerancia TINYINT UNSIGNED NOT NULL DEFAULT 3,
  fecha_fin_tolerancia DATE NOT NULL,
  estado ENUM('vigente','por_vencer','en_tolerancia','en_mora','pagado') NOT NULL DEFAULT 'vigente',
  fecha_pago_confirmado DATETIME NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_periodo_numero (taller_id, numero),
  KEY ix_periodo_vencimiento (fecha_vencimiento),
  KEY ix_periodo_estado (estado),
  CONSTRAINT ck_periodo_fechas CHECK (fecha_vencimiento > fecha_inicio AND fecha_fin_tolerancia >= fecha_vencimiento),
  CONSTRAINT ck_periodo_tolerancia CHECK (dias_tolerancia = 3),
  CONSTRAINT ck_periodo_importe CHECK (importe > 0),
  CONSTRAINT fk_periodo_taller FOREIGN KEY (taller_id) REFERENCES taller(id)
) ENGINE=InnoDB;

-- 24. pagos_sistema (pagos que el DUEÑO hace al SUPERADMIN) [MOD: + motivo_rechazo] -
CREATE TABLE pagos_sistema (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  periodo_id INT UNSIGNED NOT NULL,
  importe_total DECIMAL(12,2) NOT NULL,
  metodo ENUM('efectivo','transferencia','combinado') NOT NULL,
  estado ENUM('informado','confirmado','rechazado') NOT NULL DEFAULT 'informado',
  registrado_por INT UNSIGNED NOT NULL,
  confirmado_por INT UNSIGNED NULL,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_confirmacion DATETIME NULL,
  motivo_rechazo VARCHAR(250) NULL,
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  KEY ix_pagos_sistema_periodo (periodo_id),
  KEY ix_pagos_sistema_estado (estado),
  KEY ix_pagos_sistema_confirmador (confirmado_por),
  CONSTRAINT ck_pagos_sistema_importe CHECK (importe_total > 0),
  CONSTRAINT fk_pagos_sistema_periodo FOREIGN KEY (periodo_id) REFERENCES periodos_pago_sistema(id),
  CONSTRAINT fk_pagos_sistema_registrador FOREIGN KEY (registrado_por) REFERENCES usuarios(id),
  CONSTRAINT fk_pagos_sistema_confirmador FOREIGN KEY (confirmado_por) REFERENCES superadmins(id)
) ENGINE=InnoDB;

-- 25. detalles_pagos_sistema -------------------------------------------------
CREATE TABLE detalles_pagos_sistema (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pago_id INT UNSIGNED NOT NULL,
  medio ENUM('efectivo','transferencia') NOT NULL,
  importe DECIMAL(12,2) NOT NULL,
  referencia VARCHAR(120) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_detpagsis_medio (pago_id, medio),
  CONSTRAINT ck_detpagsis_importe CHECK (importe > 0),
  CONSTRAINT fk_detpagsis_pago FOREIGN KEY (pago_id) REFERENCES pagos_sistema(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 26. comprobantes_pagos_sistema ---------------------------------------------
-- Tabla original conservada SIN USO en el MVP (que solo registra la referencia de la transferencia).
-- Queda vacía: no se carga ningún archivo de demostración. Ver "decisiones pendientes" en el informe final.
CREATE TABLE comprobantes_pagos_sistema (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pago_sistema_id INT UNSIGNED NOT NULL,
  nombre_archivo VARCHAR(180) NOT NULL,
  ruta_archivo VARCHAR(255) NOT NULL,
  tipo_archivo VARCHAR(80) NULL,
  subido_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_comprobante_pago (pago_sistema_id),
  CONSTRAINT fk_comprobante_pago FOREIGN KEY (pago_sistema_id) REFERENCES pagos_sistema(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 27. notificaciones ---------------------------------------------------------
CREATE TABLE notificaciones (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id INT UNSIGNED NULL,
  superadmin_id INT UNSIGNED NULL,
  texto VARCHAR(300) NOT NULL,
  enlace VARCHAR(120) NULL,
  tipo VARCHAR(30) NOT NULL DEFAULT 'general',
  clave_unica VARCHAR(100) NULL,
  leida TINYINT(1) NOT NULL DEFAULT 0,
  creada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_notif_clave (clave_unica),
  KEY ix_notif_usuario (usuario_id, leida),
  KEY ix_notif_superadmin (superadmin_id, leida),
  CONSTRAINT ck_notif_destino CHECK (
    (usuario_id IS NOT NULL AND superadmin_id IS NULL) OR
    (usuario_id IS NULL AND superadmin_id IS NOT NULL)
  ),
  CONSTRAINT fk_notif_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_superadmin FOREIGN KEY (superadmin_id) REFERENCES superadmins(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 28. auditoria --------------------------------------------------------------
CREATE TABLE auditoria (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id INT UNSIGNED NULL,
  superadmin_id INT UNSIGNED NULL,
  actor_login VARCHAR(40) NOT NULL,
  ambito ENUM('taller','sistema') NOT NULL DEFAULT 'taller',
  accion VARCHAR(120) NOT NULL,
  entidad VARCHAR(40) NULL,
  entidad_id INT UNSIGNED NULL,
  detalle JSON NULL,
  ip VARCHAR(45) NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_auditoria_fecha (fecha),
  KEY ix_auditoria_ambito (ambito),
  KEY ix_auditoria_usuario (usuario_id),
  KEY ix_auditoria_superadmin (superadmin_id),
  CONSTRAINT ck_auditoria_actor CHECK (
    (ambito = 'taller' AND usuario_id IS NOT NULL AND superadmin_id IS NULL) OR
    (ambito = 'sistema' AND usuario_id IS NULL AND superadmin_id IS NOT NULL)
  ),
  CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  CONSTRAINT fk_auditoria_superadmin FOREIGN KEY (superadmin_id) REFERENCES superadmins(id)
) ENGINE=InnoDB;

-- 29. propuestas_ia (mejora de redacción; el MVP usa reglas locales, sin IA externa) -
-- contexto: problema_consulta -> consulta_id | inspeccion -> consulta_id | observacion_mecanico -> orden_id
CREATE TABLE propuestas_ia (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id INT UNSIGNED NOT NULL,
  contexto ENUM('problema_consulta','inspeccion','observacion_mecanico') NOT NULL,
  consulta_id INT UNSIGNED NULL,
  orden_id INT UNSIGNED NULL,
  texto_original TEXT NOT NULL,
  texto_propuesto TEXT NOT NULL,
  texto_final TEXT NULL,
  estado ENUM('generada','aceptada','editada','descartada') NOT NULL DEFAULT 'generada',
  proveedor VARCHAR(30) NOT NULL,
  modelo VARCHAR(60) NULL,
  creada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resuelta_en DATETIME NULL,
  PRIMARY KEY (id),
  KEY ix_ia_usuario (usuario_id),
  KEY ix_ia_consulta (consulta_id),
  KEY ix_ia_orden (orden_id),
  CONSTRAINT fk_ia_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  CONSTRAINT fk_ia_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id) ON DELETE SET NULL,
  CONSTRAINT fk_ia_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 30. avances_ordenes [NUEVA] -------------------------------------------------
-- Reemplaza a archivos_trabajos en la numeración (30 tablas). Guarda los avances/observaciones que el
-- mecánico o el dueño registran durante el trabajo (colección orden_avances del MVP), que antes no tenían tabla.
CREATE TABLE avances_ordenes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id INT UNSIGNED NOT NULL,
  usuario_id INT UNSIGNED NOT NULL,
  texto TEXT NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_avances_orden (orden_id),
  KEY ix_avances_usuario (usuario_id),
  CONSTRAINT fk_avances_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
  CONSTRAINT fk_avances_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;
