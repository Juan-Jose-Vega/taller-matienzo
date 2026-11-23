// Correspondencia de roles Vue <-> MySQL. Se resuelve SIEMPRE por código ('admin', 'mecanico'), nunca por un número fijo.
// El SuperAdmin no tiene rol: se identifica por usuarios.tipo_cuenta === 'superadmin'.
import { db } from './storageService.js';
export const rolId = (codigo) => { const r = db.roles.find((x) => x.codigo === codigo); return r ? r.id : null; };
export const rolCodigoDe = (u) => { if (!u) return null; if (u.tipo_cuenta === 'superadmin') return 'superadmin'; const r = db.roles.find((x) => x.id === u.rol_id); return r ? r.codigo : null; };
