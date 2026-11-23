// TODA la lógica de fechas del sistema vive acá (vencimientos, gracia, formatos). Funciones puras.
const p2 = (n) => String(n).padStart(2, '0');
let _fechaSimulada = null; // solo para pruebas automáticas
export const fijarHoy = (iso) => { _fechaSimulada = iso; };

export const hoy = () => {
  if (_fechaSimulada) return _fechaSimulada;
  const d = new Date();
  return `${d.getFullYear()}-${p2(d.getMonth() + 1)}-${p2(d.getDate())}`;
};
export const ahora = () => {
  const d = new Date();
  return `${hoy()} ${p2(d.getHours())}:${p2(d.getMinutes())}`;
};
const aFecha = (iso) => { const [y, m, d] = String(iso).slice(0, 10).split('-').map(Number); return new Date(Date.UTC(y, m - 1, d)); };
const aIso = (d) => `${d.getUTCFullYear()}-${p2(d.getUTCMonth() + 1)}-${p2(d.getUTCDate())}`;

export const addDias = (iso, n) => { const d = aFecha(iso); d.setUTCDate(d.getUTCDate() + n); return aIso(d); };
// Suma meses sin desbordar fin de mes (31/01 + 1 mes = 28/02); "ancla" conserva el día original (28/02 + 1 mes = 31/03).
export const addMeses = (iso, n, ancla) => {
  const d = aFecha(iso); const a = ancla || d.getUTCDate();
  const y = d.getUTCFullYear(); const m = d.getUTCMonth() + n;
  const ultimo = new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
  return aIso(new Date(Date.UTC(y, m, Math.min(a, ultimo))));
};
export const diffDias = (desde, hasta) => Math.round((aFecha(hasta) - aFecha(desde)) / 864e5);
export const fecha = (iso) => {
  if (!iso) return '—';
  const s = String(iso); const [y, m, d] = s.slice(0, 10).split('-');
  return `${d}/${m}/${y}` + (s.length > 10 ? ' ' + s.slice(11, 16) : '');
};
export const mesDe = (iso) => String(iso).slice(0, 7);
const MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
export const mesTxt = (ym) => { const [y, m] = ym.split('-'); return `${MESES[+m - 1]} ${y}`; };
export const esFechaIso = (s) => /^\d{4}-\d{2}-\d{2}$/.test(s || '') && !isNaN(aFecha(s));
