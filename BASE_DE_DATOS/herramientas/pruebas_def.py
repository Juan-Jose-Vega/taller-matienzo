# -*- coding: utf-8 -*-
"""Definición ÚNICA de las pruebas SQL. De acá salen: la sección 3 del SQL final, la ejecución real y DOCUMENTACION/pruebas_sql.md.

Tipos de prueba (kind):
  integridad : consulta que debe devolver 0 filas (cada fila devuelta sería una inconsistencia)
  info       : consulta informativa que debe devolver filas (>= 1, o exactamente N)
  op         : operación (INSERT/UPDATE/DELETE) dentro de una transacción que termina en ROLLBACK; la última consulta devuelve resultado = 'OK'
  error      : sentencia que DEBE fallar con un código de error MySQL concreto (se ejecuta con sp_esperar_error, siempre con ROLLBACK)
expect: ('rows0',) | ('rowsgt',) | ('rowsN', n) | ('ok',) | ('err', codigo)
"""

MODULOS = [
    ('1', 'Usuarios y roles'), ('2', 'Taller'), ('3', 'Clientes y vehículos'), ('4', 'Consultas'), ('5', 'Presupuestos'),
    ('6', 'Órdenes de trabajo'), ('7', 'Asignaciones'), ('8', 'Pagos de clientes'), ('9', 'Catálogo y stock'),
    ('10', 'Movimientos de mecánicos'), ('11', 'Liquidaciones'), ('12', 'Suscripciones'), ('13', 'Pagos del sistema'),
    ('14', 'Notificaciones'), ('15', 'Auditoría'), ('16', 'Propuestas de IA'), ('17', 'Estructura e integridad general'),
    ('18', 'Procesos principales de punta a punta'),
]
P = []


def t(id, nombre, objetivo, tablas, kind, sql, esperado, interp, expect, orig=None):
    P.append(dict(id=id, modulo=id.split('.')[0], nombre=nombre, objetivo=objetivo, tablas=tablas, kind=kind, sql=sql.strip(), esperado=esperado, interp=interp, expect=expect, orig=orig))


R0 = ('rows0',)
# ============================== 1. USUARIOS Y ROLES ==============================
t('1.1', 'Usuarios de taller con rol válido', 'Todo usuario de taller debe tener un rol existente.', 'usuarios, roles', 'integridad',
  "SELECT u.id, u.usuario FROM usuarios u LEFT JOIN roles r ON r.id = u.rol_id WHERE u.tipo_cuenta = 'taller' AND r.id IS NULL;",
  '0 filas', 'Si aparece alguna fila, hay un usuario de taller sin rol válido.', R0, 'PRUEBA 1.1')
t('1.2', 'SuperAdmin sin rol operativo y con registro en superadmins', 'Cada usuario superadmin debe tener rol_id NULL y su fila en superadmins.', 'usuarios, superadmins', 'integridad',
  "SELECT u.id, u.usuario FROM usuarios u LEFT JOIN superadmins s ON s.usuario_id = u.id WHERE u.tipo_cuenta = 'superadmin' AND (s.id IS NULL OR u.rol_id IS NOT NULL);",
  '0 filas', 'Cumple la regla: el SuperAdmin no es un rol común del taller y está registrado en su tabla propia.', R0, 'PRUEBA 1.2')
t('1.3', 'Administrador del taller correcto', 'El administrador registrado en taller debe ser un usuario de taller con rol Administrador.', 'taller, usuarios, roles', 'integridad',
  "SELECT t.id FROM taller t JOIN usuarios u ON u.id = t.admin_usuario_id JOIN roles r ON r.id = u.rol_id WHERE u.tipo_cuenta <> 'taller' OR r.nombre <> 'Administrador';",
  '0 filas', 'El dueño del taller es siempre un usuario con rol Administrador.', R0, 'PRUEBA 1.3')
t('1.4', 'Usuarios de taller sin rol (control cruzado)', 'Control complementario de la 1.1 usando NOT EXISTS.', 'usuarios, roles', 'integridad',
  "SELECT u.id FROM usuarios u WHERE u.tipo_cuenta = 'taller' AND NOT EXISTS (SELECT 1 FROM roles r WHERE r.id = u.rol_id);",
  '0 filas', 'Confirma la 1.1 con otra forma de consulta.', R0, 'PRUEBA 1.4')
t('1.5', 'Listado de usuarios con su rol (INNER JOIN)', 'Mostrar los usuarios del taller con el nombre de su rol.', 'usuarios, roles', 'info',
  "SELECT u.id, u.usuario, u.nombre, r.nombre AS rol, u.estado FROM usuarios u INNER JOIN roles r ON r.id = u.rol_id ORDER BY u.id;",
  '4 filas (1 administrador y 3 mecánicos)', 'El SuperAdmin no aparece porque no tiene rol operativo.', ('rowsN', 4))
t('1.6', 'Contraseñas almacenadas como hash', 'Ningún password_hash puede ser texto plano: deben ser hashes bcrypt ($2b$, 60 caracteres).', 'usuarios', 'integridad',
  "SELECT id, usuario FROM usuarios WHERE password_hash NOT REGEXP '^\\\\$2[aby]\\\\$[0-9]{2}\\\\$.{53}$';",
  '0 filas', 'Todas las contraseñas de demostración son hashes bcrypt; nunca texto plano.', R0)
t('1.7', 'SuperAdmin no figura como rol operativo', 'La tabla roles no debe contener un rol SuperAdmin.', 'roles', 'integridad',
  "SELECT id, nombre FROM roles WHERE LOWER(nombre) LIKE '%superadmin%';",
  '0 filas', 'El SuperAdmin se distingue por tipo_cuenta, no por un rol.', R0)
t('1.8', 'Alta de un mecánico', 'Insertar un mecánico nuevo y comprobar que queda con su rol (se deshace con ROLLBACK).', 'usuarios, roles', 'op',
  """START TRANSACTION;
INSERT INTO usuarios (id, tipo_cuenta, rol_id, nombre, usuario, password_hash, telefono, especialidad, disponible)
VALUES (9001, 'taller', 2, 'Mecánico de Prueba', 'mecprueba', '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ0123456', '381-0000000', 'Electricidad', 1);
SELECT IF(COUNT(*) = 1 AND MAX(r.nombre) = 'Mecanico' AND MAX(u.especialidad) = 'Electricidad', 'OK', 'FALLA') AS resultado
FROM usuarios u INNER JOIN roles r ON r.id = u.rol_id WHERE u.id = 9001;
ROLLBACK;""", 'resultado = OK', 'El alta funciona y los datos de mecánico (especialidad, disponibilidad) se guardan en usuarios.', ('ok',))
t('1.9', 'Pausar a un mecánico', 'UPDATE del estado de un usuario (equivale a "inactivo" en el MVP).', 'usuarios', 'op',
  """START TRANSACTION;
UPDATE usuarios SET estado = 'pausado', disponible = 0 WHERE usuario = 'carlos';
SELECT IF(estado = 'pausado' AND disponible = 0, 'OK', 'FALLA') AS resultado FROM usuarios WHERE usuario = 'carlos';
ROLLBACK;""", 'resultado = OK', 'La baja lógica se guarda sin borrar al usuario (conserva su historial).', ('ok',))
t('1.10', 'Baja física de un usuario sin historial', 'DELETE de un usuario recién creado, sin movimientos.', 'usuarios', 'op',
  """START TRANSACTION;
INSERT INTO usuarios (id, tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES (9002, 'taller', 2, 'Temporal', 'temporal', '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ0123456');
DELETE FROM usuarios WHERE id = 9002;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM usuarios WHERE id = 9002;
ROLLBACK;""", 'resultado = OK', 'Un usuario sin registros asociados se puede eliminar.', ('ok',))
t('1.11', 'Usuario duplicado rechazado', 'El nombre de usuario es único.', 'usuarios', 'error',
  "INSERT INTO usuarios (tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES ('taller', 2, 'Otro Juan', 'juan', 'x');",
  'ERROR 1062 (clave duplicada)', 'La restricción UNIQUE impide dos usuarios con el mismo nombre.', ('err', 1062))
t('1.12', 'SuperAdmin con rol rechazado', 'CHECK ck_usuarios_tipo_rol: un superadmin no puede tener rol operativo.', 'usuarios', 'error',
  "INSERT INTO usuarios (tipo_cuenta, rol_id, nombre, usuario, password_hash) VALUES ('superadmin', 1, 'Falso SA', 'falsosa', 'x');",
  'ERROR 3819 (restricción CHECK)', 'El rol operativo y el SuperAdmin son excluyentes.', ('err', 3819))
t('1.13', 'No se puede borrar un rol en uso', 'Integridad referencial usuarios -> roles.', 'roles, usuarios', 'error',
  "DELETE FROM roles WHERE nombre = 'Mecanico';",
  'ERROR 1451 (clave foránea)', 'La FK protege los usuarios que usan el rol.', ('err', 1451))
t('1.14', 'Roles de MySQL = roles del frontend', 'La tabla roles tiene exactamente Administrador (1) y Mecanico (2), los mismos del MVP; el SuperAdmin no figura.', 'roles', 'integridad',
  "SELECT x.* FROM (SELECT COUNT(*) AS c, SUM(id = 1 AND nombre = 'Administrador') AS a, SUM(id = 2 AND nombre = 'Mecanico') AS m FROM roles) x WHERE NOT (x.c = 2 AND x.a = 1 AND x.m = 1);", '0 filas', 'Vue resuelve el rol por código (admin, mecanico) y MySQL lo guarda en roles.', R0)
t('1.15', 'Un único SuperAdmin, separado del taller', 'El SuperAdmin no es dueño ni mecánico ni aparece en listas operativas.', 'usuarios, taller, superadmins', 'integridad',
  "SELECT u.id FROM usuarios u WHERE u.tipo_cuenta = 'superadmin' AND (u.rol_id IS NOT NULL OR EXISTS (SELECT 1 FROM taller t WHERE t.admin_usuario_id = u.id) OR EXISTS (SELECT 1 FROM asignaciones_trabajo a WHERE a.mecanico_id = u.id));", '0 filas', 'Cuenta independiente con contraseña hash en la base.', R0)

# ============================== 2. TALLER ==============================
t('2.1', 'Existe un único taller', 'El sistema administra un solo taller.', 'taller', 'integridad',
  "SELECT COUNT(*) AS cantidad FROM taller HAVING COUNT(*) <> 1;",
  '0 filas', 'Si devolviera una fila, habría 0 o más de 1 taller.', R0)
t('2.2', 'Taller con su administrador (INNER JOIN)', 'Mostrar el taller y su dueño.', 'taller, usuarios', 'info',
  "SELECT t.id, t.nombre, u.nombre AS administrador, t.estado_acceso FROM taller t INNER JOIN usuarios u ON u.id = t.admin_usuario_id;",
  '1 fila: Taller Matienzo / Roberto Díaz / activo', 'Relación 1 a 1 entre taller y su administrador.', ('rowsN', 1))
t('2.3', 'Segundo taller rechazado', 'CHECK ck_taller_unico (id = 1).', 'taller', 'error',
  "INSERT INTO taller (id, nombre, admin_usuario_id) VALUES (2, 'Otro Taller', 3);",
  'ERROR 3819 (restricción CHECK)', 'No es posible crear un segundo taller.', ('err', 3819))
t('2.4', 'Bloqueo y desbloqueo del taller', 'UPDATE de estado_acceso (lo que hace el sistema al vencer la tolerancia).', 'taller', 'op',
  """START TRANSACTION;
UPDATE taller SET estado_acceso = 'bloqueado', bloqueado_en = NOW(), motivo_bloqueo = 'Falta de pago' WHERE id = 1;
SELECT IF(estado_acceso = 'bloqueado', 'OK', 'FALLA') AS resultado FROM taller WHERE id = 1;
ROLLBACK;""", 'resultado = OK', 'El bloqueo operativo se registra en el taller; el SuperAdmin sigue pudiendo ingresar.', ('ok',))

# ============================== 3. CLIENTES Y VEHÍCULOS ==============================
t('3.1', 'Vehículos con propietario válido', 'Todo vehículo debe pertenecer a un cliente existente.', 'vehiculos, clientes', 'integridad',
  "SELECT v.id FROM vehiculos v LEFT JOIN clientes c ON c.id = v.cliente_id WHERE c.id IS NULL;", '0 filas', 'Sin vehículos huérfanos.', R0, 'PRUEBA 2.1')
