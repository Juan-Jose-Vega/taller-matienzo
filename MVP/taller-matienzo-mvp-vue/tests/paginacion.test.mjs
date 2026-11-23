import test from 'node:test'; import assert from 'node:assert/strict';
import { ref, nextTick } from 'vue';
import { usePaginacion } from '../src/composables/usePaginacion.js';
const lista = (n) => Array.from({ length: n }, (_, i) => i + 1);
test('35 registros, 10 por página: 4 páginas y rangos correctos', () => {
  const datos = ref(lista(35)); const p = usePaginacion(() => datos.value);
  assert.equal(p.total, 35); assert.equal(p.totalPaginas, 4); assert.equal(p.items.length, 10); assert.equal(p.desde, 1); assert.equal(p.hasta, 10);
  p.siguiente(); p.siguiente(); p.siguiente(); assert.equal(p.pagina, 4); assert.deepEqual(p.items, [31, 32, 33, 34, 35]); assert.equal(p.desde, 31); assert.equal(p.hasta, 35);
  p.siguiente(); assert.equal(p.pagina, 4, 'no pasa de la última'); p.ir(1); p.anterior(); assert.equal(p.pagina, 1, 'no baja de la primera');
});
test('opciones 5, 10, 20 y 50 por página', () => {
  const p = usePaginacion(() => lista(120)); for (const [n, pags] of [[5, 24], [10, 12], [20, 6], [50, 3]]) { p.cambiarTamano(n); assert.equal(p.totalPaginas, pags); assert.equal(p.items.length, n); assert.equal(p.pagina, 1); }
  p.cambiarTamano(7); assert.equal(p.tamano, 10, 'valores no permitidos vuelven a 10');
});
test('al eliminar el último registro de la última página, corrige la página actual', async () => {
  const datos = ref(lista(21)); const p = usePaginacion(() => datos.value, { porPagina: 10 }); p.ir(3); assert.deepEqual(p.items, [21]);
  datos.value = datos.value.slice(0, 20); await nextTick(); assert.equal(p.pagina, 2); assert.equal(p.items.length, 10); assert.equal(p.totalPaginas, 2);
});
test('al buscar o filtrar vuelve a la página 1', async () => {
  const q = ref(''); const datos = ref(lista(50)); const p = usePaginacion(() => datos.value.filter((n) => String(n).includes(q.value)), { reiniciarCon: () => [q.value] });
  p.ir(4); assert.equal(p.pagina, 4); q.value = '1'; await nextTick(); assert.equal(p.pagina, 1); assert.equal(p.total, 14);
});
test('lista vacía: una página, sin registros', () => { const p = usePaginacion(() => []); assert.equal(p.total, 0); assert.equal(p.totalPaginas, 1); assert.equal(p.desde, 0); assert.deepEqual(p.items, []); });
