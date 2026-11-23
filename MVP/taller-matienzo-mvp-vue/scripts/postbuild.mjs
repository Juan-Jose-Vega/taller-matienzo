// Después de compilar: crea dist/superadmin.html, una página mínima que lleva al acceso independiente
// del SuperAdmin (#/superadmin/login). No se enlaza desde ninguna pantalla del taller.
import { writeFileSync, existsSync } from 'node:fs';
if (!existsSync('dist/index.html')) { console.error('No existe dist/index.html'); process.exit(1); }
writeFileSync('dist/superadmin.html', `<!doctype html>
<html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Acceso de administración</title>
<meta http-equiv="refresh" content="0; url=index.html#/superadmin/login"></head>
<body><script>location.replace('index.html#/superadmin/login');</script>
<p><a href="index.html#/superadmin/login">Continuar</a></p></body></html>
`);
console.log('dist/index.html y dist/superadmin.html listos');