t('3.2', 'Patentes duplicadas', 'La patente cargada es única.', 'vehiculos', 'integridad',
  "SELECT patente, COUNT(*) AS veces FROM vehiculos WHERE patente IS NOT NULL GROUP BY patente HAVING COUNT(*) > 1;", '0 filas', 'La restricción UNIQUE se refleja en los datos.', R0, 'PRUEBA 2.2')
t('3.3', 'Clientes con sus vehículos (INNER JOIN)', 'Listar cada vehículo con su cliente.', 'clientes, vehiculos', 'info',
  "SELECT c.id AS cliente_id, c.nombre, v.patente, v.marca, v.modelo FROM clientes c INNER JOIN vehiculos v ON v.cliente_id = c.id ORDER BY c.id, v.id;",
  '17 filas', 'Un cliente puede tener varios vehículos (1 a N).', ('rowsN', 17), 'PRUEBA 2.3')
t('3.4', 'Clientes sin vehículos (LEFT JOIN)', 'Los clientes de demostración deben tener al menos un vehículo.', 'clientes, vehiculos', 'integridad',
  "SELECT c.id, c.nombre FROM clientes c LEFT JOIN vehiculos v ON v.cliente_id = c.id WHERE v.id IS NULL;", '0 filas', 'Datos de demostración coherentes.', R0, 'PRUEBA 2.4')
t('3.5', 'Alta de cliente con vehículo', 'INSERT de cliente y vehículo relacionados, sin patente ni kilometraje (opcionales en el MVP).', 'clientes, vehiculos', 'op',
  """START TRANSACTION;
INSERT INTO clientes (id, nombre, telefono) VALUES (9001, 'Cliente de Prueba', '381-1112233');
INSERT INTO vehiculos (id, cliente_id, patente, marca, modelo) VALUES (9001, 9001, NULL, 'Ford', 'Fiesta');
INSERT INTO vehiculos (id, cliente_id, patente, marca, modelo) VALUES (9002, 9001, NULL, 'Fiat', 'Uno');
SELECT IF(COUNT(*) = 2 AND SUM(v.kilometraje IS NULL) = 2, 'OK', 'FALLA') AS resultado FROM clientes c INNER JOIN vehiculos v ON v.cliente_id = c.id WHERE c.id = 9001;
ROLLBACK;""", 'resultado = OK', 'Se admiten varios vehículos sin patente (NULL no viola UNIQUE).', ('ok',))
t('3.6', 'Actualizar kilometraje', 'UPDATE de un dato del vehículo.', 'vehiculos', 'op',
  """START TRANSACTION;
UPDATE vehiculos SET kilometraje = 123456 WHERE id = 1;
SELECT IF(kilometraje = 123456, 'OK', 'FALLA') AS resultado FROM vehiculos WHERE id = 1;
ROLLBACK;""", 'resultado = OK', 'Modificación simple.', ('ok',))
t('3.7', 'Eliminar cliente nuevo y su vehículo', 'DELETE en orden: primero el vehículo y luego el cliente.', 'clientes, vehiculos', 'op',
  """START TRANSACTION;
INSERT INTO clientes (id, nombre) VALUES (9003, 'Borrar');
INSERT INTO vehiculos (id, cliente_id, marca) VALUES (9003, 9003, 'Renault');
DELETE FROM vehiculos WHERE id = 9003;
DELETE FROM clientes WHERE id = 9003;
SELECT IF((SELECT COUNT(*) FROM clientes WHERE id = 9003) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'Eliminación correcta respetando las dependencias.', ('ok',))
t('3.8', 'No se puede borrar un cliente con vehículos', 'Integridad referencial clientes -> vehiculos.', 'clientes, vehiculos', 'error',
  "DELETE FROM clientes WHERE id = 1;", 'ERROR 1451 (clave foránea)', 'La FK evita dejar vehículos sin dueño.', ('err', 1451))
t('3.9', 'Patente duplicada rechazada', 'UNIQUE uq_vehiculos_patente.', 'vehiculos', 'error',
  "INSERT INTO vehiculos (cliente_id, patente, marca) SELECT 1, patente, 'Fiat' FROM vehiculos WHERE patente IS NOT NULL LIMIT 1;", 'ERROR 1062 (clave duplicada)', 'No pueden existir dos vehículos con la misma patente.', ('err', 1062))

# ============================== 4. CONSULTAS ==============================
t('4.1', 'Consultas con cliente y vehículo coherentes', 'Si la consulta tiene vehículo, éste debe pertenecer al cliente de la consulta.', 'consultas, vehiculos', 'integridad',
  "SELECT c.id FROM consultas c INNER JOIN vehiculos v ON v.id = c.vehiculo_id WHERE c.cliente_id IS NULL OR c.cliente_id <> v.cliente_id;", '0 filas', 'El vehículo consultado es del cliente que consulta.', R0, 'PRUEBA 3.1')
t('4.2', 'Detalles de consulta con consulta existente', 'detalles_consultas no tiene filas huérfanas.', 'detalles_consultas, consultas', 'integridad',
  "SELECT d.id FROM detalles_consultas d LEFT JOIN consultas c ON c.id = d.consulta_id WHERE c.id IS NULL;", '0 filas', 'Relación 1 a N consulta -> detalles correcta.', R0, 'PRUEBA 3.2')
t('4.3', 'Consultas con cliente y vehículo (INNER JOIN)', 'Listar las consultas registradas junto a su cliente y vehículo.', 'consultas, clientes, vehiculos', 'info',
  "SELECT c.id, cl.nombre AS cliente, v.patente, v.marca, v.modelo, c.estado FROM consultas c INNER JOIN clientes cl ON cl.id = c.cliente_id INNER JOIN vehiculos v ON v.id = c.vehiculo_id ORDER BY c.id;",
  '20 filas (consultas con cliente y vehículo registrados)', 'Consultas completas con sus relaciones.', ('rowsN', 20))
t('4.4', 'Solo la primera consulta de un cliente es gratuita', 'Regla del MVP: las consultas repetidas no son gratuitas por defecto.', 'consultas', 'integridad',
  "SELECT c.id FROM consultas c WHERE c.es_gratuita = 1 AND EXISTS (SELECT 1 FROM consultas x WHERE x.cliente_id = c.cliente_id AND x.id < c.id);", '0 filas', 'Los datos respetan la regla de consulta gratuita.', R0)
t('4.5', 'Consultas cerradas con motivo', 'Toda consulta cerrada sin trabajo debe indicar el motivo.', 'consultas', 'integridad',
  "SELECT id FROM consultas WHERE estado = 'cerrada' AND (motivo_cierre IS NULL OR motivo_cierre = '');", '0 filas', 'Cierre justificado.', R0)
t('4.6', 'Consultas aprobadas tienen presupuesto aceptado', 'Una consulta aprobada debe tener su presupuesto aceptado.', 'consultas, presupuestos', 'integridad',
  "SELECT c.id FROM consultas c LEFT JOIN presupuestos p ON p.consulta_id = c.id AND p.estado = 'aceptado' WHERE c.estado = 'aprobada' AND p.id IS NULL;", '0 filas', 'Estado de consulta coherente con el presupuesto.', R0)
t('4.7', 'Alta de consulta con revisión técnica', 'INSERT de consulta y de su revisión (varias filas de detalle) y su importe estimado.', 'consultas, detalles_consultas', 'op',
  """START TRANSACTION;
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, contacto_telefono, motivo, descripcion_problema, estado, es_gratuita, creado_por)
VALUES (9001, 1, 1, 'Carlos Gómez', '381-0000', 'Ruido al frenar', 'Ruido al frenar y pedal blando', 'abierta', 0, 2);
INSERT INTO detalles_consultas (consulta_id, descripcion, tipo, registrado_por) VALUES
 (9001, 'Pastillas gastadas', 'verificado', 2), (9001, 'Pastillas delanteras', 'repuestos_necesarios', 2), (9001, 'Cambio de pastillas', 'trabajo_recomendado', 2);
UPDATE consultas SET observaciones_inspeccion = 'Discos en buen estado', importe_estimado = 45000 WHERE id = 9001;
SELECT IF(COUNT(*) = 3 AND MAX(c.importe_estimado) = 45000, 'OK', 'FALLA') AS resultado FROM consultas c INNER JOIN detalles_consultas d ON d.consulta_id = c.id WHERE c.id = 9001;
ROLLBACK;""", 'resultado = OK', 'La revisión del MVP se distribuye en filas por tipo + 2 columnas de la consulta.', ('ok',))
t('4.8', 'Cierre de consulta sin trabajo', 'UPDATE a estado cerrada con motivo.', 'consultas', 'op',
  """START TRANSACTION;
UPDATE consultas SET estado = 'cerrada', motivo_cierre = 'El cliente no continuó' WHERE id = 1;
SELECT IF(estado = 'cerrada' AND motivo_cierre IS NOT NULL, 'OK', 'FALLA') AS resultado FROM consultas WHERE id = 1;
ROLLBACK;""", 'resultado = OK', 'Cierre registrado.', ('ok',))
t('4.9', 'Eliminar consulta y sus detalles', 'DELETE de una consulta nueva: los detalles se eliminan en cascada.', 'consultas, detalles_consultas', 'op',
  """START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9002, 'Persona', 'Prueba', 2);
INSERT INTO detalles_consultas (consulta_id, descripcion, registrado_por) VALUES (9002, 'x', 2);
DELETE FROM consultas WHERE id = 9002;
SELECT IF((SELECT COUNT(*) FROM detalles_consultas WHERE consulta_id = 9002) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'ON DELETE CASCADE de detalles_consultas.', ('ok',))
t('4.10', 'Cobro "cobrar" sin importe rechazado', 'CHECK ck_consultas_cobro.', 'consultas', 'error',
  "UPDATE consultas SET cobro_decision = 'cobrar', cobro_importe = NULL WHERE id = 1;", 'ERROR 3819 (restricción CHECK)', 'Si se decide cobrar, el importe es obligatorio.', ('err', 3819))

# ============================== 5. PRESUPUESTOS ==============================
t('5.1', 'Un presupuesto por consulta', 'Cada consulta tiene como máximo un presupuesto.', 'presupuestos', 'integridad',
  "SELECT consulta_id, COUNT(*) AS cantidad FROM presupuestos GROUP BY consulta_id HAVING COUNT(*) > 1;", '0 filas', 'Relación 1 a 1 consulta-presupuesto.', R0, 'PRUEBA 3.3')
t('5.2', 'Total calculado = suma de los detalles', 'total_calculado coincide con SUM(monto) de sus detalles.', 'presupuestos, detalles_presupuestos', 'integridad',
  "SELECT p.id, p.total_calculado, COALESCE(SUM(d.monto), 0) AS suma FROM presupuestos p LEFT JOIN detalles_presupuestos d ON d.presupuesto_id = p.id GROUP BY p.id, p.total_calculado HAVING p.total_calculado <> COALESCE(SUM(d.monto), 0);",
  '0 filas', 'Importes consistentes (monto = cantidad × precio unitario).', R0, 'PRUEBA 3.4')
t('5.3', 'Presupuestos enviados/aceptados con fecha de envío', 'Un presupuesto enviado o aceptado debe tener fecha_envio.', 'presupuestos', 'integridad',
  "SELECT id FROM presupuestos WHERE estado IN ('enviado','aceptado','rechazado') AND fecha_envio IS NULL;", '0 filas', 'Trazabilidad de envíos.', R0, 'PRUEBA 3.5')
t('5.4', 'Presupuesto con detalles (INNER JOIN)', 'Listar presupuestos con la cantidad de líneas y su total.', 'presupuestos, detalles_presupuestos, consultas', 'info',
  "SELECT p.numero, p.estado, COUNT(d.id) AS lineas, SUM(d.monto) AS total FROM presupuestos p INNER JOIN detalles_presupuestos d ON d.presupuesto_id = p.id GROUP BY p.id, p.numero, p.estado ORDER BY p.id;",
  '12 filas', 'Cada presupuesto tiene al menos una línea.', ('rowsN', 12))
