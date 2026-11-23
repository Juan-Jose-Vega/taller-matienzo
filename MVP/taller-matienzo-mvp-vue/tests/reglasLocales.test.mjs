import test from 'node:test'; import assert from 'node:assert/strict';
import { mejorarConReglas } from '../src/services/ai/reglasLocales.js';
import { LEXICO_CAUSAS } from '../src/config/textRules.js';
const m = (t, c = 'problema') => mejorarConReglas(t, { contexto: c }).propuesta;
const sinPunto = (s) => s.replace(/\.$/, '');
test('ejemplo 1 de la consigna', () => assert.equal(sinPunto(m('El auto hace un ruido cuando freno y parece que vibra todo')), 'Se informa un ruido al accionar los frenos, acompañado de vibraciones durante la frenada'));
test('ejemplo 2 de la consigna', () => assert.equal(sinPunto(m('el motor hace un ruido raro cuando lo prendo y despues se va')), 'Se informa un ruido inusual al encender el motor que desaparece después de unos momentos'));
test('otros casos no hardcodeados', () => {
  assert.match(m('ruido en la rueda delantera derecha cuando doblo'), /^Se informa ruido en la rueda delantera derecha al girar el volante/);
  assert.match(m('me pierde aceite y no arranca'), /pérdida de aceite/);
  assert.match(m('el volante vibra mucho a 100 km/h'), /vibraciones intensas en el volante/);
});
test('corrige tildes y ortografía en avances', () => assert.equal(m('se cambio el filtro falta probar el vehiculo en ruta', 'avance'), 'Se cambió el filtro. Falta probar el vehículo en ruta.'));
test('no inventa causas ni diagnósticos', () => {
  const entradas = ['el auto hace un ruido cuando freno y parece que vibra todo', 'el motor hace un ruido raro cuando lo prendo y despues se va', 'me pierde aceite y no arranca', 'sale humo blanco del escape'];
  for (const e of entradas) { const out = m(e).toLowerCase(); for (const w of LEXICO_CAUSAS) if (!e.toLowerCase().includes(w)) assert.ok(!out.includes(w), `"${w}" aparece en "${out}"`); }
});
test('un texto ya formal no cambia', () => { const r = mejorarConReglas('Se informa un ruido al accionar los frenos.', { contexto: 'problema' }); assert.equal(r.propuesta, 'Se informa un ruido al accionar los frenos.'); assert.equal(r.sinCambios, true); });
