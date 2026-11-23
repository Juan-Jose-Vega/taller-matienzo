// Vuelca los datos de demostración del MVP (src/services/seedData.js) a JSON, con una fecha de referencia fija.
// Uso:  node dump_seed.mjs <ruta-al-MVP> <AAAA-MM-DD> > seed.json
import { pathToFileURL } from 'node:url'; import path from 'node:path';
const [mvp, fecha] = [process.argv[2], process.argv[3] || '2026-11-20'];
const { fijarHoy } = await import(pathToFileURL(path.resolve(mvp, 'src/utils/dates.js')).href);
fijarHoy(fecha);
const { crearSeed } = await import(pathToFileURL(path.resolve(mvp, 'src/services/seedData.js')).href);
process.stdout.write(JSON.stringify(crearSeed(), null, 1));
