// Roles y permisos: son EXACTAMENTE las filas de las tablas roles, permisos y rol_permisos.
export const ROLES = [
  { id: 1, codigo: 'admin', nombre: 'Administrador', ambito: 'taller', descripcion: 'Dueño del taller: gestiona todo lo del taller.' },
  { id: 2, codigo: 'mecanico', nombre: 'Mecanico', ambito: 'taller', descripcion: 'Atiende consultas y ejecuta los trabajos que se le asignan.' },
];
// El SuperAdmin NO es un rol operativo: es un tipo de cuenta independiente (usuarios.tipo_cuenta = 'superadmin', sin rol_id).
// Los ids de ROLES coinciden con la tabla MySQL roles, pero el código NUNCA depende del número: busca siempre por `codigo`.
export const TIPOS_CUENTA = ['taller', 'superadmin'];
const P = (codigo, modulo, descripcion) => ({ codigo, modulo, descripcion });
export const PERMISOS = [
  P('consultas.ver', 'consultas', 'Ver consultas'), P('consultas.crear', 'consultas', 'Registrar consultas'), P('consultas.revisar', 'consultas', 'Registrar la revisión técnica'),
  P('presupuestos.gestionar', 'presupuestos', 'Crear, editar y responder presupuestos'), P('clientes.gestionar', 'clientes', 'Gestionar clientes y vehículos'),
  P('ordenes.ver_todas', 'ordenes', 'Ver todas las órdenes del taller'), P('ordenes.ver_propias', 'ordenes', 'Ver las órdenes asignadas'), P('ordenes.gestionar', 'ordenes', 'Asignar, reasignar, editar y cancelar órdenes'),
  P('ordenes.ejecutar', 'ordenes', 'Aceptar, avanzar y finalizar trabajos'), P('mecanicos.gestionar', 'mecanicos', 'Administrar cuentas de mecánicos'),
  P('stock.gestionar', 'stock', 'Gestionar artículos y movimientos de stock'), P('stock.consumir', 'stock', 'Registrar repuestos usados en un trabajo'),
  P('pagos_clientes.gestionar', 'pagos', 'Registrar y consultar pagos de clientes'), P('reportes.ver', 'reportes', 'Ver reportes'), P('suscripcion.ver', 'suscripcion', 'Ver e informar pagos de la suscripción'),
  P('actividad.ver', 'auditoria', 'Ver la actividad del taller'), P('ia.usar', 'ia', 'Usar la mejora de redacción'),
  P('comisiones.gestionar', 'comisiones', 'Calcular comisiones, registrar adelantos y liquidar a los mecánicos'), P('comisiones.ver_propias', 'comisiones', 'Ver las propias comisiones y liquidaciones'),
  P('sa.cuentas', 'plataforma', 'Crear, editar, activar y suspender cuentas de dueños'), P('sa.planes', 'plataforma', 'Configurar planes de suscripción'),
  P('sa.pagos', 'plataforma', 'Registrar, confirmar y rechazar pagos del sistema'), P('sa.auditoria', 'plataforma', 'Ver la actividad del sistema'), P('sa.mantenimiento', 'plataforma', 'Herramientas de demostración y mantenimiento'),
];
const TALLER_ADMIN = PERMISOS.filter((p) => !p.codigo.startsWith('sa.') && p.codigo !== 'stock.consumir' && p.codigo !== 'ordenes.ver_propias' && p.codigo !== 'comisiones.ver_propias').map((p) => p.codigo).concat(['stock.consumir']);
export const ROL_PERMISOS = {
  admin: TALLER_ADMIN,
  mecanico: ['consultas.ver', 'consultas.crear', 'consultas.revisar', 'ordenes.ver_propias', 'ordenes.ejecutar', 'stock.consumir', 'ia.usar', 'comisiones.ver_propias'],
};
export const PERMISOS_SUPERADMIN = PERMISOS.filter((p) => p.codigo.startsWith('sa.')).map((p) => p.codigo);
export const MEDIOS_PAGO = [{ id: 1, codigo: 'efectivo', nombre: 'Efectivo' }, { id: 2, codigo: 'transferencia', nombre: 'Transferencia' }, { id: 3, codigo: 'mercadopago', nombre: 'Mercado Pago' }];
// Un ÚNICO plan de suscripción con dos modalidades. No existen otros planes ni duraciones arbitrarias.
export const MODALIDADES = { mensual: { nombre: 'Mensual', meses: 1 }, anual: { nombre: 'Anual', meses: 12 } };
export const PARAMETROS = [
  { id: 1, clave: 'dias_gracia', valor: '3', descripcion: 'Días de gracia después del vencimiento antes de restringir el acceso' },
  { id: 3, clave: 'importe_mensual', valor: '30000', descripcion: 'Importe de la modalidad mensual (único plan)' },
  { id: 4, clave: 'importe_anual', valor: '300000', descripcion: 'Importe de la modalidad anual (único plan)' },
  { id: 2, clave: 'dias_aviso', valor: '7', descripcion: 'Desde cuántos días antes del vencimiento se avisa' },
];
