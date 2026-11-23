-- ============================================================================
-- TALLER MATIENZO — BASE DE DATOS MySQL 8 (VERSIÓN FINAL, ARCHIVO ÚNICO)
-- ============================================================================
-- Contenido: 1) estructura de 30 tablas  2) datos de demostración coherentes
--            3) pruebas SQL (INSERT / SELECT / UPDATE / DELETE / INNER JOIN /
--               integridad / procesos), organizadas por módulo.
--
-- CÓMO IMPORTARLO
--   mysql -u root -p < taller_matienzo_final.sql
--   (o, en MySQL Workbench: File > Open SQL Script > ejecutar todo con el rayo).
--
-- ADVERTENCIAS
--   * Este script BORRA y vuelve a crear la base "taller_matienzo".
--   * Requiere MySQL 8.0.16 o superior (usa restricciones CHECK y columnas generadas).
--   * Las pruebas de la sección 3 que modifican datos están dentro de transacciones
--     que terminan en ROLLBACK: los datos de demostración quedan intactos.
--   * Las contraseñas de demostración están guardadas como hash bcrypt, nunca en
--     texto plano. Credenciales de DEMOSTRACIÓN: ver DOCUMENTACION/documentacion_general.md.
--   * Todos los datos son ficticios.
-- ============================================================================

DROP DATABASE IF EXISTS taller_matienzo;
CREATE DATABASE taller_matienzo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE taller_matienzo;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

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

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- SECCIÓN 2. DATOS DE DEMOSTRACIÓN (fecha de referencia 2026-11-20)
-- ============================================================================
SET FOREIGN_KEY_CHECKS = 0;
-- Roles operativos del taller (el SuperAdmin NO es un rol: usuarios.tipo_cuenta = superadmin)
INSERT INTO roles (id, nombre, descripcion) VALUES
  (1, 'Administrador', 'Administra el funcionamiento del taller'),
  (2, 'Mecanico', 'Realiza los trabajos y reparaciones de vehículos');

-- Usuarios (contraseñas de DEMOSTRACIÓN almacenadas como hash bcrypt; ver README de la base de datos)
INSERT INTO usuarios (id, tipo_cuenta, rol_id, nombre, usuario, password_hash, email, telefono, especialidad, disponible, estado, debe_cambiar_password, intentos_fallidos, bloqueado_hasta, ultimo_ingreso, creado_en) VALUES
  (1, 'superadmin', NULL, 'Administrador del sistema', 'superadmin', '$2b$10$OV.2Z1tH2FsLui4G3ni4y.wKKUDtrfr8t5FJtVrN5JH6etFzTJE12', 'admin@plataforma.example', NULL, NULL, 1, 'activo', 0, 0, NULL, NULL, '2026-10-11 09:00:00'),
  (2, 'taller', 1, 'Roberto Díaz', 'roberto', '$2b$10$NLgOp.AQJXHXAw8cxAeTde0ba04GVA6S20TLyVv7hwcXduDTulpUC', NULL, '381-4001122', NULL, 1, 'activo', 0, 0, NULL, NULL, '2026-10-11 09:00:00'),
  (3, 'taller', 2, 'Juan Pérez', 'juan', '$2b$10$Jf60Iq6TCrYDydQk7moTqOqgRdSSJSh8qLm2DPmeGI.ZOZgJZtwmK', NULL, '381-4112233', 'Frenos y suspensión', 1, 'activo', 0, 0, NULL, NULL, '2026-10-11 09:00:00'),
  (4, 'taller', 2, 'Pedro Gómez', 'pedro', '$2b$10$rlgO0W7uy5j0Xh8x/y3hje3h.tz6V59xYxWkVu2pZH4Pma81yQtNK', NULL, '381-4223344', 'Motor y service', 1, 'activo', 0, 0, NULL, NULL, '2026-10-11 09:00:00'),
  (5, 'taller', 2, 'Carlos López', 'carlos', '$2b$10$XJ4txz97A2HAN4gXF/kII.u09rxom3t6wIwK16jpYN8.sibf8PxeS', NULL, NULL, 'General', 0, 'pausado', 0, 0, NULL, NULL, '2026-10-11 09:00:00');

INSERT INTO superadmins (id, usuario_id, creado_en, observaciones) VALUES
  (1, 1, '2026-10-11 09:00:00', 'Administrador general');

INSERT INTO taller (id, nombre, telefono, direccion, admin_usuario_id, estado_acceso, creado_en) VALUES
  (1, 'Taller Matienzo', '381-4001122', 'Av. Matienzo 100', 2, 'activo', '2026-10-11 09:00:00');

-- Clientes
INSERT INTO clientes (id, nombre, dni, telefono, email, direccion, creado_en) VALUES
  (1, 'Carlos Gómez', NULL, '381-5123456', NULL, 'Av. Matienzo 452', '2026-10-21 09:00:00'),
  (2, 'María López', NULL, '381-5234567', NULL, NULL, '2026-10-21 09:00:00'),
  (3, 'Jorge Ramírez', NULL, '381-5345678', NULL, NULL, '2026-10-21 09:00:00'),
  (4, 'Laura Fernández', NULL, '381-5456789', NULL, NULL, '2026-11-14 09:00:00'),
  (5, 'Ana Torres', NULL, '381-610010', NULL, NULL, '2026-10-23 09:00:00'),
  (6, 'Luis Medina', NULL, '381-610711', NULL, NULL, '2026-10-24 09:00:00'),
  (7, 'Marta Ruiz', NULL, '381-611412', NULL, NULL, '2026-10-25 09:00:00'),
  (8, 'Diego Sosa', NULL, '381-612113', NULL, NULL, '2026-10-26 09:00:00'),
  (9, 'Paula Ríos', NULL, '381-612814', NULL, NULL, '2026-10-27 09:00:00'),
  (10, 'Hugo Acosta', NULL, '381-613515', NULL, NULL, '2026-10-28 09:00:00'),
  (11, 'Elena Vega', NULL, '381-614216', NULL, NULL, '2026-10-29 09:00:00'),
  (12, 'Raúl Herrera', NULL, '381-614917', NULL, NULL, '2026-10-30 09:00:00'),
  (13, 'Nadia Castro', NULL, '381-615618', NULL, NULL, '2026-10-31 09:00:00'),
  (14, 'Sergio Molina', NULL, '381-616319', NULL, NULL, '2026-11-01 09:00:00'),
  (15, 'Julia Ponce', NULL, '381-617020', NULL, NULL, '2026-11-02 09:00:00'),
  (16, 'Martín Aguirre', NULL, '381-617721', NULL, NULL, '2026-11-03 09:00:00');

-- Vehículos (cliente_id = propietario actual; ver vehiculo_propietarios en el mapeo)
INSERT INTO vehiculos (id, cliente_id, patente, marca, modelo, anio, color, kilometraje, observaciones) VALUES
  (1, 1, 'AB123CD', 'Fiat', 'Palio', 2014, NULL, 98000, NULL),
  (2, 1, 'AE456FG', 'Renault', 'Kangoo', 2018, NULL, 64000, NULL),
  (3, 2, 'AC789HI', 'Volkswagen', 'Gol', 2017, NULL, 61000, NULL),
  (4, 3, 'AA321JK', 'Ford', 'Fiesta', 2015, NULL, 88000, NULL),
  (5, 4, 'AD456EF', 'Renault', 'Clio', 2012, NULL, 120000, NULL),
  (6, 5, 'AA100FK', 'Peugeot', '208', 2019, NULL, 30000, NULL),
  (7, 6, 'AB111GL', 'Toyota', 'Etios', 2017, NULL, 39000, NULL),
  (8, 7, 'AC122HM', 'Chevrolet', 'Onix', 2020, NULL, 48000, NULL),
  (9, 8, 'AD133IN', 'Renault', 'Sandero', 2016, NULL, 57000, NULL),
  (10, 9, 'AE144JO', 'Ford', 'Focus', 2013, NULL, 66000, NULL),
  (11, 10, 'AF155KP', 'Volkswagen', 'Voyage', 2018, NULL, 75000, NULL),
  (12, 11, 'AG166LQ', 'Fiat', 'Uno', 2011, NULL, 84000, NULL),
  (13, 12, 'AH177MR', 'Nissan', 'March', 2015, NULL, 93000, NULL),
  (14, 13, 'AI188NS', 'Citroën', 'C3', 2014, NULL, 102000, NULL),
  (15, 14, 'AJ199OT', 'Honda', 'Fit', 2012, NULL, 111000, NULL),
  (16, 15, 'AK210PK', 'Renault', 'Logan', 2019, NULL, 120000, NULL),
  (17, 16, 'AL221QL', 'Ford', 'Ka', 2016, NULL, 129000, NULL);

