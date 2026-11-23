// Datos de demostración (fechas relativas a "hoy"). Contraseñas de PRUEBA: no usar en un sistema real.
// Contraseñas de PRUEBA (no usar en un sistema real).
import { hoy, addDias, addMeses } from '../utils/dates.js';
import { hashClave } from '../utils/hash.js';
import { codigo, digits } from '../utils/formatters.js';
import { baseComision, calcularComision, totalesLiquidacion } from '../utils/comisiones.js';
import { ROLES, PERMISOS, ROL_PERMISOS, MEDIOS_PAGO, PARAMETROS } from '../config/permisos.js';

export const COLECCIONES = ['roles', 'permisos', 'rol_permisos', 'usuarios', 'superadmins', 'talleres', 'mecanicos', 'clientes', 'vehiculos', 'vehiculo_propietarios', 'consultas', 'consulta_revisiones', 'presupuestos', 'presupuesto_detalles', 'ordenes_trabajo', 'orden_asignaciones', 'orden_estados_historial', 'orden_avances', 'categorias_repuesto', 'repuestos', 'movimientos_stock', 'orden_repuestos', 'medios_pago', 'pagos_cliente', 'pago_cliente_medios', 'suscripciones', 'periodos_suscripcion', 'pagos_suscripcion', 'pago_suscripcion_medios', 'notificaciones', 'auditoria', 'ia_propuestas', 'movimientos_mecanico', 'liquidaciones', 'liquidacion_detalles', 'parametros_sistema', 'intentos_acceso'];
export const CLAVES_DEMO = { superadmin: 'Super123', roberto: 'Dueno123', juan: 'Mecanico123', pedro: 'Mecanico123', carlos: 'Mecanico123' };

