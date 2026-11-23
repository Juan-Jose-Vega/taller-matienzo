import test from 'node:test'; import assert from 'node:assert/strict';
globalThis.localStorage = { getItem: () => null, setItem() {}, removeItem() {} };
const S = await import('../src/services/aiTextService.js');
test('rechaza texto vacío', async () => { for (const v of ['', '   ', null, undefined]) { const r = await S.mejorarTexto(v); assert.equal(r.ok, false); } });
test('el proveedor activo es local y no simula una llamada externa', () => { const p = S.proveedorActivo(); assert.match(p.nombre, /local/i); assert.equal(S.proveedorRemoto.disponible, false); });
test('no se puede activar un proveedor remoto no disponible', () => { S.usarProveedor(S.proveedorRemoto); assert.match(S.proveedorActivo().nombre, /local/i); });
test('conserva el original', async () => { const r = await S.mejorarTexto('el motor hace un ruido raro cuando lo prendo y despues se va'); assert.equal(r.ok, true); assert.equal(r.original, 'el motor hace un ruido raro cuando lo prendo y despues se va'); });
