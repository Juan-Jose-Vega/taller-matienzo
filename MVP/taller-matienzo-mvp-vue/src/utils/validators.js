// Validaciones de formularios. Devuelven '' si está bien o el mensaje de error.
import { digits, patente } from './formatters.js';
export const vUsuario = (s) => (/^[a-zA-Z0-9._]{3,20}$/.test(s || '') ? '' : 'El usuario debe tener entre 3 y 20 letras o números, sin espacios.');
export const vClaveNueva = (s) => (s && s.length >= 8 && /[A-Za-z]/.test(s) && /\d/.test(s) ? '' : 'La contraseña debe tener al menos 8 caracteres, con letras y números.');
export const vTelefono = (s) => (digits(s).length >= 6 ? '' : 'Escribí un teléfono válido (al menos 6 números).');
export const vEmail = (s) => (!s || /^\S+@\S+\.\S+$/.test(s) ? '' : 'El correo no parece válido.');
export const vPatente = (s, obligatoria) => { const p = patente(s); if (!p) return obligatoria ? 'Indicá la patente.' : ''; return p.length >= 5 && p.length <= 8 ? '' : 'La patente debe tener entre 5 y 8 letras o números.'; };
export const vAnio = (s) => { if (s === '' || s == null) return ''; const a = parseInt(s, 10); return a >= 1950 && a <= new Date().getFullYear() + 1 ? '' : 'El año del vehículo no es válido.'; };
export const vPositivo = (n, msg) => (Number(n) > 0 ? '' : msg || 'El valor debe ser mayor que cero.');
