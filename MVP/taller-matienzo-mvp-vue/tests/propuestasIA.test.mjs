import test from 'node:test'; import assert from 'node:assert/strict';
globalThis.localStorage = { getItem: () => null, setItem() {}, removeItem() {} };
const { db } = await import('../src/services/storageService.js');
const A = await import('../src/services/authService.js');
const I = await import('../src/services/aiTextService.js');
assert.equal(A.ingresarTaller('juan', 'Mecanico123').ok, true);
const U = A.usuario.value;
const orig = 'el auto hace un ruido cuando freno y parece que vibra todo';

test('mejorar es opcional y NO modifica el texto original', async () => {
  const antes = db.ia_propuestas.length; const r = await I.mejorarTexto(orig); assert.equal(r.ok, true);
  assert.equal(r.original, orig); assert.notEqual(r.propuesta, orig); assert.equal(db.ia_propuestas.length, antes, 'solo proponer no guarda ni cambia nada');
  assert.equal(r.proveedor.id, 'reglas_locales');
});
test('no inventa diagnósticos ni causas', async () => {
  const r = await I.mejorarTexto('hace ruido al frenar'); const t = r.propuesta.toLowerCase();
  for (const mal of ['pastilla', 'disco', 'rodamiento', 'correa', 'bujía', 'bujia', 'porque', 'debido a', 'se debe']) assert.ok(!t.includes(mal), 'inventó: ' + mal);
});
test('aceptar guarda original, propuesta y resultado', async () => {
  const r = await I.mejorarTexto(orig); const p = I.registrarPropuesta({ usuario: U, entidad: 'consultas', campo: 'problema', original: r.original, propuesta: r.propuesta, final: r.propuesta, estado: 'aceptada' });
  const g = db.ia_propuestas.find((x) => x.id === p.id); assert.equal(g.estado, 'aceptada'); assert.equal(g.texto_original, orig); assert.equal(g.texto_propuesto, r.propuesta); assert.equal(g.texto_final, r.propuesta); assert.equal(g.proveedor, 'reglas_locales');
});
test('editar la propuesta guarda el texto final distinto de lo propuesto', async () => {
  const r = await I.mejorarTexto(orig); const final = r.propuesta + ' Además, el cliente pidió revisar el nivel de aceite.';
  const p = I.registrarPropuesta({ usuario: U, entidad: 'orden_avances', campo: 'texto', original: r.original, propuesta: r.propuesta, final, estado: 'editada' });
  assert.equal(p.estado, 'editada'); assert.equal(p.texto_final, final); assert.equal(p.texto_original, orig); assert.notEqual(p.texto_final, p.texto_propuesto);
});
test('descartar conserva el original y no deja texto final', async () => {
  const r = await I.mejorarTexto(orig); const p = I.registrarPropuesta({ usuario: U, entidad: 'consultas', campo: 'problema', original: r.original, propuesta: r.propuesta, final: null, estado: 'descartada' });
  assert.equal(p.estado, 'descartada'); assert.equal(p.texto_final, null); assert.equal(p.texto_original, orig);
});
test('se vincula la propuesta a la entidad guardada', async () => {
  const r = await I.mejorarTexto(orig); const p = I.registrarPropuesta({ usuario: U, entidad: 'consultas', campo: 'problema', original: r.original, propuesta: r.propuesta, final: r.propuesta, estado: 'aceptada' });
  I.vincularPropuestas([p.id], 'consultas', 7); assert.equal(p.entidad, 'consultas'); assert.equal(p.entidad_id, 7);
});
test('no hay IA externa: el proveedor remoto está deshabilitado y no se llama a internet', async () => {
  assert.equal(I.proveedorRemoto.disponible, false); await assert.rejects(() => I.proveedorRemoto.mejorar('x')); assert.equal(I.proveedorActivo().tipo, 'local');
});