-- Consultas (motivo = primeros 200 caracteres del problema informado)
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, contacto_dni, contacto_telefono, veh_patente, veh_marca, veh_modelo, veh_anio, veh_kilometraje, motivo, descripcion_problema, observaciones, observaciones_inspeccion, importe_estimado, estado, es_gratuita, cobro_decision, cobro_importe, cobro_por, cobro_fecha, motivo_cierre, creado_por, creado_en) VALUES
  (1, 1, 1, 'Carlos Gómez', NULL, '381-5123456', 'AB123CD', 'Fiat', 'Palio', 2014, 98000, 'Se informa pérdida leve de aceite y cambio de aceite pendiente.', 'Se informa pérdida leve de aceite y cambio de aceite pendiente.', NULL, 'Sin pérdidas visibles en el cárter.', 50000, 'aprobada', 1, NULL, NULL, NULL, NULL, NULL, 2, '2026-11-04 09:00:00'),
  (2, 2, 3, 'María López', NULL, '381-5234567', 'AC789HI', 'Volkswagen', 'Gol', 2017, 61000, 'Se informa un ruido al accionar los frenos, acompañado de vibraciones durante la frenada.', 'Se informa un ruido al accionar los frenos, acompañado de vibraciones durante la frenada.', 'Prefiere que la llamen por la tarde.', 'Espesor de pastillas por debajo del mínimo; discos con leve desgaste.', 70000, 'aprobada', 1, NULL, NULL, NULL, NULL, NULL, 3, '2026-11-17 09:00:00'),
  (3, 4, 5, 'Laura Fernández', NULL, '381-5456789', 'AD456EF', 'Renault', 'Clio', 2012, 120000, 'Service completo pendiente hace mucho tiempo.', 'Service completo pendiente hace mucho tiempo.', NULL, NULL, 60000, 'aprobada', 1, NULL, NULL, NULL, NULL, NULL, 2, '2026-11-14 09:00:00'),
  (4, 3, 4, 'Jorge Ramírez', NULL, '381-5345678', 'AA321JK', 'Ford', 'Fiesta', 2015, 88000, 'Se informa que corresponde el cambio de la distribución.', 'Se informa que corresponde el cambio de la distribución.', NULL, 'Se recomienda cambio por kilometraje y estado.', 200000, 'esperando_respuesta', 1, NULL, NULL, NULL, NULL, NULL, 3, '2026-11-18 09:00:00'),
  (5, NULL, NULL, 'Sofía Prospecto', NULL, '381-5987654', 'HJK123', 'Chevrolet', 'Corsa', 2010, NULL, 'el auto hace un ruido en el motor cuando acelero', 'el auto hace un ruido en el motor cuando acelero', 'Llamó por teléfono.', NULL, NULL, 'abierta', 1, NULL, NULL, NULL, NULL, NULL, 2, '2026-11-20 09:00:00'),
  (6, 5, 6, 'Ana Torres', NULL, '381-610010', 'AA100FK', 'Peugeot', '208', 2019, 30000, 'Se informa un ruido al girar el volante.', 'Se informa un ruido al girar el volante.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 3, '2026-10-24 09:00:00'),
  (7, 6, 7, 'Luis Medina', NULL, '381-610711', 'AB111GL', 'Toyota', 'Etios', 2017, 39000, 'Se informa que el motor no arranca por las mañanas.', 'Se informa que el motor no arranca por las mañanas.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 2, '2026-10-26 09:00:00'),
  (8, 7, 8, 'Marta Ruiz', NULL, '381-611412', 'AC122HM', 'Chevrolet', 'Onix', 2020, 48000, 'Se informa una pérdida de líquido refrigerante.', 'Se informa una pérdida de líquido refrigerante.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 3, '2026-10-28 09:00:00'),
  (9, 8, 9, 'Diego Sosa', NULL, '381-612113', 'AD133IN', 'Renault', 'Sandero', 2016, 57000, 'Se informan vibraciones en el volante a unos 100 km/h.', 'Se informan vibraciones en el volante a unos 100 km/h.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 2, '2026-10-30 09:00:00'),
  (10, 9, 10, 'Paula Ríos', NULL, '381-612814', 'AE144JO', 'Ford', 'Focus', 2013, 66000, 'Se informa que el auto se apaga al detenerse.', 'Se informa que el auto se apaga al detenerse.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 3, '2026-11-01 09:00:00'),
  (11, 10, 11, 'Hugo Acosta', NULL, '381-613515', 'AF155KP', 'Volkswagen', 'Voyage', 2018, 75000, 'Se informa olor a quemado al frenar.', 'Se informa olor a quemado al frenar.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 2, '2026-11-03 09:00:00'),
  (12, 11, 12, 'Elena Vega', NULL, '381-614216', 'AG166LQ', 'Fiat', 'Uno', 2011, 84000, 'Se informa que se enciende la luz del tablero.', 'Se informa que se enciende la luz del tablero.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 3, '2026-11-05 09:00:00'),
  (13, 12, 13, 'Raúl Herrera', NULL, '381-614917', 'AH177MR', 'Nissan', 'March', 2015, 93000, 'Se informa un ruido en la rueda trasera derecha.', 'Se informa un ruido en la rueda trasera derecha.', NULL, NULL, NULL, 'cerrada', 1, NULL, NULL, NULL, NULL, 'El cliente decidió no realizar el trabajo', 2, '2026-11-07 09:00:00'),
  (14, 9, 10, 'Paula Ríos', NULL, '381-612814', 'AE144JO', 'Ford', 'Focus', 2013, 66000, 'Se informan vibraciones en el volante a unos 100 km/h.', 'Se informan vibraciones en el volante a unos 100 km/h.', NULL, NULL, 40000, 'aprobada', 0, 'gratis', 0, 2, '2026-10-27', NULL, 2, '2026-10-27 09:00:00'),
  (15, 10, 11, 'Hugo Acosta', NULL, '381-613515', 'AF155KP', 'Volkswagen', 'Voyage', 2018, 75000, 'Se informa que el auto se apaga al detenerse.', 'Se informa que el auto se apaga al detenerse.', NULL, NULL, 45000, 'aprobada', 0, 'gratis', 0, 2, '2026-10-29', NULL, 2, '2026-10-29 09:00:00'),
  (16, 11, 12, 'Elena Vega', NULL, '381-614216', 'AG166LQ', 'Fiat', 'Uno', 2011, 84000, 'Se informa olor a quemado al frenar.', 'Se informa olor a quemado al frenar.', NULL, NULL, 50000, 'aprobada', 0, 'gratis', 0, 2, '2026-10-31', NULL, 2, '2026-10-31 09:00:00'),
  (17, 12, 13, 'Raúl Herrera', NULL, '381-614917', 'AH177MR', 'Nissan', 'March', 2015, 93000, 'Se informa que se enciende la luz del tablero.', 'Se informa que se enciende la luz del tablero.', NULL, NULL, 55000, 'aprobada', 0, 'gratis', 0, 2, '2026-11-02', NULL, 2, '2026-11-02 09:00:00'),
  (18, 13, 14, 'Nadia Castro', NULL, '381-615618', 'AI188NS', 'Citroën', 'C3', 2014, 102000, 'Se informa un ruido en la rueda trasera derecha.', 'Se informa un ruido en la rueda trasera derecha.', NULL, NULL, 60000, 'aprobada', 1, NULL, NULL, NULL, NULL, NULL, 2, '2026-11-04 09:00:00'),
  (19, 14, 15, 'Sergio Molina', NULL, '381-616319', 'AJ199OT', 'Honda', 'Fit', 2012, 111000, 'Se informa un ruido al girar el volante.', 'Se informa un ruido al girar el volante.', NULL, NULL, 65000, 'aprobada', 1, NULL, NULL, NULL, NULL, NULL, 2, '2026-11-06 09:00:00'),
  (20, 15, 16, 'Julia Ponce', NULL, '381-617020', 'AK210PK', 'Renault', 'Logan', 2019, 120000, 'Se informa que el motor no arranca por las mañanas.', 'Se informa que el motor no arranca por las mañanas.', NULL, NULL, 70000, 'aprobada', 1, NULL, NULL, NULL, NULL, NULL, 2, '2026-11-08 09:00:00'),
  (21, 16, 17, 'Martín Aguirre', NULL, '381-617721', 'AL221QL', 'Ford', 'Ka', 2016, 129000, 'Se informa una pérdida de líquido refrigerante.', 'Se informa una pérdida de líquido refrigerante.', NULL, NULL, 75000, 'aprobada', 1, NULL, NULL, NULL, NULL, NULL, 2, '2026-11-10 09:00:00');

-- Revisión técnica distribuida en filas por tipo (colección consulta_revisiones del MVP)
INSERT INTO detalles_consultas (id, consulta_id, descripcion, tipo, registrado_por, creado_en) VALUES
  (1, 1, 'Aceite sucio, filtro saturado.', 'verificado', 3, '2026-11-04 12:00:00'),
  (2, 1, 'Aceite 10W40, filtro de aceite', 'repuestos_necesarios', 3, '2026-11-04 12:00:00'),
  (3, 1, 'Cambio de aceite y filtro', 'trabajo_recomendado', 3, '2026-11-04 12:00:00'),
  (4, 2, 'Pastillas delanteras desgastadas.', 'verificado', 3, '2026-11-17 12:00:00'),
  (5, 2, 'Pastillas de freno delanteras', 'repuestos_necesarios', 3, '2026-11-17 12:00:00'),
  (6, 2, 'Cambio de pastillas delanteras', 'trabajo_recomendado', 3, '2026-11-17 12:00:00'),
  (7, 3, 'Aceite oscuro, filtro de aire sucio.', 'verificado', 4, '2026-11-14 12:00:00'),
  (8, 3, 'Filtro de aire, bujías', 'repuestos_necesarios', 4, '2026-11-14 12:00:00'),
  (9, 3, 'Service completo', 'trabajo_recomendado', 4, '2026-11-14 12:00:00'),
  (10, 4, 'Correa de distribución con fisuras visibles.', 'verificado', 3, '2026-11-18 12:00:00'),
  (11, 4, 'Kit de distribución', 'repuestos_necesarios', 3, '2026-11-18 12:00:00'),
  (12, 4, 'Cambio de distribución', 'trabajo_recomendado', 3, '2026-11-18 12:00:00'),
  (13, 14, 'Falla confirmada en la revisión.', 'verificado', 3, '2026-10-27 12:00:00'),
  (14, 14, 'Reparación según presupuesto', 'trabajo_recomendado', 3, '2026-10-27 12:00:00'),
  (15, 15, 'Falla confirmada en la revisión.', 'verificado', 4, '2026-10-29 12:00:00'),
  (16, 15, 'Reparación según presupuesto', 'trabajo_recomendado', 4, '2026-10-29 12:00:00'),
  (17, 16, 'Falla confirmada en la revisión.', 'verificado', 3, '2026-10-31 12:00:00'),
  (18, 16, 'Reparación según presupuesto', 'trabajo_recomendado', 3, '2026-10-31 12:00:00'),
  (19, 17, 'Falla confirmada en la revisión.', 'verificado', 4, '2026-11-02 12:00:00'),
  (20, 17, 'Reparación según presupuesto', 'trabajo_recomendado', 4, '2026-11-02 12:00:00'),
  (21, 18, 'Falla confirmada en la revisión.', 'verificado', 3, '2026-11-04 12:00:00'),
  (22, 18, 'Reparación según presupuesto', 'trabajo_recomendado', 3, '2026-11-04 12:00:00'),
  (23, 19, 'Falla confirmada en la revisión.', 'verificado', 4, '2026-11-06 12:00:00'),
  (24, 19, 'Reparación según presupuesto', 'trabajo_recomendado', 4, '2026-11-06 12:00:00'),
  (25, 20, 'Falla confirmada en la revisión.', 'verificado', 3, '2026-11-08 12:00:00'),
  (26, 20, 'Reparación según presupuesto', 'trabajo_recomendado', 3, '2026-11-08 12:00:00'),
  (27, 21, 'Falla confirmada en la revisión.', 'verificado', 4, '2026-11-10 12:00:00'),
  (28, 21, 'Reparación según presupuesto', 'trabajo_recomendado', 4, '2026-11-10 12:00:00');

-- Presupuestos (comision_pct = el de su orden de trabajo; 0 si todavía no tiene orden)
INSERT INTO presupuestos (id, consulta_id, numero, total_calculado, precio_final, comision_pct, estado, valido_hasta, fecha_envio, fecha_respuesta, creado_por, creado_en) VALUES
  (1, 1, 'PRE-0001', 75000, 75000, 30, 'aceptado', '2026-11-11', '2026-11-04 00:00:00', '2026-11-05 00:00:00', 2, '2026-11-04 10:00:00'),
  (2, 2, 'PRE-0002', 70000, 70000, 0, 'aceptado', '2026-11-24', '2026-11-17 00:00:00', '2026-11-19 00:00:00', 2, '2026-11-17 10:00:00'),
  (3, 3, 'PRE-0003', 66500, 66500, 0, 'aceptado', '2026-11-21', '2026-11-14 00:00:00', '2026-11-15 00:00:00', 2, '2026-11-14 10:00:00'),
  (4, 4, 'PRE-0004', 200000, 200000, 0, 'enviado', '2026-11-25', '2026-11-19 00:00:00', NULL, 2, '2026-11-18 10:00:00'),
  (5, 14, 'PRE-0005', 40000, 40000, 30, 'aceptado', '2026-11-10', '2026-10-27 00:00:00', '2026-10-28 00:00:00', 2, '2026-10-27 10:00:00'),
  (6, 15, 'PRE-0006', 45000, 45000, 30, 'aceptado', '2026-11-10', '2026-10-29 00:00:00', '2026-10-30 00:00:00', 2, '2026-10-29 10:00:00'),
  (7, 16, 'PRE-0007', 50000, 50000, 30, 'aceptado', '2026-11-10', '2026-10-31 00:00:00', '2026-11-01 00:00:00', 2, '2026-10-31 10:00:00'),
  (8, 17, 'PRE-0008', 55000, 55000, 30, 'aceptado', '2026-11-10', '2026-11-02 00:00:00', '2026-11-03 00:00:00', 2, '2026-11-02 10:00:00'),
  (9, 18, 'PRE-0009', 60000, 60000, 30, 'aceptado', '2026-11-10', '2026-11-04 00:00:00', '2026-11-05 00:00:00', 2, '2026-11-04 10:00:00'),
  (10, 19, 'PRE-0010', 65000, 65000, 30, 'aceptado', '2026-11-10', '2026-11-06 00:00:00', '2026-11-07 00:00:00', 2, '2026-11-06 10:00:00'),
  (11, 20, 'PRE-0011', 70000, 70000, 30, 'aceptado', '2026-11-10', '2026-11-08 00:00:00', '2026-11-09 00:00:00', 2, '2026-11-08 10:00:00'),
  (12, 21, 'PRE-0012', 75000, 75000, 30, 'aceptado', '2026-11-10', '2026-11-10 00:00:00', '2026-11-11 00:00:00', 2, '2026-11-10 10:00:00');

-- Detalles de presupuestos (monto es columna generada: cantidad x precio_unitario)
INSERT INTO detalles_presupuestos (id, presupuesto_id, concepto, tipo, cantidad, precio_unitario, catalogo_item_id) VALUES
  (1, 1, 'Aceite 10W40', 'repuesto', 4, 14000, NULL),
  (2, 1, 'Filtro de aceite', 'repuesto', 1, 7000, NULL),
  (3, 1, 'Mano de obra service', 'mano_obra', 1, 12000, NULL),
  (4, 2, 'Pastillas de freno delanteras', 'repuesto', 1, 45000, NULL),
  (5, 2, 'Mano de obra', 'mano_obra', 1, 25000, NULL),
  (6, 3, 'Service completo', 'mano_obra', 1, 40000, NULL),
  (7, 3, 'Bujías', 'repuesto', 4, 4500, NULL),
  (8, 3, 'Filtro de aire', 'repuesto', 1, 8500, NULL),
  (9, 4, 'Kit de distribución', 'repuesto', 1, 120000, NULL),
  (10, 4, 'Mano de obra', 'mano_obra', 1, 80000, NULL),
  (11, 5, 'Mano de obra', 'mano_obra', 1, 25000, NULL),
  (12, 5, 'Repuestos', 'repuesto', 1, 15000, NULL),
  (13, 6, 'Mano de obra', 'mano_obra', 1, 30000, NULL),
  (14, 6, 'Repuestos', 'repuesto', 1, 15000, NULL),
  (15, 7, 'Mano de obra', 'mano_obra', 1, 35000, NULL),
  (16, 7, 'Repuestos', 'repuesto', 1, 15000, NULL),
  (17, 8, 'Mano de obra', 'mano_obra', 1, 40000, NULL),
  (18, 8, 'Repuestos', 'repuesto', 1, 15000, NULL),
  (19, 9, 'Mano de obra', 'mano_obra', 1, 45000, NULL),
  (20, 9, 'Repuestos', 'repuesto', 1, 15000, NULL),
  (21, 10, 'Mano de obra', 'mano_obra', 1, 50000, NULL),
  (22, 10, 'Repuestos', 'repuesto', 1, 15000, NULL),
  (23, 11, 'Mano de obra', 'mano_obra', 1, 55000, NULL),
  (24, 11, 'Repuestos', 'repuesto', 1, 15000, NULL),
  (25, 12, 'Mano de obra', 'mano_obra', 1, 60000, NULL),
  (26, 12, 'Repuestos', 'repuesto', 1, 15000, NULL);

-- Catálogo: categorías (colección categorias_repuesto)
INSERT INTO categorias_catalogo (id, nombre, descripcion, activo) VALUES
  (1, 'Lubricantes', NULL, 1),
  (2, 'Filtros', NULL, 1),
  (3, 'Frenos', NULL, 1),
  (4, 'Encendido', NULL, 1),
  (5, 'Correas', NULL, 1),
  (6, 'Líquidos', NULL, 1),
  (7, 'Iluminación', NULL, 1);

-- Catálogo: artículos (colección repuestos; alerta_stock se deduce de cantidad <= stock_minimo)
INSERT INTO catalogo_items (id, categoria_id, tipo, nombre, codigo, marca, ubicacion, precio_compra, precio_venta, cantidad, stock_minimo, activo) VALUES
  (1, 1, 'repuesto', 'Aceite 10W40 (litro)', 'ACE-1040', 'Elaion', 'Estante A1', 8000, 14000, 28, 6, 1),
  (2, 2, 'repuesto', 'Filtro de aceite', 'FIL-OIL', 'Mann', 'Estante B2', 3500, 7000, 11, 5, 1),
  (3, 2, 'repuesto', 'Filtro de aire', 'FIL-AIR', 'Mann', 'Estante B2', 4000, 8500, 4, 5, 1),
  (4, 3, 'repuesto', 'Pastillas de freno delanteras', 'PAS-DEL', 'Fras-le', 'Estante C1', 18000, 32000, 8, 3, 1),
  (5, 4, 'repuesto', 'Bujías (unidad)', 'BUJ-STD', 'NGK', 'Cajón D3', 2000, 4500, 26, 8, 1),
  (6, 5, 'repuesto', 'Correa de distribución', 'COR-DIS', 'Gates', 'Estante C3', 15000, 28000, 3, 3, 1),
  (7, 6, 'repuesto', 'Líquido refrigerante (litro)', 'LIQ-REF', NULL, 'Estante A2', 4500, 9000, 9, 4, 1),
  (8, 7, 'repuesto', 'Lámpara H7', 'LAM-H7', 'Osram', 'Cajón D1', 3000, 6500, 12, 4, 1),
  (9, 1, 'repuesto', 'Aceite 5W30 (litro)', 'ACE-5W30', 'Elaion', 'Estante A1', 9500, 16000, 19, 6, 1),
  (10, 2, 'repuesto', 'Filtro de combustible', 'FIL-COM', 'Mann', 'Estante B3', 3800, 7500, 8, 4, 1),
  (11, 3, 'repuesto', 'Pastillas de freno traseras', 'PAS-TRA', 'Fras-le', 'Estante C1', 14000, 26000, 6, 3, 1),
  (12, 3, 'repuesto', 'Disco de freno delantero', 'DIS-DEL', 'Fremax', 'Estante C2', 22000, 38000, 5, 2, 1),
  (13, 4, 'repuesto', 'Batería 60 Ah', 'BAT-60', 'Moura', 'Depósito', 70000, 105000, 4, 2, 1),
  (14, 5, 'repuesto', 'Correa de alternador', 'COR-ALT', 'Gates', 'Estante C3', 6000, 11000, 7, 3, 1),
  (15, 6, 'repuesto', 'Líquido de frenos', 'LIQ-FRE', NULL, 'Estante A2', 3500, 7000, 13, 5, 1),
  (16, 7, 'repuesto', 'Lámpara H4', 'LAM-H4', 'Osram', 'Cajón D1', 2800, 6000, 14, 5, 1),
  (17, 3, 'repuesto', 'Amortiguador delantero', 'AMO-DEL', 'Cofap', 'Depósito', 30000, 52000, 3, 2, 1);

-- Órdenes de trabajo (pendiente_aceptacion del MVP = ofrecido)
INSERT INTO ordenes_trabajo (id, numero, presupuesto_id, cliente_id, vehiculo_id, mecanico_id, descripcion, repuestos_previstos, observaciones, estado, precio_final, comision_pct, observaciones_mecanico, creado_en, inicio_previsto, entrega_prevista, fecha_inicio, fecha_fin) VALUES
  (1, 'OT-0001', 1, 1, 1, 3, 'Cambio de aceite y filtro', 'Aceite x4, filtro x1', NULL, 'finalizado', 75000, 30, NULL, '2026-11-05 11:00:00', '2026-11-06', '2026-11-07', '2026-11-06 09:30:00', '2026-11-06 12:00:00'),
  (2, 'OT-0002', 2, 2, 3, 3, 'Cambio de pastillas de freno delanteras', 'Pastillas de freno delanteras', NULL, 'ofrecido', 70000, 0, NULL, '2026-11-19 11:00:00', '2026-11-21', '2026-11-22', NULL, NULL),
  (3, 'OT-0003', 3, 4, 5, 4, 'Service completo', 'Bujías x4, filtro de aire x1', NULL, 'en_proceso', 66500, 0, NULL, '2026-11-15 11:00:00', '2026-11-18', '2026-11-21', '2026-11-19 08:30:00', NULL),
  (4, 'OT-0004', 5, 9, 10, 3, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 40000, 30, NULL, '2026-10-28 11:00:00', '2026-10-29', '2026-10-30', '2026-10-29 09:00:00', '2026-10-30 12:00:00'),
  (5, 'OT-0005', 6, 10, 11, 4, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 45000, 30, NULL, '2026-10-30 11:00:00', '2026-10-31', '2026-11-01', '2026-10-31 09:00:00', '2026-11-01 12:00:00'),
  (6, 'OT-0006', 7, 11, 12, 3, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 50000, 30, NULL, '2026-11-01 11:00:00', '2026-11-02', '2026-11-03', '2026-11-02 09:00:00', '2026-11-03 12:00:00'),
  (7, 'OT-0007', 8, 12, 13, 4, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 55000, 30, NULL, '2026-11-03 11:00:00', '2026-11-04', '2026-11-05', '2026-11-04 09:00:00', '2026-11-05 12:00:00'),
  (8, 'OT-0008', 9, 13, 14, 3, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 60000, 30, NULL, '2026-11-05 11:00:00', '2026-11-06', '2026-11-07', '2026-11-06 09:00:00', '2026-11-07 12:00:00'),
  (9, 'OT-0009', 10, 14, 15, 4, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 65000, 30, NULL, '2026-11-07 11:00:00', '2026-11-08', '2026-11-09', '2026-11-08 09:00:00', '2026-11-09 12:00:00'),
  (10, 'OT-0010', 11, 15, 16, 3, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 70000, 30, NULL, '2026-11-09 11:00:00', '2026-11-10', '2026-11-11', '2026-11-10 09:00:00', '2026-11-11 12:00:00'),
  (11, 'OT-0011', 12, 16, 17, 4, 'Reparación según presupuesto', NULL, NULL, 'finalizado', 75000, 30, NULL, '2026-11-11 11:00:00', '2026-11-12', '2026-11-13', '2026-11-12 09:00:00', '2026-11-13 12:00:00');

INSERT INTO historial_estados_ordenes (id, orden_id, estado_anterior, estado_nuevo, cambiado_por, observacion, fecha) VALUES
  (1, 1, NULL, 'ofrecido', 2, 'Asignado a Juan Pérez', '2026-11-05 09:00:00'),
  (2, 1, 'ofrecido', 'aceptado', 3, NULL, '2026-11-05 10:00:00'),
  (3, 1, 'aceptado', 'en_proceso', 3, NULL, '2026-11-06 09:30:00'),
  (4, 1, 'en_proceso', 'finalizado', 3, NULL, '2026-11-06 12:00:00'),
  (5, 2, NULL, 'ofrecido', 2, 'Asignado a Juan Pérez', '2026-11-19 09:00:00'),
  (6, 3, NULL, 'ofrecido', 2, 'Asignado a Pedro Gómez', '2026-11-15 09:00:00'),
  (7, 3, 'ofrecido', 'aceptado', 4, NULL, '2026-11-15 11:00:00'),
  (8, 3, 'aceptado', 'en_proceso', 4, NULL, '2026-11-19 08:30:00'),
  (9, 4, NULL, 'ofrecido', 2, 'Asignado a Juan Pérez', '2026-10-28 09:00:00'),
  (10, 4, 'ofrecido', 'aceptado', 3, NULL, '2026-10-28 10:00:00'),
  (11, 4, 'aceptado', 'en_proceso', 3, NULL, '2026-10-29 09:00:00'),
  (12, 4, 'en_proceso', 'finalizado', 3, NULL, '2026-10-30 12:00:00'),
  (13, 5, NULL, 'ofrecido', 2, 'Asignado a Pedro Gómez', '2026-10-30 09:00:00'),
  (14, 5, 'ofrecido', 'aceptado', 4, NULL, '2026-10-30 10:00:00'),
  (15, 5, 'aceptado', 'en_proceso', 4, NULL, '2026-10-31 09:00:00'),
  (16, 5, 'en_proceso', 'finalizado', 4, NULL, '2026-11-01 12:00:00'),
  (17, 6, NULL, 'ofrecido', 2, 'Asignado a Juan Pérez', '2026-11-01 09:00:00'),
  (18, 6, 'ofrecido', 'aceptado', 3, NULL, '2026-11-01 10:00:00'),
  (19, 6, 'aceptado', 'en_proceso', 3, NULL, '2026-11-02 09:00:00'),
  (20, 6, 'en_proceso', 'finalizado', 3, NULL, '2026-11-03 12:00:00'),
  (21, 7, NULL, 'ofrecido', 2, 'Asignado a Pedro Gómez', '2026-11-03 09:00:00'),
  (22, 7, 'ofrecido', 'aceptado', 4, NULL, '2026-11-03 10:00:00'),
  (23, 7, 'aceptado', 'en_proceso', 4, NULL, '2026-11-04 09:00:00'),
  (24, 7, 'en_proceso', 'finalizado', 4, NULL, '2026-11-05 12:00:00'),
  (25, 8, NULL, 'ofrecido', 2, 'Asignado a Juan Pérez', '2026-11-05 09:00:00'),
  (26, 8, 'ofrecido', 'aceptado', 3, NULL, '2026-11-05 10:00:00'),
  (27, 8, 'aceptado', 'en_proceso', 3, NULL, '2026-11-06 09:00:00'),
  (28, 8, 'en_proceso', 'finalizado', 3, NULL, '2026-11-07 12:00:00'),
  (29, 9, NULL, 'ofrecido', 2, 'Asignado a Pedro Gómez', '2026-11-07 09:00:00'),
  (30, 9, 'ofrecido', 'aceptado', 4, NULL, '2026-11-07 10:00:00'),
  (31, 9, 'aceptado', 'en_proceso', 4, NULL, '2026-11-08 09:00:00'),
  (32, 9, 'en_proceso', 'finalizado', 4, NULL, '2026-11-09 12:00:00'),
  (33, 10, NULL, 'ofrecido', 2, 'Asignado a Juan Pérez', '2026-11-09 09:00:00'),
  (34, 10, 'ofrecido', 'aceptado', 3, NULL, '2026-11-09 10:00:00'),
  (35, 10, 'aceptado', 'en_proceso', 3, NULL, '2026-11-10 09:00:00'),
  (36, 10, 'en_proceso', 'finalizado', 3, NULL, '2026-11-11 12:00:00'),
  (37, 11, NULL, 'ofrecido', 2, 'Asignado a Pedro Gómez', '2026-11-11 09:00:00'),
  (38, 11, 'ofrecido', 'aceptado', 4, NULL, '2026-11-11 10:00:00'),
  (39, 11, 'aceptado', 'en_proceso', 4, NULL, '2026-11-12 09:00:00'),
  (40, 11, 'en_proceso', 'finalizado', 4, NULL, '2026-11-13 12:00:00');

-- Asignaciones de mecánicos (pendiente del MVP = ofrecida)
INSERT INTO asignaciones_trabajo (id, orden_id, mecanico_id, asignado_por, resultado, motivo_rechazo, creado_en, resuelto_en) VALUES
  (1, 1, 3, 2, 'aceptada', NULL, '2026-11-05 09:00:00', '2026-11-05 10:00:00'),
  (2, 2, 3, 2, 'ofrecida', NULL, '2026-11-19 09:00:00', NULL),
  (3, 3, 4, 2, 'aceptada', NULL, '2026-11-15 09:00:00', '2026-11-15 11:00:00'),
  (4, 4, 3, 2, 'aceptada', NULL, '2026-10-28 09:00:00', '2026-10-28 10:00:00'),
  (5, 5, 4, 2, 'aceptada', NULL, '2026-10-30 09:00:00', '2026-10-30 10:00:00'),
  (6, 6, 3, 2, 'aceptada', NULL, '2026-11-01 09:00:00', '2026-11-01 10:00:00'),
  (7, 7, 4, 2, 'aceptada', NULL, '2026-11-03 09:00:00', '2026-11-03 10:00:00'),
  (8, 8, 3, 2, 'aceptada', NULL, '2026-11-05 09:00:00', '2026-11-05 10:00:00'),
  (9, 9, 4, 2, 'aceptada', NULL, '2026-11-07 09:00:00', '2026-11-07 10:00:00'),
  (10, 10, 3, 2, 'aceptada', NULL, '2026-11-09 09:00:00', '2026-11-09 10:00:00'),
  (11, 11, 4, 2, 'aceptada', NULL, '2026-11-11 09:00:00', '2026-11-11 10:00:00');

-- Avances de las órdenes (colección orden_avances)
INSERT INTO avances_ordenes (id, orden_id, usuario_id, texto, creado_en) VALUES
  (1, 1, 3, 'Se drenó el aceite y se reemplazó el filtro.', '2026-11-06 10:10:00'),
  (2, 3, 4, 'Se cambiaron las bujías. Falta el filtro de aire (poco stock).', '2026-11-19 16:00:00'),
  (3, 4, 3, 'Trabajo realizado y probado en ruta.', '2026-10-30 11:00:00'),
  (4, 5, 4, 'Trabajo realizado y probado en ruta.', '2026-11-01 11:00:00'),
  (5, 6, 3, 'Trabajo realizado y probado en ruta.', '2026-11-03 11:00:00'),
  (6, 7, 4, 'Trabajo realizado y probado en ruta.', '2026-11-05 11:00:00'),
  (7, 8, 3, 'Trabajo realizado y probado en ruta.', '2026-11-07 11:00:00'),
  (8, 9, 4, 'Trabajo realizado y probado en ruta.', '2026-11-09 11:00:00'),
  (9, 10, 3, 'Trabajo realizado y probado en ruta.', '2026-11-11 11:00:00'),
  (10, 11, 4, 'Trabajo realizado y probado en ruta.', '2026-11-13 11:00:00');

-- Pagos de CLIENTES al taller (colección pagos_cliente)
INSERT INTO pagos_clientes (id, tipo, orden_id, cliente_id, monto, metodo, registrado_por, fecha, observaciones) VALUES
  (1, 'trabajo', 1, 1, 40000, 'combinado', 2, '2026-11-07 09:00:00', 'Adelanto y entrega'),
  (2, 'trabajo', 4, 9, 40000, 'efectivo', 2, '2026-10-30 09:00:00', NULL),
  (3, 'trabajo', 5, 10, 45000, 'transferencia', 2, '2026-11-01 09:00:00', NULL),
  (4, 'trabajo', 6, 11, 50000, 'mercadopago', 2, '2026-11-03 09:00:00', NULL),
  (5, 'trabajo', 7, 12, 55000, 'efectivo', 2, '2026-11-05 09:00:00', NULL),
  (6, 'trabajo', 8, 13, 60000, 'transferencia', 2, '2026-11-07 09:00:00', NULL),
  (7, 'trabajo', 9, 14, 65000, 'mercadopago', 2, '2026-11-09 09:00:00', NULL);

-- Medios de cada pago de cliente (colección pago_cliente_medios)
INSERT INTO detalles_pagos_clientes (id, pago_cliente_id, medio, importe, referencia) VALUES
  (1, 1, 'efectivo', 25000, NULL),
  (2, 1, 'transferencia', 15000, NULL),
  (3, 2, 'efectivo', 40000, NULL),
  (4, 3, 'transferencia', 45000, NULL),
  (5, 4, 'mercadopago', 50000, NULL),
  (6, 5, 'efectivo', 55000, NULL),
  (7, 6, 'transferencia', 60000, NULL),
  (8, 7, 'mercadopago', 65000, NULL);

-- Movimientos de stock (uso_orden del MVP = salida con orden_id; reversion = entrada con orden_id)
INSERT INTO movimientos_stock (id, catalogo_item_id, descripcion_libre, tipo, cantidad, estado, aportado_cliente, motivo, orden_id, pago_cliente_id, solicitado_por, resuelto_por, fecha) VALUES
  (1, 1, NULL, 'entrada', 32, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-26 09:00:00'),
  (2, 2, NULL, 'entrada', 12, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-26 09:00:00'),
  (3, 3, NULL, 'entrada', 4, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-26 09:00:00'),
  (4, 5, NULL, 'entrada', 30, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-26 09:00:00'),
  (5, 1, NULL, 'salida', 4, 'confirmado', 0, 'Usado en OT-0001', 1, NULL, 3, 3, '2026-11-06 11:00:00'),
  (6, 2, NULL, 'salida', 1, 'confirmado', 0, 'Usado en OT-0001', 1, NULL, 3, 3, '2026-11-06 11:00:00'),
  (7, 5, NULL, 'salida', 4, 'confirmado', 0, 'Usado en OT-0003', 3, NULL, 4, 4, '2026-11-19 15:30:00'),
  (8, 9, NULL, 'entrada', 20, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (9, 9, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (10, 10, NULL, 'entrada', 9, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (11, 10, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (12, 11, NULL, 'entrada', 7, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (13, 11, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (14, 12, NULL, 'entrada', 6, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (15, 12, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (16, 13, NULL, 'entrada', 5, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (17, 13, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (18, 14, NULL, 'entrada', 8, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (19, 14, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (20, 15, NULL, 'entrada', 14, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (21, 15, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (22, 16, NULL, 'entrada', 15, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (23, 16, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (24, 17, NULL, 'entrada', 4, 'confirmado', 0, 'Compra a proveedor', NULL, NULL, 2, 2, '2026-10-31 09:00:00'),
  (25, 17, NULL, 'salida', 1, 'confirmado', 0, 'Consumo del taller', NULL, NULL, 2, 2, '2026-11-08 09:00:00'),
  (26, 4, NULL, 'entrada', 8, 'confirmado', 0, 'Stock inicial', NULL, NULL, 2, 2, '2026-10-26 09:00:00'),
  (27, 6, NULL, 'entrada', 3, 'confirmado', 0, 'Stock inicial', NULL, NULL, 2, 2, '2026-10-26 09:00:00'),
  (28, 7, NULL, 'entrada', 9, 'confirmado', 0, 'Stock inicial', NULL, NULL, 2, 2, '2026-10-26 09:00:00'),
  (29, 8, NULL, 'entrada', 12, 'confirmado', 0, 'Stock inicial', NULL, NULL, 2, 2, '2026-10-26 09:00:00');

-- Comisiones y adelantos (colección movimientos_mecanico del MVP; mecanico_id del MVP = mecanicos.id -> usuarios.id)
INSERT INTO movimientos_mecanicos (id, mecanico_id, tipo, monto, orden_id, registrado_por, fecha, descripcion) VALUES
  (1, 3, 'comision', 3600, 1, 2, '2026-11-06 12:00:00', 'Comisión 30 % sobre la mano de obra de OT-0001'),
  (2, 3, 'comision', 7500, 4, 2, '2026-10-30 12:00:00', 'Comisión 30 % sobre la mano de obra de OT-0004'),
  (3, 3, 'comision', 10500, 6, 2, '2026-11-03 12:00:00', 'Comisión 30 % sobre la mano de obra de OT-0006'),
  (4, 4, 'comision', 9000, 5, 2, '2026-11-01 12:00:00', 'Comisión 30 % sobre la mano de obra de OT-0005'),
  (5, 4, 'comision', 12000, 7, 2, '2026-11-05 12:00:00', 'Comisión 30 % sobre la mano de obra de OT-0007'),
  (6, 3, 'adelanto', 5000, NULL, 2, '2026-11-04 09:00:00', 'Adelanto de sueldo (demostración)'),
  (7, 4, 'adelanto', 8000, NULL, 2, '2026-11-02 09:00:00', 'Adelanto de sueldo (demostración)');

-- Liquidaciones (colección liquidaciones del MVP: una pagada, una pendiente y una anulada)
INSERT INTO liquidaciones_mecanicos (id, mecanico_id, periodo_desde, periodo_hasta, total_comisiones, total_adelantos, total_a_pagar, estado, creado_por, fecha_creacion, fecha_pago, observaciones) VALUES
  (1, 3, '2026-10-21', '2026-11-08', 21600, 5000, 16600, 'pagada', 2, '2026-11-09 10:00:00', '2026-11-09 11:00:00', 'Liquidación pagada (demostración)'),
  (2, 4, '2026-10-21', '2026-11-01', 9000, 0, 9000, 'anulada', 2, '2026-11-02 10:00:00', NULL, 'Anulada: se rehizo con otro período (demostración)'),
  (3, 4, '2026-10-21', '2026-11-06', 21000, 8000, 13000, 'pendiente', 2, '2026-11-07 10:00:00', NULL, 'Pendiente de pago (demostración)');

-- Movimientos incluidos en cada liquidación (una liquidación anulada libera los suyos: no tiene detalles)
INSERT INTO detalles_liquidaciones_mecanicos (id, liquidacion_id, movimiento_mecanico_id, importe_incluido) VALUES
  (1, 1, 1, 3600),
  (2, 1, 2, 7500),
  (3, 1, 3, 10500),
  (4, 1, 6, 5000),
  (5, 3, 4, 9000),
  (6, 3, 5, 12000),
  (7, 3, 7, 8000);

-- DATO DE PRUEBA (no proviene del MVP): el MVP no genera historial de precios del catálogo.

-- DATO DE PRUEBA: ajuste de precio del filtro de aceite (los precios "nuevos" coinciden con los actuales del catálogo)
INSERT INTO historial_precios_catalogo (id, catalogo_item_id, precio_compra_anterior, precio_compra_nuevo, precio_venta_anterior, precio_venta_nuevo, cambiado_por, fecha) VALUES
  (1, 2, 3200, 3500, 6500, 7000, 2, '2026-10-31 10:00:00');

-- Suscripción: ciclo 1 (pagado) y ciclo 2 (vigente = suscripción actual del MVP, vence en 12 días)
INSERT INTO periodos_pago_sistema (id, taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia, estado, fecha_pago_confirmado, creado_en) VALUES
  (1, 1, 1, 'mensual', '2026-10-02', '2026-11-02', 30000, 3, '2026-11-05', 'pagado', '2026-11-02 09:00:00', '2026-10-02 09:00:00'),
  (2, 1, 2, 'mensual', '2026-11-02', '2026-12-02', 30000, 3, '2026-12-05', 'vigente', NULL, '2026-11-02 09:00:00');

-- Pagos del SISTEMA (el dueño paga la suscripción al SuperAdmin) — distinto de pagos_clientes
INSERT INTO pagos_sistema (id, periodo_id, importe_total, metodo, estado, registrado_por, confirmado_por, fecha_registro, fecha_confirmacion, motivo_rechazo, observaciones) VALUES
  (1, 1, 30000, 'combinado', 'confirmado', 2, 1, '2026-11-02 09:00:00', '2026-11-02 09:00:00', NULL, 'Pago informado por el dueño y confirmado por el SuperAdmin'),
  (2, 2, 30000, 'transferencia', 'informado', 2, NULL, '2026-11-20 09:00:00', NULL, NULL, 'Pago informado por el dueño, pendiente de confirmar');

INSERT INTO detalles_pagos_sistema (id, pago_id, medio, importe, referencia) VALUES
  (1, 1, 'efectivo', 10000, NULL),
  (2, 1, 'transferencia', 20000, 'TRF-88213'),
  (3, 2, 'transferencia', 30000, 'TRF-55120');

-- Notificaciones (las de rol del MVP se expanden a un registro por destinatario; la del SuperAdmin es la del pago informado)
INSERT INTO notificaciones (id, usuario_id, superadmin_id, texto, enlace, tipo, clave_unica, leida, creada_en) VALUES
  (1, 2, NULL, 'Trabajo finalizado: avisá al cliente. (demostración)', '/trabajos', 'info', 'seed:old0:u2', 1, '2026-11-05 09:00:00'),
  (2, 2, NULL, 'Pago registrado. (demostración)', '/trabajos', 'info', 'seed:old1:u2', 1, '2026-11-06 09:00:00'),
  (3, 2, NULL, 'Presupuesto aceptado. (demostración)', '/trabajos', 'info', 'seed:old2:u2', 1, '2026-11-07 09:00:00'),
  (4, 2, NULL, 'Trabajo finalizado: avisá al cliente. (demostración)', '/trabajos', 'info', 'seed:old3:u2', 1, '2026-11-08 09:00:00'),
  (5, 2, NULL, 'Pago registrado. (demostración)', '/trabajos', 'info', 'seed:old4:u2', 1, '2026-11-09 09:00:00'),
  (6, 2, NULL, 'Presupuesto aceptado. (demostración)', '/trabajos', 'info', 'seed:old5:u2', 1, '2026-11-10 09:00:00'),
  (7, 2, NULL, 'Trabajo finalizado: avisá al cliente. (demostración)', '/trabajos', 'info', 'seed:old6:u2', 1, '2026-11-11 09:00:00'),
  (8, 2, NULL, 'Pago registrado. (demostración)', '/trabajos', 'info', 'seed:old7:u2', 1, '2026-11-12 09:00:00'),
  (9, 2, NULL, 'Presupuesto aceptado. (demostración)', '/trabajos', 'info', 'seed:old8:u2', 1, '2026-11-13 09:00:00'),
  (10, 2, NULL, 'Nueva consulta: Sofía Prospecto (Chevrolet Corsa).', '/consultas/5', 'info', 'seed:n1:u2', 0, '2026-11-20 08:00:00'),
  (11, 3, NULL, 'Nuevo trabajo asignado: OT-0002 (Volkswagen Gol).', '/trabajos/2', 'trabajo', 'seed:n2:u3', 0, '2026-11-20 08:00:00'),
  (12, 2, NULL, 'Stock bajo: Filtro de aire (quedan 4, mínimo 5).', '/stock', 'stock', 'seed:n3:u2', 0, '2026-11-20 08:00:00'),
  (13, NULL, 1, 'Taller Matienzo informó un pago de $30.000 pendiente de confirmación.', '/superadmin/pagos', 'pago', 'seed:sa1:sa', 0, '2026-11-20 08:00:00');

-- Auditoría
INSERT INTO auditoria (id, usuario_id, superadmin_id, actor_login, ambito, accion, entidad, entidad_id, detalle, ip, fecha) VALUES
  (1, 2, NULL, 'roberto', 'taller', 'Registró una consulta', NULL, NULL, '{"detalle": "Registro de demostración 1"}', NULL, '2026-11-08 10:00:00'),
  (2, 2, NULL, 'roberto', 'taller', 'Presentó un presupuesto al cliente', NULL, NULL, '{"detalle": "Registro de demostración 2"}', NULL, '2026-11-09 10:00:00'),
  (3, 2, NULL, 'roberto', 'taller', 'Registró un pago de cliente', NULL, NULL, '{"detalle": "Registro de demostración 3"}', NULL, '2026-11-10 10:00:00'),
  (4, 2, NULL, 'roberto', 'taller', 'Asignó el trabajo', NULL, NULL, '{"detalle": "Registro de demostración 4"}', NULL, '2026-11-11 10:00:00'),
  (5, 2, NULL, 'roberto', 'taller', 'Registró una consulta', NULL, NULL, '{"detalle": "Registro de demostración 5"}', NULL, '2026-11-12 10:00:00'),
  (6, 2, NULL, 'roberto', 'taller', 'Presentó un presupuesto al cliente', NULL, NULL, '{"detalle": "Registro de demostración 6"}', NULL, '2026-11-13 10:00:00'),
  (7, 2, NULL, 'roberto', 'taller', 'Registró un pago de cliente', NULL, NULL, '{"detalle": "Registro de demostración 7"}', NULL, '2026-11-14 10:00:00'),
  (8, 2, NULL, 'roberto', 'taller', 'Asignó el trabajo', NULL, NULL, '{"detalle": "Registro de demostración 8"}', NULL, '2026-11-15 10:00:00'),
  (9, 2, NULL, 'roberto', 'taller', 'Registró una consulta', NULL, NULL, '{"detalle": "Registro de demostración 9"}', NULL, '2026-11-16 10:00:00'),
  (10, 2, NULL, 'roberto', 'taller', 'Presentó un presupuesto al cliente', NULL, NULL, '{"detalle": "Registro de demostración 10"}', NULL, '2026-11-17 10:00:00'),
  (11, 2, NULL, 'roberto', 'taller', 'Registró un pago de cliente', NULL, NULL, '{"detalle": "Registro de demostración 11"}', NULL, '2026-11-18 10:00:00'),
  (12, 2, NULL, 'roberto', 'taller', 'Asignó el trabajo', NULL, NULL, '{"detalle": "Registro de demostración 12"}', NULL, '2026-11-19 10:00:00'),
  (13, NULL, 1, 'superadmin', 'sistema', 'Datos de demostración cargados', NULL, NULL, '{"detalle": "Instalación inicial de la demo"}', NULL, '2026-11-20 08:00:00');

-- Propuestas de mejora de redacción (proveedor local de reglas; no se usa ninguna IA externa)
INSERT INTO propuestas_ia (id, usuario_id, contexto, consulta_id, orden_id, texto_original, texto_propuesto, texto_final, estado, proveedor, modelo, creada_en, resuelta_en) VALUES
  (1, 3, 'problema_consulta', 2, NULL, 'el auto hace un ruido cuando freno y parece que vibra todo', 'Se informa un ruido al accionar los frenos, acompañado de vibraciones durante la frenada.', 'Se informa un ruido al accionar los frenos, acompañado de vibraciones durante la frenada.', 'aceptada', 'reglas_locales', NULL, '2026-11-17 09:00:00', '2026-11-17 09:00:00');
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- SECCIÓN 3. PRUEBAS SQL
-- ============================================================================
-- Tipos: integridad (debe devolver 0 filas), info (consulta informativa),
-- op (INSERT/UPDATE/DELETE dentro de una transacción con ROLLBACK, devuelve
-- resultado = OK) y error (la sentencia DEBE fallar con el código indicado).
-- Fecha de referencia de la demostración: 2026-11-20.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_esperar_error;
DELIMITER $$
CREATE PROCEDURE sp_esperar_error(IN p_id VARCHAR(10), IN p_sql TEXT, IN p_codigo INT)
BEGIN
  -- Ejecuta una sentencia que DEBE fallar y compara el código de error de MySQL.
  DECLARE v_err INT DEFAULT NULL;
  DECLARE v_msg TEXT DEFAULT NULL;
  DECLARE v_e2 INT DEFAULT NULL;
  DECLARE v_m2 TEXT DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN GET DIAGNOSTICS CONDITION 1 v_e2 = MYSQL_ERRNO, v_m2 = MESSAGE_TEXT; IF v_err IS NULL THEN SET v_err = v_e2, v_msg = v_m2; END IF; END;
  SET @sql_prueba = p_sql;
  PREPARE st FROM @sql_prueba;
  EXECUTE st;
  DEALLOCATE PREPARE st;
  SELECT p_id AS prueba, p_codigo AS error_esperado, v_err AS error_obtenido,
         IF(v_err = p_codigo, 'OK', 'FALLA') AS resultado, LEFT(v_msg, 120) AS mensaje;
END$$
DELIMITER ;


-- ----------------------------------------------------------------------------
-- MÓDULO 1. USUARIOS Y ROLES
-- ----------------------------------------------------------------------------
-- PRUEBA 1.1 — Usuarios de taller con rol válido [integridad]
-- Objetivo: Todo usuario de taller debe tener un rol existente.
-- Esperado: 0 filas
SELECT '1.1' AS prueba, 'integridad' AS tipo;
SELECT u.id, u.usuario FROM usuarios u LEFT JOIN roles r ON r.id = u.rol_id WHERE u.tipo_cuenta = 'taller' AND r.id IS NULL;
-- PRUEBA 1.2 — SuperAdmin sin rol operativo y con registro en superadmins [integridad]
-- Objetivo: Cada usuario superadmin debe tener rol_id NULL y su fila en superadmins.
-- Esperado: 0 filas
SELECT '1.2' AS prueba, 'integridad' AS tipo;
SELECT u.id, u.usuario FROM usuarios u LEFT JOIN superadmins s ON s.usuario_id = u.id WHERE u.tipo_cuenta = 'superadmin' AND (s.id IS NULL OR u.rol_id IS NOT NULL);
-- PRUEBA 1.3 — Administrador del taller correcto [integridad]
-- Objetivo: El administrador registrado en taller debe ser un usuario de taller con rol Administrador.
-- Esperado: 0 filas
SELECT '1.3' AS prueba, 'integridad' AS tipo;
SELECT t.id FROM taller t JOIN usuarios u ON u.id = t.admin_usuario_id JOIN roles r ON r.id = u.rol_id WHERE u.tipo_cuenta <> 'taller' OR r.nombre <> 'Administrador';
-- PRUEBA 1.4 — Usuarios de taller sin rol (control cruzado) [integridad]
-- Objetivo: Control complementario de la 1.1 usando NOT EXISTS.
-- Esperado: 0 filas
SELECT '1.4' AS prueba, 'integridad' AS tipo;
SELECT u.id FROM usuarios u WHERE u.tipo_cuenta = 'taller' AND NOT EXISTS (SELECT 1 FROM roles r WHERE r.id = u.rol_id);
-- PRUEBA 1.5 — Listado de usuarios con su rol (INNER JOIN) [info]
-- Objetivo: Mostrar los usuarios del taller con el nombre de su rol.
-- Esperado: 4 filas (1 administrador y 3 mecánicos)
SELECT '1.5' AS prueba, 'info' AS tipo;
SELECT u.id, u.usuario, u.nombre, r.nombre AS rol, u.estado FROM usuarios u INNER JOIN roles r ON r.id = u.rol_id ORDER BY u.id;
-- PRUEBA 1.6 — Contraseñas almacenadas como hash [integridad]
-- Objetivo: Ningún password_hash puede ser texto plano: deben ser hashes bcrypt ($2b$, 60 caracteres).
-- Esperado: 0 filas
SELECT '1.6' AS prueba, 'integridad' AS tipo;
SELECT id, usuario FROM usuarios WHERE password_hash NOT REGEXP '^\\$2[aby]\\$[0-9]{2}\\$.{53}$';
-- PRUEBA 1.7 — SuperAdmin no figura como rol operativo [integridad]
-- Objetivo: La tabla roles no debe contener un rol SuperAdmin.
-- Esperado: 0 filas
SELECT '1.7' AS prueba, 'integridad' AS tipo;
SELECT id, nombre FROM roles WHERE LOWER(nombre) LIKE '%superadmin%';
-- PRUEBA 1.8 — Alta de un mecánico [op]
-- Objetivo: Insertar un mecánico nuevo y comprobar que queda con su rol (se deshace con ROLLBACK).
-- Esperado: resultado = OK
SELECT '1.8' AS prueba;
START TRANSACTION;
INSERT INTO usuarios (id, tipo_cuenta, rol_id, nombre, usuario, password_hash, telefono, especialidad, disponible)
VALUES (9001, 'taller', 2, 'Mecánico de Prueba', 'mecprueba', '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ0123456', '381-0000000', 'Electricidad', 1);
SELECT IF(COUNT(*) = 1 AND MAX(r.nombre) = 'Mecanico' AND MAX(u.especialidad) = 'Electricidad', 'OK', 'FALLA') AS resultado
FROM usuarios u INNER JOIN roles r ON r.id = u.rol_id WHERE u.id = 9001;
ROLLBACK;
-- PRUEBA 1.9 — Pausar a un mecánico [op]
-- Objetivo: UPDATE del estado de un usuario (equivale a "inactivo" en el MVP).
-- Esperado: resultado = OK
SELECT '1.9' AS prueba;
START TRANSACTION;
UPDATE usuarios SET estado = 'pausado', disponible = 0 WHERE usuario = 'carlos';
SELECT IF(estado = 'pausado' AND disponible = 0, 'OK', 'FALLA') AS resultado FROM usuarios WHERE usuario = 'carlos';
ROLLBACK;
-- PRUEBA 1.10 — Baja física de un usuario sin historial [op]
-- Objetivo: DELETE de un usuario recién creado, sin movimientos.
-- Esperado: resultado = OK
SELECT '1.10' AS prueba;
START TRANSACTION;
INSERT INTO usuarios (id, tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES (9002, 'taller', 2, 'Temporal', 'temporal', '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ0123456');
DELETE FROM usuarios WHERE id = 9002;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM usuarios WHERE id = 9002;
ROLLBACK;
-- PRUEBA 1.11 — Usuario duplicado rechazado [error]
-- Objetivo: El nombre de usuario es único.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('1.11', 'INSERT INTO usuarios (tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES (''taller'', 2, ''Otro Juan'', ''juan'', ''x'');', 1062);
ROLLBACK;
-- PRUEBA 1.12 — SuperAdmin con rol rechazado [error]
-- Objetivo: CHECK ck_usuarios_tipo_rol: un superadmin no puede tener rol operativo.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('1.12', 'INSERT INTO usuarios (tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES (''superadmin'', 1, ''Falso SA'', ''falsosa'', ''x'');', 3819);
ROLLBACK;
-- PRUEBA 1.13 — No se puede borrar un rol en uso [error]
-- Objetivo: Integridad referencial usuarios -> roles.
-- Esperado: ERROR 1451 (clave foránea)
START TRANSACTION;
CALL sp_esperar_error('1.13', 'DELETE FROM roles WHERE nombre = ''Mecanico'';', 1451);
ROLLBACK;
-- PRUEBA 1.14 — Roles de MySQL = roles del frontend [integridad]
-- Objetivo: La tabla roles tiene exactamente Administrador (1) y Mecanico (2), los mismos del MVP; el SuperAdmin no figura.
-- Esperado: 0 filas
SELECT '1.14' AS prueba, 'integridad' AS tipo;
SELECT x.* FROM (SELECT COUNT(*) AS c, SUM(id = 1 AND nombre = 'Administrador') AS a, SUM(id = 2 AND nombre = 'Mecanico') AS m FROM roles) x WHERE NOT (x.c = 2 AND x.a = 1 AND x.m = 1);
-- PRUEBA 1.15 — Un único SuperAdmin, separado del taller [integridad]
-- Objetivo: El SuperAdmin no es dueño ni mecánico ni aparece en listas operativas.
-- Esperado: 0 filas
SELECT '1.15' AS prueba, 'integridad' AS tipo;
SELECT u.id FROM usuarios u WHERE u.tipo_cuenta = 'superadmin' AND (u.rol_id IS NOT NULL OR EXISTS (SELECT 1 FROM taller t WHERE t.admin_usuario_id = u.id) OR EXISTS (SELECT 1 FROM asignaciones_trabajo a WHERE a.mecanico_id = u.id));

-- ----------------------------------------------------------------------------
-- MÓDULO 2. TALLER
-- ----------------------------------------------------------------------------
-- PRUEBA 2.1 — Existe un único taller [integridad]
-- Objetivo: El sistema administra un solo taller.
-- Esperado: 0 filas
SELECT '2.1' AS prueba, 'integridad' AS tipo;
SELECT COUNT(*) AS cantidad FROM taller HAVING COUNT(*) <> 1;
-- PRUEBA 2.2 — Taller con su administrador (INNER JOIN) [info]
-- Objetivo: Mostrar el taller y su dueño.
-- Esperado: 1 fila: Taller Matienzo / Roberto Díaz / activo
SELECT '2.2' AS prueba, 'info' AS tipo;
SELECT t.id, t.nombre, u.nombre AS administrador, t.estado_acceso FROM taller t INNER JOIN usuarios u ON u.id = t.admin_usuario_id;
-- PRUEBA 2.3 — Segundo taller rechazado [error]
-- Objetivo: CHECK ck_taller_unico (id = 1).
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('2.3', 'INSERT INTO taller (id, nombre, admin_usuario_id) VALUES (2, ''Otro Taller'', 3);', 3819);
ROLLBACK;
-- PRUEBA 2.4 — Bloqueo y desbloqueo del taller [op]
-- Objetivo: UPDATE de estado_acceso (lo que hace el sistema al vencer la tolerancia).
-- Esperado: resultado = OK
SELECT '2.4' AS prueba;
START TRANSACTION;
UPDATE taller SET estado_acceso = 'bloqueado', bloqueado_en = NOW(), motivo_bloqueo = 'Falta de pago' WHERE id = 1;
SELECT IF(estado_acceso = 'bloqueado', 'OK', 'FALLA') AS resultado FROM taller WHERE id = 1;
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 3. CLIENTES Y VEHÍCULOS
-- ----------------------------------------------------------------------------
-- PRUEBA 3.1 — Vehículos con propietario válido [integridad]
-- Objetivo: Todo vehículo debe pertenecer a un cliente existente.
-- Esperado: 0 filas
SELECT '3.1' AS prueba, 'integridad' AS tipo;
SELECT v.id FROM vehiculos v LEFT JOIN clientes c ON c.id = v.cliente_id WHERE c.id IS NULL;
-- PRUEBA 3.2 — Patentes duplicadas [integridad]
-- Objetivo: La patente cargada es única.
-- Esperado: 0 filas
SELECT '3.2' AS prueba, 'integridad' AS tipo;
SELECT patente, COUNT(*) AS veces FROM vehiculos WHERE patente IS NOT NULL GROUP BY patente HAVING COUNT(*) > 1;
-- PRUEBA 3.3 — Clientes con sus vehículos (INNER JOIN) [info]
-- Objetivo: Listar cada vehículo con su cliente.
-- Esperado: 17 filas
SELECT '3.3' AS prueba, 'info' AS tipo;
SELECT c.id AS cliente_id, c.nombre, v.patente, v.marca, v.modelo FROM clientes c INNER JOIN vehiculos v ON v.cliente_id = c.id ORDER BY c.id, v.id;
-- PRUEBA 3.4 — Clientes sin vehículos (LEFT JOIN) [integridad]
-- Objetivo: Los clientes de demostración deben tener al menos un vehículo.
-- Esperado: 0 filas
SELECT '3.4' AS prueba, 'integridad' AS tipo;
SELECT c.id, c.nombre FROM clientes c LEFT JOIN vehiculos v ON v.cliente_id = c.id WHERE v.id IS NULL;
-- PRUEBA 3.5 — Alta de cliente con vehículo [op]
-- Objetivo: INSERT de cliente y vehículo relacionados, sin patente ni kilometraje (opcionales en el MVP).
-- Esperado: resultado = OK
SELECT '3.5' AS prueba;
START TRANSACTION;
INSERT INTO clientes (id, nombre, telefono) VALUES (9001, 'Cliente de Prueba', '381-1112233');
INSERT INTO vehiculos (id, cliente_id, patente, marca, modelo) VALUES (9001, 9001, NULL, 'Ford', 'Fiesta');
INSERT INTO vehiculos (id, cliente_id, patente, marca, modelo) VALUES (9002, 9001, NULL, 'Fiat', 'Uno');
SELECT IF(COUNT(*) = 2 AND SUM(v.kilometraje IS NULL) = 2, 'OK', 'FALLA') AS resultado FROM clientes c INNER JOIN vehiculos v ON v.cliente_id = c.id WHERE c.id = 9001;
ROLLBACK;
-- PRUEBA 3.6 — Actualizar kilometraje [op]
-- Objetivo: UPDATE de un dato del vehículo.
-- Esperado: resultado = OK
SELECT '3.6' AS prueba;
START TRANSACTION;
UPDATE vehiculos SET kilometraje = 123456 WHERE id = 1;
SELECT IF(kilometraje = 123456, 'OK', 'FALLA') AS resultado FROM vehiculos WHERE id = 1;
ROLLBACK;
-- PRUEBA 3.7 — Eliminar cliente nuevo y su vehículo [op]
-- Objetivo: DELETE en orden: primero el vehículo y luego el cliente.
-- Esperado: resultado = OK
SELECT '3.7' AS prueba;
START TRANSACTION;
INSERT INTO clientes (id, nombre) VALUES (9003, 'Borrar');
INSERT INTO vehiculos (id, cliente_id, marca) VALUES (9003, 9003, 'Renault');
DELETE FROM vehiculos WHERE id = 9003;
DELETE FROM clientes WHERE id = 9003;
SELECT IF((SELECT COUNT(*) FROM clientes WHERE id = 9003) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 3.8 — No se puede borrar un cliente con vehículos [error]
-- Objetivo: Integridad referencial clientes -> vehiculos.
-- Esperado: ERROR 1451 (clave foránea)
START TRANSACTION;
CALL sp_esperar_error('3.8', 'DELETE FROM clientes WHERE id = 1;', 1451);
ROLLBACK;
-- PRUEBA 3.9 — Patente duplicada rechazada [error]
-- Objetivo: UNIQUE uq_vehiculos_patente.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('3.9', 'INSERT INTO vehiculos (cliente_id, patente, marca) SELECT 1, patente, ''Fiat'' FROM vehiculos WHERE patente IS NOT NULL LIMIT 1;', 1062);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 4. CONSULTAS
-- ----------------------------------------------------------------------------
-- PRUEBA 4.1 — Consultas con cliente y vehículo coherentes [integridad]
-- Objetivo: Si la consulta tiene vehículo, éste debe pertenecer al cliente de la consulta.
-- Esperado: 0 filas
SELECT '4.1' AS prueba, 'integridad' AS tipo;
SELECT c.id FROM consultas c INNER JOIN vehiculos v ON v.id = c.vehiculo_id WHERE c.cliente_id IS NULL OR c.cliente_id <> v.cliente_id;
-- PRUEBA 4.2 — Detalles de consulta con consulta existente [integridad]
-- Objetivo: detalles_consultas no tiene filas huérfanas.
-- Esperado: 0 filas
SELECT '4.2' AS prueba, 'integridad' AS tipo;
SELECT d.id FROM detalles_consultas d LEFT JOIN consultas c ON c.id = d.consulta_id WHERE c.id IS NULL;
-- PRUEBA 4.3 — Consultas con cliente y vehículo (INNER JOIN) [info]
-- Objetivo: Listar las consultas registradas junto a su cliente y vehículo.
-- Esperado: 20 filas (consultas con cliente y vehículo registrados)
SELECT '4.3' AS prueba, 'info' AS tipo;
SELECT c.id, cl.nombre AS cliente, v.patente, v.marca, v.modelo, c.estado FROM consultas c INNER JOIN clientes cl ON cl.id = c.cliente_id INNER JOIN vehiculos v ON v.id = c.vehiculo_id ORDER BY c.id;
-- PRUEBA 4.4 — Solo la primera consulta de un cliente es gratuita [integridad]
-- Objetivo: Regla del MVP: las consultas repetidas no son gratuitas por defecto.
-- Esperado: 0 filas
SELECT '4.4' AS prueba, 'integridad' AS tipo;
SELECT c.id FROM consultas c WHERE c.es_gratuita = 1 AND EXISTS (SELECT 1 FROM consultas x WHERE x.cliente_id = c.cliente_id AND x.id < c.id);
-- PRUEBA 4.5 — Consultas cerradas con motivo [integridad]
-- Objetivo: Toda consulta cerrada sin trabajo debe indicar el motivo.
-- Esperado: 0 filas
SELECT '4.5' AS prueba, 'integridad' AS tipo;
SELECT id FROM consultas WHERE estado = 'cerrada' AND (motivo_cierre IS NULL OR motivo_cierre = '');
-- PRUEBA 4.6 — Consultas aprobadas tienen presupuesto aceptado [integridad]
-- Objetivo: Una consulta aprobada debe tener su presupuesto aceptado.
-- Esperado: 0 filas
SELECT '4.6' AS prueba, 'integridad' AS tipo;
SELECT c.id FROM consultas c LEFT JOIN presupuestos p ON p.consulta_id = c.id AND p.estado = 'aceptado' WHERE c.estado = 'aprobada' AND p.id IS NULL;
-- PRUEBA 4.7 — Alta de consulta con revisión técnica [op]
-- Objetivo: INSERT de consulta y de su revisión (varias filas de detalle) y su importe estimado.
-- Esperado: resultado = OK
SELECT '4.7' AS prueba;
START TRANSACTION;
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, contacto_telefono, motivo, descripcion_problema, estado, es_gratuita, creado_por)
VALUES (9001, 1, 1, 'Carlos Gómez', '381-0000', 'Ruido al frenar', 'Ruido al frenar y pedal blando', 'abierta', 0, 2);
INSERT INTO detalles_consultas (consulta_id, descripcion, tipo, registrado_por) VALUES
 (9001, 'Pastillas gastadas', 'verificado', 2), (9001, 'Pastillas delanteras', 'repuestos_necesarios', 2), (9001, 'Cambio de pastillas', 'trabajo_recomendado', 2);
UPDATE consultas SET observaciones_inspeccion = 'Discos en buen estado', importe_estimado = 45000 WHERE id = 9001;
SELECT IF(COUNT(*) = 3 AND MAX(c.importe_estimado) = 45000, 'OK', 'FALLA') AS resultado FROM consultas c INNER JOIN detalles_consultas d ON d.consulta_id = c.id WHERE c.id = 9001;
ROLLBACK;
-- PRUEBA 4.8 — Cierre de consulta sin trabajo [op]
-- Objetivo: UPDATE a estado cerrada con motivo.
-- Esperado: resultado = OK
SELECT '4.8' AS prueba;
START TRANSACTION;
UPDATE consultas SET estado = 'cerrada', motivo_cierre = 'El cliente no continuó' WHERE id = 1;
SELECT IF(estado = 'cerrada' AND motivo_cierre IS NOT NULL, 'OK', 'FALLA') AS resultado FROM consultas WHERE id = 1;
ROLLBACK;
-- PRUEBA 4.9 — Eliminar consulta y sus detalles [op]
-- Objetivo: DELETE de una consulta nueva: los detalles se eliminan en cascada.
-- Esperado: resultado = OK
SELECT '4.9' AS prueba;
START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9002, 'Persona', 'Prueba', 2);
INSERT INTO detalles_consultas (consulta_id, descripcion, registrado_por) VALUES (9002, 'x', 2);
DELETE FROM consultas WHERE id = 9002;
SELECT IF((SELECT COUNT(*) FROM detalles_consultas WHERE consulta_id = 9002) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 4.10 — Cobro "cobrar" sin importe rechazado [error]
-- Objetivo: CHECK ck_consultas_cobro.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('4.10', 'UPDATE consultas SET cobro_decision = ''cobrar'', cobro_importe = NULL WHERE id = 1;', 3819);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 5. PRESUPUESTOS
-- ----------------------------------------------------------------------------
-- PRUEBA 5.1 — Un presupuesto por consulta [integridad]
-- Objetivo: Cada consulta tiene como máximo un presupuesto.
-- Esperado: 0 filas
SELECT '5.1' AS prueba, 'integridad' AS tipo;
SELECT consulta_id, COUNT(*) AS cantidad FROM presupuestos GROUP BY consulta_id HAVING COUNT(*) > 1;
-- PRUEBA 5.2 — Total calculado = suma de los detalles [integridad]
-- Objetivo: total_calculado coincide con SUM(monto) de sus detalles.
-- Esperado: 0 filas
SELECT '5.2' AS prueba, 'integridad' AS tipo;
SELECT p.id, p.total_calculado, COALESCE(SUM(d.monto), 0) AS suma FROM presupuestos p LEFT JOIN detalles_presupuestos d ON d.presupuesto_id = p.id GROUP BY p.id, p.total_calculado HAVING p.total_calculado <> COALESCE(SUM(d.monto), 0);
-- PRUEBA 5.3 — Presupuestos enviados/aceptados con fecha de envío [integridad]
-- Objetivo: Un presupuesto enviado o aceptado debe tener fecha_envio.
-- Esperado: 0 filas
SELECT '5.3' AS prueba, 'integridad' AS tipo;
SELECT id FROM presupuestos WHERE estado IN ('enviado','aceptado','rechazado') AND fecha_envio IS NULL;
-- PRUEBA 5.4 — Presupuesto con detalles (INNER JOIN) [info]
-- Objetivo: Listar presupuestos con la cantidad de líneas y su total.
-- Esperado: 12 filas
SELECT '5.4' AS prueba, 'info' AS tipo;
SELECT p.numero, p.estado, COUNT(d.id) AS lineas, SUM(d.monto) AS total FROM presupuestos p INNER JOIN detalles_presupuestos d ON d.presupuesto_id = p.id GROUP BY p.id, p.numero, p.estado ORDER BY p.id;
-- PRUEBA 5.5 — Presupuestos aceptados con orden / órdenes con presupuesto aceptado [integridad]
-- Objetivo: Una orden solo nace de un presupuesto aceptado.
-- Esperado: 0 filas
SELECT '5.5' AS prueba, 'integridad' AS tipo;
SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id WHERE p.estado <> 'aceptado';
-- PRUEBA 5.6 — Alta de presupuesto con detalles [op]
-- Objetivo: INSERT de presupuesto y líneas; el monto se calcula solo.
-- Esperado: resultado = OK
SELECT '5.6' AS prueba;
START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9003, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, estado, valido_hasta, creado_por) VALUES (9001, 9003, 'PRE-9001', 'borrador', '2026-12-31', 2);
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, tipo, cantidad, precio_unitario) VALUES (9001, 'Filtro', 'repuesto', 2, 1500.50), (9001, 'Mano de obra', 'mano_obra', 1, 8000);
UPDATE presupuestos SET total_calculado = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9001), precio_final = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9001) WHERE id = 9001;
SELECT IF(total_calculado = 11001.00 AND precio_final = 11001.00, 'OK', 'FALLA') AS resultado FROM presupuestos WHERE id = 9001;
ROLLBACK;
-- PRUEBA 5.7 — Aceptación de un presupuesto [op]
-- Objetivo: UPDATE a aceptado con fecha de respuesta.
-- Esperado: resultado = OK
SELECT '5.7' AS prueba;
START TRANSACTION;
UPDATE presupuestos SET estado = 'aceptado', fecha_respuesta = NOW() WHERE id = (SELECT id FROM (SELECT id FROM presupuestos WHERE estado = 'enviado' LIMIT 1) x);
SELECT IF(COUNT(*) >= 1, 'OK', 'FALLA') AS resultado FROM presupuestos WHERE estado = 'aceptado' AND fecha_respuesta >= CURDATE();
ROLLBACK;
-- PRUEBA 5.8 — Eliminar presupuesto: sus detalles se borran en cascada [op]
-- Objetivo: DELETE con ON DELETE CASCADE.
-- Esperado: resultado = OK
SELECT '5.8' AS prueba;
START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9004, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, creado_por) VALUES (9002, 9004, 'PRE-9002', 2);
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario) VALUES (9002, 'x', 1, 100);
DELETE FROM presupuestos WHERE id = 9002;
SELECT IF((SELECT COUNT(*) FROM detalles_presupuestos WHERE presupuesto_id = 9002) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 5.9 — Segundo presupuesto para una consulta rechazado [error]
-- Objetivo: UNIQUE uq_presupuestos_consulta.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('5.9', 'INSERT INTO presupuestos (consulta_id, numero, creado_por) VALUES (1, ''PRE-9999'', 2);', 1062);
ROLLBACK;
-- PRUEBA 5.10 — Línea con cantidad 0 rechazada [error]
-- Objetivo: CHECK ck_detpres_valores.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('5.10', 'INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario) VALUES (1, ''x'', 0, 10);', 3819);
ROLLBACK;
-- PRUEBA 5.11 — No se puede escribir la columna calculada monto [error]
-- Objetivo: monto es GENERATED: no admite valores manuales.
-- Esperado: ERROR 3105 (columna generada)
START TRANSACTION;
CALL sp_esperar_error('5.11', 'INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario, monto) VALUES (1, ''x'', 1, 10, 999);', 3105);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 6. ÓRDENES DE TRABAJO
-- ----------------------------------------------------------------------------
-- PRUEBA 6.1 — Una orden por presupuesto [integridad]
-- Objetivo: No puede haber dos órdenes del mismo presupuesto.
-- Esperado: 0 filas
SELECT '6.1' AS prueba, 'integridad' AS tipo;
SELECT presupuesto_id, COUNT(*) FROM ordenes_trabajo GROUP BY presupuesto_id HAVING COUNT(*) > 1;
-- PRUEBA 6.2 — Cliente y vehículo de la orden coinciden con la consulta [integridad]
-- Objetivo: La orden refleja el cliente y vehículo de su consulta.
-- Esperado: 0 filas
SELECT '6.2' AS prueba, 'integridad' AS tipo;
SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id INNER JOIN consultas c ON c.id = p.consulta_id WHERE o.cliente_id <> c.cliente_id OR o.vehiculo_id <> c.vehiculo_id;
-- PRUEBA 6.3 — Precio final de la orden = precio final del presupuesto [integridad]
-- Objetivo: El precio de la orden no se desvía del presupuesto aceptado. El % de comisión se define en la orden (el dueño lo puede ajustar mientras no haya comisión registrada), por eso no se compara.
-- Esperado: 0 filas
SELECT '6.3' AS prueba, 'integridad' AS tipo;
SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id WHERE o.precio_final <> p.precio_final;
-- PRUEBA 6.4 — Estados y mecánico [integridad]
-- Objetivo: sin_asignar/cancelado pueden no tener mecánico; ofrecido, aceptado, en_proceso y finalizado sí.
-- Esperado: 0 filas
SELECT '6.4' AS prueba, 'integridad' AS tipo;
SELECT id, estado FROM ordenes_trabajo WHERE (estado IN ('ofrecido','aceptado','en_proceso','finalizado') AND mecanico_id IS NULL) OR (estado = 'sin_asignar' AND mecanico_id IS NOT NULL);
-- PRUEBA 6.5 — Último estado del historial = estado de la orden [integridad]
-- Objetivo: historial_estados_ordenes registra cada cambio y termina en el estado actual.
-- Esperado: 0 filas
SELECT '6.5' AS prueba, 'integridad' AS tipo;
SELECT o.id, o.estado, h.estado_nuevo FROM ordenes_trabajo o INNER JOIN historial_estados_ordenes h ON h.id = (SELECT MAX(x.id) FROM historial_estados_ordenes x WHERE x.orden_id = o.id) WHERE h.estado_nuevo <> o.estado;
-- PRUEBA 6.6 — Fechas de inicio y fin según estado [integridad]
-- Objetivo: en_proceso/finalizado tienen fecha_inicio; finalizado tiene fecha_fin.
-- Esperado: 0 filas
SELECT '6.6' AS prueba, 'integridad' AS tipo;
SELECT id, estado FROM ordenes_trabajo WHERE (estado IN ('en_proceso','finalizado') AND fecha_inicio IS NULL) OR (estado = 'finalizado' AND fecha_fin IS NULL);
-- PRUEBA 6.7 — Órdenes con cliente, vehículo y mecánico (INNER JOIN) [info]
-- Objetivo: Listado operativo de órdenes asignadas.
-- Esperado: 11 filas
SELECT '6.7' AS prueba, 'info' AS tipo;
SELECT o.numero, cl.nombre AS cliente, v.marca, v.modelo, u.nombre AS mecanico, o.estado FROM ordenes_trabajo o INNER JOIN clientes cl ON cl.id = o.cliente_id INNER JOIN vehiculos v ON v.id = o.vehiculo_id INNER JOIN usuarios u ON u.id = o.mecanico_id ORDER BY o.id;
-- PRUEBA 6.8 — Avances con orden y autor válidos [integridad]
-- Objetivo: avances_ordenes no tiene filas huérfanas.
-- Esperado: 0 filas
SELECT '6.8' AS prueba, 'integridad' AS tipo;
SELECT a.id FROM avances_ordenes a LEFT JOIN ordenes_trabajo o ON o.id = a.orden_id LEFT JOIN usuarios u ON u.id = a.usuario_id WHERE o.id IS NULL OR u.id IS NULL;
-- PRUEBA 6.9 — Avances registrados (INNER JOIN) [info]
-- Objetivo: Listar los avances con su orden y autor.
-- Esperado: 10 filas
SELECT '6.9' AS prueba, 'info' AS tipo;
SELECT o.numero, u.nombre, a.texto, a.creado_en FROM avances_ordenes a INNER JOIN ordenes_trabajo o ON o.id = a.orden_id INNER JOIN usuarios u ON u.id = a.usuario_id ORDER BY a.id;
-- PRUEBA 6.10 — Cambio de estado con historial y avance [op]
-- Objetivo: UPDATE de estado + INSERT en historial y avance.
-- Esperado: resultado = OK
SELECT '6.10' AS prueba;
START TRANSACTION;
UPDATE ordenes_trabajo SET estado = 'en_proceso', fecha_inicio = NOW() WHERE id = 2;
INSERT INTO historial_estados_ordenes (orden_id, estado_anterior, estado_nuevo, cambiado_por) VALUES (2, 'ofrecido', 'en_proceso', 3);
INSERT INTO avances_ordenes (orden_id, usuario_id, texto) VALUES (2, 3, 'Se inició el desarme');
SELECT IF(o.estado = 'en_proceso' AND (SELECT COUNT(*) FROM avances_ordenes WHERE orden_id = 2) >= 1, 'OK', 'FALLA') AS resultado FROM ordenes_trabajo o WHERE o.id = 2;
ROLLBACK;
-- PRUEBA 6.11 — Eliminar orden nueva: historial y avances en cascada [op]
-- Objetivo: DELETE con cascada.
-- Esperado: resultado = OK
SELECT '6.11' AS prueba;
START TRANSACTION;
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, motivo, creado_por) VALUES (9005, 1, 1, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, estado, creado_por) VALUES (9003, 9005, 'PRE-9003', 'aceptado', 2);
INSERT INTO ordenes_trabajo (id, numero, presupuesto_id, cliente_id, vehiculo_id, descripcion, precio_final) VALUES (9001, 'OT-9001', 9003, 1, 1, 'Prueba', 100);
INSERT INTO historial_estados_ordenes (orden_id, estado_nuevo, cambiado_por) VALUES (9001, 'sin_asignar', 2);
INSERT INTO avances_ordenes (orden_id, usuario_id, texto) VALUES (9001, 2, 'x');
DELETE FROM ordenes_trabajo WHERE id = 9001;
SELECT IF((SELECT COUNT(*) FROM historial_estados_ordenes WHERE orden_id = 9001) + (SELECT COUNT(*) FROM avances_ordenes WHERE orden_id = 9001) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 6.12 — Segunda orden para un presupuesto rechazada [error]
-- Objetivo: UNIQUE uq_ordenes_presupuesto.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('6.12', 'INSERT INTO ordenes_trabajo (numero, presupuesto_id, cliente_id, vehiculo_id, descripcion, precio_final) VALUES (''OT-9998'', 1, 1, 1, ''dup'', 1);', 1062);
ROLLBACK;
-- PRUEBA 6.13 — Comisión mayor a 100 % rechazada [error]
-- Objetivo: CHECK ck_ordenes_importes.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('6.13', 'UPDATE ordenes_trabajo SET comision_pct = 150 WHERE id = 1;', 3819);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 7. ASIGNACIONES
-- ----------------------------------------------------------------------------
-- PRUEBA 7.1 — Asignación activa coincide con el mecánico de la orden [integridad]
-- Objetivo: La última asignación ofrecida/aceptada es la del mecánico de la orden.
-- Esperado: 0 filas
SELECT '7.1' AS prueba, 'integridad' AS tipo;
SELECT o.id FROM ordenes_trabajo o INNER JOIN asignaciones_trabajo a ON a.id = (SELECT MAX(x.id) FROM asignaciones_trabajo x WHERE x.orden_id = o.id) WHERE o.mecanico_id IS NOT NULL AND a.mecanico_id <> o.mecanico_id;
-- PRUEBA 7.2 — Una sola asignación activa por orden [integridad]
-- Objetivo: No más de una asignación ofrecida/aceptada por orden.
-- Esperado: 0 filas
SELECT '7.2' AS prueba, 'integridad' AS tipo;
SELECT orden_id, COUNT(*) FROM asignaciones_trabajo WHERE resultado IN ('ofrecida','aceptada') GROUP BY orden_id HAVING COUNT(*) > 1;
-- PRUEBA 7.3 — Rechazos con motivo [integridad]
-- Objetivo: Una asignación rechazada debe tener motivo_rechazo.
-- Esperado: 0 filas
SELECT '7.3' AS prueba, 'integridad' AS tipo;
SELECT id FROM asignaciones_trabajo WHERE resultado = 'rechazada' AND (motivo_rechazo IS NULL OR motivo_rechazo = '');
-- PRUEBA 7.4 — Asignaciones con orden y mecánico (INNER JOIN) [info]
-- Objetivo: Listar las asignaciones.
-- Esperado: 11 filas
SELECT '7.4' AS prueba, 'info' AS tipo;
SELECT o.numero, u.nombre AS mecanico, a.resultado, a.creado_en, a.resuelto_en FROM asignaciones_trabajo a INNER JOIN ordenes_trabajo o ON o.id = a.orden_id INNER JOIN usuarios u ON u.id = a.mecanico_id ORDER BY a.id;
-- PRUEBA 7.5 — Rechazo y reasignación [op]
-- Objetivo: El mecánico rechaza con motivo y se reasigna a otro.
-- Esperado: resultado = OK
SELECT '7.5' AS prueba;
START TRANSACTION;
UPDATE asignaciones_trabajo SET resultado = 'rechazada', motivo_rechazo = 'Sin disponibilidad', resuelto_en = NOW() WHERE orden_id = 2;
UPDATE ordenes_trabajo SET estado = 'sin_asignar', mecanico_id = NULL WHERE id = 2;
INSERT INTO asignaciones_trabajo (orden_id, mecanico_id, asignado_por, resultado) VALUES (2, 4, 2, 'ofrecida');
UPDATE ordenes_trabajo SET estado = 'ofrecido', mecanico_id = 4 WHERE id = 2;
SELECT IF((SELECT COUNT(*) FROM asignaciones_trabajo WHERE orden_id = 2) = 2 AND (SELECT mecanico_id FROM ordenes_trabajo WHERE id = 2) = 4, 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 7.6 — Asignar a un mecánico inexistente rechazado [error]
-- Objetivo: FK fk_asig_mecanico.
-- Esperado: ERROR 1452 (clave foránea)
START TRANSACTION;
CALL sp_esperar_error('7.6', 'INSERT INTO asignaciones_trabajo (orden_id, mecanico_id, asignado_por) VALUES (2, 99999, 2);', 1452);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 8. PAGOS DE CLIENTES
-- ----------------------------------------------------------------------------
-- PRUEBA 8.1 — Pagos de trabajo con orden; venta de mostrador sin orden [integridad]
-- Objetivo: Coherencia entre tipo de pago y orden.
-- Esperado: 0 filas
SELECT '8.1' AS prueba, 'integridad' AS tipo;
SELECT id FROM pagos_clientes WHERE (tipo = 'trabajo' AND orden_id IS NULL) OR (tipo = 'venta_mostrador' AND orden_id IS NOT NULL);
-- PRUEBA 8.2 — Monto del pago = suma de sus medios [integridad]
-- Objetivo: El monto de cada pago coincide con sus detalles.
-- Esperado: 0 filas
SELECT '8.2' AS prueba, 'integridad' AS tipo;
SELECT p.id FROM pagos_clientes p LEFT JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id GROUP BY p.id, p.monto HAVING p.monto <> COALESCE(SUM(d.importe), 0);
-- PRUEBA 8.3 — Método combinado ↔ dos medios [integridad]
-- Objetivo: metodo = combinado solo si tiene 2 o más medios; si no, el medio coincide con metodo.
-- Esperado: 0 filas
SELECT '8.3' AS prueba, 'integridad' AS tipo;
SELECT p.id FROM pagos_clientes p INNER JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id GROUP BY p.id, p.metodo HAVING (p.metodo = 'combinado' AND COUNT(*) < 2) OR (p.metodo <> 'combinado' AND (COUNT(*) <> 1 OR MAX(d.medio) <> p.metodo));
-- PRUEBA 8.4 — Cliente del pago = cliente de la orden [integridad]
-- Objetivo: Un pago de trabajo pertenece al cliente de esa orden.
-- Esperado: 0 filas
SELECT '8.4' AS prueba, 'integridad' AS tipo;
SELECT p.id FROM pagos_clientes p INNER JOIN ordenes_trabajo o ON o.id = p.orden_id WHERE p.cliente_id <> o.cliente_id;
-- PRUEBA 8.5 — Lo pagado no supera el precio de la orden [integridad]
-- Objetivo: SUM(pagos) <= precio_final.
-- Esperado: 0 filas
SELECT '8.5' AS prueba, 'integridad' AS tipo;
SELECT o.id, o.precio_final, SUM(p.monto) AS pagado FROM ordenes_trabajo o INNER JOIN pagos_clientes p ON p.orden_id = o.id GROUP BY o.id, o.precio_final HAVING SUM(p.monto) > o.precio_final;
-- PRUEBA 8.6 — Saldo por orden (INNER JOIN) [info]
-- Objetivo: Precio, pagado y saldo de las órdenes con pagos.
-- Esperado: al menos 1 fila
SELECT '8.6' AS prueba, 'info' AS tipo;
SELECT o.numero, c.nombre, o.precio_final, SUM(p.monto) AS pagado, o.precio_final - SUM(p.monto) AS saldo FROM ordenes_trabajo o INNER JOIN pagos_clientes p ON p.orden_id = o.id INNER JOIN clientes c ON c.id = o.cliente_id GROUP BY o.id, o.numero, c.nombre, o.precio_final ORDER BY o.id;
-- PRUEBA 8.7 — Registrar un pago combinado [op]
-- Objetivo: INSERT de pago + dos medios; la suma coincide.
-- Esperado: resultado = OK
SELECT '8.7' AS prueba;
START TRANSACTION;
INSERT INTO pagos_clientes (id, tipo, orden_id, cliente_id, monto, metodo, registrado_por) VALUES (9001, 'trabajo', 2, (SELECT cliente_id FROM ordenes_trabajo WHERE id = 2), 10000, 'combinado', 2);
INSERT INTO detalles_pagos_clientes (pago_cliente_id, medio, importe, referencia) VALUES (9001, 'efectivo', 4000, NULL), (9001, 'transferencia', 6000, 'TRF-1');
SELECT IF(p.monto = SUM(d.importe), 'OK', 'FALLA') AS resultado FROM pagos_clientes p INNER JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id WHERE p.id = 9001 GROUP BY p.id, p.monto;
ROLLBACK;
-- PRUEBA 8.8 — Corregir el monto de un pago (UPDATE) [op]
-- Objetivo: Modificación de observaciones del pago.
-- Esperado: resultado = OK
SELECT '8.8' AS prueba;
START TRANSACTION;
UPDATE pagos_clientes SET observaciones = 'Corregido' WHERE id = 1;
SELECT IF(observaciones = 'Corregido', 'OK', 'FALLA') AS resultado FROM pagos_clientes WHERE id = 1;
ROLLBACK;
-- PRUEBA 8.9 — Eliminar un pago: sus medios se borran en cascada [op]
-- Objetivo: DELETE con cascada.
-- Esperado: resultado = OK
SELECT '8.9' AS prueba;
START TRANSACTION;
DELETE FROM pagos_clientes WHERE id = 1;
SELECT IF((SELECT COUNT(*) FROM detalles_pagos_clientes WHERE pago_cliente_id = 1) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 8.10 — Pago con monto 0 rechazado [error]
-- Objetivo: CHECK ck_pagcli_monto.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('8.10', 'INSERT INTO pagos_clientes (tipo, cliente_id, monto, registrado_por) VALUES (''venta_mostrador'', 1, 0, 2);', 3819);
ROLLBACK;
-- PRUEBA 8.11 — Medio repetido en un pago rechazado [error]
-- Objetivo: UNIQUE (pago, medio).
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('8.11', 'INSERT INTO detalles_pagos_clientes (pago_cliente_id, medio, importe) SELECT pago_cliente_id, medio, 1 FROM detalles_pagos_clientes LIMIT 1;', 1062);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 9. CATÁLOGO Y STOCK
-- ----------------------------------------------------------------------------
-- PRUEBA 9.1 — Artículos con categoría [integridad]
-- Objetivo: Todo artículo del MVP tiene categoría existente.
-- Esperado: 0 filas
SELECT '9.1' AS prueba, 'integridad' AS tipo;
SELECT i.id FROM catalogo_items i LEFT JOIN categorias_catalogo c ON c.id = i.categoria_id WHERE i.categoria_id IS NOT NULL AND c.id IS NULL;
-- PRUEBA 9.2 — Movimientos confirmados con responsable [integridad]
-- Objetivo: Un movimiento confirmado tiene resuelto_por.
-- Esperado: 0 filas
SELECT '9.2' AS prueba, 'integridad' AS tipo;
SELECT id FROM movimientos_stock WHERE estado = 'confirmado' AND resuelto_por IS NULL;
-- PRUEBA 9.3 — Salidas por orden con orden existente [integridad]
-- Objetivo: movimientos_stock.orden_id apunta a órdenes reales.
-- Esperado: 0 filas
SELECT '9.3' AS prueba, 'integridad' AS tipo;
SELECT m.id FROM movimientos_stock m LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.orden_id IS NOT NULL AND o.id IS NULL;
-- PRUEBA 9.4 — Artículos con stock bajo [info]
-- Objetivo: Artículos con cantidad <= stock mínimo (alerta de stock).
-- Esperado: al menos 1 fila
SELECT '9.4' AS prueba, 'info' AS tipo;
SELECT id, codigo, nombre, cantidad, stock_minimo FROM catalogo_items WHERE activo = 1 AND cantidad <= stock_minimo ORDER BY cantidad;
-- PRUEBA 9.5 — Stock actual = entradas − salidas confirmadas [integridad]
-- Objetivo: La cantidad del catálogo coincide con la suma de sus movimientos.
-- Esperado: 0 filas
SELECT '9.5' AS prueba, 'integridad' AS tipo;
SELECT i.id, i.codigo, i.cantidad, COALESCE(SUM(CASE WHEN m.tipo = 'entrada' THEN m.cantidad ELSE -m.cantidad END), 0) AS segun_movimientos FROM catalogo_items i LEFT JOIN movimientos_stock m ON m.catalogo_item_id = i.id AND m.estado = 'confirmado' GROUP BY i.id, i.codigo, i.cantidad HAVING i.cantidad <> COALESCE(SUM(CASE WHEN m.tipo = 'entrada' THEN m.cantidad ELSE -m.cantidad END), 0);
-- PRUEBA 9.6 — Historial de precios coherente [integridad]
-- Objetivo: El último precio del historial coincide con el precio actual del artículo.
-- Esperado: 0 filas
SELECT '9.6' AS prueba, 'integridad' AS tipo;
SELECT i.id FROM catalogo_items i INNER JOIN historial_precios_catalogo h ON h.id = (SELECT MAX(x.id) FROM historial_precios_catalogo x WHERE x.catalogo_item_id = i.id) WHERE h.precio_compra_nuevo <> i.precio_compra OR h.precio_venta_nuevo <> i.precio_venta;
-- PRUEBA 9.7 — Artículos con su categoría (INNER JOIN) [info]
-- Objetivo: Listado del catálogo.
-- Esperado: 17 filas
SELECT '9.7' AS prueba, 'info' AS tipo;
SELECT c.nombre AS categoria, i.codigo, i.nombre, i.marca, i.cantidad, i.precio_venta FROM catalogo_items i INNER JOIN categorias_catalogo c ON c.id = i.categoria_id ORDER BY c.nombre, i.nombre;
-- PRUEBA 9.8 — Registrar salida de stock por una orden [op]
-- Objetivo: INSERT del movimiento y UPDATE de la cantidad.
-- Esperado: resultado = OK
SELECT '9.8' AS prueba;
START TRANSACTION;
SET @antes = (SELECT cantidad FROM catalogo_items WHERE id = 1);
INSERT INTO movimientos_stock (catalogo_item_id, tipo, cantidad, estado, motivo, orden_id, solicitado_por, resuelto_por) VALUES (1, 'salida', 2, 'confirmado', 'Usado en OT-0003', 3, 3, 3);
UPDATE catalogo_items SET cantidad = cantidad - 2 WHERE id = 1;
SELECT IF(cantidad = @antes - 2, 'OK', 'FALLA') AS resultado FROM catalogo_items WHERE id = 1;
ROLLBACK;
-- PRUEBA 9.9 — Eliminar un artículo sin movimientos [op]
-- Objetivo: DELETE de un artículo nuevo.
-- Esperado: resultado = OK
SELECT '9.9' AS prueba;
START TRANSACTION;
INSERT INTO catalogo_items (id, tipo, nombre, codigo) VALUES (9001, 'repuesto', 'Temporal', 'TMP-1');
DELETE FROM catalogo_items WHERE id = 9001;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM catalogo_items WHERE id = 9001;
ROLLBACK;
-- PRUEBA 9.10 — Stock negativo rechazado [error]
-- Objetivo: CHECK ck_catalogo_stock.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('9.10', 'UPDATE catalogo_items SET cantidad = cantidad - 100000 WHERE id = 1;', 3819);
ROLLBACK;
-- PRUEBA 9.11 — Código de artículo duplicado rechazado [error]
-- Objetivo: UNIQUE uq_catalogo_codigo.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('9.11', 'INSERT INTO catalogo_items (tipo, nombre, codigo) SELECT ''repuesto'', ''Copia'', codigo FROM catalogo_items WHERE codigo IS NOT NULL LIMIT 1;', 1062);
ROLLBACK;
-- PRUEBA 9.12 — Movimiento sin artículo ni descripción rechazado [error]
-- Objetivo: CHECK ck_movstock_descripcion.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('9.12', 'INSERT INTO movimientos_stock (tipo, cantidad, motivo, solicitado_por) VALUES (''salida'', 1, ''x'', 2);', 3819);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 10. MOVIMIENTOS DE MECÁNICOS
-- ----------------------------------------------------------------------------
-- PRUEBA 10.1 — Movimientos de usuarios con rol Mecánico [integridad]
-- Objetivo: Solo mecánicos tienen movimientos.
-- Esperado: 0 filas
SELECT '10.1' AS prueba, 'integridad' AS tipo;
SELECT m.id FROM movimientos_mecanicos m INNER JOIN usuarios u ON u.id = m.mecanico_id INNER JOIN roles r ON r.id = u.rol_id WHERE r.nombre <> 'Mecanico';
-- PRUEBA 10.2 — Comisión con orden finalizada del mismo mecánico [integridad]
-- Objetivo: Toda comisión corresponde a una orden finalizada de ese mecánico.
-- Esperado: 0 filas
SELECT '10.2' AS prueba, 'integridad' AS tipo;
SELECT m.id FROM movimientos_mecanicos m LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.tipo = 'comision' AND (o.id IS NULL OR o.estado <> 'finalizado' OR o.mecanico_id <> m.mecanico_id);
-- PRUEBA 10.3 — Comisión = mano de obra × comision_pct ÷ 100 (sin repuestos) [integridad]
-- Objetivo: La fórmula documentada: la base es SOLO la suma de las líneas de tipo mano_obra del presupuesto de la orden.
-- Esperado: 0 filas
SELECT '10.3' AS prueba, 'integridad' AS tipo;
SELECT x.id, x.monto, x.esperado FROM (SELECT m.id, m.monto, ROUND(COALESCE((SELECT SUM(d.monto) FROM detalles_presupuestos d WHERE d.presupuesto_id = o.presupuesto_id AND d.tipo = 'mano_obra'), 0) * o.comision_pct / 100, 2) AS esperado
 FROM movimientos_mecanicos m INNER JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.tipo = 'comision') x WHERE x.monto <> x.esperado;
-- PRUEBA 10.4 — Movimientos con mecánico y orden (INNER JOIN) [info]
-- Objetivo: Listado de movimientos.
-- Esperado: 7 filas (5 comisiones y 2 adelantos)
SELECT '10.4' AS prueba, 'info' AS tipo;
SELECT u.nombre, m.tipo, m.monto, o.numero, m.fecha FROM movimientos_mecanicos m INNER JOIN usuarios u ON u.id = m.mecanico_id LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id ORDER BY m.id;
-- PRUEBA 10.5 — Registrar un adelanto [op]
-- Objetivo: INSERT de un adelanto.
-- Esperado: resultado = OK
SELECT '10.5' AS prueba;
START TRANSACTION;
INSERT INTO movimientos_mecanicos (id, mecanico_id, tipo, monto, registrado_por, descripcion) VALUES (9001, 3, 'adelanto', 2500, 2, 'Prueba');
SELECT IF(COUNT(*) = 1, 'OK', 'FALLA') AS resultado FROM movimientos_mecanicos WHERE id = 9001 AND orden_id IS NULL;
ROLLBACK;
-- PRUEBA 10.6 — Movimiento con monto 0 rechazado [error]
-- Objetivo: CHECK ck_movmec_monto.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('10.6', 'INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, registrado_por) VALUES (3, ''adelanto'', 0, 2);', 3819);
ROLLBACK;
-- PRUEBA 10.7 — Calcular y registrar una comisión sobre la mano de obra [op]
-- Objetivo: Calcula en SQL la comisión de una orden finalizada sin comisión (30 % sobre la mano de obra) y la registra; comprueba que NO se calcula sobre el precio total.
-- Esperado: resultado = OK
SELECT '10.7' AS prueba;
START TRANSACTION;
SET @oid = (SELECT o.id FROM ordenes_trabajo o WHERE o.estado = 'finalizado' AND NOT EXISTS (SELECT 1 FROM movimientos_mecanicos m WHERE m.orden_id = o.id) ORDER BY o.id LIMIT 1);
SET @mano = (SELECT SUM(d.monto) FROM detalles_presupuestos d INNER JOIN ordenes_trabajo o ON o.presupuesto_id = d.presupuesto_id WHERE o.id = @oid AND d.tipo = 'mano_obra');
SET @total = (SELECT precio_final FROM ordenes_trabajo WHERE id = @oid);
INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por, fecha, descripcion)
 SELECT mecanico_id, 'comision', ROUND(@mano * comision_pct / 100, 2), id, 2, fecha_fin, 'Comisión de prueba' FROM ordenes_trabajo WHERE id = @oid;
SELECT IF(m.monto = ROUND(@mano * o.comision_pct / 100, 2) AND m.monto <> ROUND(@total * o.comision_pct / 100, 2) AND m.monto > 0, 'OK', 'FALLA') AS resultado
FROM movimientos_mecanicos m INNER JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.orden_id = @oid AND m.tipo = 'comision';
ROLLBACK;
-- PRUEBA 10.8 — Segunda comisión para la misma orden rechazada [error]
-- Objetivo: UNIQUE uq_movmec_orden_tipo: una sola comisión por orden.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('10.8', 'INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por) SELECT mecanico_id, ''comision'', 1, orden_id, 2 FROM movimientos_mecanicos WHERE tipo = ''comision'' LIMIT 1;', 1062);
ROLLBACK;
-- PRUEBA 10.9 — Comisión sin orden / adelanto con orden rechazados [error]
-- Objetivo: CHECK ck_movmec_tipo_orden.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('10.9', 'INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por) VALUES (3, ''comision'', 100, NULL, 2);', 3819);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 11. LIQUIDACIONES
-- ----------------------------------------------------------------------------
-- PRUEBA 11.1 — Total a pagar = comisiones − adelantos [integridad]
-- Objetivo: Cálculo de la liquidación.
-- Esperado: 0 filas
SELECT '11.1' AS prueba, 'integridad' AS tipo;
SELECT id FROM liquidaciones_mecanicos WHERE total_a_pagar <> total_comisiones - total_adelantos;
-- PRUEBA 11.2 — Totales = suma de los detalles [integridad]
-- Objetivo: Comisiones y adelantos de la cabecera coinciden con sus detalles.
-- Esperado: 0 filas
SELECT '11.2' AS prueba, 'integridad' AS tipo;
SELECT l.id FROM liquidaciones_mecanicos l LEFT JOIN detalles_liquidaciones_mecanicos d ON d.liquidacion_id = l.id LEFT JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id WHERE l.estado <> 'anulada' GROUP BY l.id, l.total_comisiones, l.total_adelantos HAVING l.total_comisiones <> COALESCE(SUM(CASE WHEN m.tipo = 'comision' THEN d.importe_incluido END), 0) OR l.total_adelantos <> COALESCE(SUM(CASE WHEN m.tipo = 'adelanto' THEN d.importe_incluido END), 0);
-- PRUEBA 11.3 — Movimientos del mismo mecánico y dentro del período [integridad]
-- Objetivo: Los movimientos liquidados son del mecánico y de las fechas de la liquidación.
-- Esperado: 0 filas
SELECT '11.3' AS prueba, 'integridad' AS tipo;
SELECT d.id FROM detalles_liquidaciones_mecanicos d INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id INNER JOIN liquidaciones_mecanicos l ON l.id = d.liquidacion_id WHERE m.mecanico_id <> l.mecanico_id OR DATE(m.fecha) NOT BETWEEN l.periodo_desde AND l.periodo_hasta;
-- PRUEBA 11.4 — Un movimiento en una sola liquidación [integridad]
-- Objetivo: Ningún movimiento aparece en dos liquidaciones.
-- Esperado: 0 filas
SELECT '11.4' AS prueba, 'integridad' AS tipo;
SELECT movimiento_mecanico_id, COUNT(*) FROM detalles_liquidaciones_mecanicos GROUP BY movimiento_mecanico_id HAVING COUNT(*) > 1;
-- PRUEBA 11.5 — Liquidación con detalles (INNER JOIN) [info]
-- Objetivo: Detalle de la liquidación del mecánico.
-- Esperado: 7 filas (liquidación pagada: 3 comisiones y 1 adelanto; pendiente: 2 comisiones y 1 adelanto)
SELECT '11.5' AS prueba, 'info' AS tipo;
SELECT l.id, u.nombre, m.tipo, d.importe_incluido, l.total_a_pagar, l.estado FROM liquidaciones_mecanicos l INNER JOIN usuarios u ON u.id = l.mecanico_id INNER JOIN detalles_liquidaciones_mecanicos d ON d.liquidacion_id = l.id INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id ORDER BY d.id;
-- PRUEBA 11.6 — Pagar una liquidación [op]
-- Objetivo: UPDATE a pagada con fecha de pago.
-- Esperado: resultado = OK
SELECT '11.6' AS prueba;
START TRANSACTION;
UPDATE liquidaciones_mecanicos SET estado = 'pagada', fecha_pago = NOW() WHERE estado = 'pendiente';
SELECT IF(COUNT(*) = 2 AND SUM(fecha_pago IS NOT NULL) = 2, 'OK', 'FALLA') AS resultado FROM liquidaciones_mecanicos WHERE estado = 'pagada';
ROLLBACK;
-- PRUEBA 11.7 — Anular una liquidación pendiente y liberar sus movimientos [op]
-- Objetivo: Se anula la liquidación pendiente y se borran sus detalles: sus movimientos pueden liquidarse de nuevo.
-- Esperado: resultado = OK
SELECT '11.7' AS prueba;
START TRANSACTION;
SET @liq = (SELECT id FROM liquidaciones_mecanicos WHERE estado = 'pendiente' LIMIT 1);
SET @movs = (SELECT COUNT(*) FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq);
DELETE FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq;
UPDATE liquidaciones_mecanicos SET estado = 'anulada' WHERE id = @liq;
SELECT IF(@movs = 3 AND (SELECT COUNT(*) FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq) = 0 AND (SELECT COUNT(*) FROM movimientos_mecanicos) = 7 AND (SELECT COUNT(*) FROM movimientos_mecanicos m WHERE NOT EXISTS (SELECT 1 FROM detalles_liquidaciones_mecanicos d WHERE d.movimiento_mecanico_id = m.id)) = 3, 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 11.8 — Movimiento liquidado dos veces rechazado [error]
-- Objetivo: UNIQUE uq_detliq_movimiento.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('11.8', 'INSERT INTO detalles_liquidaciones_mecanicos (liquidacion_id, movimiento_mecanico_id, importe_incluido) VALUES (1, 1, 10);', 1062);
ROLLBACK;
-- PRUEBA 11.9 — Período invertido rechazado [error]
-- Objetivo: CHECK ck_liq_fechas.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('11.9', 'INSERT INTO liquidaciones_mecanicos (mecanico_id, periodo_desde, periodo_hasta, creado_por) VALUES (3, ''2026-12-01'', ''2026-11-01'', 2);', 3819);
ROLLBACK;
-- PRUEBA 11.10 — Liquidaciones pendientes, pagadas y anuladas [info]
-- Objetivo: Agrupa las liquidaciones por estado.
-- Esperado: 3 filas (anulada, pagada, pendiente)
SELECT '11.10' AS prueba, 'info' AS tipo;
SELECT estado, COUNT(*) AS cantidad, SUM(total_a_pagar) AS total FROM liquidaciones_mecanicos GROUP BY estado ORDER BY estado;
-- PRUEBA 11.11 — Estados coherentes: pagadas con fecha de pago, anuladas sin detalles [integridad]
-- Objetivo: pagada tiene fecha_pago; pendiente/anulada no; anulada no conserva movimientos.
-- Esperado: 0 filas
SELECT '11.11' AS prueba, 'integridad' AS tipo;
SELECT l.id FROM liquidaciones_mecanicos l WHERE (l.estado = 'pagada' AND l.fecha_pago IS NULL) OR (l.estado <> 'pagada' AND l.fecha_pago IS NOT NULL) OR (l.estado = 'anulada' AND EXISTS (SELECT 1 FROM detalles_liquidaciones_mecanicos d WHERE d.liquidacion_id = l.id));
-- PRUEBA 11.12 — Los adelantos se descuentan de la liquidación [op]
-- Objetivo: Genera una liquidación con una comisión y un adelanto nuevos: total a pagar = comisión − adelanto.
-- Esperado: resultado = OK
SELECT '11.12' AS prueba;
START TRANSACTION;
INSERT INTO movimientos_mecanicos (id, mecanico_id, tipo, monto, orden_id, registrado_por, fecha) VALUES (9001, 3, 'adelanto', 2500, NULL, 2, '2026-11-19 09:00:00');
INSERT INTO liquidaciones_mecanicos (id, mecanico_id, periodo_desde, periodo_hasta, total_comisiones, total_adelantos, total_a_pagar, estado, creado_por) VALUES (9001, 3, '2026-11-19', '2026-11-20', 10000, 2500, 7500, 'pendiente', 2);
INSERT INTO detalles_liquidaciones_mecanicos (liquidacion_id, movimiento_mecanico_id, importe_incluido) VALUES (9001, 9001, 2500);
SELECT IF(l.total_a_pagar = l.total_comisiones - l.total_adelantos AND l.total_adelantos = (SELECT SUM(d.importe_incluido) FROM detalles_liquidaciones_mecanicos d INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id WHERE d.liquidacion_id = 9001 AND m.tipo = 'adelanto'), 'OK', 'FALLA') AS resultado FROM liquidaciones_mecanicos l WHERE l.id = 9001;
ROLLBACK;
-- PRUEBA 11.13 — Total a pagar negativo rechazado [error]
-- Objetivo: CHECK de liquidaciones: si los adelantos superan las comisiones no se genera.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('11.13', 'INSERT INTO liquidaciones_mecanicos (mecanico_id, periodo_desde, periodo_hasta, total_comisiones, total_adelantos, total_a_pagar, creado_por) VALUES (3, ''2026-11-01'', ''2026-11-02'', 100, 500, -400, 2);', 3819);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 12. SUSCRIPCIONES
-- ----------------------------------------------------------------------------
-- PRUEBA 12.1 — Períodos consecutivos sin huecos [integridad]
-- Objetivo: Cada período empieza donde terminó el anterior y la numeración es correlativa.
-- Esperado: 0 filas
SELECT '12.1' AS prueba, 'integridad' AS tipo;
SELECT b.id FROM periodos_pago_sistema b INNER JOIN periodos_pago_sistema a ON a.taller_id = b.taller_id AND a.numero = b.numero - 1 WHERE b.fecha_inicio <> a.fecha_vencimiento;
-- PRUEBA 12.2 — Tolerancia de 3 días [integridad]
-- Objetivo: fecha_fin_tolerancia = vencimiento + 3 días.
-- Esperado: 0 filas
SELECT '12.2' AS prueba, 'integridad' AS tipo;
SELECT id FROM periodos_pago_sistema WHERE fecha_fin_tolerancia <> DATE_ADD(fecha_vencimiento, INTERVAL dias_tolerancia DAY) OR dias_tolerancia <> 3;
-- PRUEBA 12.3 — Duración según modalidad [integridad]
-- Objetivo: mensual = 1 mes; anual = 12 meses.
-- Esperado: 0 filas
SELECT '12.3' AS prueba, 'integridad' AS tipo;
SELECT id FROM periodos_pago_sistema WHERE (modalidad = 'mensual' AND fecha_vencimiento <> DATE_ADD(fecha_inicio, INTERVAL 1 MONTH)) OR (modalidad = 'anual' AND fecha_vencimiento <> DATE_ADD(fecha_inicio, INTERVAL 12 MONTH));
-- PRUEBA 12.4 — Período pagado con pago confirmado [integridad]
-- Objetivo: Un período pagado tiene fecha de pago y al menos un pago confirmado.
-- Esperado: 0 filas
SELECT '12.4' AS prueba, 'integridad' AS tipo;
SELECT p.id FROM periodos_pago_sistema p WHERE p.estado = 'pagado' AND (p.fecha_pago_confirmado IS NULL OR NOT EXISTS (SELECT 1 FROM pagos_sistema s WHERE s.periodo_id = p.id AND s.estado = 'confirmado'));
-- PRUEBA 12.5 — Estado de la suscripción a la fecha de referencia [info]
-- Objetivo: Estado y días al vencimiento del último período (fecha de referencia de la demo: 2026-11-20).
-- Esperado: 1 fila: período 2, 12 días al vencimiento, acceso vigente
SELECT '12.5' AS prueba, 'info' AS tipo;
SET @hoy_demo = DATE('2026-11-20');
SELECT p.numero, p.fecha_vencimiento, DATEDIFF(p.fecha_vencimiento, @hoy_demo) AS dias_al_vencimiento,
 CASE WHEN @hoy_demo <= p.fecha_vencimiento THEN 'vigente' WHEN @hoy_demo <= p.fecha_fin_tolerancia THEN 'en tolerancia' ELSE 'bloqueado' END AS acceso, t.estado_acceso
FROM periodos_pago_sistema p INNER JOIN taller t ON t.id = p.taller_id WHERE p.numero = (SELECT MAX(numero) FROM periodos_pago_sistema);
-- PRUEBA 12.6 — Taller bloqueado solo si venció la tolerancia [integridad]
-- Objetivo: estado_acceso coherente con la fecha de referencia.
-- Esperado: 0 filas
SELECT '12.6' AS prueba, 'integridad' AS tipo;
SET @hoy_demo = DATE('2026-11-20');
SELECT t.id FROM taller t INNER JOIN periodos_pago_sistema p ON p.numero = (SELECT MAX(numero) FROM periodos_pago_sistema) WHERE (t.estado_acceso = 'bloqueado') <> (p.estado <> 'pagado' AND @hoy_demo > p.fecha_fin_tolerancia);
-- PRUEBA 12.7 — Renovación: informar y confirmar un pago [op]
-- Objetivo: Proceso completo: se informa el pago, el SuperAdmin lo confirma, el período se marca pagado y nace el siguiente.
-- Esperado: resultado = OK
SELECT '12.7' AS prueba;
START TRANSACTION;
INSERT INTO pagos_sistema (id, periodo_id, importe_total, metodo, estado, registrado_por) VALUES (9001, 2, 30000, 'transferencia', 'informado', 2);
INSERT INTO detalles_pagos_sistema (pago_id, medio, importe, referencia) VALUES (9001, 'transferencia', 30000, 'TRF-PRUEBA');
UPDATE pagos_sistema SET estado = 'confirmado', confirmado_por = 1, fecha_confirmacion = NOW() WHERE id = 9001;
UPDATE periodos_pago_sistema SET estado = 'pagado', fecha_pago_confirmado = NOW() WHERE id = 2;
INSERT INTO periodos_pago_sistema (id, taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia, estado)
 SELECT 9001, 1, 3, 'mensual', fecha_vencimiento, DATE_ADD(fecha_vencimiento, INTERVAL 1 MONTH), importe, 3, DATE_ADD(DATE_ADD(fecha_vencimiento, INTERVAL 1 MONTH), INTERVAL 3 DAY), 'vigente' FROM periodos_pago_sistema WHERE id = 2;
SELECT IF((SELECT estado FROM periodos_pago_sistema WHERE id = 2) = 'pagado' AND (SELECT fecha_vencimiento FROM periodos_pago_sistema WHERE id = 9001) = '2027-01-02', 'OK', 'FALLA') AS resultado;
ROLLBACK;
-- PRUEBA 12.8 — Rechazo de un pago informado [op]
-- Objetivo: UPDATE a rechazado con motivo.
-- Esperado: resultado = OK
SELECT '12.8' AS prueba;
START TRANSACTION;
INSERT INTO pagos_sistema (id, periodo_id, importe_total, metodo, estado, registrado_por) VALUES (9002, 2, 30000, 'efectivo', 'informado', 2);
UPDATE pagos_sistema SET estado = 'rechazado', motivo_rechazo = 'No se recibió el dinero', confirmado_por = 1, fecha_confirmacion = NOW() WHERE id = 9002;
SELECT IF(estado = 'rechazado' AND motivo_rechazo IS NOT NULL, 'OK', 'FALLA') AS resultado FROM pagos_sistema WHERE id = 9002;
ROLLBACK;
-- PRUEBA 12.9 — Tolerancia distinta de 3 días rechazada [error]
-- Objetivo: CHECK ck_periodo_tolerancia.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('12.9', 'INSERT INTO periodos_pago_sistema (taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia) VALUES (1, 50, ''mensual'', ''2027-01-01'', ''2027-02-01'', 100, 5, ''2027-02-06'');', 3819);
ROLLBACK;
-- PRUEBA 12.10 — Modalidad: solo mensual o anual [integridad]
-- Objetivo: El ENUM de modalidad no admite otros valores (p. ej. trimestral).
-- Esperado: 0 filas
SELECT '12.10' AS prueba, 'integridad' AS tipo;
SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'periodos_pago_sistema' AND column_name = 'modalidad' AND column_type <> "enum('mensual','anual')";
-- PRUEBA 12.11 — No existe el plan trimestral [integridad]
-- Objetivo: Ningún período usa una modalidad distinta de mensual o anual.
-- Esperado: 0 filas
SELECT '12.11' AS prueba, 'integridad' AS tipo;
SELECT id, modalidad FROM periodos_pago_sistema WHERE modalidad NOT IN ('mensual','anual');
-- PRUEBA 12.12 — Modalidad anual: 12 meses y tolerancia de 3 días [op]
-- Objetivo: Se inserta un período anual y se comprueba su vencimiento y tolerancia.
-- Esperado: resultado = OK
SELECT '12.12' AS prueba;
START TRANSACTION;
INSERT INTO periodos_pago_sistema (id, taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia) VALUES (9002, 1, 40, 'anual', '2026-12-02', '2027-12-02', 300000, 3, '2027-12-05');
SELECT IF(fecha_vencimiento = DATE_ADD(fecha_inicio, INTERVAL 12 MONTH) AND fecha_fin_tolerancia = DATE_ADD(fecha_vencimiento, INTERVAL 3 DAY), 'OK', 'FALLA') AS resultado FROM periodos_pago_sistema WHERE id = 9002;
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 13. PAGOS DEL SISTEMA
-- ----------------------------------------------------------------------------
-- PRUEBA 13.1 — Confirmados con SuperAdmin y fecha [integridad]
-- Objetivo: Un pago confirmado tiene confirmado_por y fecha de confirmación.
-- Esperado: 0 filas
SELECT '13.1' AS prueba, 'integridad' AS tipo;
SELECT id FROM pagos_sistema WHERE estado = 'confirmado' AND (confirmado_por IS NULL OR fecha_confirmacion IS NULL);
-- PRUEBA 13.2 — Importe = suma de los medios [integridad]
-- Objetivo: importe_total coincide con sus detalles.
-- Esperado: 0 filas
SELECT '13.2' AS prueba, 'integridad' AS tipo;
SELECT p.id FROM pagos_sistema p LEFT JOIN detalles_pagos_sistema d ON d.pago_id = p.id GROUP BY p.id, p.importe_total HAVING p.importe_total <> COALESCE(SUM(d.importe), 0);
-- PRUEBA 13.3 — Método combinado ↔ dos medios [integridad]
-- Objetivo: combinado = efectivo + transferencia; los demás, un solo medio igual al método.
-- Esperado: 0 filas
SELECT '13.3' AS prueba, 'integridad' AS tipo;
SELECT p.id FROM pagos_sistema p INNER JOIN detalles_pagos_sistema d ON d.pago_id = p.id GROUP BY p.id, p.metodo HAVING (p.metodo = 'combinado' AND COUNT(*) <> 2) OR (p.metodo <> 'combinado' AND (COUNT(*) <> 1 OR MAX(d.medio) <> p.metodo));
-- PRUEBA 13.4 — Pagos del sistema y de clientes están separados [integridad]
-- Objetivo: No existe ninguna clave foránea entre las tablas de pagos de clientes y las del sistema.
-- Esperado: 0 filas
SELECT '13.4' AS prueba, 'integridad' AS tipo;
SELECT table_name, referenced_table_name FROM information_schema.key_column_usage
WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL
 AND ((table_name IN ('pagos_clientes','detalles_pagos_clientes') AND referenced_table_name IN ('pagos_sistema','detalles_pagos_sistema','periodos_pago_sistema','comprobantes_pagos_sistema'))
   OR (table_name IN ('pagos_sistema','detalles_pagos_sistema','periodos_pago_sistema','comprobantes_pagos_sistema') AND referenced_table_name IN ('pagos_clientes','detalles_pagos_clientes')));
-- PRUEBA 13.5 — Pago del sistema con período, dueño y SuperAdmin (INNER JOIN) [info]
-- Objetivo: Listado de pagos de suscripción.
-- Esperado: 2 filas (1 confirmado y 1 informado)
SELECT '13.5' AS prueba, 'info' AS tipo;
SELECT p.id, per.numero AS periodo, u.nombre AS pagador, p.importe_total, p.metodo, p.estado, su.usuario AS confirmo FROM pagos_sistema p INNER JOIN periodos_pago_sistema per ON per.id = p.periodo_id INNER JOIN usuarios u ON u.id = p.registrado_por LEFT JOIN superadmins s ON s.id = p.confirmado_por LEFT JOIN usuarios su ON su.id = s.usuario_id;
-- PRUEBA 13.6 — Comprobantes con pago existente [integridad]
-- Objetivo: comprobantes_pagos_sistema (tabla sin uso en el MVP) no tiene huérfanos.
-- Esperado: 0 filas
SELECT '13.6' AS prueba, 'integridad' AS tipo;
SELECT c.id FROM comprobantes_pagos_sistema c LEFT JOIN pagos_sistema p ON p.id = c.pago_sistema_id WHERE p.id IS NULL;
-- PRUEBA 13.7 — Medio repetido en un pago del sistema rechazado [error]
-- Objetivo: UNIQUE (pago, medio).
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('13.7', 'INSERT INTO detalles_pagos_sistema (pago_id, medio, importe) VALUES (1, ''efectivo'', 5);', 1062);
ROLLBACK;
-- PRUEBA 13.8 — Medios del sistema: solo efectivo y transferencia [integridad]
-- Objetivo: El ENUM de medio de detalles_pagos_sistema no admite otros valores.
-- Esperado: 0 filas
SELECT '13.8' AS prueba, 'integridad' AS tipo;
SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'detalles_pagos_sistema' AND column_name = 'medio' AND column_type <> "enum('efectivo','transferencia')";
-- PRUEBA 13.9 — Confirmar con un usuario que no es SuperAdmin rechazado [error]
-- Objetivo: FK confirmado_por -> superadmins.
-- Esperado: ERROR 1452 (clave foránea)
START TRANSACTION;
CALL sp_esperar_error('13.9', 'UPDATE pagos_sistema SET confirmado_por = 99 WHERE id = 1;', 1452);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 14. NOTIFICACIONES
-- ----------------------------------------------------------------------------
-- PRUEBA 14.1 — Destinatario único [integridad]
-- Objetivo: Cada notificación tiene exactamente un destinatario (usuario o superadmin).
-- Esperado: 0 filas
SELECT '14.1' AS prueba, 'integridad' AS tipo;
SELECT id FROM notificaciones WHERE (usuario_id IS NULL AND superadmin_id IS NULL) OR (usuario_id IS NOT NULL AND superadmin_id IS NOT NULL);
-- PRUEBA 14.2 — Notificaciones con destinatario (INNER JOIN) [info]
-- Objetivo: Listar las notificaciones de usuarios del taller.
-- Esperado: al menos 1 fila
SELECT '14.2' AS prueba, 'info' AS tipo;
SELECT u.usuario, n.tipo, n.texto, n.leida FROM notificaciones n INNER JOIN usuarios u ON u.id = n.usuario_id ORDER BY n.id;
-- PRUEBA 14.3 — Notificaciones del SuperAdmin (INNER JOIN) [info]
-- Objetivo: Listar las del SuperAdmin.
-- Esperado: 1 fila
SELECT '14.3' AS prueba, 'info' AS tipo;
SELECT u.usuario, n.texto FROM notificaciones n INNER JOIN superadmins s ON s.id = n.superadmin_id INNER JOIN usuarios u ON u.id = s.usuario_id;
-- PRUEBA 14.4 — Marcar como leída [op]
-- Objetivo: UPDATE leida = 1.
-- Esperado: resultado = OK
SELECT '14.4' AS prueba;
START TRANSACTION;
UPDATE notificaciones SET leida = 1 WHERE usuario_id = 2;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM notificaciones WHERE usuario_id = 2 AND leida = 0;
ROLLBACK;
-- PRUEBA 14.5 — Crear y eliminar una notificación [op]
-- Objetivo: INSERT y DELETE.
-- Esperado: resultado = OK
SELECT '14.5' AS prueba;
START TRANSACTION;
INSERT INTO notificaciones (id, usuario_id, texto, tipo, clave_unica) VALUES (9001, 3, 'Nuevo trabajo asignado', 'trabajo', 'prueba:9001');
DELETE FROM notificaciones WHERE id = 9001;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM notificaciones WHERE id = 9001;
ROLLBACK;
-- PRUEBA 14.6 — Aviso duplicado rechazado [error]
-- Objetivo: clave_unica evita repetir el mismo aviso.
-- Esperado: ERROR 1062 (clave duplicada)
START TRANSACTION;
CALL sp_esperar_error('14.6', 'INSERT INTO notificaciones (usuario_id, texto, clave_unica) SELECT usuario_id, ''dup'', clave_unica FROM notificaciones WHERE clave_unica IS NOT NULL LIMIT 1;', 1062);
ROLLBACK;
-- PRUEBA 14.7 — Dos destinatarios rechazados [error]
-- Objetivo: CHECK ck_notif_destino.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('14.7', 'INSERT INTO notificaciones (usuario_id, superadmin_id, texto) VALUES (2, 1, ''x'');', 3819);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 15. AUDITORÍA
-- ----------------------------------------------------------------------------
-- PRUEBA 15.1 — Ámbito y actor coherentes [integridad]
-- Objetivo: taller -> usuario; sistema -> superadmin.
-- Esperado: 0 filas
SELECT '15.1' AS prueba, 'integridad' AS tipo;
SELECT id FROM auditoria WHERE NOT ((ambito = 'taller' AND usuario_id IS NOT NULL AND superadmin_id IS NULL) OR (ambito = 'sistema' AND usuario_id IS NULL AND superadmin_id IS NOT NULL));
-- PRUEBA 15.2 — actor_login coincide con el usuario [integridad]
-- Objetivo: El login guardado es el del usuario o SuperAdmin referenciado.
-- Esperado: 0 filas
SELECT '15.2' AS prueba, 'integridad' AS tipo;
SELECT a.id FROM auditoria a LEFT JOIN usuarios u ON u.id = a.usuario_id LEFT JOIN superadmins s ON s.id = a.superadmin_id LEFT JOIN usuarios us ON us.id = s.usuario_id WHERE a.actor_login <> COALESCE(u.usuario, us.usuario);
-- PRUEBA 15.3 — Detalle JSON válido [integridad]
-- Objetivo: Todo detalle es JSON.
-- Esperado: 0 filas
SELECT '15.3' AS prueba, 'integridad' AS tipo;
SELECT id FROM auditoria WHERE detalle IS NOT NULL AND JSON_VALID(detalle) = 0;
-- PRUEBA 15.4 — Actividad con su autor (INNER JOIN) [info]
-- Objetivo: Listar la actividad reciente del taller.
-- Esperado: al menos 1 fila
SELECT '15.4' AS prueba, 'info' AS tipo;
SELECT a.fecha, u.nombre, a.accion, JSON_UNQUOTE(JSON_EXTRACT(a.detalle, '$.detalle')) AS detalle FROM auditoria a INNER JOIN usuarios u ON u.id = a.usuario_id ORDER BY a.fecha DESC;
-- PRUEBA 15.5 — Registrar una acción [op]
-- Objetivo: INSERT con detalle JSON.
-- Esperado: resultado = OK
SELECT '15.5' AS prueba;
START TRANSACTION;
INSERT INTO auditoria (usuario_id, actor_login, ambito, accion, entidad, entidad_id, detalle) VALUES (2, 'roberto', 'taller', 'Editó una consulta', 'consultas', 1, JSON_OBJECT('detalle', 'Cambió el motivo'));
SELECT IF(JSON_UNQUOTE(JSON_EXTRACT(detalle, '$.detalle')) = 'Cambió el motivo', 'OK', 'FALLA') AS resultado FROM auditoria WHERE accion = 'Editó una consulta';
ROLLBACK;
-- PRUEBA 15.6 — Acción de sistema con usuario de taller rechazada [error]
-- Objetivo: CHECK ck_auditoria_actor.
-- Esperado: ERROR 3819 (restricción CHECK)
START TRANSACTION;
CALL sp_esperar_error('15.6', 'INSERT INTO auditoria (usuario_id, actor_login, ambito, accion) VALUES (2, ''roberto'', ''sistema'', ''x'');', 3819);
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 16. PROPUESTAS DE IA
-- ----------------------------------------------------------------------------
-- PRUEBA 16.1 — Propuestas resueltas con fecha [integridad]
-- Objetivo: aceptada/editada/descartada tienen resuelta_en.
-- Esperado: 0 filas
SELECT '16.1' AS prueba, 'integridad' AS tipo;
SELECT id FROM propuestas_ia WHERE estado IN ('aceptada','editada','descartada') AND resuelta_en IS NULL;
-- PRUEBA 16.2 — Texto final según estado [integridad]
-- Objetivo: Aceptada/editada requieren texto_final.
-- Esperado: 0 filas
SELECT '16.2' AS prueba, 'integridad' AS tipo;
SELECT id FROM propuestas_ia WHERE estado IN ('aceptada','editada') AND (texto_final IS NULL OR texto_final = '');
-- PRUEBA 16.3 — Contexto y referencia (corregida) [integridad]
-- Objetivo: problema_consulta e inspeccion deben referir una consulta; observacion_mecanico, una orden.
-- Esperado: 0 filas
SELECT '16.3' AS prueba, 'integridad' AS tipo;
SELECT id FROM propuestas_ia WHERE (contexto IN ('problema_consulta','inspeccion') AND consulta_id IS NULL) OR (contexto = 'observacion_mecanico' AND orden_id IS NULL);
-- PRUEBA 16.4 — Sin proveedores externos [integridad]
-- Objetivo: El MVP usa reglas locales: no debe haber proveedores de IA externos ni claves.
-- Esperado: 0 filas
SELECT '16.4' AS prueba, 'integridad' AS tipo;
SELECT id, proveedor FROM propuestas_ia WHERE proveedor NOT IN ('reglas_locales');
-- PRUEBA 16.5 — Propuestas con autor y consulta (INNER JOIN) [info]
-- Objetivo: Listar propuestas.
-- Esperado: 1 fila
SELECT '16.5' AS prueba, 'info' AS tipo;
SELECT p.id, u.nombre, c.id AS consulta, p.estado, p.texto_original, p.texto_final FROM propuestas_ia p INNER JOIN usuarios u ON u.id = p.usuario_id INNER JOIN consultas c ON c.id = p.consulta_id;
-- PRUEBA 16.6 — Generar y aceptar una propuesta [op]
-- Objetivo: INSERT y UPDATE de estado.
-- Esperado: resultado = OK
SELECT '16.6' AS prueba;
START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, orden_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9001, 3, 'observacion_mecanico', 3, 'cambie filtro', 'Se cambió el filtro.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'aceptada', texto_final = texto_propuesto, resuelta_en = NOW() WHERE id = 9001;
SELECT IF(estado = 'aceptada' AND texto_final = 'Se cambió el filtro.', 'OK', 'FALLA') AS resultado FROM propuestas_ia WHERE id = 9001;
ROLLBACK;
-- PRUEBA 16.7 — Contextos de IA: sin fotografía [integridad]
-- Objetivo: El ENUM de contexto solo admite textos (sin imágenes).
-- Esperado: 0 filas
SELECT '16.7' AS prueba, 'integridad' AS tipo;
SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'propuestas_ia' AND column_name = 'contexto' AND column_type REGEXP 'foto|imagen';
-- PRUEBA 16.8 — El texto original siempre se conserva [integridad]
-- Objetivo: Toda propuesta guarda el texto original y la propuesta; el final solo existe si se aceptó o editó.
-- Esperado: 0 filas
SELECT '16.8' AS prueba, 'integridad' AS tipo;
SELECT id FROM propuestas_ia WHERE texto_original IS NULL OR texto_original = '' OR texto_propuesto IS NULL OR (estado = 'descartada' AND texto_final IS NOT NULL) OR (estado = 'generada' AND texto_final IS NOT NULL);
-- PRUEBA 16.9 — Aceptar una propuesta no modifica el texto original [op]
-- Objetivo: UPDATE a aceptada: texto_original queda igual.
-- Esperado: resultado = OK
SELECT '16.9' AS prueba;
START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, consulta_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9002, 2, 'problema_consulta', 1, 'ruido al frenar', 'Se informa un ruido al frenar.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'aceptada', texto_final = texto_propuesto, resuelta_en = NOW() WHERE id = 9002;
SELECT IF(texto_original = 'ruido al frenar' AND texto_final = 'Se informa un ruido al frenar.' AND estado = 'aceptada', 'OK', 'FALLA') AS resultado FROM propuestas_ia WHERE id = 9002;
ROLLBACK;
-- PRUEBA 16.10 — Editar y descartar propuestas [op]
-- Objetivo: Una editada guarda un texto final distinto de la propuesta; una descartada no deja texto final.
-- Esperado: resultado = OK
SELECT '16.10' AS prueba;
START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, orden_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9003, 3, 'observacion_mecanico', 3, 'cambie filtro', 'Se cambió el filtro.', 'generada', 'reglas_locales'), (9004, 3, 'observacion_mecanico', 3, 'revise frenos', 'Se revisaron los frenos.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'editada', texto_final = 'Se cambió el filtro de aceite.', resuelta_en = NOW() WHERE id = 9003;
UPDATE propuestas_ia SET estado = 'descartada', resuelta_en = NOW() WHERE id = 9004;
SELECT IF((SELECT texto_final <> texto_propuesto AND texto_original = 'cambie filtro' FROM propuestas_ia WHERE id = 9003) AND (SELECT texto_final IS NULL AND texto_original = 'revise frenos' FROM propuestas_ia WHERE id = 9004), 'OK', 'FALLA') AS resultado;
ROLLBACK;

-- ----------------------------------------------------------------------------
-- MÓDULO 17. ESTRUCTURA E INTEGRIDAD GENERAL
-- ----------------------------------------------------------------------------
-- PRUEBA 17.1 — La base tiene 30 tablas [integridad]
-- Objetivo: Cantidad de tablas del esquema.
-- Esperado: 0 filas (hay exactamente 30)
SELECT '17.1' AS prueba, 'integridad' AS tipo;
SELECT COUNT(*) AS tablas FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE' HAVING COUNT(*) <> 30;
-- PRUEBA 17.2 — No existen tablas ni columnas de fotos o archivos de trabajos [integridad]
-- Objetivo: Verifica la eliminación de la función de fotografías.
-- Esperado: 0 filas
SELECT '17.2' AS prueba, 'integridad' AS tipo;
SELECT table_name, column_name FROM information_schema.columns WHERE table_schema = DATABASE() AND (table_name = 'archivos_trabajos' OR column_name REGEXP 'foto|imagen|ruta_foto')
UNION ALL SELECT table_name, NULL FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name REGEXP 'foto|archivos_trabajos';
-- PRUEBA 17.3 — Toda tabla tiene clave primaria [integridad]
-- Objetivo: Sin tablas sin PK.
-- Esperado: 0 filas
SELECT '17.3' AS prueba, 'integridad' AS tipo;
SELECT t.table_name FROM information_schema.tables t LEFT JOIN information_schema.table_constraints c ON c.table_schema = t.table_schema AND c.table_name = t.table_name AND c.constraint_type = 'PRIMARY KEY' WHERE t.table_schema = DATABASE() AND t.table_type = 'BASE TABLE' AND c.constraint_name IS NULL;
-- PRUEBA 17.4 — Claves foráneas definidas [info]
-- Objetivo: Listado de las relaciones del modelo.
-- Esperado: al menos 1 fila
SELECT '17.4' AS prueba, 'info' AS tipo;
SELECT table_name, column_name, referenced_table_name, referenced_column_name FROM information_schema.key_column_usage WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL ORDER BY table_name, column_name;
-- PRUEBA 17.5 — Claves foráneas sin índice propio [integridad]
-- Objetivo: Toda FK debería tener un índice que la acompañe.
-- Esperado: 0 filas
SELECT '17.5' AS prueba, 'integridad' AS tipo;
SELECT k.table_name, k.column_name FROM information_schema.key_column_usage k
WHERE k.table_schema = DATABASE() AND k.referenced_table_name IS NOT NULL AND k.ordinal_position = 1
 AND NOT EXISTS (SELECT 1 FROM information_schema.statistics s WHERE s.table_schema = k.table_schema AND s.table_name = k.table_name AND s.column_name = k.column_name AND s.seq_in_index = 1);
-- PRUEBA 17.6 — Cantidad de registros por tabla [info]
-- Objetivo: Resumen de datos de demostración.
-- Esperado: 30 filas (comprobantes_pagos_sistema con 0 registros)
SELECT '17.6' AS prueba, 'info' AS tipo;
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

-- ----------------------------------------------------------------------------
-- MÓDULO 18. PROCESOS PRINCIPALES DE PUNTA A PUNTA
-- ----------------------------------------------------------------------------
-- PRUEBA 18.1 — Flujo completo: consulta → presupuesto → orden → pago [op]
-- Objetivo: Recorre el proceso principal del taller en una transacción (se deshace): consulta con revisión, presupuesto aceptado, orden, asignación y aceptación del mecánico, inicio, avance, uso de repuesto, finalización, comisión y pago combinado.
-- Esperado: resultado = OK
SELECT '18.1' AS prueba;
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
-- PRUEBA 18.2 — Los datos no cambiaron tras las pruebas [integridad]
-- Objetivo: Después de las pruebas con ROLLBACK, el stock del artículo 1 y el estado de la orden 2 siguen igual.
-- Esperado: 0 filas
SELECT '18.2' AS prueba, 'integridad' AS tipo;
SELECT i.id FROM catalogo_items i INNER JOIN ordenes_trabajo o ON o.id = 2 WHERE i.id = 1 AND (i.cantidad <> 28 OR o.estado <> 'ofrecido');

DROP PROCEDURE IF EXISTS sp_esperar_error;
-- FIN DEL ARCHIVO
