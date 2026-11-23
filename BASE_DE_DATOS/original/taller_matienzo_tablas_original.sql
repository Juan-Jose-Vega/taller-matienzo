
CREATE DATABASE taller_matienzo
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;


USE taller_matienzo;

SELECT DATABASE();

CREATE TABLE roles (
  id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(40) NOT NULL,
  descripcion VARCHAR(200) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_cuenta ENUM('taller','superadmin') NOT NULL DEFAULT 'taller',
  rol_id TINYINT UNSIGNED NULL,
  nombre VARCHAR(100) NOT NULL,
  usuario VARCHAR(40) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
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

CREATE TABLE superadmins (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_superadmins_usuario (usuario_id),
  CONSTRAINT fk_superadmins_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

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

CREATE TABLE vehiculos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cliente_id INT UNSIGNED NOT NULL,
  patente VARCHAR(10) NOT NULL,
  marca VARCHAR(40) NOT NULL,
  modelo VARCHAR(40) NULL,
  anio SMALLINT UNSIGNED NULL,
  color VARCHAR(30) NULL,
  kilometraje INT UNSIGNED NOT NULL DEFAULT 0,
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vehiculos_patente (patente),
  KEY ix_vehiculos_cliente (cliente_id),
  CONSTRAINT fk_vehiculos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) ENGINE=InnoDB;

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
  observaciones_inspeccion TEXT NULL,
  estado ENUM('abierta','esperando_respuesta','aprobada','rechazada','cerrada') NOT NULL DEFAULT 'abierta',
  es_gratuita TINYINT(1) NOT NULL DEFAULT 0,
  creado_por INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_consultas_cliente (cliente_id),
  KEY ix_consultas_estado (estado),
  KEY ix_consultas_fecha (creado_en),
  CONSTRAINT fk_consultas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  CONSTRAINT fk_consultas_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id),
  CONSTRAINT fk_consultas_creador FOREIGN KEY (creado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

CREATE TABLE detalles_consultas (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  consulta_id INT UNSIGNED NOT NULL,
  descripcion VARCHAR(300) NOT NULL,
  tipo ENUM('sintoma_informado','verificado') NOT NULL DEFAULT 'verificado',
  registrado_por INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_detcons_consulta (consulta_id),
  CONSTRAINT fk_detcons_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id) ON DELETE CASCADE,
  CONSTRAINT fk_detcons_usuario FOREIGN KEY (registrado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

CREATE TABLE presupuestos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  consulta_id INT UNSIGNED NOT NULL,
  total_calculado DECIMAL(12,2) NOT NULL DEFAULT 0,
  precio_final DECIMAL(12,2) NOT NULL DEFAULT 0,
  comision_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
  estado ENUM('borrador','enviado','aceptado','rechazado') NOT NULL DEFAULT 'borrador',
  fecha_envio DATETIME NULL,
  fecha_respuesta DATETIME NULL,
  creado_por INT UNSIGNED NOT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_presupuestos_consulta (consulta_id),
  CONSTRAINT ck_presup_pct CHECK (comision_pct >= 0 AND comision_pct <= 100),
  CONSTRAINT ck_presup_importes CHECK (total_calculado >= 0 AND precio_final >= 0),
  CONSTRAINT fk_presup_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id),
  CONSTRAINT fk_presup_creador FOREIGN KEY (creado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

CREATE TABLE categorias_catalogo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL,
  descripcion VARCHAR(200) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categorias_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE catalogo_items (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id INT UNSIGNED NULL,
  tipo ENUM('servicio','repuesto') NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  codigo VARCHAR(40) NULL,
  precio_compra DECIMAL(12,2) NOT NULL DEFAULT 0,
  precio_venta DECIMAL(12,2) NOT NULL DEFAULT 0,
  cantidad INT NOT NULL DEFAULT 0,
  stock_minimo INT NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_catalogo_codigo (codigo),
  KEY ix_catalogo_tipo (tipo),
  CONSTRAINT ck_catalogo_importes CHECK (precio_compra >= 0 AND precio_venta >= 0),
  CONSTRAINT ck_catalogo_stock CHECK (cantidad >= 0 AND stock_minimo >= 0),
  CONSTRAINT fk_catalogo_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_catalogo(id)
) ENGINE=InnoDB;

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

CREATE TABLE detalles_presupuestos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  presupuesto_id INT UNSIGNED NOT NULL,
  concepto VARCHAR(200) NOT NULL,
  tipo ENUM('mano_obra','repuesto','otro') NOT NULL DEFAULT 'mano_obra',
  cantidad DECIMAL(8,2) NOT NULL DEFAULT 1,
  monto DECIMAL(12,2) NOT NULL,
  catalogo_item_id INT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY ix_detpres_presupuesto (presupuesto_id),
  CONSTRAINT ck_detpres_valores CHECK (cantidad > 0 AND monto >= 0),
  CONSTRAINT fk_detpres_presupuesto FOREIGN KEY (presupuesto_id) REFERENCES presupuestos(id) ON DELETE CASCADE,
  CONSTRAINT fk_detpres_item FOREIGN KEY (catalogo_item_id) REFERENCES catalogo_items(id)
) ENGINE=InnoDB;

CREATE TABLE ordenes_trabajo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  presupuesto_id INT UNSIGNED NOT NULL,
  cliente_id INT UNSIGNED NOT NULL,
  vehiculo_id INT UNSIGNED NOT NULL,
  mecanico_id INT UNSIGNED NULL,
  descripcion VARCHAR(200) NOT NULL,
  estado ENUM('sin_asignar','ofrecido','aceptado','en_proceso','finalizado','cancelado') NOT NULL DEFAULT 'sin_asignar',
  precio_final DECIMAL(12,2) NOT NULL,
  comision_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
  observaciones_mecanico TEXT NULL,
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_inicio DATETIME NULL,
  fecha_fin DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ordenes_presupuesto (presupuesto_id),
  KEY ix_ordenes_estado (estado),
  KEY ix_ordenes_mecanico (mecanico_id),
  KEY ix_ordenes_cliente (cliente_id),
  CONSTRAINT ck_ordenes_importes CHECK (precio_final >= 0 AND comision_pct >= 0 AND comision_pct <= 100),
  CONSTRAINT fk_ordenes_presupuesto FOREIGN KEY (presupuesto_id) REFERENCES presupuestos(id),
  CONSTRAINT fk_ordenes_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  CONSTRAINT fk_ordenes_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id),
  CONSTRAINT fk_ordenes_mecanico FOREIGN KEY (mecanico_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

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

CREATE TABLE asignaciones_trabajo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id INT UNSIGNED NOT NULL,
  mecanico_id INT UNSIGNED NOT NULL,
  asignado_por INT UNSIGNED NOT NULL,
  resultado ENUM('ofrecida','aceptada','rechazada','reasignada','completada') NOT NULL DEFAULT 'ofrecida',
  creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resuelto_en DATETIME NULL,
  PRIMARY KEY (id),
  KEY ix_asig_orden (orden_id),
  KEY ix_asig_mecanico (mecanico_id),
  CONSTRAINT fk_asig_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id),
  CONSTRAINT fk_asig_mecanico FOREIGN KEY (mecanico_id) REFERENCES usuarios(id),
  CONSTRAINT fk_asig_por FOREIGN KEY (asignado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

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
  CONSTRAINT ck_movstock_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_movstock_descripcion CHECK (catalogo_item_id IS NOT NULL OR descripcion_libre IS NOT NULL),
  CONSTRAINT fk_movstock_item FOREIGN KEY (catalogo_item_id) REFERENCES catalogo_items(id),
  CONSTRAINT fk_movstock_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id),
  CONSTRAINT fk_movstock_pago FOREIGN KEY (pago_cliente_id) REFERENCES pagos_clientes(id),
  CONSTRAINT fk_movstock_solicitante FOREIGN KEY (solicitado_por) REFERENCES usuarios(id),
  CONSTRAINT fk_movstock_resolutor FOREIGN KEY (resuelto_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

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
  CONSTRAINT ck_movmec_monto CHECK (monto > 0),
  CONSTRAINT fk_movmec_mecanico FOREIGN KEY (mecanico_id) REFERENCES usuarios(id),
  CONSTRAINT fk_movmec_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id),
  CONSTRAINT fk_movmec_usuario FOREIGN KEY (registrado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

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
  observaciones VARCHAR(250) NULL,
  PRIMARY KEY (id),
  KEY ix_pagos_sistema_periodo (periodo_id),
  KEY ix_pagos_sistema_estado (estado),
  CONSTRAINT ck_pagos_sistema_importe CHECK (importe_total > 0),
  CONSTRAINT fk_pagos_sistema_periodo FOREIGN KEY (periodo_id) REFERENCES periodos_pago_sistema(id),
  CONSTRAINT fk_pagos_sistema_registrador FOREIGN KEY (registrado_por) REFERENCES usuarios(id),
  CONSTRAINT fk_pagos_sistema_confirmador FOREIGN KEY (confirmado_por) REFERENCES superadmins(id)
) ENGINE=InnoDB;

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
  CONSTRAINT ck_auditoria_actor CHECK (
    (ambito = 'taller' AND usuario_id IS NOT NULL AND superadmin_id IS NULL) OR
    (ambito = 'sistema' AND usuario_id IS NULL AND superadmin_id IS NOT NULL)
  ),
  CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  CONSTRAINT fk_auditoria_superadmin FOREIGN KEY (superadmin_id) REFERENCES superadmins(id)
) ENGINE=InnoDB;

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
  CONSTRAINT fk_ia_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  CONSTRAINT fk_ia_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id) ON DELETE SET NULL,
  CONSTRAINT fk_ia_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE archivos_trabajos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden_id INT UNSIGNED NOT NULL,
  subido_por INT UNSIGNED NOT NULL,
  nombre_archivo VARCHAR(180) NOT NULL,
  ruta_archivo VARCHAR(255) NOT NULL,
  tipo_archivo VARCHAR(80) NULL,
  descripcion VARCHAR(200) NULL,
  fecha_subida DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_archivos_orden (orden_id),
  CONSTRAINT fk_archivos_orden FOREIGN KEY (orden_id) REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
  CONSTRAINT fk_archivos_usuario FOREIGN KEY (subido_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

INSERT INTO roles (nombre, descripcion)
VALUES
('Administrador', 'Administra el funcionamiento del taller'),
('Mecanico', 'Realiza los trabajos y reparaciones de vehículos');
SELECT * FROM roles;
SELECT id, nombre FROM roles;

INSERT INTO usuarios (
    tipo_cuenta,
    rol_id,
    nombre,
    usuario,
    password_hash,
    estado,
    debe_cambiar_password
)
VALUES (
    'superadmin',
    NULL,
    'Super Administrador',
    'superadmin',
    'CAMBIAR_POR_HASH_BCRYPT',
    'activo',
    1
);
INSERT INTO superadmins (usuario_id, observaciones)
SELECT id, 'Cuenta principal del sistema'
FROM usuarios
WHERE usuario = 'superadmin'
AND tipo_cuenta = 'superadmin';
SELECT
    u.id,
    u.nombre,
    u.usuario,
    u.tipo_cuenta,
    u.rol_id,
    s.id AS superadmin_id
FROM usuarios u
INNER JOIN superadmins s ON s.usuario_id = u.id;

INSERT INTO usuarios (
    tipo_cuenta,
    rol_id,
    nombre,
    usuario,
    password_hash,
    estado,
    debe_cambiar_password
)
VALUES (
    'taller',
    1,
    'Administrador Taller Matienzo',
    'admin',
    'CAMBIAR_POR_HASH_BCRYPT',
    'activo',
    1
);
SELECT
    u.id,
    u.nombre,
    u.usuario,
    u.tipo_cuenta,
    u.rol_id,
    r.nombre AS nombre_rol,
    u.estado
FROM usuarios u
INNER JOIN roles r ON u.rol_id = r.id
WHERE u.usuario = 'admin';

DESCRIBE taller;

INSERT INTO taller (
    id,
    nombre,
    admin_usuario_id
)
SELECT
    1,
    'Taller Matienzo',
    id
FROM usuarios
WHERE usuario = 'admin'
AND tipo_cuenta = 'taller';
SELECT
    t.id,
    t.nombre,
    t.estado_acceso,
    t.admin_usuario_id,
    u.usuario AS usuario_administrador
FROM taller t
INNER JOIN usuarios u
    ON t.admin_usuario_id = u.id;
    
    DESCRIBE usuarios;
    INSERT INTO usuarios (
    tipo_cuenta,
    rol_id,
    nombre,
    usuario,
    password_hash,
    estado,
    debe_cambiar_password
)
SELECT
    'taller',
    id,
    'Juan Pérez',
    'juan',
    'CAMBIAR_POR_HASH_BCRYPT',
    'activo',
    1
FROM roles
WHERE nombre = 'Mecanico';
SELECT
    u.id,
    u.nombre,
    u.usuario,
    u.tipo_cuenta,
    u.rol_id,
    r.nombre AS nombre_rol,
    u.estado
FROM usuarios u
INNER JOIN roles r
    ON u.rol_id = r.id
WHERE u.usuario = 'juan';

DESCRIBE clientes;
INSERT INTO clientes (
    nombre,
    dni,
    telefono,
    email,
    direccion
)
VALUES (
    'Carlos Gonzalez',
    '30123456',
    '3815551234',
    'carlos@gmail.com',
    'Bella Vista, Tucuman'
);
SELECT * FROM clientes;
INSERT INTO vehiculos (
    cliente_id,
    patente,
    marca,
    modelo,
    anio,
    color,
    kilometraje,
    observaciones
)
VALUES (
    1,
    'AB123CD',
    'Toyota',
    'Corolla',
    2018,
    'Gris',
    85000,
    'Vehiculo de prueba'
);
SELECT
    v.id,
    c.nombre AS cliente,
    v.patente,
    v.marca,
    v.modelo,
    v.anio
FROM vehiculos v
INNER JOIN clientes c ON v.cliente_id = c.id;
INSERT INTO consultas (
    cliente_id,
    vehiculo_id,
    contacto_nombre,
    contacto_dni,
    contacto_telefono,
    veh_patente,
    veh_marca,
    veh_modelo,
    veh_anio,
    veh_kilometraje,
    motivo,
    descripcion_problema,
    estado,
    es_gratuita,
    creado_por
)
VALUES (
    1,
    1,
    'Carlos Gonzalez',
    '30123456',
    '3815551234',
    'AB123CD',
    'Toyota',
    'Corolla',
    2018,
    85000,
    'Problema en el motor',
    'El cliente informa que el motor hace un ruido extraño al arrancar.',
    'abierta',
    1,
    2
);
SELECT * FROM consultas;
INSERT INTO detalles_consultas (
    consulta_id,
    descripcion,
    tipo,
    registrado_por
)
VALUES (
    1,
    'El cliente manifiesta que escucha un ruido metálico al encender el vehículo.',
    'sintoma_informado',
    2
);
INSERT INTO detalles_consultas (
    consulta_id,
    descripcion,
    tipo,
    registrado_por
)
VALUES (
    1,
    'Se verifica un ruido en la zona del motor durante el arranque.',
    'verificado',
    3
);
SELECT * FROM detalles_consultas;
INSERT INTO presupuestos (
    consulta_id,
    total_calculado,
    precio_final,
    comision_pct,
    estado,
    creado_por
)
VALUES (
    1,
    35000,
    35000,
    30,
    'borrador',
    2
);
SELECT * FROM presupuestos;
INSERT INTO categorias_catalogo (
    nombre,
    descripcion,
    activo
)
VALUES (
    'Repuestos',
    'Repuestos y componentes utilizados en los trabajos del taller.',
    1
);
SELECT * FROM categorias_catalogo;
INSERT INTO catalogo_items (
    categoria_id,
    tipo,
    nombre,
    codigo,
    precio_compra,
    precio_venta,
    cantidad,
    stock_minimo,
    activo
)
VALUES (
    1,
    'repuesto',
    'Filtro de aceite',
    'REP001',
    8000,
    10000,
    10,
    2,
    1
);
SELECT * FROM catalogo_items;
UPDATE catalogo_items
SET
    precio_compra = 9000,
    precio_venta = 12000
WHERE id = 1;
INSERT INTO historial_precios_catalogo (
    catalogo_item_id,
    precio_compra_anterior,
    precio_compra_nuevo,
    precio_venta_anterior,
    precio_venta_nuevo,
    cambiado_por
)
VALUES (
    1,
    8000,
    9000,
    10000,
    12000,
    2
);
SELECT * FROM historial_precios_catalogo;
INSERT INTO detalles_presupuestos (
    presupuesto_id,
    concepto,
    tipo,
    cantidad,
    monto,
    catalogo_item_id
)
VALUES
(
    1,
    'Reparación del motor',
    'mano_obra',
    1,
    25000,
    NULL
),
(
    1,
    'Filtro de aceite',
    'repuesto',
    1,
    10000,
    1
);
UPDATE presupuestos
SET
    estado = 'aceptado',
    fecha_envio = NOW(),
    fecha_respuesta = NOW()
WHERE id = 1;
UPDATE consultas
SET estado = 'aprobada'
WHERE id = 1;
SELECT * FROM detalles_presupuestos;
INSERT INTO ordenes_trabajo (
    presupuesto_id,
    cliente_id,
    vehiculo_id,
    mecanico_id,
    descripcion,
    estado,
    precio_final,
    comision_pct
)
VALUES (
    1,
    1,
    1,
    3,
    'Reparacion del motor y cambio de filtro de aceite.',
    'ofrecido',
    35000,
    30
);
SELECT * FROM ordenes_trabajo;
INSERT INTO historial_estados_ordenes (
    orden_id,
    estado_anterior,
    estado_nuevo,
    cambiado_por,
    observacion
)
VALUES (
    1,
    NULL,
    'ofrecido',
    2,
    'Se crea la orden y se ofrece el trabajo al mecanico Juan.'
);
SELECT * FROM historial_estados_ordenes;
INSERT INTO asignaciones_trabajo (
    orden_id,
    mecanico_id,
    asignado_por,
    resultado
)
VALUES (
    1,
    3,
    2,
    'ofrecida'
);
SELECT * FROM asignaciones_trabajo;
INSERT INTO pagos_clientes (
    tipo,
    orden_id,
    cliente_id,
    monto,
    metodo,
    registrado_por,
    observaciones
)
VALUES (
    'trabajo',
    1,
    1,
    15000,
    'efectivo',
    2,
    'Pago parcial como adelanto de la reparacion.'
);
SELECT * FROM pagos_clientes;

INSERT INTO liquidaciones_mecanicos (
    mecanico_id,
    periodo_desde,
    periodo_hasta,
    total_comisiones,
    total_adelantos,
    total_a_pagar,
    estado,
    creado_por,
    observaciones
)
VALUES (
    3,
    '2026-11-01',
    '2026-11-30',
    10000,
    2000,
    8000,
    'pendiente',
    2,
    'Liquidacion de prueba correspondiente a noviembre.'
);

SELECT * FROM liquidaciones_mecanicos;

SELECT * FROM movimientos_mecanicos;

INSERT INTO movimientos_mecanicos (
    mecanico_id,
    tipo,
    monto,
    orden_id,
    registrado_por,
    descripcion
)
VALUES (
    3,
    'comision',
    10000,
    1,
    2,
    'Comision correspondiente a la reparacion del Toyota Corolla.'
);

INSERT INTO detalles_liquidaciones_mecanicos (
    liquidacion_id,
    movimiento_mecanico_id,
    importe_incluido
)
VALUES (
    1,
    1,
    10000
);

SELECT
    l.id AS liquidacion,
    u.nombre AS mecanico,
    m.tipo AS tipo_movimiento,
    m.monto,
    d.importe_incluido
FROM detalles_liquidaciones_mecanicos d
INNER JOIN liquidaciones_mecanicos l
    ON d.liquidacion_id = l.id
INNER JOIN movimientos_mecanicos m
    ON d.movimiento_mecanico_id = m.id
INNER JOIN usuarios u
    ON l.mecanico_id = u.id;
    
    INSERT INTO periodos_pago_sistema (
    taller_id,
    numero,
    modalidad,
    fecha_inicio,
    fecha_vencimiento,
    importe,
    dias_tolerancia,
    fecha_fin_tolerancia,
    estado
)
VALUES (
    1,
    1,
    'mensual',
    '2026-11-01',
    '2026-11-30',
    50000,
    3,
    '2026-12-03',
    'vigente'
);

SELECT * FROM periodos_pago_sistema;

INSERT INTO pagos_sistema (
    periodo_id,
    importe_total,
    metodo,
    estado,
    registrado_por,
    observaciones
)
VALUES (
    1,
    50000,
    'transferencia',
    'informado',
    2,
    'El administrador informa el pago mensual por transferencia.'
);

SELECT * FROM pagos_sistema;

INSERT INTO detalles_pagos_sistema (
    pago_id,
    medio,
    importe,
    referencia
)
VALUES (
    1,
    'transferencia',
    50000,
    'TRANSFERENCIA-PRUEBA-001'
);

SELECT * FROM detalles_pagos_sistema;

INSERT INTO comprobantes_pagos_sistema (
    pago_sistema_id,
    nombre_archivo,
    ruta_archivo,
    tipo_archivo
)
VALUES (
    1,
    'comprobante_noviembre.pdf',
    'uploads/comprobantes/comprobante_noviembre.pdf',
    'application/pdf'
);

SELECT * FROM comprobantes_pagos_sistema;

INSERT INTO notificaciones (
    usuario_id,
    superadmin_id,
    texto,
    enlace,
    tipo,
    clave_unica
)
VALUES (
    2,
    NULL,
    'Tu pago de suscripcion fue informado y esta pendiente de confirmacion.',
    'suscripcion',
    'pago',
    'pago_suscripcion_admin_001'
);

INSERT INTO notificaciones (
    usuario_id,
    superadmin_id,
    texto,
    enlace,
    tipo,
    clave_unica
)
VALUES (
    NULL,
    1,
    'El Taller Matienzo informo un nuevo pago de suscripcion.',
    'pagos_sistema',
    'pago',
    'pago_suscripcion_superadmin_001'
);

SELECT * FROM notificaciones;

INSERT INTO auditoria (
    usuario_id,
    superadmin_id,
    actor_login,
    ambito,
    accion,
    entidad,
    entidad_id,
    detalle,
    ip
)
VALUES (
    2,
    NULL,
    'admin',
    'taller',
    'registro_pago_cliente',
    'pagos_clientes',
    1,
    JSON_OBJECT(
        'monto', 15000,
        'metodo', 'efectivo',
        'descripcion', 'Registro de adelanto del cliente'
    ),
    '127.0.0.1'
);

INSERT INTO auditoria (
    usuario_id,
    superadmin_id,
    actor_login,
    ambito,
    accion,
    entidad,
    entidad_id,
    detalle,
    ip
)
VALUES (
    NULL,
    1,
    'superadmin',
    'sistema',
    'revision_pago_suscripcion',
    'pagos_sistema',
    1,
    JSON_OBJECT(
        'periodo_id', 1,
        'importe', 50000,
        'estado', 'informado'
    ),
    '127.0.0.1'
);

SELECT * FROM auditoria;

INSERT INTO propuestas_ia (
    usuario_id,
    contexto,
    consulta_id,
    orden_id,
    texto_original,
    texto_propuesto,
    texto_final,
    estado,
    proveedor,
    modelo
)
VALUES (
    3,
    'observacion_mecanico',
    1,
    1,
    'El motor hace ruido cuando arranca y parece que vibra mucho.',
    'Se detecta un ruido anormal en el motor durante el arranque, acompañado de vibraciones.',
    NULL,
    'generada',
    'OpenAI',
    'modelo-de-prueba'
);

SELECT * FROM propuestas_ia;

INSERT INTO archivos_trabajos (
    orden_id,
    subido_por,
    nombre_archivo,
    ruta_archivo,
    tipo_archivo,
    descripcion
)
VALUES (
    1,
    3,
    'motor_corolla.jpg',
    'uploads/trabajos/motor_corolla.jpg',
    'image/jpeg',
    'Fotografia del motor antes de realizar la reparacion.'
);

SELECT * FROM archivos_trabajos;

INSERT INTO detalles_pagos_clientes (
    pago_cliente_id,
    medio,
    importe,
    referencia
)
VALUES (
    1,
    'efectivo',
    15000,
    'PAGO-EFECTIVO-001'
);

SELECT * FROM detalles_pagos_clientes;

INSERT INTO movimientos_stock (
    catalogo_item_id,
    descripcion_libre,
    tipo,
    cantidad,
    estado,
    aportado_cliente,
    motivo,
    orden_id,
    pago_cliente_id,
    solicitado_por,
    resuelto_por
)
VALUES (
    1,
    NULL,
    'entrada',
    10,
    'confirmado',
    0,
    'Compra inicial de filtros de aceite para el inventario.',
    NULL,
    NULL,
    2,
    2
);

SELECT * FROM movimientos_stock;

SELECT 'roles' AS tabla, COUNT(*) AS registros FROM roles
UNION ALL
SELECT 'usuarios', COUNT(*) FROM usuarios
UNION ALL
SELECT 'superadmins', COUNT(*) FROM superadmins
UNION ALL
SELECT 'taller', COUNT(*) FROM taller
UNION ALL
SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL
SELECT 'vehiculos', COUNT(*) FROM vehiculos
UNION ALL
SELECT 'consultas', COUNT(*) FROM consultas
UNION ALL
SELECT 'detalles_consultas', COUNT(*) FROM detalles_consultas
UNION ALL
SELECT 'presupuestos', COUNT(*) FROM presupuestos
UNION ALL
SELECT 'categorias_catalogo', COUNT(*) FROM categorias_catalogo
UNION ALL
SELECT 'catalogo_items', COUNT(*) FROM catalogo_items
UNION ALL
SELECT 'historial_precios_catalogo', COUNT(*) FROM historial_precios_catalogo
UNION ALL
SELECT 'detalles_presupuestos', COUNT(*) FROM detalles_presupuestos
UNION ALL
SELECT 'ordenes_trabajo', COUNT(*) FROM ordenes_trabajo
UNION ALL
SELECT 'historial_estados_ordenes', COUNT(*) FROM historial_estados_ordenes
UNION ALL
SELECT 'asignaciones_trabajo', COUNT(*) FROM asignaciones_trabajo
UNION ALL
SELECT 'pagos_clientes', COUNT(*) FROM pagos_clientes
UNION ALL
SELECT 'detalles_pagos_clientes', COUNT(*) FROM detalles_pagos_clientes
UNION ALL
SELECT 'movimientos_stock', COUNT(*) FROM movimientos_stock
UNION ALL
SELECT 'movimientos_mecanicos', COUNT(*) FROM movimientos_mecanicos
UNION ALL
SELECT 'liquidaciones_mecanicos', COUNT(*) FROM liquidaciones_mecanicos
UNION ALL
SELECT 'detalles_liquidaciones_mecanicos', COUNT(*) FROM detalles_liquidaciones_mecanicos
UNION ALL
SELECT 'periodos_pago_sistema', COUNT(*) FROM periodos_pago_sistema
UNION ALL
SELECT 'pagos_sistema', COUNT(*) FROM pagos_sistema
UNION ALL
SELECT 'detalles_pagos_sistema', COUNT(*) FROM detalles_pagos_sistema
UNION ALL
SELECT 'comprobantes_pagos_sistema', COUNT(*) FROM comprobantes_pagos_sistema
UNION ALL
SELECT 'notificaciones', COUNT(*) FROM notificaciones
UNION ALL
SELECT 'auditoria', COUNT(*) FROM auditoria
UNION ALL
SELECT 'propuestas_ia', COUNT(*) FROM propuestas_ia
UNION ALL
SELECT 'archivos_trabajos', COUNT(*) FROM archivos_trabajos;
-- verificar relaciones
SELECT
    TABLE_NAME AS tabla,
    COLUMN_NAME AS columna,
    CONSTRAINT_NAME AS nombre_relacion,
    REFERENCED_TABLE_NAME AS tabla_referenciada,
    REFERENCED_COLUMN_NAME AS columna_referenciada
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    TABLE_SCHEMA = 'taller_matienzo'
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;
-- verificar registros huérfanos
SELECT
    o.id AS orden_id,
    o.presupuesto_id,
    o.cliente_id,
    o.vehiculo_id,
    o.mecanico_id
FROM ordenes_trabajo o
LEFT JOIN presupuestos p ON o.presupuesto_id = p.id
LEFT JOIN clientes c ON o.cliente_id = c.id
LEFT JOIN vehiculos v ON o.vehiculo_id = v.id
LEFT JOIN usuarios u ON o.mecanico_id = u.id
WHERE
    p.id IS NULL
    OR c.id IS NULL
    OR v.id IS NULL
    OR (o.mecanico_id IS NOT NULL AND u.id IS NULL);

-- verificar que las consultas no tengan vehículos asociados a un cliente distinto del que figura en la consulta.

SELECT
    co.id AS consulta_id,
    co.cliente_id AS cliente_consulta,
    co.vehiculo_id,
    v.cliente_id AS cliente_vehiculo
FROM consultas co
INNER JOIN vehiculos v
    ON co.vehiculo_id = v.id
WHERE co.cliente_id IS NOT NULL
  AND co.cliente_id <> v.cliente_id;
  
-- validar los mecánicos
SELECT
    o.id AS orden_id,
    u.id AS usuario_id,
    u.nombre,
    r.nombre AS rol
FROM ordenes_trabajo o
INNER JOIN usuarios u
    ON o.mecanico_id = u.id
LEFT JOIN roles r
    ON u.rol_id = r.id
WHERE o.mecanico_id IS NOT NULL
  AND (
      u.tipo_cuenta <> 'taller'
      OR r.nombre <> 'Mecanico'
      OR r.id IS NULL
  );
  
-- pagos de clientes: comprobar que los detalles de cada pago sumen exactamente el importe total registrado.

SELECT
    p.id AS pago_id,
    p.monto AS monto_total,
    COALESCE(SUM(d.importe), 0) AS suma_detalles,
    p.monto - COALESCE(SUM(d.importe), 0) AS diferencia
FROM pagos_clientes p
LEFT JOIN detalles_pagos_clientes d
    ON p.id = d.pago_cliente_id
GROUP BY p.id, p.monto
HAVING p.monto <> COALESCE(SUM(d.importe), 0);
-- verificar que los detalles de los pagos del sistema también coincidan con el importe total informado.
SELECT
    p.id AS pago_sistema_id,
    p.importe_total,
    COALESCE(SUM(d.importe), 0) AS suma_detalles,
    p.importe_total - COALESCE(SUM(d.importe), 0) AS diferencia
FROM pagos_sistema p
LEFT JOIN detalles_pagos_sistema d
    ON p.id = d.pago_id
GROUP BY p.id, p.importe_total
HAVING p.importe_total <> COALESCE(SUM(d.importe), 0);

DESCRIBE clientes;

DESCRIBE vehiculos;

-- Primera consulta: clientes y vehículos mediante INNER JOIN.
SELECT
    c.id AS cliente_id,
    c.nombre AS cliente,
    c.dni,
    v.patente,
    v.marca,
    v.modelo
FROM clientes c
INNER JOIN vehiculos v
    ON c.id = v.cliente_id;
    
-- Segunda consulta: todos los clientes, incluso aquellos que no tengan vehículos, mediante LEFT JOIN.

SELECT
    c.id AS cliente_id,
    c.nombre AS cliente,
    v.patente,
    v.marca,
    v.modelo
FROM clientes c
LEFT JOIN vehiculos v
    ON c.id = v.cliente_id;
    
-- PRUEBA 1.1: Verificar la relación entre usuarios y roles.
-- Los usuarios del taller deben tener un rol asignado.
-- Los superadministradores no deben tener un rol de taller.
SELECT
    u.id,
    u.nombre,
    u.usuario,
    u.tipo_cuenta,
    u.rol_id,
    r.nombre AS nombre_rol
FROM usuarios u
LEFT JOIN roles r ON u.rol_id = r.id
WHERE
    (u.tipo_cuenta = 'taller' AND r.id IS NULL)
    OR
    (u.tipo_cuenta = 'superadmin' AND u.rol_id IS NOT NULL);
    
-- PRUEBA 1.2: Comprobar que cada registro de superadmin
-- corresponda a un usuario cuyo tipo de cuenta sea superadmin.

SELECT
    s.id AS superadmin_id,
    u.id AS usuario_id,
    u.nombre,
    u.usuario,
    u.tipo_cuenta
FROM superadmins s
INNER JOIN usuarios u ON s.usuario_id = u.id
WHERE u.tipo_cuenta <> 'superadmin';

-- PRUEBA 1.3: Comprobar que el administrador configurado
-- en la tabla taller sea un usuario de tipo taller
-- y tenga el rol Administrador.

SELECT
    t.id AS taller_id,
    t.nombre AS taller,
    u.id AS usuario_id,
    u.nombre AS administrador,
    u.tipo_cuenta,
    r.nombre AS rol
FROM taller t
INNER JOIN usuarios u ON t.admin_usuario_id = u.id
LEFT JOIN roles r ON u.rol_id = r.id
WHERE
    u.tipo_cuenta <> 'taller'
    OR r.nombre <> 'Administrador'
    OR r.id IS NULL;

-- PRUEBA 1.4: Mostrar los usuarios de tipo taller
-- que no tengan asociado un rol existente.

SELECT
    u.id,
    u.nombre,
    u.usuario,
    u.rol_id
FROM usuarios u
LEFT JOIN roles r ON u.rol_id = r.id
WHERE
    u.tipo_cuenta = 'taller'
    AND r.id IS NULL;
    
-- PRUEBA 2.1: Buscar vehículos sin un cliente válido.
-- Si aparecen registros, hay una inconsistencia en la relación.

SELECT
    v.id AS vehiculo_id,
    v.patente,
    v.marca,
    v.modelo,
    v.cliente_id
FROM vehiculos v
LEFT JOIN clientes c ON v.cliente_id = c.id
WHERE c.id IS NULL;

-- PRUEBA 2.2: Buscar patentes duplicadas.
-- Se normalizan los espacios y las mayúsculas para detectar
-- posibles duplicados que una comparación simple podría pasar por alto.

SELECT
    UPPER(TRIM(patente)) AS patente_normalizada,
    COUNT(*) AS cantidad,
    GROUP_CONCAT(id ORDER BY id) AS vehiculos
FROM vehiculos
GROUP BY UPPER(TRIM(patente))
HAVING COUNT(*) > 1;

-- PRUEBA 2.3: Buscar DNI duplicados.
-- Se eliminan puntos, espacios y guiones para comparar
-- los números independientemente de cómo fueron escritos.

SELECT
    REPLACE(
        REPLACE(
            REPLACE(TRIM(dni), '.', ''),
            '-', ''
        ),
        ' ', ''
    ) AS dni_normalizado,
    COUNT(*) AS cantidad,
    GROUP_CONCAT(id ORDER BY id) AS clientes
FROM clientes
WHERE dni IS NOT NULL
  AND TRIM(dni) <> ''
GROUP BY dni_normalizado
HAVING COUNT(*) > 1;

-- PRUEBA 2.4: Buscar clientes sin medios de contacto.
-- No es necesariamente un error de base de datos,
-- pero puede dificultar la comunicación con el cliente.

SELECT
    id,
    nombre,
    dni,
    telefono,
    email
FROM clientes
WHERE
    (telefono IS NULL OR TRIM(telefono) = '')
    AND
    (email IS NULL OR TRIM(email) = '');
    
-- PRUEBA 3.1: Buscar consultas con referencias inexistentes.
-- Si cliente_id o vehiculo_id tienen un valor, ese registro
-- debe existir en su tabla correspondiente.

SELECT
    co.id AS consulta_id,
    co.cliente_id,
    co.vehiculo_id,
    co.contacto_nombre,
    co.motivo
FROM consultas co
LEFT JOIN clientes c ON co.cliente_id = c.id
LEFT JOIN vehiculos v ON co.vehiculo_id = v.id
WHERE
    (co.cliente_id IS NOT NULL AND c.id IS NULL)
    OR
    (co.vehiculo_id IS NOT NULL AND v.id IS NULL);
    
-- PRUEBA 3.2: Detectar consultas donde el vehículo
-- pertenece a un cliente distinto del cliente de la consulta.

SELECT
    co.id AS consulta_id,
    co.cliente_id AS cliente_consulta,
    co.vehiculo_id,
    v.cliente_id AS cliente_del_vehiculo,
    co.contacto_nombre,
    v.patente
FROM consultas co
INNER JOIN vehiculos v ON co.vehiculo_id = v.id
WHERE
    co.cliente_id IS NOT NULL
    AND co.cliente_id <> v.cliente_id;
    
-- PRUEBA 3.3: Buscar presupuestos con consultas o creadores inexistentes.
-- Todo presupuesto debe tener una consulta y un usuario creador válidos.

SELECT
    p.id AS presupuesto_id,
    p.consulta_id,
    p.creado_por,
    p.estado
FROM presupuestos p
LEFT JOIN consultas co ON p.consulta_id = co.id
LEFT JOIN usuarios u ON p.creado_por = u.id
WHERE
    co.id IS NULL
    OR u.id IS NULL;

-- PRUEBA 3.4: Comparar el total calculado del presupuesto
-- con la suma de los importes de sus detalles.
--
-- Se revisan solamente presupuestos que tienen detalles.
-- Los presupuestos sin detalles pueden ser borradores todavía.

SELECT
    p.id AS presupuesto_id,
    p.total_calculado,
    COALESCE(SUM(dp.monto), 0) AS suma_detalles,
    p.total_calculado - COALESCE(SUM(dp.monto), 0) AS diferencia
FROM presupuestos p
INNER JOIN detalles_presupuestos dp
    ON p.id = dp.presupuesto_id
GROUP BY
    p.id,
    p.total_calculado
HAVING ABS(
    p.total_calculado - SUM(dp.monto)
) > 0.01;

-- PRUEBA 3.5: Revisar coherencia entre el estado del presupuesto
-- y las fechas registradas.
--
-- Un presupuesto en borrador no necesita fechas.
-- Uno enviado, aceptado o rechazado debe tener fecha_envio.
-- Uno aceptado o rechazado también debe tener fecha_respuesta.

SELECT
    id AS presupuesto_id,
    estado,
    fecha_envio,
    fecha_respuesta
FROM presupuestos
WHERE
    (
        estado IN ('enviado', 'aceptado', 'rechazado')
        AND fecha_envio IS NULL
    )
    OR
    (
        estado IN ('aceptado', 'rechazado')
        AND fecha_respuesta IS NULL
    );
    
-- PRUEBA 4.1: Verificar las relaciones principales de las órdenes.

SELECT
    o.id AS orden_id,
    o.presupuesto_id,
    o.cliente_id,
    o.vehiculo_id,
    o.mecanico_id,
    v.cliente_id AS cliente_del_vehiculo
FROM ordenes_trabajo o
LEFT JOIN presupuestos p ON o.presupuesto_id = p.id
LEFT JOIN clientes c ON o.cliente_id = c.id
LEFT JOIN vehiculos v ON o.vehiculo_id = v.id
WHERE
    p.id IS NULL
    OR c.id IS NULL
    OR v.id IS NULL
    OR (v.id IS NOT NULL AND o.cliente_id <> v.cliente_id);

-- PRUEBA 4.2: Una orden de trabajo debería originarse
-- de un presupuesto aceptado.

SELECT
    o.id AS orden_id,
    o.presupuesto_id,
    p.estado AS estado_presupuesto,
    o.estado AS estado_orden
FROM ordenes_trabajo o
INNER JOIN presupuestos p ON o.presupuesto_id = p.id
WHERE p.estado <> 'aceptado';

-- PRUEBA 4.3: Verificar que los mecánicos sean usuarios
-- de tipo taller y tengan el rol Mecanico.

SELECT
    o.id AS orden_id,
    u.id AS mecanico_id,
    u.nombre AS mecanico,
    u.tipo_cuenta,
    r.nombre AS rol
FROM ordenes_trabajo o
INNER JOIN usuarios u ON o.mecanico_id = u.id
LEFT JOIN roles r ON u.rol_id = r.id
WHERE
    o.mecanico_id IS NOT NULL
    AND (
        u.tipo_cuenta <> 'taller'
        OR r.nombre <> 'Mecanico'
        OR r.id IS NULL
    )

UNION ALL

SELECT
    a.orden_id,
    u.id,
    u.nombre,
    u.tipo_cuenta,
    r.nombre
FROM asignaciones_trabajo a
INNER JOIN usuarios u ON a.mecanico_id = u.id
LEFT JOIN roles r ON u.rol_id = r.id
WHERE
    u.tipo_cuenta <> 'taller'
    OR r.nombre <> 'Mecanico'
    OR r.id IS NULL;
    
-- PRUEBA 4.4: Comprobar que las asignaciones resueltas
-- tengan registrada la fecha en que se resolvieron.

SELECT
    id AS asignacion_id,
    orden_id,
    mecanico_id,
    resultado,
    creado_en,
    resuelto_en
FROM asignaciones_trabajo
WHERE
    resultado IN ('aceptada', 'rechazada', 'reasignada', 'completada')
    AND resuelto_en IS NULL;
    
-- PRUEBA 4.5: Revisar los estados registrados en el historial.
-- Se detectan estados que no pertenecen al ENUM de ordenes_trabajo
-- y usuarios inexistentes que hayan realizado cambios.

SELECT
    h.id AS historial_id,
    h.orden_id,
    h.estado_anterior,
    h.estado_nuevo,
    h.cambiado_por
FROM historial_estados_ordenes h
LEFT JOIN usuarios u ON h.cambiado_por = u.id
WHERE
    u.id IS NULL
    OR h.estado_nuevo NOT IN (
        'sin_asignar',
        'ofrecido',
        'aceptado',
        'en_proceso',
        'finalizado',
        'cancelado'
    )
    OR (
        h.estado_anterior IS NOT NULL
        AND h.estado_anterior NOT IN (
            'sin_asignar',
            'ofrecido',
            'aceptado',
            'en_proceso',
            'finalizado',
            'cancelado'
        )
    );
    
-- PRUEBA 5.1: Revisar la relación entre pagos, órdenes y clientes.
-- Se consideran inconsistencias:
-- 1. Un pago de tipo trabajo sin orden asociada.
-- 2. Una venta de mostrador asociada a una orden.
-- 3. Un pago cuya orden no existe.
-- 4. Un cliente del pago diferente al cliente de la orden.

SELECT
    p.id AS pago_id,
    p.tipo,
    p.orden_id,
    p.cliente_id AS cliente_del_pago,
    o.cliente_id AS cliente_de_la_orden
FROM pagos_clientes p
LEFT JOIN ordenes_trabajo o ON p.orden_id = o.id
WHERE
    (p.tipo = 'trabajo' AND p.orden_id IS NULL)
    OR (p.tipo = 'venta_mostrador' AND p.orden_id IS NOT NULL)
    OR (p.orden_id IS NOT NULL AND o.id IS NULL)
    OR (
        p.orden_id IS NOT NULL
        AND p.cliente_id IS NOT NULL
        AND p.cliente_id <> o.cliente_id
    );
    
-- PRUEBA 5.2: Comparar el monto del pago con la suma de sus detalles.
-- Si un pago tiene detalles, su suma debe coincidir con el monto.
-- Si el método es combinado, debe existir al menos un detalle.
-- Los pagos simples sin detalles son válidos según el esquema.

SELECT
    p.id AS pago_id,
    p.metodo,
    p.monto,
    COUNT(d.id) AS cantidad_detalles,
    COALESCE(SUM(d.importe), 0) AS suma_detalles,
    p.monto - COALESCE(SUM(d.importe), 0) AS diferencia
FROM pagos_clientes p
LEFT JOIN detalles_pagos_clientes d
    ON p.id = d.pago_cliente_id
GROUP BY
    p.id,
    p.metodo,
    p.monto
HAVING
    (COUNT(d.id) > 0 AND p.monto <> SUM(d.importe))
    OR
    (p.metodo = 'combinado' AND COUNT(d.id) = 0);
    
-- PRUEBA 5.3: Verificar que los detalles respeten el método declarado.
-- Para pagos simples con detalles debe existir exactamente un detalle
-- y su medio debe coincidir con el método del pago.
-- Los pagos combinados quedan excluidos porque pueden tener varios medios.

SELECT
    p.id AS pago_id,
    p.metodo,
    COUNT(d.id) AS cantidad_detalles,
    GROUP_CONCAT(d.medio) AS medios_registrados
FROM pagos_clientes p
INNER JOIN detalles_pagos_clientes d
    ON p.id = d.pago_cliente_id
WHERE p.metodo <> 'combinado'
GROUP BY p.id, p.metodo
HAVING
    COUNT(d.id) <> 1
    OR MAX(d.medio) <> p.metodo;
    
-- PRUEBA 5.4: Revisar los importes de pagos y sus detalles.
-- El esquema establece que los importes deben ser mayores que cero.
-- Esta consulta permite comprobarlo también sobre los datos existentes.

SELECT
    'pago_cliente' AS origen,
    p.id AS registro_id,
    p.monto AS importe
FROM pagos_clientes p
WHERE p.monto IS NULL OR p.monto <= 0

UNION ALL

SELECT
    'detalle_pago_cliente' AS origen,
    d.id AS registro_id,
    d.importe AS importe
FROM detalles_pagos_clientes d
WHERE d.importe IS NULL OR d.importe <= 0;

-- PRUEBA 5.5: Un pago marcado como combinado debería
-- tener al menos dos medios de pago diferentes.
--
-- La restricción UNIQUE de la tabla evita repetir
-- un mismo medio dentro de un pago.

SELECT
    p.id AS pago_id,
    p.monto,
    COUNT(d.id) AS cantidad_medios,
    GROUP_CONCAT(d.medio) AS medios_registrados
FROM pagos_clientes p
LEFT JOIN detalles_pagos_clientes d
    ON d.pago_cliente_id = p.id
WHERE p.metodo = 'combinado'
GROUP BY
    p.id,
    p.monto
HAVING COUNT(d.id) < 2;

-- PRUEBA 6.1: Verificar que los movimientos de stock
-- asociados al catálogo correspondan a repuestos y no servicios.
--
-- Un servicio no debería generar movimientos de inventario.

SELECT
    m.id AS movimiento_id,
    m.catalogo_item_id,
    c.nombre AS articulo,
    c.tipo AS tipo_catalogo,
    m.tipo AS tipo_movimiento,
    m.cantidad
FROM movimientos_stock m
INNER JOIN catalogo_items c
    ON m.catalogo_item_id = c.id
WHERE c.tipo = 'servicio';

-- PRUEBA 6.2: Revisar si los movimientos pendientes
-- todavía no tienen un usuario que los haya resuelto,
-- y si los confirmados o rechazados sí tienen uno.
--
-- Resultado esperado: 0 registros.
--
-- Esta prueba supone que toda resolución debe registrar
-- quién la realizó.

SELECT
    id AS movimiento_id,
    estado,
    solicitado_por,
    resuelto_por,
    fecha
FROM movimientos_stock
WHERE
    (estado = 'pendiente' AND resuelto_por IS NOT NULL)
    OR
    (estado IN ('confirmado', 'rechazado') AND resuelto_por IS NULL);
    
    -- PRUEBA 6.3: Si un movimiento tiene una orden y un pago
-- asociados, comprobar que el pago corresponda a esa misma orden.
--
-- Resultado esperado: 0 registros.

SELECT
    m.id AS movimiento_id,
    m.orden_id AS orden_movimiento,
    m.pago_cliente_id,
    p.orden_id AS orden_del_pago,
    p.monto AS monto_pago
FROM movimientos_stock m
INNER JOIN pagos_clientes p
    ON m.pago_cliente_id = p.id
WHERE
    m.orden_id IS NOT NULL
    AND p.orden_id IS NOT NULL
    AND m.orden_id <> p.orden_id;
    
-- PRUEBA 6.4: Identificar artículos cuyo stock actual
-- sea menor o igual al stock mínimo configurado.
--
-- Esta consulta es informativa: puede devolver registros.
-- No significa necesariamente que exista un error.

SELECT
    id AS articulo_id,
    nombre,
    tipo,
    cantidad AS stock_actual,
    stock_minimo,
    activo
FROM catalogo_items
WHERE
    tipo = 'repuesto'
    AND cantidad <= stock_minimo
ORDER BY cantidad ASC;

-- PRUEBA 7.1: Comprobar que el mecánico del movimiento
-- coincida con el mecánico de la liquidación.

SELECT
    l.id AS liquidacion_id,
    l.mecanico_id AS mecanico_liquidacion,
    m.id AS movimiento_id,
    m.mecanico_id AS mecanico_movimiento
FROM detalles_liquidaciones_mecanicos d
INNER JOIN liquidaciones_mecanicos l
    ON d.liquidacion_id = l.id
INNER JOIN movimientos_mecanicos m
    ON d.movimiento_mecanico_id = m.id
WHERE l.mecanico_id <> m.mecanico_id;

-- PRUEBA 7.2: Comparar los totales de la liquidación
-- con los importes de sus movimientos detallados.

SELECT
    l.id AS liquidacion_id,
    l.total_comisiones,
    COALESCE(SUM(
        CASE WHEN m.tipo = 'comision'
        THEN d.importe_incluido ELSE 0 END
    ), 0) AS comisiones_calculadas,
    l.total_adelantos,
    COALESCE(SUM(
        CASE WHEN m.tipo = 'adelanto'
        THEN d.importe_incluido ELSE 0 END
    ), 0) AS adelantos_calculados
FROM liquidaciones_mecanicos l
LEFT JOIN detalles_liquidaciones_mecanicos d
    ON l.id = d.liquidacion_id
LEFT JOIN movimientos_mecanicos m
    ON d.movimiento_mecanico_id = m.id
GROUP BY
    l.id,
    l.total_comisiones,
    l.total_adelantos
HAVING
    l.total_comisiones <> comisiones_calculadas
    OR l.total_adelantos <> adelantos_calculados;

-- PRUEBA 7.3: Comprobar la operación matemática
-- utilizada para calcular el importe final de la liquidación.

SELECT
    id AS liquidacion_id,
    total_comisiones,
    total_adelantos,
    total_a_pagar,
    (total_comisiones - total_adelantos) AS calculo_esperado
FROM liquidaciones_mecanicos
WHERE total_a_pagar <> (total_comisiones - total_adelantos);

-- PRUEBA 7.4: Revisar la coherencia entre el estado
-- de la liquidación y su fecha de pago.

SELECT
    id AS liquidacion_id,
    estado,
    fecha_pago
FROM liquidaciones_mecanicos
WHERE
    (estado = 'pagada' AND fecha_pago IS NULL)
    OR
    (estado = 'pendiente' AND fecha_pago IS NOT NULL);
    
-- PRUEBA 7.5: Consultar los movimientos registrados
-- para cada mecánico y revisar sus importes.

SELECT
    m.id AS movimiento_id,
    u.nombre AS mecanico,
    m.tipo,
    m.monto,
    m.orden_id,
    m.fecha,
    m.descripcion
FROM movimientos_mecanicos m
INNER JOIN usuarios u
    ON m.mecanico_id = u.id
ORDER BY m.fecha DESC;

-- PRUEBA 8.1: Comparar el importe total del pago
-- con la suma de sus detalles.

SELECT
    p.id AS pago_id,
    p.importe_total,
    COALESCE(SUM(d.importe), 0) AS suma_detalles
FROM pagos_sistema p
LEFT JOIN detalles_pagos_sistema d
    ON p.id = d.pago_id
GROUP BY p.id, p.importe_total
HAVING p.importe_total <> COALESCE(SUM(d.importe), 0);

-- PRUEBA 8.2: Revisar que los pagos confirmados
-- tengan registrada su confirmación.

SELECT
    id AS pago_id,
    estado,
    confirmado_por,
    fecha_confirmacion
FROM pagos_sistema
WHERE estado = 'confirmado'
AND (
    confirmado_por IS NULL
    OR fecha_confirmacion IS NULL
);

-- PRUEBA 8.3: Revisar que los pagos informados
-- o rechazados no tengan una confirmación registrada.

SELECT
    id AS pago_id,
    estado,
    confirmado_por,
    fecha_confirmacion
FROM pagos_sistema
WHERE estado IN ('informado', 'rechazado')
AND (
    confirmado_por IS NOT NULL
    OR fecha_confirmacion IS NOT NULL
);

-- PRUEBA 8.4: Comprobar que los períodos pagados
-- tengan registrada la fecha de confirmación.

SELECT
    id AS periodo_id,
    numero,
    estado,
    fecha_pago_confirmado
FROM periodos_pago_sistema
WHERE estado = 'pagado'
AND fecha_pago_confirmado IS NULL;

-- PRUEBA 8.5: Consultar los pagos del sistema
-- y el período de suscripción correspondiente.

SELECT
    p.id AS pago_id,
    p.importe_total,
    p.metodo,
    p.estado AS estado_pago,
    pp.numero AS numero_periodo,
    pp.modalidad,
    pp.importe AS importe_periodo,
    pp.estado AS estado_periodo
FROM pagos_sistema p
INNER JOIN periodos_pago_sistema pp
    ON p.periodo_id = pp.id
ORDER BY p.fecha_registro DESC;

-- PRUEBA 9.1: Verificar que cada notificación
-- tenga exactamente un destinatario.

SELECT
    id AS notificacion_id,
    usuario_id,
    superadmin_id,
    texto
FROM notificaciones
WHERE
    (usuario_id IS NULL AND superadmin_id IS NULL)
    OR
    (usuario_id IS NOT NULL AND superadmin_id IS NOT NULL);
    
-- PRUEBA 9.2: Revisar que los registros de auditoría
-- identifiquen correctamente al usuario o superadministrador.

SELECT
    id AS auditoria_id,
    ambito,
    usuario_id,
    superadmin_id,
    actor_login,
    accion
FROM auditoria
WHERE
    (ambito = 'taller'
        AND (usuario_id IS NULL OR superadmin_id IS NOT NULL))
    OR
    (ambito = 'sistema'
        AND (superadmin_id IS NULL OR usuario_id IS NOT NULL));
        
-- PRUEBA 9.3: Comprobar la relación entre el estado
-- de una propuesta de IA y su fecha de resolución.
SELECT
    id AS propuesta_id,
    estado,
    creada_en,
    resuelta_en
FROM propuestas_ia
WHERE
    (estado = 'generada' AND resuelta_en IS NOT NULL)
    OR
    (estado IN ('aceptada', 'editada', 'descartada')
        AND resuelta_en IS NULL);

-- PRUEBA 9.4: Revisar que cada propuesta tenga
-- la referencia correspondiente a su contexto.
--
-- problema_consulta: debe tener consulta_id.
-- inspeccion y observacion_mecanico: deben tener orden_id.
SELECT
    id AS propuesta_id,
    contexto,
    consulta_id,
    orden_id
FROM propuestas_ia
WHERE
    (contexto = 'problema_consulta' AND consulta_id IS NULL)
    OR
    (contexto IN ('inspeccion', 'observacion_mecanico')
        AND orden_id IS NULL);
-- PRUEBA 9.5: Consultar los archivos asociados
-- a las órdenes de trabajo y sus usuarios responsables.

SELECT
    a.id AS archivo_id,
    a.orden_id,
    o.id AS orden_verificada,
    a.nombre_archivo,
    a.ruta_archivo,
    a.tipo_archivo,
    u.nombre AS subido_por,
    a.fecha_subida
FROM archivos_trabajos a
INNER JOIN ordenes_trabajo o
    ON a.orden_id = o.id
INNER JOIN usuarios u
    ON a.subido_por = u.id
ORDER BY a.fecha_subida DESC;