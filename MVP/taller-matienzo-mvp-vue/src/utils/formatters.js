// Formatos y normalización de texto (funciones puras).
export const money = (n) => '$' + (Math.round((Number(n) || 0) * 100) / 100).toLocaleString('es-AR', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
export const num = (v) => { const n = parseFloat(String(v == null ? '' : v).replace(',', '.')); return Number.isFinite(n) ? n : 0; };
export const norm = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').trim();
export const digits = (s) => String(s || '').replace(/\D/g, '');
export const patente = (s) => String(s || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
export const plural = (n, uno, varios) => `${n} ${n === 1 ? uno : varios}`;
export const codigo = (prefijo, n) => `${prefijo}-${String(n).padStart(4, '0')}`;
export const vehTxt = (v) => v ? `${v.marca || ''} ${v.modelo || ''}${v.anio ? ' ' + v.anio : ''}${v.patente ? ' · ' + v.patente : ''}`.trim() : '—';
export const nombreCorto = (s) => String(s || '').split(' ')[0];
// Enlace wa.me: solo PREPARA el mensaje; nunca se envía automáticamente.
export const waLink = (tel, texto) => {
  let d = digits(tel); if (d.startsWith('00')) d = d.slice(2); if (d.startsWith('0')) d = d.slice(1);
  if (d.length === 10) d = '549' + d; // celular argentino sin código de país
  if (d.length < 10 || d.length > 15) return null;
  return `https://wa.me/${d}?text=${encodeURIComponent(texto)}`;
};