export function crearSeed() {
  const H = hoy(); const d = (n) => addDias(H, n); const dt = (n, h = '09:00') => `${d(n)} ${h}`;
  const db = { version: 1, seq: {} };
  COLECCIONES.forEach((c) => { db[c] = []; });
  const add = (col, o) => { db.seq[col] = (db.seq[col] || 0) + 1; const x = Object.assign({ id: db.seq[col] }, o); db[col].push(x); return x; };

  ROLES.forEach((r) => add('roles', r)); PERMISOS.forEach((p) => add('permisos', p));
  Object.entries(ROL_PERMISOS).forEach(([rol, lista]) => lista.forEach((cod) => db.rol_permisos.push({ rol_id: ROLES.find((r) => r.codigo === rol).id, permiso_id: db.permisos.find((p) => p.codigo === cod).id })));
  MEDIOS_PAGO.forEach((m) => add('medios_pago', m)); PARAMETROS.forEach((p) => add('parametros_sistema', p));

  const RID = (codigo) => ROLES.find((r) => r.codigo === codigo).id; // los roles se buscan por código, no por número
  const U = (o) => add('usuarios', Object.assign({ tipo_cuenta: 'taller', taller_id: null, email: null, telefono: null, estado: 'activo', debe_cambiar_clave: 0, ultimo_acceso: null, created_at: dt(-40), updated_at: dt(-40) }, o, { password_hash: hashClave(o.usuario, CLAVES_DEMO[o.usuario]) }));
  const sa = U({ tipo_cuenta: 'superadmin', rol_id: null, nombre: 'Administrador del sistema', usuario: 'superadmin', email: 'admin@plataforma.example' });
  add('superadmins', { usuario_id: sa.id, nivel: 'total', estado: 'activo', cargo: 'Administrador general', notas: null, creado_por: null, created_at: dt(-40) });
  const rob = U({ rol_id: RID('admin'), nombre: 'Roberto Díaz', usuario: 'roberto', telefono: '381-4001122' });
  const t1 = add('talleres', { nombre: 'Taller Matienzo', dueno_id: rob.id, telefono: '381-4001122', direccion: 'Av. Matienzo 100', estado: 'activo', created_at: dt(-40) });
  rob.taller_id = t1.id; // UN SOLO taller

  const juanU = U({ rol_id: RID('mecanico'), taller_id: t1.id, nombre: 'Juan Pérez', usuario: 'juan', telefono: '381-4112233' });
  const pedroU = U({ rol_id: RID('mecanico'), taller_id: t1.id, nombre: 'Pedro Gómez', usuario: 'pedro', telefono: '381-4223344' });
  const carlosU = U({ rol_id: RID('mecanico'), taller_id: t1.id, nombre: 'Carlos López', usuario: 'carlos', estado: 'inactivo' });
  const mec = (u, esp, disp = 1) => add('mecanicos', { usuario_id: u.id, taller_id: t1.id, disponible: disp, especialidad: esp, fecha_alta: d(-35) });
  const juan = mec(juanU, 'Frenos y suspensión'); const pedro = mec(pedroU, 'Motor y service'); mec(carlosU, 'General', 0);

  // Suscripción única (plan único, modalidad mensual, 3 días de tolerancia)
  const s1 = add('suscripciones', { taller_id: t1.id, modalidad: 'mensual', importe: 30000, duracion_meses: 1, fecha_inicio: d(-18), fecha_vencimiento: d(12), dia_ancla: +d(-18).slice(8), created_at: dt(-40) });
  const pagoSis = (s, t, estado, origen, medios, ref, fecha, extra = {}) => {
    const p = add('pagos_suscripcion', Object.assign({ taller_id: t.id, suscripcion_id: s.id, importe: s.importe, estado, origen, referencia: ref, periodo_venc: s.fecha_vencimiento, fecha, registrado_por: origen === 'dueno' ? t.dueno_id : sa.id, decidido_por: null, fecha_decision: null, nuevo_vencimiento: null, motivo_rechazo: null }, extra));
    medios.forEach(([m, imp]) => add('pago_suscripcion_medios', { pago_id: p.id, medio_id: m, importe: imp })); return p;
  };
  const pc1 = pagoSis(s1, t1, 'confirmado', 'dueno', [[1, 10000], [2, 20000]], 'TRF-88213', d(-18), { periodo_venc: d(-18), decidido_por: 1, fecha_decision: d(-18), nuevo_vencimiento: d(12) });
  add('periodos_suscripcion', { suscripcion_id: s1.id, pago_id: pc1.id, desde: d(-18), hasta: d(12), created_at: dt(-18) });
  pagoSis(s1, t1, 'pendiente', 'dueno', [[2, 30000]], 'TRF-55120', H);

  // Clientes y vehículos de Taller Matienzo
  const T = t1.id;
  const cli = (o) => add('clientes', Object.assign({ taller_id: T, email: null, direccion: null, created_at: dt(-30) }, o));
  const veh = (c, o) => { const v = add('vehiculos', Object.assign({ taller_id: T, km: null, created_at: dt(-30) }, o)); add('vehiculo_propietarios', { vehiculo_id: v.id, cliente_id: c.id, desde: d(-30), hasta: null, es_actual: 1 }); return v; };
  const c1 = cli({ nombre: 'Carlos Gómez', telefono: '381-5123456', direccion: 'Av. Matienzo 452' }); const c2 = cli({ nombre: 'María López', telefono: '381-5234567' }); const c3 = cli({ nombre: 'Jorge Ramírez', telefono: '381-5345678' }); const c4 = cli({ nombre: 'Laura Fernández', telefono: '381-5456789', created_at: dt(-6) });
  const v1 = veh(c1, { marca: 'Fiat', modelo: 'Palio', anio: 2014, patente: 'AB123CD', km: 98000 }); veh(c1, { marca: 'Renault', modelo: 'Kangoo', anio: 2018, patente: 'AE456FG', km: 64000 });
  const v2 = veh(c2, { marca: 'Volkswagen', modelo: 'Gol', anio: 2017, patente: 'AC789HI', km: 61000 }); const v3 = veh(c3, { marca: 'Ford', modelo: 'Fiesta', anio: 2015, patente: 'AA321JK', km: 88000 }); const v4 = veh(c4, { marca: 'Renault', modelo: 'Clio', anio: 2012, patente: 'AD456EF', km: 120000 });

  // Stock
  const cat = {}; ['Lubricantes', 'Filtros', 'Frenos', 'Encendido', 'Correas', 'Líquidos', 'Iluminación'].forEach((n) => { cat[n] = add('categorias_repuesto', { taller_id: T, nombre: n }); });
  const stk = (cod, nombre, c, marca, cant, min, costo, precio, ubi) => add('repuestos', { taller_id: T, categoria_id: cat[c].id, codigo: cod, nombre, marca: marca || null, cantidad: cant, minimo: min, costo, precio_referencia: precio, ubicacion: ubi, alerta_stock: cant <= min ? 1 : 0 });
  const rAceite = stk('ACE-1040', 'Aceite 10W40 (litro)', 'Lubricantes', 'Elaion', 28, 6, 8000, 14000, 'Estante A1'); const rFiltro = stk('FIL-OIL', 'Filtro de aceite', 'Filtros', 'Mann', 11, 5, 3500, 7000, 'Estante B2');
  stk('FIL-AIR', 'Filtro de aire', 'Filtros', 'Mann', 4, 5, 4000, 8500, 'Estante B2'); stk('PAS-DEL', 'Pastillas de freno delanteras', 'Frenos', 'Fras-le', 8, 3, 18000, 32000, 'Estante C1');
  const rBujia = stk('BUJ-STD', 'Bujías (unidad)', 'Encendido', 'NGK', 26, 8, 2000, 4500, 'Cajón D3'); stk('COR-DIS', 'Correa de distribución', 'Correas', 'Gates', 3, 3, 15000, 28000, 'Estante C3');
  stk('LIQ-REF', 'Líquido refrigerante (litro)', 'Líquidos', null, 9, 4, 4500, 9000, 'Estante A2'); stk('LAM-H7', 'Lámpara H7', 'Iluminación', 'Osram', 12, 4, 3000, 6500, 'Cajón D1');
  const mov = (r, tipo, cantidad, fecha, nota, extra = {}) => add('movimientos_stock', Object.assign({ repuesto_id: r.id, tipo, cantidad, orden_id: null, usuario_id: rob.id, nota, created_at: fecha }, extra));
  mov(rAceite, 'entrada', 32, dt(-25), 'Compra a proveedor'); mov(rFiltro, 'entrada', 12, dt(-25), 'Compra a proveedor'); mov(db.repuestos[2], 'entrada', 4, dt(-25), 'Compra a proveedor'); mov(rBujia, 'entrada', 30, dt(-25), 'Compra a proveedor');

  // Consultas, presupuestos y órdenes
  const consulta = (c, v, o) => add('consultas', Object.assign({ taller_id: T, cliente_id: c ? c.id : null, vehiculo_id: v ? v.id : null, nombre_contacto: c ? c.nombre : '', telefono_contacto: c ? c.telefono : '', marca: v ? v.marca : '', modelo: v ? v.modelo : '', anio: v ? v.anio : null, patente: v ? v.patente : null, km: v ? v.km : null, problema_original: null, observaciones: null, es_gratuita: 1, cobro_decision: null, cobro_importe: null, cobro_por: null, cobro_fecha: null, motivo_cierre: null, created_at: o.fecha + ' 09:00' }, o));
  const rev = (k, usuario, o) => add('consulta_revisiones', Object.assign({ consulta_id: k.id, usuario_id: usuario.id, problemas_original: null, tecnicas_original: null, fecha: k.fecha }, o));
  const pres = (k, n, estado, items, extra) => { const p = add('presupuestos', Object.assign({ taller_id: T, consulta_id: k.id, numero: codigo('PRE', n), estado, valido_hasta: d(5), fecha_creacion: k.fecha, fecha_envio: k.fecha, fecha_decision: null, total: items.reduce((s, i) => s + i[2] * i[3], 0) }, extra)); items.forEach((i, ix) => add('presupuesto_detalles', { presupuesto_id: p.id, tipo: i[0], descripcion: i[1], cantidad: i[2], precio_unitario: i[3], orden: ix + 1 })); db.seq.pres = n; return p; };
  const orden = (k, p, c, v, n, mecan, estado, o) => add('ordenes_trabajo', Object.assign({ taller_id: T, numero: codigo('OT', n), cliente_id: c.id, vehiculo_id: v.id, consulta_id: k.id, presupuesto_id: p.id, mecanico_id: mecan ? mecan.id : null, estado, comision_pct: 0, repuestos_previstos: null, observaciones: null }, o));
  const hist = (o, estado, usuario, nota, fecha) => add('orden_estados_historial', { orden_id: o.id, estado, usuario_id: usuario.id, nota, created_at: fecha });
  const asig = (o, mecan, resp, fecha, fresp, motivo) => add('orden_asignaciones', { orden_id: o.id, mecanico_id: mecan.id, asignado_por: rob.id, fecha_asignacion: fecha, respuesta: resp, fecha_respuesta: fresp || null, motivo_rechazo: motivo || null });
  db.seq.ot = 3;

  const k1 = consulta(c1, v1, { fecha: d(-16), creada_por: rob.id, problema: 'Se informa pérdida leve de aceite y cambio de aceite pendiente.', estado: 'aprobada' });
  rev(k1, juanU, { problemas: 'Aceite sucio, filtro saturado.', tecnicas: 'Sin pérdidas visibles en el cárter.', repuestos_necesarios: 'Aceite 10W40, filtro de aceite', trabajo_recomendado: 'Cambio de aceite y filtro', importe_estimado: 50000 });
  const p1 = pres(k1, 1, 'aceptado', [['repuesto', 'Aceite 10W40', 4, 14000], ['repuesto', 'Filtro de aceite', 1, 7000], ['mano_obra', 'Mano de obra service', 1, 12000]], { valido_hasta: d(-9), fecha_decision: d(-15) });
  const o1 = orden(k1, p1, c1, v1, 1, juan, 'finalizado', { descripcion: 'Cambio de aceite y filtro', repuestos_previstos: 'Aceite x4, filtro x1', fecha_creacion: d(-15), inicio_previsto: d(-14), entrega_prevista: d(-13) });
  hist(o1, 'pendiente_aceptacion', rob, 'Asignado a Juan Pérez', dt(-15)); hist(o1, 'aceptado', juanU, null, dt(-15, '10:00')); hist(o1, 'en_proceso', juanU, null, dt(-14, '09:30')); hist(o1, 'finalizado', juanU, null, dt(-14, '12:00')); asig(o1, juan, 'aceptada', dt(-15), dt(-15, '10:00'));
  add('orden_avances', { orden_id: o1.id, usuario_id: juanU.id, texto: 'Se drenó el aceite y se reemplazó el filtro.', texto_original: null, created_at: dt(-14, '10:10') });
  [[rAceite, 4], [rFiltro, 1]].forEach(([r, n]) => { const m = mov(r, 'uso_orden', n, dt(-14, '11:00'), 'Usado en ' + o1.numero, { orden_id: o1.id, usuario_id: juanU.id }); add('orden_repuestos', { orden_id: o1.id, repuesto_id: r.id, cantidad: n, usuario_id: juanU.id, movimiento_id: m.id, anulado: 0, created_at: dt(-14, '11:00') }); });
  const pg1 = add('pagos_cliente', { taller_id: T, cliente_id: c1.id, orden_id: o1.id, importe: 40000, fecha: d(-13), es_combinado: 1, observaciones: 'Adelanto y entrega', registrado_por: rob.id, created_at: dt(-13) });
  add('pago_cliente_medios', { pago_id: pg1.id, medio_id: 1, importe: 25000 }); add('pago_cliente_medios', { pago_id: pg1.id, medio_id: 2, importe: 15000 });

  const k2 = consulta(c2, v2, { fecha: d(-3), creada_por: juanU.id, problema: 'Se informa un ruido al accionar los frenos, acompañado de vibraciones durante la frenada.', problema_original: 'el auto hace un ruido cuando freno y parece que vibra todo', observaciones: 'Prefiere que la llamen por la tarde.', estado: 'aprobada' });
  rev(k2, juanU, { problemas: 'Pastillas delanteras desgastadas.', tecnicas: 'Espesor de pastillas por debajo del mínimo; discos con leve desgaste.', repuestos_necesarios: 'Pastillas de freno delanteras', trabajo_recomendado: 'Cambio de pastillas delanteras', importe_estimado: 70000 });
  const p2 = pres(k2, 2, 'aceptado', [['repuesto', 'Pastillas de freno delanteras', 1, 45000], ['mano_obra', 'Mano de obra', 1, 25000]], { valido_hasta: d(4), fecha_decision: d(-1) });
  const o2 = orden(k2, p2, c2, v2, 2, juan, 'pendiente_aceptacion', { descripcion: 'Cambio de pastillas de freno delanteras', repuestos_previstos: 'Pastillas de freno delanteras', fecha_creacion: d(-1), inicio_previsto: d(1), entrega_prevista: d(2) });
  hist(o2, 'pendiente_aceptacion', rob, 'Asignado a Juan Pérez', dt(-1)); asig(o2, juan, 'pendiente', dt(-1));
  add('ia_propuestas', { taller_id: T, usuario_id: juanU.id, entidad: 'consultas', entidad_id: k2.id, campo: 'problema', texto_original: 'el auto hace un ruido cuando freno y parece que vibra todo', texto_propuesto: k2.problema, texto_final: k2.problema, estado: 'aceptada', proveedor: 'reglas_locales', created_at: dt(-3) });

  const k3 = consulta(c4, v4, { fecha: d(-6), creada_por: rob.id, problema: 'Service completo pendiente hace mucho tiempo.', estado: 'aprobada' });
  rev(k3, pedroU, { problemas: 'Aceite oscuro, filtro de aire sucio.', tecnicas: '', repuestos_necesarios: 'Filtro de aire, bujías', trabajo_recomendado: 'Service completo', importe_estimado: 60000 });
  const p3 = pres(k3, 3, 'aceptado', [['mano_obra', 'Service completo', 1, 40000], ['repuesto', 'Bujías', 4, 4500], ['repuesto', 'Filtro de aire', 1, 8500]], { valido_hasta: d(1), fecha_decision: d(-5) });
  const o3 = orden(k3, p3, c4, v4, 3, pedro, 'en_proceso', { descripcion: 'Service completo', repuestos_previstos: 'Bujías x4, filtro de aire x1', fecha_creacion: d(-5), inicio_previsto: d(-2), entrega_prevista: d(1) });
  hist(o3, 'pendiente_aceptacion', rob, 'Asignado a Pedro Gómez', dt(-5)); hist(o3, 'aceptado', pedroU, null, dt(-5, '11:00')); hist(o3, 'en_proceso', pedroU, null, dt(-1, '08:30')); asig(o3, pedro, 'aceptada', dt(-5), dt(-5, '11:00'));
  add('orden_avances', { orden_id: o3.id, usuario_id: pedroU.id, texto: 'Se cambiaron las bujías. Falta el filtro de aire (poco stock).', texto_original: null, created_at: dt(-1, '16:00') });
  const m3 = mov(rBujia, 'uso_orden', 4, dt(-1, '15:30'), 'Usado en ' + o3.numero, { orden_id: o3.id, usuario_id: pedroU.id }); add('orden_repuestos', { orden_id: o3.id, repuesto_id: rBujia.id, cantidad: 4, usuario_id: pedroU.id, movimiento_id: m3.id, anulado: 0, created_at: dt(-1, '15:30') });

  const k4 = consulta(c3, v3, { fecha: d(-2), creada_por: juanU.id, problema: 'Se informa que corresponde el cambio de la distribución.', estado: 'en_presupuesto' });
  rev(k4, juanU, { problemas: 'Correa de distribución con fisuras visibles.', tecnicas: 'Se recomienda cambio por kilometraje y estado.', repuestos_necesarios: 'Kit de distribución', trabajo_recomendado: 'Cambio de distribución', importe_estimado: 200000 });
  pres(k4, 4, 'pendiente', [['repuesto', 'Kit de distribución', 1, 120000], ['mano_obra', 'Mano de obra', 1, 80000]], { fecha_envio: d(-1) });
  const k5 = consulta(null, null, { fecha: d(0), creada_por: rob.id, nombre_contacto: 'Sofía Prospecto', telefono_contacto: '381-5987654', marca: 'Chevrolet', modelo: 'Corsa', anio: 2010, patente: 'HJK123', problema: 'el auto hace un ruido en el motor cuando acelero', observaciones: 'Llamó por teléfono.', estado: 'pendiente' });

  // ---- Volumen de demostración: suficiente para probar buscadores y paginación (más de 10 registros por lista) ----
  const nombres = ['Ana Torres', 'Luis Medina', 'Marta Ruiz', 'Diego Sosa', 'Paula Ríos', 'Hugo Acosta', 'Elena Vega', 'Raúl Herrera', 'Nadia Castro', 'Sergio Molina', 'Julia Ponce', 'Martín Aguirre'];
  const autos = [['Peugeot', '208', 2019], ['Toyota', 'Etios', 2017], ['Chevrolet', 'Onix', 2020], ['Renault', 'Sandero', 2016], ['Ford', 'Focus', 2013], ['Volkswagen', 'Voyage', 2018], ['Fiat', 'Uno', 2011], ['Nissan', 'March', 2015], ['Citroën', 'C3', 2014], ['Honda', 'Fit', 2012], ['Renault', 'Logan', 2019], ['Ford', 'Ka', 2016]];
  const extra = nombres.map((nom, i) => { const c = cli({ nombre: nom, telefono: `381-6${String(100 + i * 7).padStart(3, '0')}${String(10 + i).padStart(2, '0')}`, created_at: dt(-28 + i) }); const a = autos[i]; const v = veh(c, { marca: a[0], modelo: a[1], anio: a[2], patente: `A${String.fromCharCode(65 + i)}${100 + i * 11}${String.fromCharCode(70 + i)}${String.fromCharCode(75 + (i % 10))}`, km: 30000 + i * 9000 }); return { c, v }; });
  const problemas = ['Se informa un ruido al girar el volante.', 'Se informa que el motor no arranca por las mañanas.', 'Se informa una pérdida de líquido refrigerante.', 'Se informan vibraciones en el volante a unos 100 km/h.', 'Se informa que el auto se apaga al detenerse.', 'Se informa olor a quemado al frenar.', 'Se informa que se enciende la luz del tablero.', 'Se informa un ruido en la rueda trasera derecha.'];
  const mecs = [[juan, juanU], [pedro, pedroU]];
  // Consultas finalizadas sin trabajo (historial de consultas)
  extra.slice(0, 8).forEach(({ c, v }, i) => consulta(c, v, { fecha: d(-27 + i * 2), creada_por: i % 2 ? rob.id : juanU.id, problema: problemas[i % problemas.length], estado: 'cerrada', motivo_cierre: 'El cliente decidió no realizar el trabajo' }));
  // Trabajos finalizados y cobrados (historial de trabajos y de pagos)
  let nPres = 4; let nOt = 3; const fin = [];
  extra.slice(4, 12).forEach(({ c, v }, i) => {
    const [mc, mu] = mecs[i % 2]; const k = consulta(c, v, { fecha: d(-24 + i * 2), creada_por: rob.id, problema: problemas[(i + 3) % problemas.length], estado: 'aprobada' });
    rev(k, mu, { problemas: 'Falla confirmada en la revisión.', tecnicas: '', repuestos_necesarios: null, trabajo_recomendado: 'Reparación según presupuesto', importe_estimado: 40000 + i * 5000 });
    nPres += 1; nOt += 1; const imp = 40000 + i * 5000;
    const p = pres(k, nPres, 'aceptado', [['mano_obra', 'Mano de obra', 1, imp - 15000], ['repuesto', 'Repuestos', 1, 15000]], { valido_hasta: d(-10), fecha_decision: d(-23 + i * 2) });
    const o = orden(k, p, c, v, nOt, mc, 'finalizado', { descripcion: 'Reparación según presupuesto', fecha_creacion: d(-23 + i * 2), inicio_previsto: d(-22 + i * 2), entrega_prevista: d(-21 + i * 2) });
    fin.push(o); hist(o, 'pendiente_aceptacion', rob, 'Asignado a ' + mu.nombre, dt(-23 + i * 2)); hist(o, 'aceptado', mu, null, dt(-23 + i * 2, '10:00')); hist(o, 'en_proceso', mu, null, dt(-22 + i * 2, '09:00')); hist(o, 'finalizado', mu, null, dt(-21 + i * 2, '12:00')); asig(o, mc, 'aceptada', dt(-23 + i * 2), dt(-23 + i * 2, '10:00'));
    add('orden_avances', { orden_id: o.id, usuario_id: mu.id, texto: 'Trabajo realizado y probado en ruta.', texto_original: null, created_at: dt(-21 + i * 2, '11:00') });
    if (i < 6) { const pg = add('pagos_cliente', { taller_id: T, cliente_id: c.id, orden_id: o.id, importe: imp, fecha: d(-21 + i * 2), es_combinado: 0, observaciones: null, registrado_por: rob.id, created_at: dt(-21 + i * 2) }); add('pago_cliente_medios', { pago_id: pg.id, medio_id: (i % 3) + 1, importe: imp }); }
  });
  db.seq.pres = nPres; db.seq.ot = nOt;
  // ---- Comisiones, adelantos y liquidaciones (DEMOSTRACIÓN). Los porcentajes son datos de ejemplo, no una política del taller. ----
  const demoOrds = [o1, ...fin]; demoOrds.forEach((o) => { o.comision_pct = 30; });
  const finDe = (o) => { const h = db.orden_estados_historial.filter((x) => x.orden_id === o.id && x.estado === 'finalizado').pop(); return h.created_at; };
  const regCom = (o) => { const base = baseComision(db.presupuesto_detalles.filter((x) => x.presupuesto_id === o.presupuesto_id)); return add('movimientos_mecanico', { taller_id: T, mecanico_id: o.mecanico_id, tipo: 'comision', monto: calcularComision(base, o.comision_pct), orden_id: o.id, fecha: finDe(o), descripcion: `Comisión ${o.comision_pct} % sobre la mano de obra de ${o.numero}`, registrado_por: rob.id }); };
  const mJ = [regCom(o1), regCom(fin[0]), regCom(fin[2])]; const mP = [regCom(fin[1]), regCom(fin[3])];
  const adJ = add('movimientos_mecanico', { taller_id: T, mecanico_id: juan.id, tipo: 'adelanto', monto: 5000, orden_id: null, fecha: dt(-16), descripcion: 'Adelanto de sueldo (demostración)', registrado_por: rob.id });
  const adP = add('movimientos_mecanico', { taller_id: T, mecanico_id: pedro.id, tipo: 'adelanto', monto: 8000, orden_id: null, fecha: dt(-18), descripcion: 'Adelanto de sueldo (demostración)', registrado_por: rob.id });
  const liq = (mec, desde, hasta, movs, estado, extra = {}) => { const t = totalesLiquidacion(movs); const l = add('liquidaciones', Object.assign({ taller_id: T, mecanico_id: mec.id, periodo_desde: d(desde), periodo_hasta: d(hasta), estado, creado_por: rob.id, fecha_creacion: dt(hasta + 1, '10:00'), fecha_pago: null, observaciones: null }, t, extra)); if (estado !== 'anulada') movs.forEach((m) => add('liquidacion_detalles', { liquidacion_id: l.id, movimiento_id: m.id, importe_incluido: m.monto })); return l; };
  liq(juan, -30, -12, [...mJ, adJ], 'pagada', { fecha_pago: dt(-11, '11:00'), observaciones: 'Liquidación pagada (demostración)' });
  liq(pedro, -30, -19, [mP[0]], 'anulada', { observaciones: 'Anulada: se rehizo con otro período (demostración)' });
  liq(pedro, -30, -14, [...mP, adP], 'pendiente', { observaciones: 'Pendiente de pago (demostración)' });
  // Más artículos de stock y sus entradas
  [['ACE-5W30', 'Aceite 5W30 (litro)', 'Lubricantes', 'Elaion', 20, 6, 9500, 16000, 'Estante A1'], ['FIL-COM', 'Filtro de combustible', 'Filtros', 'Mann', 9, 4, 3800, 7500, 'Estante B3'], ['PAS-TRA', 'Pastillas de freno traseras', 'Frenos', 'Fras-le', 7, 3, 14000, 26000, 'Estante C1'], ['DIS-DEL', 'Disco de freno delantero', 'Frenos', 'Fremax', 6, 2, 22000, 38000, 'Estante C2'], ['BAT-60', 'Batería 60 Ah', 'Encendido', 'Moura', 5, 2, 70000, 105000, 'Depósito'], ['COR-ALT', 'Correa de alternador', 'Correas', 'Gates', 8, 3, 6000, 11000, 'Estante C3'], ['LIQ-FRE', 'Líquido de frenos', 'Líquidos', null, 14, 5, 3500, 7000, 'Estante A2'], ['LAM-H4', 'Lámpara H4', 'Iluminación', 'Osram', 15, 5, 2800, 6000, 'Cajón D1'], ['AMO-DEL', 'Amortiguador delantero', 'Frenos', 'Cofap', 4, 2, 30000, 52000, 'Depósito']].forEach((a) => { const r = stk(...a); mov(r, 'entrada', r.cantidad, dt(-20), 'Compra a proveedor'); mov(r, 'salida', 1, dt(-12), 'Consumo del taller'); r.cantidad -= 1; r.alerta_stock = r.cantidad <= r.minimo ? 1 : 0; });
  db.repuestos.filter((r) => !db.movimientos_stock.some((x) => x.repuesto_id === r.id)).forEach((r) => mov(r, 'entrada', r.cantidad, dt(-25), 'Stock inicial'));
  // Actividad e historial de notificaciones leídas
  for (let i = 0; i < 12; i++) add('auditoria', { usuario_id: rob.id, taller_id: T, ambito: 'taller', accion: ['Registró una consulta', 'Presentó un presupuesto al cliente', 'Registró un pago de cliente', 'Asignó el trabajo'][i % 4], entidad: null, entidad_id: null, detalle: `Registro de demostración ${i + 1}`, created_at: dt(-12 + i, '10:00') });
  for (let i = 0; i < 9; i++) add('notificaciones', { clave_unica: 'seed:old' + i, taller_id: T, usuario_id: null, rol_destino: 'admin', texto: ['Trabajo finalizado: avisá al cliente.', 'Pago registrado.', 'Presupuesto aceptado.'][i % 3] + ' (demostración)', ruta: '/trabajos', tipo: 'info', leida: 1, created_at: dt(-15 + i, '09:00') });

  // Notificaciones (con clave única para no duplicarse)
  const n = (o) => add('notificaciones', Object.assign({ clave_unica: null, taller_id: null, usuario_id: null, rol_destino: null, ruta: '/', tipo: 'info', leida: 0, created_at: dt(0, '08:00') }, o));
  n({ clave_unica: 'seed:n1', taller_id: T, rol_destino: 'admin', texto: 'Nueva consulta: Sofía Prospecto (Chevrolet Corsa).', ruta: '/consultas/' + k5.id });
  n({ clave_unica: 'seed:n2', taller_id: T, usuario_id: juanU.id, texto: 'Nuevo trabajo asignado: OT-0002 (Volkswagen Gol).', ruta: '/trabajos/' + o2.id, tipo: 'trabajo' });
  n({ clave_unica: 'seed:n3', taller_id: T, rol_destino: 'admin', texto: 'Stock bajo: Filtro de aire (quedan 4, mínimo 5).', ruta: '/stock', tipo: 'stock' });
  n({ clave_unica: 'seed:sa1', rol_destino: 'superadmin', texto: 'Taller Matienzo informó un pago de $30.000 pendiente de confirmación.', ruta: '/superadmin/pagos', tipo: 'pago' });
  // Coherencia con la regla de negocio del MVP: solo la primera consulta de una misma persona (mismo cliente, teléfono o patente) es gratuita;
  // las siguientes son "repetidas" y quedan con la decisión de cobro registrada por el dueño (sin cargo, para la demostración).
  db.consultas.forEach((k) => {
    const antes = db.consultas.filter((x) => x.id < k.id && ((k.cliente_id && x.cliente_id === k.cliente_id) || (digits(k.telefono_contacto).length >= 6 && digits(x.telefono_contacto).slice(-8) === digits(k.telefono_contacto).slice(-8)) || (k.patente && x.patente === k.patente)));
    k.es_gratuita = antes.length === 0 ? 1 : 0;
    if (!k.es_gratuita) Object.assign(k, { cobro_decision: 'gratis', cobro_importe: 0, cobro_por: rob.id, cobro_fecha: k.fecha });
  });
  add('auditoria', { usuario_id: sa.id, taller_id: null, ambito: 'sistema', accion: 'Datos de demostración cargados', entidad: null, entidad_id: null, detalle: 'Instalación inicial de la demo', created_at: dt(0, '08:00') });
  return db;
}
