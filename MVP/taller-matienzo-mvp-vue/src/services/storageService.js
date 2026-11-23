// Almacenamiento centralizado: toda la base vive en UNA clave de localStorage y es reactiva (Vue).
// Cada colección guarda registros con campos en snake_case (clientes, vehiculos, consultas…).
import { reactive, watch } from 'vue';
import { crearSeed, COLECCIONES } from './seedData.js';

export const KEY = 'tm_vue_v1'; export const KEY_SESION = 'tm_vue_sesion'; export const KEY_TEMA = 'tm_vue_tema';
let memoria = null;
const leer = (k) => { try { return localStorage.getItem(k); } catch (e) { return k === KEY ? memoria : null; } };
const escribir = (k, v) => { try { if (v == null) localStorage.removeItem(k); else localStorage.setItem(k, v); return true; } catch (e) { if (k === KEY) memoria = v; return false; } };

function cargar() {
  try { const t = leer(KEY); if (t) { const d = JSON.parse(t); if (d && d.version === 1 && COLECCIONES.every((c) => Array.isArray(d[c]))) { delete d.consulta_fotos; if (d.seq) delete d.seq.consulta_fotos; return d; } /* limpia restos de datos guardados con la antigua función de adjuntos */ } } catch (e) { /* se regenera */ }
  const s = crearSeed(); escribir(KEY, JSON.stringify(s)); return s;
}
export const db = reactive(cargar());
export const estadoAlmacen = reactive({ error: false });
let timer = null;
watch(db, () => { clearTimeout(timer); timer = setTimeout(guardar, 40); }, { deep: true });
export function guardar() { const ok = escribir(KEY, JSON.stringify(db)); estadoAlmacen.error = !ok; }

export const nid = (col) => { db.seq[col] = (db.seq[col] || 0) + 1; return db.seq[col]; };
export const add = (col, obj) => { const o = Object.assign({ id: nid(col) }, obj); db[col].push(o); return db[col][db[col].length - 1]; };
export const get = (col, id) => db[col].find((x) => x.id === Number(id)) || null;
export const donde = (col, fn) => db[col].filter(fn);
export function reiniciarDemo() { const s = crearSeed(); COLECCIONES.forEach((c) => { db[c] = s[c]; }); db.seq = s.seq; guardar(); }
export function exportarJson() { return JSON.stringify(db, null, 1); }
export function importarJson(texto) {
  const d = JSON.parse(texto);
  if (!d || d.version !== 1 || !COLECCIONES.every((c) => Array.isArray(d[c]))) throw new Error('formato');
  COLECCIONES.forEach((c) => { db[c] = d[c]; }); db.seq = d.seq || {}; delete db.seq.consulta_fotos; guardar();
}
export const tamanoKb = () => Math.round(((leer(KEY) || '').length) / 1024);
export const leerRaw = leer; export const escribirRaw = escribir;