t('5.5', 'Presupuestos aceptados con orden / órdenes con presupuesto aceptado', 'Una orden solo nace de un presupuesto aceptado.', 'ordenes_trabajo, presupuestos', 'integridad',
  "SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id WHERE p.estado <> 'aceptado';", '0 filas', 'Flujo presupuesto -> orden respetado.', R0)
t('5.6', 'Alta de presupuesto con detalles', 'INSERT de presupuesto y líneas; el monto se calcula solo.', 'presupuestos, detalles_presupuestos', 'op',
  """START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9003, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, estado, valido_hasta, creado_por) VALUES (9001, 9003, 'PRE-9001', 'borrador', '2026-12-31', 2);
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, tipo, cantidad, precio_unitario) VALUES (9001, 'Filtro', 'repuesto', 2, 1500.50), (9001, 'Mano de obra', 'mano_obra', 1, 8000);
UPDATE presupuestos SET total_calculado = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9001), precio_final = (SELECT SUM(monto) FROM detalles_presupuestos WHERE presupuesto_id = 9001) WHERE id = 9001;
SELECT IF(total_calculado = 11001.00 AND precio_final = 11001.00, 'OK', 'FALLA') AS resultado FROM presupuestos WHERE id = 9001;
ROLLBACK;""", 'resultado = OK', '2 × 1500,50 + 8000 = 11001,00.', ('ok',))
t('5.7', 'Aceptación de un presupuesto', 'UPDATE a aceptado con fecha de respuesta.', 'presupuestos, consultas', 'op',
  """START TRANSACTION;
UPDATE presupuestos SET estado = 'aceptado', fecha_respuesta = NOW() WHERE id = (SELECT id FROM (SELECT id FROM presupuestos WHERE estado = 'enviado' LIMIT 1) x);
SELECT IF(COUNT(*) >= 1, 'OK', 'FALLA') AS resultado FROM presupuestos WHERE estado = 'aceptado' AND fecha_respuesta >= CURDATE();
ROLLBACK;""", 'resultado = OK', 'La decisión del cliente queda registrada.', ('ok',))
t('5.8', 'Eliminar presupuesto: sus detalles se borran en cascada', 'DELETE con ON DELETE CASCADE.', 'presupuestos, detalles_presupuestos', 'op',
  """START TRANSACTION;
INSERT INTO consultas (id, contacto_nombre, motivo, creado_por) VALUES (9004, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, creado_por) VALUES (9002, 9004, 'PRE-9002', 2);
INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario) VALUES (9002, 'x', 1, 100);
DELETE FROM presupuestos WHERE id = 9002;
SELECT IF((SELECT COUNT(*) FROM detalles_presupuestos WHERE presupuesto_id = 9002) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'No quedan líneas huérfanas.', ('ok',))
t('5.9', 'Segundo presupuesto para una consulta rechazado', 'UNIQUE uq_presupuestos_consulta.', 'presupuestos', 'error',
  "INSERT INTO presupuestos (consulta_id, numero, creado_por) VALUES (1, 'PRE-9999', 2);", 'ERROR 1062 (clave duplicada)', 'Una consulta, un presupuesto.', ('err', 1062))
t('5.10', 'Línea con cantidad 0 rechazada', 'CHECK ck_detpres_valores.', 'detalles_presupuestos', 'error',
  "INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario) VALUES (1, 'x', 0, 10);", 'ERROR 3819 (restricción CHECK)', 'No se admiten cantidades nulas.', ('err', 3819))
t('5.11', 'No se puede escribir la columna calculada monto', 'monto es GENERATED: no admite valores manuales.', 'detalles_presupuestos', 'error',
  "INSERT INTO detalles_presupuestos (presupuesto_id, concepto, cantidad, precio_unitario, monto) VALUES (1, 'x', 1, 10, 999);", 'ERROR 3105 (columna generada)', 'El importe de la línea siempre es cantidad × precio.', ('err', 3105))

# ============================== 6. ÓRDENES DE TRABAJO ==============================
t('6.1', 'Una orden por presupuesto', 'No puede haber dos órdenes del mismo presupuesto.', 'ordenes_trabajo', 'integridad',
  "SELECT presupuesto_id, COUNT(*) FROM ordenes_trabajo GROUP BY presupuesto_id HAVING COUNT(*) > 1;", '0 filas', 'Relación 1 a 1.', R0, 'PRUEBA 4.1')
t('6.2', 'Cliente y vehículo de la orden coinciden con la consulta', 'La orden refleja el cliente y vehículo de su consulta.', 'ordenes_trabajo, presupuestos, consultas', 'integridad',
  "SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id INNER JOIN consultas c ON c.id = p.consulta_id WHERE o.cliente_id <> c.cliente_id OR o.vehiculo_id <> c.vehiculo_id;", '0 filas', 'Cadena consulta -> presupuesto -> orden consistente.', R0, 'PRUEBA 4.2')
t('6.3', 'Precio final de la orden = precio final del presupuesto', 'El precio de la orden no se desvía del presupuesto aceptado. El % de comisión se define en la orden (el dueño lo puede ajustar mientras no haya comisión registrada), por eso no se compara.', 'ordenes_trabajo, presupuestos', 'integridad',
  "SELECT o.id FROM ordenes_trabajo o INNER JOIN presupuestos p ON p.id = o.presupuesto_id WHERE o.precio_final <> p.precio_final;", '0 filas', 'El precio se copia del presupuesto.', R0, 'PRUEBA 4.3')
t('6.4', 'Estados y mecánico', 'sin_asignar/cancelado pueden no tener mecánico; ofrecido, aceptado, en_proceso y finalizado sí.', 'ordenes_trabajo', 'integridad',
  "SELECT id, estado FROM ordenes_trabajo WHERE (estado IN ('ofrecido','aceptado','en_proceso','finalizado') AND mecanico_id IS NULL) OR (estado = 'sin_asignar' AND mecanico_id IS NOT NULL);", '0 filas', 'El mecánico se asigna al ofrecer el trabajo.', R0, 'PRUEBA 4.4')
t('6.5', 'Último estado del historial = estado de la orden', 'historial_estados_ordenes registra cada cambio y termina en el estado actual.', 'ordenes_trabajo, historial_estados_ordenes', 'integridad',
  "SELECT o.id, o.estado, h.estado_nuevo FROM ordenes_trabajo o INNER JOIN historial_estados_ordenes h ON h.id = (SELECT MAX(x.id) FROM historial_estados_ordenes x WHERE x.orden_id = o.id) WHERE h.estado_nuevo <> o.estado;", '0 filas', 'El historial es fiel al estado.', R0, 'PRUEBA 4.5')
t('6.6', 'Fechas de inicio y fin según estado', 'en_proceso/finalizado tienen fecha_inicio; finalizado tiene fecha_fin.', 'ordenes_trabajo', 'integridad',
  "SELECT id, estado FROM ordenes_trabajo WHERE (estado IN ('en_proceso','finalizado') AND fecha_inicio IS NULL) OR (estado = 'finalizado' AND fecha_fin IS NULL);", '0 filas', 'Trazabilidad temporal de los trabajos.', R0)
t('6.7', 'Órdenes con cliente, vehículo y mecánico (INNER JOIN)', 'Listado operativo de órdenes asignadas.', 'ordenes_trabajo, clientes, vehiculos, usuarios', 'info',
  "SELECT o.numero, cl.nombre AS cliente, v.marca, v.modelo, u.nombre AS mecanico, o.estado FROM ordenes_trabajo o INNER JOIN clientes cl ON cl.id = o.cliente_id INNER JOIN vehiculos v ON v.id = o.vehiculo_id INNER JOIN usuarios u ON u.id = o.mecanico_id ORDER BY o.id;", '11 filas', 'Todas las órdenes de la demo tienen mecánico.', ('rowsN', 11))
t('6.8', 'Avances con orden y autor válidos', 'avances_ordenes no tiene filas huérfanas.', 'avances_ordenes, ordenes_trabajo, usuarios', 'integridad',
  "SELECT a.id FROM avances_ordenes a LEFT JOIN ordenes_trabajo o ON o.id = a.orden_id LEFT JOIN usuarios u ON u.id = a.usuario_id WHERE o.id IS NULL OR u.id IS NULL;", '0 filas', 'Relación 1 a N orden -> avances.', R0)
t('6.9', 'Avances registrados (INNER JOIN)', 'Listar los avances con su orden y autor.', 'avances_ordenes, ordenes_trabajo, usuarios', 'info',
  "SELECT o.numero, u.nombre, a.texto, a.creado_en FROM avances_ordenes a INNER JOIN ordenes_trabajo o ON o.id = a.orden_id INNER JOIN usuarios u ON u.id = a.usuario_id ORDER BY a.id;", '10 filas', 'Cada avance es una fila.', ('rowsN', 10))
t('6.10', 'Cambio de estado con historial y avance', 'UPDATE de estado + INSERT en historial y avance.', 'ordenes_trabajo, historial_estados_ordenes, avances_ordenes', 'op',
  """START TRANSACTION;
UPDATE ordenes_trabajo SET estado = 'en_proceso', fecha_inicio = NOW() WHERE id = 2;
INSERT INTO historial_estados_ordenes (orden_id, estado_anterior, estado_nuevo, cambiado_por) VALUES (2, 'ofrecido', 'en_proceso', 3);
INSERT INTO avances_ordenes (orden_id, usuario_id, texto) VALUES (2, 3, 'Se inició el desarme');
SELECT IF(o.estado = 'en_proceso' AND (SELECT COUNT(*) FROM avances_ordenes WHERE orden_id = 2) >= 1, 'OK', 'FALLA') AS resultado FROM ordenes_trabajo o WHERE o.id = 2;
ROLLBACK;""", 'resultado = OK', 'El estado, su historial y los avances se guardan juntos.', ('ok',))
t('6.11', 'Eliminar orden nueva: historial y avances en cascada', 'DELETE con cascada.', 'ordenes_trabajo, historial_estados_ordenes, avances_ordenes', 'op',
  """START TRANSACTION;
INSERT INTO consultas (id, cliente_id, vehiculo_id, contacto_nombre, motivo, creado_por) VALUES (9005, 1, 1, 'Persona', 'Prueba', 2);
INSERT INTO presupuestos (id, consulta_id, numero, estado, creado_por) VALUES (9003, 9005, 'PRE-9003', 'aceptado', 2);
INSERT INTO ordenes_trabajo (id, numero, presupuesto_id, cliente_id, vehiculo_id, descripcion, precio_final) VALUES (9001, 'OT-9001', 9003, 1, 1, 'Prueba', 100);
INSERT INTO historial_estados_ordenes (orden_id, estado_nuevo, cambiado_por) VALUES (9001, 'sin_asignar', 2);
INSERT INTO avances_ordenes (orden_id, usuario_id, texto) VALUES (9001, 2, 'x');
DELETE FROM ordenes_trabajo WHERE id = 9001;
SELECT IF((SELECT COUNT(*) FROM historial_estados_ordenes WHERE orden_id = 9001) + (SELECT COUNT(*) FROM avances_ordenes WHERE orden_id = 9001) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'No quedan registros hijos.', ('ok',))
t('6.12', 'Segunda orden para un presupuesto rechazada', 'UNIQUE uq_ordenes_presupuesto.', 'ordenes_trabajo', 'error',
  "INSERT INTO ordenes_trabajo (numero, presupuesto_id, cliente_id, vehiculo_id, descripcion, precio_final) VALUES ('OT-9998', 1, 1, 1, 'dup', 1);", 'ERROR 1062 (clave duplicada)', 'Una orden por presupuesto.', ('err', 1062))
t('6.13', 'Comisión mayor a 100 % rechazada', 'CHECK ck_ordenes_importes.', 'ordenes_trabajo', 'error',
  "UPDATE ordenes_trabajo SET comision_pct = 150 WHERE id = 1;", 'ERROR 3819 (restricción CHECK)', 'Porcentaje fuera de rango.', ('err', 3819))

# ============================== 7. ASIGNACIONES ==============================
t('7.1', 'Asignación activa coincide con el mecánico de la orden', 'La última asignación ofrecida/aceptada es la del mecánico de la orden.', 'asignaciones_trabajo, ordenes_trabajo', 'integridad',
  "SELECT o.id FROM ordenes_trabajo o INNER JOIN asignaciones_trabajo a ON a.id = (SELECT MAX(x.id) FROM asignaciones_trabajo x WHERE x.orden_id = o.id) WHERE o.mecanico_id IS NOT NULL AND a.mecanico_id <> o.mecanico_id;", '0 filas', 'Orden y asignación coherentes.', R0)
t('7.2', 'Una sola asignación activa por orden', 'No más de una asignación ofrecida/aceptada por orden.', 'asignaciones_trabajo', 'integridad',
  "SELECT orden_id, COUNT(*) FROM asignaciones_trabajo WHERE resultado IN ('ofrecida','aceptada') GROUP BY orden_id HAVING COUNT(*) > 1;", '0 filas', 'Un solo mecánico responsable.', R0)
t('7.3', 'Rechazos con motivo', 'Una asignación rechazada debe tener motivo_rechazo.', 'asignaciones_trabajo', 'integridad',
  "SELECT id FROM asignaciones_trabajo WHERE resultado = 'rechazada' AND (motivo_rechazo IS NULL OR motivo_rechazo = '');", '0 filas', 'Los rechazos se justifican.', R0)
t('7.4', 'Asignaciones con orden y mecánico (INNER JOIN)', 'Listar las asignaciones.', 'asignaciones_trabajo, ordenes_trabajo, usuarios', 'info',
  "SELECT o.numero, u.nombre AS mecanico, a.resultado, a.creado_en, a.resuelto_en FROM asignaciones_trabajo a INNER JOIN ordenes_trabajo o ON o.id = a.orden_id INNER JOIN usuarios u ON u.id = a.mecanico_id ORDER BY a.id;", '11 filas', 'Una asignación por orden en la demo.', ('rowsN', 11))
t('7.5', 'Rechazo y reasignación', 'El mecánico rechaza con motivo y se reasigna a otro.', 'asignaciones_trabajo, ordenes_trabajo', 'op',
  """START TRANSACTION;
UPDATE asignaciones_trabajo SET resultado = 'rechazada', motivo_rechazo = 'Sin disponibilidad', resuelto_en = NOW() WHERE orden_id = 2;
UPDATE ordenes_trabajo SET estado = 'sin_asignar', mecanico_id = NULL WHERE id = 2;
INSERT INTO asignaciones_trabajo (orden_id, mecanico_id, asignado_por, resultado) VALUES (2, 4, 2, 'ofrecida');
UPDATE ordenes_trabajo SET estado = 'ofrecido', mecanico_id = 4 WHERE id = 2;
SELECT IF((SELECT COUNT(*) FROM asignaciones_trabajo WHERE orden_id = 2) = 2 AND (SELECT mecanico_id FROM ordenes_trabajo WHERE id = 2) = 4, 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'Se conserva el historial de asignaciones.', ('ok',))
t('7.6', 'Asignar a un mecánico inexistente rechazado', 'FK fk_asig_mecanico.', 'asignaciones_trabajo', 'error',
  "INSERT INTO asignaciones_trabajo (orden_id, mecanico_id, asignado_por) VALUES (2, 99999, 2);", 'ERROR 1452 (clave foránea)', 'Solo usuarios existentes.', ('err', 1452))

# ============================== 8. PAGOS DE CLIENTES ==============================
t('8.1', 'Pagos de trabajo con orden; venta de mostrador sin orden', 'Coherencia entre tipo de pago y orden.', 'pagos_clientes', 'integridad',
  "SELECT id FROM pagos_clientes WHERE (tipo = 'trabajo' AND orden_id IS NULL) OR (tipo = 'venta_mostrador' AND orden_id IS NOT NULL);", '0 filas', 'Mapeo del MVP: pago sin orden = venta de mostrador.', R0, 'PRUEBA 5.1')
t('8.2', 'Monto del pago = suma de sus medios', 'El monto de cada pago coincide con sus detalles.', 'pagos_clientes, detalles_pagos_clientes', 'integridad',
  "SELECT p.id FROM pagos_clientes p LEFT JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id GROUP BY p.id, p.monto HAVING p.monto <> COALESCE(SUM(d.importe), 0);", '0 filas', 'Pagos combinados correctamente desglosados.', R0, 'PRUEBA 5.2')
t('8.3', 'Método combinado ↔ dos medios', 'metodo = combinado solo si tiene 2 o más medios; si no, el medio coincide con metodo.', 'pagos_clientes, detalles_pagos_clientes', 'integridad',
  "SELECT p.id FROM pagos_clientes p INNER JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id GROUP BY p.id, p.metodo HAVING (p.metodo = 'combinado' AND COUNT(*) < 2) OR (p.metodo <> 'combinado' AND (COUNT(*) <> 1 OR MAX(d.medio) <> p.metodo));", '0 filas', 'Coherencia del método de pago.', R0, 'PRUEBA 5.3')
t('8.4', 'Cliente del pago = cliente de la orden', 'Un pago de trabajo pertenece al cliente de esa orden.', 'pagos_clientes, ordenes_trabajo', 'integridad',
  "SELECT p.id FROM pagos_clientes p INNER JOIN ordenes_trabajo o ON o.id = p.orden_id WHERE p.cliente_id <> o.cliente_id;", '0 filas', 'Pagos asignados al cliente correcto.', R0, 'PRUEBA 5.4')
t('8.5', 'Lo pagado no supera el precio de la orden', 'SUM(pagos) <= precio_final.', 'pagos_clientes, ordenes_trabajo', 'integridad',
  "SELECT o.id, o.precio_final, SUM(p.monto) AS pagado FROM ordenes_trabajo o INNER JOIN pagos_clientes p ON p.orden_id = o.id GROUP BY o.id, o.precio_final HAVING SUM(p.monto) > o.precio_final;", '0 filas', 'No hay sobrepagos.', R0, 'PRUEBA 5.5')
t('8.6', 'Saldo por orden (INNER JOIN)', 'Precio, pagado y saldo de las órdenes con pagos.', 'ordenes_trabajo, pagos_clientes, clientes', 'info',
  "SELECT o.numero, c.nombre, o.precio_final, SUM(p.monto) AS pagado, o.precio_final - SUM(p.monto) AS saldo FROM ordenes_trabajo o INNER JOIN pagos_clientes p ON p.orden_id = o.id INNER JOIN clientes c ON c.id = o.cliente_id GROUP BY o.id, o.numero, c.nombre, o.precio_final ORDER BY o.id;", 'al menos 1 fila', 'Seguimiento de deuda por trabajo.', ('rowsgt',))
t('8.7', 'Registrar un pago combinado', 'INSERT de pago + dos medios; la suma coincide.', 'pagos_clientes, detalles_pagos_clientes', 'op',
  """START TRANSACTION;
INSERT INTO pagos_clientes (id, tipo, orden_id, cliente_id, monto, metodo, registrado_por) VALUES (9001, 'trabajo', 2, (SELECT cliente_id FROM ordenes_trabajo WHERE id = 2), 10000, 'combinado', 2);
INSERT INTO detalles_pagos_clientes (pago_cliente_id, medio, importe, referencia) VALUES (9001, 'efectivo', 4000, NULL), (9001, 'transferencia', 6000, 'TRF-1');
SELECT IF(p.monto = SUM(d.importe), 'OK', 'FALLA') AS resultado FROM pagos_clientes p INNER JOIN detalles_pagos_clientes d ON d.pago_cliente_id = p.id WHERE p.id = 9001 GROUP BY p.id, p.monto;
ROLLBACK;""", 'resultado = OK', 'El pago combinado se reparte en dos medios.', ('ok',))
t('8.8', 'Corregir el monto de un pago (UPDATE)', 'Modificación de observaciones del pago.', 'pagos_clientes', 'op',
  """START TRANSACTION;
UPDATE pagos_clientes SET observaciones = 'Corregido' WHERE id = 1;
SELECT IF(observaciones = 'Corregido', 'OK', 'FALLA') AS resultado FROM pagos_clientes WHERE id = 1;
ROLLBACK;""", 'resultado = OK', 'Modificación simple.', ('ok',))
t('8.9', 'Eliminar un pago: sus medios se borran en cascada', 'DELETE con cascada.', 'pagos_clientes, detalles_pagos_clientes', 'op',
  """START TRANSACTION;
DELETE FROM pagos_clientes WHERE id = 1;
SELECT IF((SELECT COUNT(*) FROM detalles_pagos_clientes WHERE pago_cliente_id = 1) = 0, 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'Sin medios huérfanos.', ('ok',))
t('8.10', 'Pago con monto 0 rechazado', 'CHECK ck_pagcli_monto.', 'pagos_clientes', 'error',
  "INSERT INTO pagos_clientes (tipo, cliente_id, monto, registrado_por) VALUES ('venta_mostrador', 1, 0, 2);", 'ERROR 3819 (restricción CHECK)', 'Los pagos son positivos.', ('err', 3819))
t('8.11', 'Medio repetido en un pago rechazado', 'UNIQUE (pago, medio).', 'detalles_pagos_clientes', 'error',
  "INSERT INTO detalles_pagos_clientes (pago_cliente_id, medio, importe) SELECT pago_cliente_id, medio, 1 FROM detalles_pagos_clientes LIMIT 1;", 'ERROR 1062 (clave duplicada)', 'Un medio por pago.', ('err', 1062))

# ============================== 9. CATÁLOGO Y STOCK ==============================
t('9.1', 'Artículos con categoría', 'Todo artículo del MVP tiene categoría existente.', 'catalogo_items, categorias_catalogo', 'integridad',
  "SELECT i.id FROM catalogo_items i LEFT JOIN categorias_catalogo c ON c.id = i.categoria_id WHERE i.categoria_id IS NOT NULL AND c.id IS NULL;", '0 filas', 'Sin categorías inexistentes.', R0, 'PRUEBA 6.1')
t('9.2', 'Movimientos confirmados con responsable', 'Un movimiento confirmado tiene resuelto_por.', 'movimientos_stock', 'integridad',
  "SELECT id FROM movimientos_stock WHERE estado = 'confirmado' AND resuelto_por IS NULL;", '0 filas', 'Todo movimiento confirmado tiene responsable.', R0, 'PRUEBA 6.2')
t('9.3', 'Salidas por orden con orden existente', 'movimientos_stock.orden_id apunta a órdenes reales.', 'movimientos_stock, ordenes_trabajo', 'integridad',
  "SELECT m.id FROM movimientos_stock m LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.orden_id IS NOT NULL AND o.id IS NULL;", '0 filas', 'Repuestos usados en trabajos reales.', R0, 'PRUEBA 6.3')
t('9.4', 'Artículos con stock bajo', 'Artículos con cantidad <= stock mínimo (alerta de stock).', 'catalogo_items', 'info',
  "SELECT id, codigo, nombre, cantidad, stock_minimo FROM catalogo_items WHERE activo = 1 AND cantidad <= stock_minimo ORDER BY cantidad;", 'al menos 1 fila', 'Consulta informativa: alimenta las alertas de stock bajo.', ('rowsgt',), 'PRUEBA 6.4')
t('9.5', 'Stock actual = entradas − salidas confirmadas', 'La cantidad del catálogo coincide con la suma de sus movimientos.', 'catalogo_items, movimientos_stock', 'integridad',
  "SELECT i.id, i.codigo, i.cantidad, COALESCE(SUM(CASE WHEN m.tipo = 'entrada' THEN m.cantidad ELSE -m.cantidad END), 0) AS segun_movimientos FROM catalogo_items i LEFT JOIN movimientos_stock m ON m.catalogo_item_id = i.id AND m.estado = 'confirmado' GROUP BY i.id, i.codigo, i.cantidad HAVING i.cantidad <> COALESCE(SUM(CASE WHEN m.tipo = 'entrada' THEN m.cantidad ELSE -m.cantidad END), 0);", '0 filas', 'El stock es consistente con su historial.', R0)
t('9.6', 'Historial de precios coherente', 'El último precio del historial coincide con el precio actual del artículo.', 'historial_precios_catalogo, catalogo_items', 'integridad',
  "SELECT i.id FROM catalogo_items i INNER JOIN historial_precios_catalogo h ON h.id = (SELECT MAX(x.id) FROM historial_precios_catalogo x WHERE x.catalogo_item_id = i.id) WHERE h.precio_compra_nuevo <> i.precio_compra OR h.precio_venta_nuevo <> i.precio_venta;", '0 filas', 'Historial fiel a los precios vigentes.', R0)
t('9.7', 'Artículos con su categoría (INNER JOIN)', 'Listado del catálogo.', 'catalogo_items, categorias_catalogo', 'info',
  "SELECT c.nombre AS categoria, i.codigo, i.nombre, i.marca, i.cantidad, i.precio_venta FROM catalogo_items i INNER JOIN categorias_catalogo c ON c.id = i.categoria_id ORDER BY c.nombre, i.nombre;", '17 filas', 'Catálogo completo.', ('rowsN', 17))
t('9.8', 'Registrar salida de stock por una orden', 'INSERT del movimiento y UPDATE de la cantidad.', 'movimientos_stock, catalogo_items', 'op',
  """START TRANSACTION;
SET @antes = (SELECT cantidad FROM catalogo_items WHERE id = 1);
INSERT INTO movimientos_stock (catalogo_item_id, tipo, cantidad, estado, motivo, orden_id, solicitado_por, resuelto_por) VALUES (1, 'salida', 2, 'confirmado', 'Usado en OT-0003', 3, 3, 3);
UPDATE catalogo_items SET cantidad = cantidad - 2 WHERE id = 1;
SELECT IF(cantidad = @antes - 2, 'OK', 'FALLA') AS resultado FROM catalogo_items WHERE id = 1;
ROLLBACK;""", 'resultado = OK', 'El descuento de stock queda registrado y aplicado.', ('ok',))
t('9.9', 'Eliminar un artículo sin movimientos', 'DELETE de un artículo nuevo.', 'catalogo_items', 'op',
  """START TRANSACTION;
INSERT INTO catalogo_items (id, tipo, nombre, codigo) VALUES (9001, 'repuesto', 'Temporal', 'TMP-1');
DELETE FROM catalogo_items WHERE id = 9001;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM catalogo_items WHERE id = 9001;
ROLLBACK;""", 'resultado = OK', 'Baja de artículo sin historial.', ('ok',))
t('9.10', 'Stock negativo rechazado', 'CHECK ck_catalogo_stock.', 'catalogo_items', 'error',
  "UPDATE catalogo_items SET cantidad = cantidad - 100000 WHERE id = 1;", 'ERROR 3819 (restricción CHECK)', 'No se puede vender lo que no hay.', ('err', 3819))
t('9.11', 'Código de artículo duplicado rechazado', 'UNIQUE uq_catalogo_codigo.', 'catalogo_items', 'error',
  "INSERT INTO catalogo_items (tipo, nombre, codigo) SELECT 'repuesto', 'Copia', codigo FROM catalogo_items WHERE codigo IS NOT NULL LIMIT 1;", 'ERROR 1062 (clave duplicada)', 'Código único.', ('err', 1062))
t('9.12', 'Movimiento sin artículo ni descripción rechazado', 'CHECK ck_movstock_descripcion.', 'movimientos_stock', 'error',
  "INSERT INTO movimientos_stock (tipo, cantidad, motivo, solicitado_por) VALUES ('salida', 1, 'x', 2);", 'ERROR 3819 (restricción CHECK)', 'Todo movimiento identifica qué se movió.', ('err', 3819))

# ============================== 10. MOVIMIENTOS DE MECÁNICOS ==============================
t('10.1', 'Movimientos de usuarios con rol Mecánico', 'Solo mecánicos tienen movimientos.', 'movimientos_mecanicos, usuarios, roles', 'integridad',
  "SELECT m.id FROM movimientos_mecanicos m INNER JOIN usuarios u ON u.id = m.mecanico_id INNER JOIN roles r ON r.id = u.rol_id WHERE r.nombre <> 'Mecanico';", '0 filas', 'Las comisiones son de mecánicos.', R0, 'PRUEBA 7.1')
t('10.2', 'Comisión con orden finalizada del mismo mecánico', 'Toda comisión corresponde a una orden finalizada de ese mecánico.', 'movimientos_mecanicos, ordenes_trabajo', 'integridad',
  "SELECT m.id FROM movimientos_mecanicos m LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.tipo = 'comision' AND (o.id IS NULL OR o.estado <> 'finalizado' OR o.mecanico_id <> m.mecanico_id);", '0 filas', 'Comisión solo por trabajos terminados.', R0)
t('10.3', 'Comisión = mano de obra × comision_pct ÷ 100 (sin repuestos)', 'La fórmula documentada: la base es SOLO la suma de las líneas de tipo mano_obra del presupuesto de la orden.', 'movimientos_mecanicos, ordenes_trabajo, detalles_presupuestos', 'integridad',
  """SELECT x.id, x.monto, x.esperado FROM (SELECT m.id, m.monto, ROUND(COALESCE((SELECT SUM(d.monto) FROM detalles_presupuestos d WHERE d.presupuesto_id = o.presupuesto_id AND d.tipo = 'mano_obra'), 0) * o.comision_pct / 100, 2) AS esperado
 FROM movimientos_mecanicos m INNER JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.tipo = 'comision') x WHERE x.monto <> x.esperado;""", '0 filas', 'Cada comisión registrada coincide con la fórmula.', R0)
t('10.4', 'Movimientos con mecánico y orden (INNER JOIN)', 'Listado de movimientos.', 'movimientos_mecanicos, usuarios, ordenes_trabajo', 'info',
  "SELECT u.nombre, m.tipo, m.monto, o.numero, m.fecha FROM movimientos_mecanicos m INNER JOIN usuarios u ON u.id = m.mecanico_id LEFT JOIN ordenes_trabajo o ON o.id = m.orden_id ORDER BY m.id;", '7 filas (5 comisiones y 2 adelantos)', 'Movimientos generados por el MVP.', ('rowsN', 7), 'PRUEBA 7.5')
t('10.5', 'Registrar un adelanto', 'INSERT de un adelanto.', 'movimientos_mecanicos', 'op',
  """START TRANSACTION;
INSERT INTO movimientos_mecanicos (id, mecanico_id, tipo, monto, registrado_por, descripcion) VALUES (9001, 3, 'adelanto', 2500, 2, 'Prueba');
SELECT IF(COUNT(*) = 1, 'OK', 'FALLA') AS resultado FROM movimientos_mecanicos WHERE id = 9001 AND orden_id IS NULL;
ROLLBACK;""", 'resultado = OK', 'Los adelantos no se vinculan a una orden.', ('ok',))
t('10.6', 'Movimiento con monto 0 rechazado', 'CHECK ck_movmec_monto.', 'movimientos_mecanicos', 'error',
  "INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, registrado_por) VALUES (3, 'adelanto', 0, 2);", 'ERROR 3819 (restricción CHECK)', 'Montos positivos.', ('err', 3819))

t('10.7', 'Calcular y registrar una comisión sobre la mano de obra', 'Calcula en SQL la comisión de una orden finalizada sin comisión (30 % sobre la mano de obra) y la registra; comprueba que NO se calcula sobre el precio total.', 'ordenes_trabajo, detalles_presupuestos, movimientos_mecanicos', 'op',
  """START TRANSACTION;
SET @oid = (SELECT o.id FROM ordenes_trabajo o WHERE o.estado = 'finalizado' AND NOT EXISTS (SELECT 1 FROM movimientos_mecanicos m WHERE m.orden_id = o.id) ORDER BY o.id LIMIT 1);
SET @mano = (SELECT SUM(d.monto) FROM detalles_presupuestos d INNER JOIN ordenes_trabajo o ON o.presupuesto_id = d.presupuesto_id WHERE o.id = @oid AND d.tipo = 'mano_obra');
SET @total = (SELECT precio_final FROM ordenes_trabajo WHERE id = @oid);
INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por, fecha, descripcion)
 SELECT mecanico_id, 'comision', ROUND(@mano * comision_pct / 100, 2), id, 2, fecha_fin, 'Comisión de prueba' FROM ordenes_trabajo WHERE id = @oid;
SELECT IF(m.monto = ROUND(@mano * o.comision_pct / 100, 2) AND m.monto <> ROUND(@total * o.comision_pct / 100, 2) AND m.monto > 0, 'OK', 'FALLA') AS resultado
FROM movimientos_mecanicos m INNER JOIN ordenes_trabajo o ON o.id = m.orden_id WHERE m.orden_id = @oid AND m.tipo = 'comision';
ROLLBACK;""", 'resultado = OK', 'La comisión usa solo la mano de obra; los repuestos no suman.', ('ok',))
t('10.8', 'Segunda comisión para la misma orden rechazada', 'UNIQUE uq_movmec_orden_tipo: una sola comisión por orden.', 'movimientos_mecanicos', 'error',
  "INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por) SELECT mecanico_id, 'comision', 1, orden_id, 2 FROM movimientos_mecanicos WHERE tipo = 'comision' LIMIT 1;", 'ERROR 1062 (clave duplicada)', 'No se registra dos veces la comisión de un trabajo.', ('err', 1062))
t('10.9', 'Comisión sin orden / adelanto con orden rechazados', 'CHECK ck_movmec_tipo_orden.', 'movimientos_mecanicos', 'error',
  "INSERT INTO movimientos_mecanicos (mecanico_id, tipo, monto, orden_id, registrado_por) VALUES (3, 'comision', 100, NULL, 2);", 'ERROR 3819 (restricción CHECK)', 'La comisión siempre nace de una orden.', ('err', 3819))

# ============================== 11. LIQUIDACIONES ==============================
t('11.1', 'Total a pagar = comisiones − adelantos', 'Cálculo de la liquidación.', 'liquidaciones_mecanicos', 'integridad',
  "SELECT id FROM liquidaciones_mecanicos WHERE total_a_pagar <> total_comisiones - total_adelantos;", '0 filas', 'Aritmética correcta.', R0, 'PRUEBA 7.2')
t('11.2', 'Totales = suma de los detalles', 'Comisiones y adelantos de la cabecera coinciden con sus detalles.', 'liquidaciones_mecanicos, detalles_liquidaciones_mecanicos, movimientos_mecanicos', 'integridad',
  "SELECT l.id FROM liquidaciones_mecanicos l LEFT JOIN detalles_liquidaciones_mecanicos d ON d.liquidacion_id = l.id LEFT JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id WHERE l.estado <> 'anulada' GROUP BY l.id, l.total_comisiones, l.total_adelantos HAVING l.total_comisiones <> COALESCE(SUM(CASE WHEN m.tipo = 'comision' THEN d.importe_incluido END), 0) OR l.total_adelantos <> COALESCE(SUM(CASE WHEN m.tipo = 'adelanto' THEN d.importe_incluido END), 0);", '0 filas', 'Cabecera y detalle coinciden (las anuladas no tienen detalle: liberaron sus movimientos).', R0, 'PRUEBA 7.2 (corregida)')
t('11.3', 'Movimientos del mismo mecánico y dentro del período', 'Los movimientos liquidados son del mecánico y de las fechas de la liquidación.', 'detalles_liquidaciones_mecanicos, movimientos_mecanicos, liquidaciones_mecanicos', 'integridad',
  "SELECT d.id FROM detalles_liquidaciones_mecanicos d INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id INNER JOIN liquidaciones_mecanicos l ON l.id = d.liquidacion_id WHERE m.mecanico_id <> l.mecanico_id OR DATE(m.fecha) NOT BETWEEN l.periodo_desde AND l.periodo_hasta;", '0 filas', 'Liquidación coherente con sus movimientos.', R0, 'PRUEBA 7.3')
t('11.4', 'Un movimiento en una sola liquidación', 'Ningún movimiento aparece en dos liquidaciones.', 'detalles_liquidaciones_mecanicos', 'integridad',
  "SELECT movimiento_mecanico_id, COUNT(*) FROM detalles_liquidaciones_mecanicos GROUP BY movimiento_mecanico_id HAVING COUNT(*) > 1;", '0 filas', 'Evita pagar dos veces.', R0, 'PRUEBA 7.4')
t('11.5', 'Liquidación con detalles (INNER JOIN)', 'Detalle de la liquidación del mecánico.', 'liquidaciones_mecanicos, detalles_liquidaciones_mecanicos, movimientos_mecanicos, usuarios', 'info',
  "SELECT l.id, u.nombre, m.tipo, d.importe_incluido, l.total_a_pagar, l.estado FROM liquidaciones_mecanicos l INNER JOIN usuarios u ON u.id = l.mecanico_id INNER JOIN detalles_liquidaciones_mecanicos d ON d.liquidacion_id = l.id INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id ORDER BY d.id;", '7 filas (liquidación pagada: 3 comisiones y 1 adelanto; pendiente: 2 comisiones y 1 adelanto)', 'Cada liquidación muestra sus comisiones y adelantos.', ('rowsN', 7))
t('11.6', 'Pagar una liquidación', 'UPDATE a pagada con fecha de pago.', 'liquidaciones_mecanicos', 'op',
  """START TRANSACTION;
UPDATE liquidaciones_mecanicos SET estado = 'pagada', fecha_pago = NOW() WHERE estado = 'pendiente';
SELECT IF(COUNT(*) = 2 AND SUM(fecha_pago IS NOT NULL) = 2, 'OK', 'FALLA') AS resultado FROM liquidaciones_mecanicos WHERE estado = 'pagada';
ROLLBACK;""", 'resultado = OK', 'Cierre de la liquidación.', ('ok',))
t('11.7', 'Anular una liquidación pendiente y liberar sus movimientos', 'Se anula la liquidación pendiente y se borran sus detalles: sus movimientos pueden liquidarse de nuevo.', 'liquidaciones_mecanicos, detalles_liquidaciones_mecanicos', 'op',
  """START TRANSACTION;
SET @liq = (SELECT id FROM liquidaciones_mecanicos WHERE estado = 'pendiente' LIMIT 1);
SET @movs = (SELECT COUNT(*) FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq);
DELETE FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq;
UPDATE liquidaciones_mecanicos SET estado = 'anulada' WHERE id = @liq;
SELECT IF(@movs = 3 AND (SELECT COUNT(*) FROM detalles_liquidaciones_mecanicos WHERE liquidacion_id = @liq) = 0 AND (SELECT COUNT(*) FROM movimientos_mecanicos) = 7 AND (SELECT COUNT(*) FROM movimientos_mecanicos m WHERE NOT EXISTS (SELECT 1 FROM detalles_liquidaciones_mecanicos d WHERE d.movimiento_mecanico_id = m.id)) = 3, 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'Los 3 movimientos de la liquidación quedan libres; ningún movimiento se borra.', ('ok',))
t('11.8', 'Movimiento liquidado dos veces rechazado', 'UNIQUE uq_detliq_movimiento.', 'detalles_liquidaciones_mecanicos', 'error',
  "INSERT INTO detalles_liquidaciones_mecanicos (liquidacion_id, movimiento_mecanico_id, importe_incluido) VALUES (1, 1, 10);", 'ERROR 1062 (clave duplicada)', 'No se paga dos veces.', ('err', 1062))
t('11.9', 'Período invertido rechazado', 'CHECK ck_liq_fechas.', 'liquidaciones_mecanicos', 'error',
  "INSERT INTO liquidaciones_mecanicos (mecanico_id, periodo_desde, periodo_hasta, creado_por) VALUES (3, '2026-12-01', '2026-11-01', 2);", 'ERROR 3819 (restricción CHECK)', 'Fechas coherentes.', ('err', 3819))

t('11.10', 'Liquidaciones pendientes, pagadas y anuladas', 'Agrupa las liquidaciones por estado.', 'liquidaciones_mecanicos', 'info',
  "SELECT estado, COUNT(*) AS cantidad, SUM(total_a_pagar) AS total FROM liquidaciones_mecanicos GROUP BY estado ORDER BY estado;", '3 filas (anulada, pagada, pendiente)', 'Consulta de liquidaciones por estado.', ('rowsN', 3))
t('11.11', 'Estados coherentes: pagadas con fecha de pago, anuladas sin detalles', 'pagada tiene fecha_pago; pendiente/anulada no; anulada no conserva movimientos.', 'liquidaciones_mecanicos, detalles_liquidaciones_mecanicos', 'integridad',
  "SELECT l.id FROM liquidaciones_mecanicos l WHERE (l.estado = 'pagada' AND l.fecha_pago IS NULL) OR (l.estado <> 'pagada' AND l.fecha_pago IS NOT NULL) OR (l.estado = 'anulada' AND EXISTS (SELECT 1 FROM detalles_liquidaciones_mecanicos d WHERE d.liquidacion_id = l.id));", '0 filas', 'Una liquidación anulada libera sus movimientos.', R0)
t('11.12', 'Los adelantos se descuentan de la liquidación', 'Genera una liquidación con una comisión y un adelanto nuevos: total a pagar = comisión − adelanto.', 'movimientos_mecanicos, liquidaciones_mecanicos, detalles_liquidaciones_mecanicos', 'op',
  """START TRANSACTION;
INSERT INTO movimientos_mecanicos (id, mecanico_id, tipo, monto, orden_id, registrado_por, fecha) VALUES (9001, 3, 'adelanto', 2500, NULL, 2, '2026-11-19 09:00:00');
INSERT INTO liquidaciones_mecanicos (id, mecanico_id, periodo_desde, periodo_hasta, total_comisiones, total_adelantos, total_a_pagar, estado, creado_por) VALUES (9001, 3, '2026-11-19', '2026-11-20', 10000, 2500, 7500, 'pendiente', 2);
INSERT INTO detalles_liquidaciones_mecanicos (liquidacion_id, movimiento_mecanico_id, importe_incluido) VALUES (9001, 9001, 2500);
SELECT IF(l.total_a_pagar = l.total_comisiones - l.total_adelantos AND l.total_adelantos = (SELECT SUM(d.importe_incluido) FROM detalles_liquidaciones_mecanicos d INNER JOIN movimientos_mecanicos m ON m.id = d.movimiento_mecanico_id WHERE d.liquidacion_id = 9001 AND m.tipo = 'adelanto'), 'OK', 'FALLA') AS resultado FROM liquidaciones_mecanicos l WHERE l.id = 9001;
ROLLBACK;""", 'resultado = OK', '10000 − 2500 = 7500.', ('ok',))
t('11.13', 'Total a pagar negativo rechazado', 'CHECK de liquidaciones: si los adelantos superan las comisiones no se genera.', 'liquidaciones_mecanicos', 'error',
  "INSERT INTO liquidaciones_mecanicos (mecanico_id, periodo_desde, periodo_hasta, total_comisiones, total_adelantos, total_a_pagar, creado_por) VALUES (3, '2026-11-01', '2026-11-02', 100, 500, -400, 2);", 'ERROR 3819 (restricción CHECK)', 'Regla del MVP: no se liquida con saldo negativo.', ('err', 3819))

# ============================== 12. SUSCRIPCIONES ==============================
t('12.1', 'Períodos consecutivos sin huecos', 'Cada período empieza donde terminó el anterior y la numeración es correlativa.', 'periodos_pago_sistema', 'integridad',
  "SELECT b.id FROM periodos_pago_sistema b INNER JOIN periodos_pago_sistema a ON a.taller_id = b.taller_id AND a.numero = b.numero - 1 WHERE b.fecha_inicio <> a.fecha_vencimiento;", '0 filas', 'La suscripción es continua.', R0, 'PRUEBA 8.4')
t('12.2', 'Tolerancia de 3 días', 'fecha_fin_tolerancia = vencimiento + 3 días.', 'periodos_pago_sistema', 'integridad',
  "SELECT id FROM periodos_pago_sistema WHERE fecha_fin_tolerancia <> DATE_ADD(fecha_vencimiento, INTERVAL dias_tolerancia DAY) OR dias_tolerancia <> 3;", '0 filas', 'Regla de negocio: 3 días corridos de tolerancia.', R0)
t('12.3', 'Duración según modalidad', 'mensual = 1 mes; anual = 12 meses.', 'periodos_pago_sistema', 'integridad',
  "SELECT id FROM periodos_pago_sistema WHERE (modalidad = 'mensual' AND fecha_vencimiento <> DATE_ADD(fecha_inicio, INTERVAL 1 MONTH)) OR (modalidad = 'anual' AND fecha_vencimiento <> DATE_ADD(fecha_inicio, INTERVAL 12 MONTH));", '0 filas', 'Un único plan, mensual o anual.', R0)
t('12.4', 'Período pagado con pago confirmado', 'Un período pagado tiene fecha de pago y al menos un pago confirmado.', 'periodos_pago_sistema, pagos_sistema', 'integridad',
  "SELECT p.id FROM periodos_pago_sistema p WHERE p.estado = 'pagado' AND (p.fecha_pago_confirmado IS NULL OR NOT EXISTS (SELECT 1 FROM pagos_sistema s WHERE s.periodo_id = p.id AND s.estado = 'confirmado'));", '0 filas', 'Estado coherente con los pagos.', R0, 'PRUEBA 8.4')
t('12.5', 'Estado de la suscripción a la fecha de referencia', 'Estado y días al vencimiento del último período (fecha de referencia de la demo: 2026-11-20).', 'periodos_pago_sistema, taller', 'info',
  """SET @hoy_demo = DATE('2026-11-20');
SELECT p.numero, p.fecha_vencimiento, DATEDIFF(p.fecha_vencimiento, @hoy_demo) AS dias_al_vencimiento,
 CASE WHEN @hoy_demo <= p.fecha_vencimiento THEN 'vigente' WHEN @hoy_demo <= p.fecha_fin_tolerancia THEN 'en tolerancia' ELSE 'bloqueado' END AS acceso, t.estado_acceso
FROM periodos_pago_sistema p INNER JOIN taller t ON t.id = p.taller_id WHERE p.numero = (SELECT MAX(numero) FROM periodos_pago_sistema);""",
  '1 fila: período 2, 12 días al vencimiento, acceso vigente', 'Cambiar @hoy_demo por CURDATE() para evaluar con la fecha real.', ('rowsN', 1))
t('12.6', 'Taller bloqueado solo si venció la tolerancia', 'estado_acceso coherente con la fecha de referencia.', 'taller, periodos_pago_sistema', 'integridad',
  """SET @hoy_demo = DATE('2026-11-20');
SELECT t.id FROM taller t INNER JOIN periodos_pago_sistema p ON p.numero = (SELECT MAX(numero) FROM periodos_pago_sistema) WHERE (t.estado_acceso = 'bloqueado') <> (p.estado <> 'pagado' AND @hoy_demo > p.fecha_fin_tolerancia);""", '0 filas', 'Bloqueo solo tras la tolerancia.', R0)
t('12.7', 'Renovación: informar y confirmar un pago', 'Proceso completo: se informa el pago, el SuperAdmin lo confirma, el período se marca pagado y nace el siguiente.', 'periodos_pago_sistema, pagos_sistema, detalles_pagos_sistema, superadmins', 'op',
  """START TRANSACTION;
INSERT INTO pagos_sistema (id, periodo_id, importe_total, metodo, estado, registrado_por) VALUES (9001, 2, 30000, 'transferencia', 'informado', 2);
INSERT INTO detalles_pagos_sistema (pago_id, medio, importe, referencia) VALUES (9001, 'transferencia', 30000, 'TRF-PRUEBA');
UPDATE pagos_sistema SET estado = 'confirmado', confirmado_por = 1, fecha_confirmacion = NOW() WHERE id = 9001;
UPDATE periodos_pago_sistema SET estado = 'pagado', fecha_pago_confirmado = NOW() WHERE id = 2;
INSERT INTO periodos_pago_sistema (id, taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia, estado)
 SELECT 9001, 1, 3, 'mensual', fecha_vencimiento, DATE_ADD(fecha_vencimiento, INTERVAL 1 MONTH), importe, 3, DATE_ADD(DATE_ADD(fecha_vencimiento, INTERVAL 1 MONTH), INTERVAL 3 DAY), 'vigente' FROM periodos_pago_sistema WHERE id = 2;
SELECT IF((SELECT estado FROM periodos_pago_sistema WHERE id = 2) = 'pagado' AND (SELECT fecha_vencimiento FROM periodos_pago_sistema WHERE id = 9001) = '2027-01-02', 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'El nuevo vencimiento se calcula desde el vencimiento anterior (2026-12-02 + 1 mes).', ('ok',))
t('12.8', 'Rechazo de un pago informado', 'UPDATE a rechazado con motivo.', 'pagos_sistema', 'op',
  """START TRANSACTION;
INSERT INTO pagos_sistema (id, periodo_id, importe_total, metodo, estado, registrado_por) VALUES (9002, 2, 30000, 'efectivo', 'informado', 2);
UPDATE pagos_sistema SET estado = 'rechazado', motivo_rechazo = 'No se recibió el dinero', confirmado_por = 1, fecha_confirmacion = NOW() WHERE id = 9002;
SELECT IF(estado = 'rechazado' AND motivo_rechazo IS NOT NULL, 'OK', 'FALLA') AS resultado FROM pagos_sistema WHERE id = 9002;
ROLLBACK;""", 'resultado = OK', 'El rechazo no extiende la suscripción.', ('ok',))
t('12.9', 'Tolerancia distinta de 3 días rechazada', 'CHECK ck_periodo_tolerancia.', 'periodos_pago_sistema', 'error',
  "INSERT INTO periodos_pago_sistema (taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia) VALUES (1, 50, 'mensual', '2027-01-01', '2027-02-01', 100, 5, '2027-02-06');", 'ERROR 3819 (restricción CHECK)', 'La tolerancia es una regla fija.', ('err', 3819))
t('12.10', 'Modalidad: solo mensual o anual', 'El ENUM de modalidad no admite otros valores (p. ej. trimestral).', 'periodos_pago_sistema', 'integridad',
  "SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'periodos_pago_sistema' AND column_name = 'modalidad' AND column_type <> \"enum('mensual','anual')\";", '0 filas', 'Un único plan, mensual o anual (la validación real por inserción se verifica en 12.3).', R0)

t('12.11', 'No existe el plan trimestral', 'Ningún período usa una modalidad distinta de mensual o anual.', 'periodos_pago_sistema', 'integridad',
  "SELECT id, modalidad FROM periodos_pago_sistema WHERE modalidad NOT IN ('mensual','anual');", '0 filas', 'Un único plan con dos modalidades.', R0)
t('12.12', 'Modalidad anual: 12 meses y tolerancia de 3 días', 'Se inserta un período anual y se comprueba su vencimiento y tolerancia.', 'periodos_pago_sistema', 'op',
  """START TRANSACTION;
INSERT INTO periodos_pago_sistema (id, taller_id, numero, modalidad, fecha_inicio, fecha_vencimiento, importe, dias_tolerancia, fecha_fin_tolerancia) VALUES (9002, 1, 40, 'anual', '2026-12-02', '2027-12-02', 300000, 3, '2027-12-05');
SELECT IF(fecha_vencimiento = DATE_ADD(fecha_inicio, INTERVAL 12 MONTH) AND fecha_fin_tolerancia = DATE_ADD(fecha_vencimiento, INTERVAL 3 DAY), 'OK', 'FALLA') AS resultado FROM periodos_pago_sistema WHERE id = 9002;
ROLLBACK;""", 'resultado = OK', 'La modalidad anual funciona; la mensual se prueba en 12.7.', ('ok',))

# ============================== 13. PAGOS DEL SISTEMA ==============================
t('13.1', 'Confirmados con SuperAdmin y fecha', 'Un pago confirmado tiene confirmado_por y fecha de confirmación.', 'pagos_sistema', 'integridad',
  "SELECT id FROM pagos_sistema WHERE estado = 'confirmado' AND (confirmado_por IS NULL OR fecha_confirmacion IS NULL);", '0 filas', 'Solo el SuperAdmin confirma.', R0, 'PRUEBA 8.1')
t('13.2', 'Importe = suma de los medios', 'importe_total coincide con sus detalles.', 'pagos_sistema, detalles_pagos_sistema', 'integridad',
  "SELECT p.id FROM pagos_sistema p LEFT JOIN detalles_pagos_sistema d ON d.pago_id = p.id GROUP BY p.id, p.importe_total HAVING p.importe_total <> COALESCE(SUM(d.importe), 0);", '0 filas', 'Pagos combinados bien desglosados.', R0, 'PRUEBA 8.2')
t('13.3', 'Método combinado ↔ dos medios', 'combinado = efectivo + transferencia; los demás, un solo medio igual al método.', 'pagos_sistema, detalles_pagos_sistema', 'integridad',
  "SELECT p.id FROM pagos_sistema p INNER JOIN detalles_pagos_sistema d ON d.pago_id = p.id GROUP BY p.id, p.metodo HAVING (p.metodo = 'combinado' AND COUNT(*) <> 2) OR (p.metodo <> 'combinado' AND (COUNT(*) <> 1 OR MAX(d.medio) <> p.metodo));", '0 filas', 'Medios de pago permitidos: efectivo, transferencia, combinado.', R0, 'PRUEBA 8.3')
t('13.4', 'Pagos del sistema y de clientes están separados', 'No existe ninguna clave foránea entre las tablas de pagos de clientes y las del sistema.', 'information_schema', 'integridad',
  """SELECT table_name, referenced_table_name FROM information_schema.key_column_usage
WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL
 AND ((table_name IN ('pagos_clientes','detalles_pagos_clientes') AND referenced_table_name IN ('pagos_sistema','detalles_pagos_sistema','periodos_pago_sistema','comprobantes_pagos_sistema'))
   OR (table_name IN ('pagos_sistema','detalles_pagos_sistema','periodos_pago_sistema','comprobantes_pagos_sistema') AND referenced_table_name IN ('pagos_clientes','detalles_pagos_clientes')));""", '0 filas', 'Los dos circuitos de cobro no se mezclan.', R0)
t('13.5', 'Pago del sistema con período, dueño y SuperAdmin (INNER JOIN)', 'Listado de pagos de suscripción.', 'pagos_sistema, periodos_pago_sistema, usuarios, superadmins', 'info',
  "SELECT p.id, per.numero AS periodo, u.nombre AS pagador, p.importe_total, p.metodo, p.estado, su.usuario AS confirmo FROM pagos_sistema p INNER JOIN periodos_pago_sistema per ON per.id = p.periodo_id INNER JOIN usuarios u ON u.id = p.registrado_por LEFT JOIN superadmins s ON s.id = p.confirmado_por LEFT JOIN usuarios su ON su.id = s.usuario_id;", '2 filas (1 confirmado y 1 informado)', 'Pago combinado confirmado del período 1 y pago informado pendiente de confirmar.', ('rowsN', 2), 'PRUEBA 8.5')
t('13.6', 'Comprobantes con pago existente', 'comprobantes_pagos_sistema (tabla sin uso en el MVP) no tiene huérfanos.', 'comprobantes_pagos_sistema, pagos_sistema', 'integridad',
  "SELECT c.id FROM comprobantes_pagos_sistema c LEFT JOIN pagos_sistema p ON p.id = c.pago_sistema_id WHERE p.id IS NULL;", '0 filas', 'La tabla está vacía; la relación queda verificada.', R0, 'PRUEBA 8.5')
t('13.7', 'Medio repetido en un pago del sistema rechazado', 'UNIQUE (pago, medio).', 'detalles_pagos_sistema', 'error',
  "INSERT INTO detalles_pagos_sistema (pago_id, medio, importe) VALUES (1, 'efectivo', 5);", 'ERROR 1062 (clave duplicada)', 'Un medio por pago.', ('err', 1062))
t('13.8', 'Medios del sistema: solo efectivo y transferencia', 'El ENUM de medio de detalles_pagos_sistema no admite otros valores.', 'detalles_pagos_sistema', 'integridad',
  "SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'detalles_pagos_sistema' AND column_name = 'medio' AND column_type <> \"enum('efectivo','transferencia')\";", '0 filas', 'Solo efectivo y transferencia.', R0)
t('13.9', 'Confirmar con un usuario que no es SuperAdmin rechazado', 'FK confirmado_por -> superadmins.', 'pagos_sistema', 'error',
  "UPDATE pagos_sistema SET confirmado_por = 99 WHERE id = 1;", 'ERROR 1452 (clave foránea)', 'Solo un SuperAdmin registrado puede confirmar.', ('err', 1452))

# ============================== 14. NOTIFICACIONES ==============================
t('14.1', 'Destinatario único', 'Cada notificación tiene exactamente un destinatario (usuario o superadmin).', 'notificaciones', 'integridad',
  "SELECT id FROM notificaciones WHERE (usuario_id IS NULL AND superadmin_id IS NULL) OR (usuario_id IS NOT NULL AND superadmin_id IS NOT NULL);", '0 filas', 'Coherente con el CHECK.', R0, 'PRUEBA 9.1')
t('14.2', 'Notificaciones con destinatario (INNER JOIN)', 'Listar las notificaciones de usuarios del taller.', 'notificaciones, usuarios', 'info',
  "SELECT u.usuario, n.tipo, n.texto, n.leida FROM notificaciones n INNER JOIN usuarios u ON u.id = n.usuario_id ORDER BY n.id;", 'al menos 1 fila', 'Notificaciones por destinatario.', ('rowsgt',))
t('14.3', 'Notificaciones del SuperAdmin (INNER JOIN)', 'Listar las del SuperAdmin.', 'notificaciones, superadmins, usuarios', 'info',
  "SELECT u.usuario, n.texto FROM notificaciones n INNER JOIN superadmins s ON s.id = n.superadmin_id INNER JOIN usuarios u ON u.id = s.usuario_id;", '1 fila', 'Aviso de pago informado.', ('rowsN', 1))
t('14.4', 'Marcar como leída', 'UPDATE leida = 1.', 'notificaciones', 'op',
  """START TRANSACTION;
UPDATE notificaciones SET leida = 1 WHERE usuario_id = 2;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM notificaciones WHERE usuario_id = 2 AND leida = 0;
ROLLBACK;""", 'resultado = OK', 'El badge de no leídas queda en cero.', ('ok',))
t('14.5', 'Crear y eliminar una notificación', 'INSERT y DELETE.', 'notificaciones', 'op',
  """START TRANSACTION;
INSERT INTO notificaciones (id, usuario_id, texto, tipo, clave_unica) VALUES (9001, 3, 'Nuevo trabajo asignado', 'trabajo', 'prueba:9001');
DELETE FROM notificaciones WHERE id = 9001;
SELECT IF(COUNT(*) = 0, 'OK', 'FALLA') AS resultado FROM notificaciones WHERE id = 9001;
ROLLBACK;""", 'resultado = OK', 'Alta y baja correctas.', ('ok',))
t('14.6', 'Aviso duplicado rechazado', 'clave_unica evita repetir el mismo aviso.', 'notificaciones', 'error',
  "INSERT INTO notificaciones (usuario_id, texto, clave_unica) SELECT usuario_id, 'dup', clave_unica FROM notificaciones WHERE clave_unica IS NOT NULL LIMIT 1;", 'ERROR 1062 (clave duplicada)', 'Un aviso por hito.', ('err', 1062))
t('14.7', 'Dos destinatarios rechazados', 'CHECK ck_notif_destino.', 'notificaciones', 'error',
  "INSERT INTO notificaciones (usuario_id, superadmin_id, texto) VALUES (2, 1, 'x');", 'ERROR 3819 (restricción CHECK)', 'Un solo destinatario.', ('err', 3819))

# ============================== 15. AUDITORÍA ==============================
t('15.1', 'Ámbito y actor coherentes', 'taller -> usuario; sistema -> superadmin.', 'auditoria', 'integridad',
  "SELECT id FROM auditoria WHERE NOT ((ambito = 'taller' AND usuario_id IS NOT NULL AND superadmin_id IS NULL) OR (ambito = 'sistema' AND usuario_id IS NULL AND superadmin_id IS NOT NULL));", '0 filas', 'Cada acción tiene un solo actor.', R0, 'PRUEBA 9.2')
t('15.2', 'actor_login coincide con el usuario', 'El login guardado es el del usuario o SuperAdmin referenciado.', 'auditoria, usuarios, superadmins', 'integridad',
  "SELECT a.id FROM auditoria a LEFT JOIN usuarios u ON u.id = a.usuario_id LEFT JOIN superadmins s ON s.id = a.superadmin_id LEFT JOIN usuarios us ON us.id = s.usuario_id WHERE a.actor_login <> COALESCE(u.usuario, us.usuario);", '0 filas', 'Trazabilidad fiel.', R0)
t('15.3', 'Detalle JSON válido', 'Todo detalle es JSON.', 'auditoria', 'integridad',
  "SELECT id FROM auditoria WHERE detalle IS NOT NULL AND JSON_VALID(detalle) = 0;", '0 filas', 'El formato JSON es válido.', R0)
t('15.4', 'Actividad con su autor (INNER JOIN)', 'Listar la actividad reciente del taller.', 'auditoria, usuarios', 'info',
  "SELECT a.fecha, u.nombre, a.accion, JSON_UNQUOTE(JSON_EXTRACT(a.detalle, '$.detalle')) AS detalle FROM auditoria a INNER JOIN usuarios u ON u.id = a.usuario_id ORDER BY a.fecha DESC;", 'al menos 1 fila', 'Registro de actividad del dueño y mecánicos.', ('rowsgt',))
t('15.5', 'Registrar una acción', 'INSERT con detalle JSON.', 'auditoria', 'op',
  """START TRANSACTION;
INSERT INTO auditoria (usuario_id, actor_login, ambito, accion, entidad, entidad_id, detalle) VALUES (2, 'roberto', 'taller', 'Editó una consulta', 'consultas', 1, JSON_OBJECT('detalle', 'Cambió el motivo'));
SELECT IF(JSON_UNQUOTE(JSON_EXTRACT(detalle, '$.detalle')) = 'Cambió el motivo', 'OK', 'FALLA') AS resultado FROM auditoria WHERE accion = 'Editó una consulta';
ROLLBACK;""", 'resultado = OK', 'El detalle se guarda y se consulta como JSON.', ('ok',))
t('15.6', 'Acción de sistema con usuario de taller rechazada', 'CHECK ck_auditoria_actor.', 'auditoria', 'error',
  "INSERT INTO auditoria (usuario_id, actor_login, ambito, accion) VALUES (2, 'roberto', 'sistema', 'x');", 'ERROR 3819 (restricción CHECK)', 'Separación de ámbitos.', ('err', 3819))

# ============================== 16. PROPUESTAS DE IA ==============================
t('16.1', 'Propuestas resueltas con fecha', 'aceptada/editada/descartada tienen resuelta_en.', 'propuestas_ia', 'integridad',
  "SELECT id FROM propuestas_ia WHERE estado IN ('aceptada','editada','descartada') AND resuelta_en IS NULL;", '0 filas', 'Trazabilidad de decisiones.', R0, 'PRUEBA 9.3')
t('16.2', 'Texto final según estado', 'Aceptada/editada requieren texto_final.', 'propuestas_ia', 'integridad',
  "SELECT id FROM propuestas_ia WHERE estado IN ('aceptada','editada') AND (texto_final IS NULL OR texto_final = '');", '0 filas', 'Se guarda el texto que quedó en la consulta.', R0)
t('16.3', 'Contexto y referencia (corregida)', 'problema_consulta e inspeccion deben referir una consulta; observacion_mecanico, una orden.', 'propuestas_ia', 'integridad',
  "SELECT id FROM propuestas_ia WHERE (contexto IN ('problema_consulta','inspeccion') AND consulta_id IS NULL) OR (contexto = 'observacion_mecanico' AND orden_id IS NULL);", '0 filas', 'La inspección es de la consulta (en el original exigía una orden: corregido).', R0, 'PRUEBA 9.4')
t('16.4', 'Sin proveedores externos', 'El MVP usa reglas locales: no debe haber proveedores de IA externos ni claves.', 'propuestas_ia', 'integridad',
  "SELECT id, proveedor FROM propuestas_ia WHERE proveedor NOT IN ('reglas_locales');", '0 filas', 'Coincide con el MVP (sin integraciones externas).', R0)
t('16.5', 'Propuestas con autor y consulta (INNER JOIN)', 'Listar propuestas.', 'propuestas_ia, usuarios, consultas', 'info',
  "SELECT p.id, u.nombre, c.id AS consulta, p.estado, p.texto_original, p.texto_final FROM propuestas_ia p INNER JOIN usuarios u ON u.id = p.usuario_id INNER JOIN consultas c ON c.id = p.consulta_id;", '1 fila', 'Propuesta aceptada de la demostración.', ('rowsN', 1))
t('16.6', 'Generar y aceptar una propuesta', 'INSERT y UPDATE de estado.', 'propuestas_ia', 'op',
  """START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, orden_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9001, 3, 'observacion_mecanico', 3, 'cambie filtro', 'Se cambió el filtro.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'aceptada', texto_final = texto_propuesto, resuelta_en = NOW() WHERE id = 9001;
SELECT IF(estado = 'aceptada' AND texto_final = 'Se cambió el filtro.', 'OK', 'FALLA') AS resultado FROM propuestas_ia WHERE id = 9001;
ROLLBACK;""", 'resultado = OK', 'Ciclo completo de una propuesta.', ('ok',))
t('16.7', 'Contextos de IA: sin fotografía', 'El ENUM de contexto solo admite textos (sin imágenes).', 'propuestas_ia', 'integridad',
  "SELECT column_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'propuestas_ia' AND column_name = 'contexto' AND column_type REGEXP 'foto|imagen';", '0 filas', 'Coherente con la eliminación de fotografías.', R0)

t('16.8', 'El texto original siempre se conserva', 'Toda propuesta guarda el texto original y la propuesta; el final solo existe si se aceptó o editó.', 'propuestas_ia', 'integridad',
  "SELECT id FROM propuestas_ia WHERE texto_original IS NULL OR texto_original = '' OR texto_propuesto IS NULL OR (estado = 'descartada' AND texto_final IS NOT NULL) OR (estado = 'generada' AND texto_final IS NOT NULL);", '0 filas', 'La mejora es opcional y no pisa el original.', R0)
t('16.9', 'Aceptar una propuesta no modifica el texto original', 'UPDATE a aceptada: texto_original queda igual.', 'propuestas_ia', 'op',
  """START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, consulta_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9002, 2, 'problema_consulta', 1, 'ruido al frenar', 'Se informa un ruido al frenar.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'aceptada', texto_final = texto_propuesto, resuelta_en = NOW() WHERE id = 9002;
SELECT IF(texto_original = 'ruido al frenar' AND texto_final = 'Se informa un ruido al frenar.' AND estado = 'aceptada', 'OK', 'FALLA') AS resultado FROM propuestas_ia WHERE id = 9002;
ROLLBACK;""", 'resultado = OK', 'Original y propuesta quedan guardados junto al resultado.', ('ok',))
t('16.10', 'Editar y descartar propuestas', 'Una editada guarda un texto final distinto de la propuesta; una descartada no deja texto final.', 'propuestas_ia', 'op',
  """START TRANSACTION;
INSERT INTO propuestas_ia (id, usuario_id, contexto, orden_id, texto_original, texto_propuesto, estado, proveedor) VALUES (9003, 3, 'observacion_mecanico', 3, 'cambie filtro', 'Se cambió el filtro.', 'generada', 'reglas_locales'), (9004, 3, 'observacion_mecanico', 3, 'revise frenos', 'Se revisaron los frenos.', 'generada', 'reglas_locales');
UPDATE propuestas_ia SET estado = 'editada', texto_final = 'Se cambió el filtro de aceite.', resuelta_en = NOW() WHERE id = 9003;
UPDATE propuestas_ia SET estado = 'descartada', resuelta_en = NOW() WHERE id = 9004;
SELECT IF((SELECT texto_final <> texto_propuesto AND texto_original = 'cambie filtro' FROM propuestas_ia WHERE id = 9003) AND (SELECT texto_final IS NULL AND texto_original = 'revise frenos' FROM propuestas_ia WHERE id = 9004), 'OK', 'FALLA') AS resultado;
ROLLBACK;""", 'resultado = OK', 'Aceptar, editar y descartar funcionan; el original no cambia nunca.', ('ok',))

# ============================== 17. ESTRUCTURA E INTEGRIDAD GENERAL ==============================
t('17.1', 'La base tiene 30 tablas', 'Cantidad de tablas del esquema.', 'information_schema', 'integridad',
  "SELECT COUNT(*) AS tablas FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE' HAVING COUNT(*) <> 30;", '0 filas (hay exactamente 30)', 'Si devolviera una fila, la cantidad no es 30.', R0)
t('17.2', 'No existen tablas ni columnas de fotos o archivos de trabajos', 'Verifica la eliminación de la función de fotografías.', 'information_schema', 'integridad',
  """SELECT table_name, column_name FROM information_schema.columns WHERE table_schema = DATABASE() AND (table_name = 'archivos_trabajos' OR column_name REGEXP 'foto|imagen|ruta_foto')
UNION ALL SELECT table_name, NULL FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name REGEXP 'foto|archivos_trabajos';""", '0 filas', 'archivos_trabajos fue eliminada.', R0)
t('17.3', 'Toda tabla tiene clave primaria', 'Sin tablas sin PK.', 'information_schema', 'integridad',
  "SELECT t.table_name FROM information_schema.tables t LEFT JOIN information_schema.table_constraints c ON c.table_schema = t.table_schema AND c.table_name = t.table_name AND c.constraint_type = 'PRIMARY KEY' WHERE t.table_schema = DATABASE() AND t.table_type = 'BASE TABLE' AND c.constraint_name IS NULL;", '0 filas', 'Todas las tablas tienen PK.', R0)
t('17.4', 'Claves foráneas definidas', 'Listado de las relaciones del modelo.', 'information_schema', 'info',
  "SELECT table_name, column_name, referenced_table_name, referenced_column_name FROM information_schema.key_column_usage WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL ORDER BY table_name, column_name;", 'al menos 1 fila', 'Fuente del diagrama entidad-relación.', ('rowsgt',))
t('17.5', 'Claves foráneas sin índice propio', 'Toda FK debería tener un índice que la acompañe.', 'information_schema', 'integridad',
  """SELECT k.table_name, k.column_name FROM information_schema.key_column_usage k
WHERE k.table_schema = DATABASE() AND k.referenced_table_name IS NOT NULL AND k.ordinal_position = 1
 AND NOT EXISTS (SELECT 1 FROM information_schema.statistics s WHERE s.table_schema = k.table_schema AND s.table_name = k.table_name AND s.column_name = k.column_name AND s.seq_in_index = 1);""", '0 filas', 'Cada FK está indexada.', R0)
t('17.6', 'Cantidad de registros por tabla', 'Resumen de datos de demostración.', 'todas', 'info',
  """SELECT 'roles' AS tabla, COUNT(*) AS filas FROM roles UNION ALL SELECT 'usuarios', COUNT(*) FROM usuarios UNION ALL SELECT 'superadmins', COUNT(*) FROM superadmins
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
UNION ALL SELECT 'auditoria', COUNT(*) FROM auditoria UNION ALL SELECT 'propuestas_ia', COUNT(*) FROM propuestas_ia UNION ALL SELECT 'avances_ordenes', COUNT(*) FROM avances_ordenes;""",
  '30 filas (comprobantes_pagos_sistema con 0 registros)', 'Una fila por tabla.', ('rowsN', 30))

# ============================== 18. PROCESOS PRINCIPALES ==============================
t('18.1', 'Flujo completo: consulta → presupuesto → orden → pago', 'Recorre el proceso principal del taller en una transacción (se deshace): consulta con revisión, presupuesto aceptado, orden, asignación y aceptación del mecánico, inicio, avance, uso de repuesto, finalización, comisión y pago combinado.', 'consultas, detalles_consultas, presupuestos, detalles_presupuestos, ordenes_trabajo, historial_estados_ordenes, asignaciones_trabajo, avances_ordenes, movimientos_stock, catalogo_items, movimientos_mecanicos, pagos_clientes, detalles_pagos_clientes', 'op',
  """START TRANSACTION;
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
ROLLBACK;""", 'resultado = OK', 'El proceso completo funciona con el modelo relacional: 4 × 5000 + 10000 = 30000; comisión 10 % sobre la mano de obra (10000) = 1000, no sobre el total; pago combinado 10000 + 20000.', ('ok',))
t('18.2', 'Los datos no cambiaron tras las pruebas', 'Después de las pruebas con ROLLBACK, el stock del artículo 1 y el estado de la orden 2 siguen igual.', 'catalogo_items, ordenes_trabajo', 'integridad',
  "SELECT i.id FROM catalogo_items i INNER JOIN ordenes_trabajo o ON o.id = 2 WHERE i.id = 1 AND (i.cantidad <> 28 OR o.estado <> 'ofrecido');", '0 filas', 'Las pruebas no destruyen los datos de las siguientes.', R0)
