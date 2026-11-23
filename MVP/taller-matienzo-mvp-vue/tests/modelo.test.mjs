import test from 'node:test'; import assert from 'node:assert/strict';
globalThis.localStorage = { getItem: () => null, setItem() {}, removeItem() {} };
const { fijarHoy } = await import('../src/utils/dates.js'); fijarHoy('2026-11-20');
const { db } = await import('../src/services/storageService.js');
const P = await import('../src/config/permisos.js');
const A = await import('../src/services/authService.js');
const S = await import('../src/services/subscriptionService.js');
const { rolId, rolCodigoDe } = await import('../src/services/rolesService.js');

test('taller único: el seed tiene un solo taller', () => { assert.equal(db.talleres.length, 1); assert.equal(db.talleres[0].nombre, 'Taller Matienzo'); assert.equal(db.suscripciones.length, 1); });
test('no se puede crear un segundo taller', () => {
  assert.equal(A.ingresarSuperAdmin('superadmin', 'Super123').ok, true);
  const r = S.crearCuenta(A.usuario.value, { nombre: 'Otro', usuario: 'otro', taller: 'Otro Taller', modalidad: 'mensual', inicio: '2026-11-20' }, 'Tmabcde1234');
  assert.equal(r.ok, false); assert.match(r.error, /único taller/); assert.equal(db.talleres.length, 1); assert.ok(!db.usuarios.some((u) => u.usuario === 'otro'));
});
test('roles del frontend = roles de MySQL: solo Administrador y Mecanico, resueltos por código', () => {
  assert.deepEqual(db.roles.map((r) => [r.id, r.codigo, r.nombre]), [[1, 'admin', 'Administrador'], [2, 'mecanico', 'Mecanico']]);
  assert.equal(rolId('admin'), 1); assert.equal(rolId('mecanico'), 2); assert.equal(rolId('superadmin'), null);
  assert.ok(!db.rol_permisos.some((rp) => !db.roles.find((r) => r.id === rp.rol_id)), 'rol_permisos solo referencia roles existentes');
});
test('el SuperAdmin es un tipo de cuenta, no un rol: sin rol_id y fuera de las listas operativas', () => {
  const sa = db.usuarios.filter((u) => u.tipo_cuenta === 'superadmin'); assert.equal(sa.length, 1); assert.equal(sa[0].rol_id, null); assert.equal(rolCodigoDe(sa[0]), 'superadmin');
  assert.ok(db.superadmins.some((x) => x.usuario_id === sa[0].id));
  assert.ok(!db.talleres.some((t) => t.dueno_id === sa[0].id), 'no es dueño de ningún taller'); assert.ok(!db.mecanicos.some((m) => m.usuario_id === sa[0].id), 'no es mecánico');
  db.usuarios.filter((u) => u.tipo_cuenta === 'taller').forEach((u) => assert.ok(u.rol_id === 1 || u.rol_id === 2));
  assert.ok(!db.roles.some((r) => /superadmin/i.test(r.codigo + r.nombre)));
});
test('la contraseña del SuperAdmin está guardada como hash y la demo conserva la clave de ejemplo', () => {
  const sa = db.usuarios.find((u) => u.tipo_cuenta === 'superadmin'); assert.notEqual(sa.password_hash, 'Super123'); assert.ok(!sa.password_hash.includes('Super123')); assert.ok(A.ingresarSuperAdmin('superadmin', 'Super123').ok);
});
test('el SuperAdmin no entra por el login del taller y viceversa', () => { A.salir(); assert.equal(A.ingresarTaller('superadmin', 'Super123').ok, false); assert.equal(A.ingresarSuperAdmin('roberto', 'Dueno123').ok, false); });
test('permisos: SuperAdmin solo "sa.*"; el administrador gestiona comisiones; el mecánico solo ve las suyas', () => {
  assert.ok(P.PERMISOS_SUPERADMIN.length && P.PERMISOS_SUPERADMIN.every((c) => c.startsWith('sa.')));
  assert.ok(P.ROL_PERMISOS.admin.includes('comisiones.gestionar')); assert.ok(!P.ROL_PERMISOS.mecanico.includes('comisiones.gestionar')); assert.ok(P.ROL_PERMISOS.mecanico.includes('comisiones.ver_propias')); assert.equal(P.ROL_PERMISOS.superadmin, undefined);
});
test('no existe el plan trimestral ni una colección de planes', () => {
  assert.deepEqual(Object.keys(P.MODALIDADES), ['mensual', 'anual']); assert.equal(db.planes_suscripcion, undefined);
  assert.ok(!/trimestral/i.test(JSON.stringify(db)), 'ningún dato menciona un plan trimestral'); assert.equal(S.modalidadValida('trimestral'), false); assert.equal(S.modalidadValida('mensual'), true); assert.equal(S.modalidadValida('anual'), true);
});
test('modalidad mensual y anual: duración, vencimiento e importes', () => {
  assert.equal(S.mesesDe('mensual'), 1); assert.equal(S.mesesDe('anual'), 12); assert.equal(S.vencimientoDe('2026-11-20', 'mensual'), '2026-12-20'); assert.equal(S.vencimientoDe('2026-11-20', 'anual'), '2027-11-20'); assert.equal(S.vencimientoDe('2026-01-31', 'mensual'), '2026-02-28');
  assert.equal(S.importeDe('mensual'), 30000); assert.equal(S.importeDe('anual'), 300000);
  const s = db.suscripciones[0]; assert.ok(['mensual', 'anual'].includes(s.modalidad)); assert.equal(s.fecha_vencimiento, S.vencimientoDe(s.fecha_inicio, s.modalidad));
});
test('cambiar la modalidad de la suscripción y los importes', () => {
  const t = db.talleres[0]; const sa = A.usuario.value || (A.ingresarSuperAdmin('superadmin', 'Super123'), A.usuario.value);
  assert.equal(S.guardarSuscripcion(sa, t.id, { modalidad: 'trimestral', inicio: '2026-11-20' }).ok, false);
  assert.equal(S.guardarSuscripcion(sa, t.id, { modalidad: 'anual', inicio: '2026-11-20' }).ok, true); const s = S.suscripcionDe(t.id); assert.equal(s.modalidad, 'anual'); assert.equal(s.fecha_vencimiento, '2027-11-20'); assert.equal(s.importe, 300000); assert.equal(s.duracion_meses, 12);
  assert.equal(S.guardarPrecios(sa, { mensual: 0, anual: 1 }).ok, false); assert.equal(S.guardarPrecios(sa, { mensual: 32000, anual: 320000 }).ok, true); assert.equal(S.importeDe('mensual'), 32000);
});
test('tolerancia de 3 días corridos', () => {
  const t = db.talleres[0]; const sa = A.usuario.value; S.guardarSuscripcion(sa, t.id, { modalidad: 'mensual', inicio: '2026-10-15' }); // vence 2026-11-15
  const e = S.estadoTaller(t.id, '2026-11-18'); assert.equal(e.estado, 'gracia'); assert.equal(S.estadoTaller(t.id, '2026-11-19').estado, 'bloqueado'); assert.equal(S.param('dias_gracia', 0), 3);
});
