# Guía de demostración

## 1. Abrir el MVP
- Taller: abrí `dist/index.html` (doble clic, funciona sin servidor) → pantalla de inicio de sesión del taller.
- Administración de la plataforma: abrí `dist/superadmin.html` o escribí `#/superadmin/login` al final de la dirección. Es una entrada **independiente**: no hay botón ni enlace hacia ella en el login del taller.
- Desarrollo: `npm install` y `npm run dev`. Para reconstruir: `npm run build`.

## 2. Cuentas de demostración — LOGIN DEL TALLER (`#/login`)
| Rol | Usuario | Contraseña |
|---|---|---|
| Dueño (Taller Matienzo) | `roberto` | `Dueno123` |
| Mecánico | `juan` | `Mecanico123` |
| Mecánico | `pedro` | `Mecanico123` |
`carlos` es un mecánico con la cuenta desactivada (sirve para probar el rechazo de acceso).

## 3. Cuenta de demostración — ADMINISTRACIÓN (`#/superadmin/login`)
Solo para esta sección. Usuario `superadmin`, contraseña `Super123`.

## 4. Recorrido sugerido
1. **Dueño**: Nueva consulta → escribir «el auto hace un ruido cuando freno y parece que vibra todo» → *Mejorar redacción* (modo local) → aceptar → guardar. Abrir la consulta, completar la revisión, armar el presupuesto, presentarlo, registrar que el cliente aceptó, *Aprobar y crear orden* (asignar a Juan).
2. **Mecánico (Juan)**: ver el trabajo asignado, aceptarlo (o rechazarlo con motivo), iniciarlo, registrar avance y repuesto usado (el stock baja y nunca queda negativo), finalizarlo.
3. **Dueño**: avisar al cliente por WhatsApp (muestra vista previa; **nunca se envía solo**), registrar el cobro (efectivo, transferencia, Mercado Pago o combinado), ver Reportes y Actividad.
4. **Administración**: Pagos del sistema → confirmar el pago pendiente del taller (confirmar dos veces no renueva dos veces). Cuenta del taller → solo existe una (no permite crear otra). Plan → editar los importes mensual y anual; en la ficha de la cuenta cambiar la modalidad. Mantenimiento → simular «vence hoy», «en gracia» o «bloqueado» y volver a entrar como dueño para ver el efecto.
4b. **Comisiones (dueño)**: Comisiones → «Comisiones por trabajo»: fijar el % de un trabajo finalizado y registrar su comisión; «Adelantos» → registrar uno; «Liquidaciones» → Nueva liquidación (elegir mecánico y período, ver el total a pagar) → generar → registrar pago. Como Juan o Pedro: «Mis comisiones» (solo lectura). Los porcentajes de la demo (30 %) son datos de ejemplo.
5. **Separación**: con el dueño abierto, escribir `#/superadmin` → vuelve a su inicio. Con la administración abierta, escribir `#/clientes` → vuelve al panel de administración.

## 5. Pruebas incluidas
- `npm test`: 22 pruebas (motor de texto, servicio de texto, paginación, reglas de suscripción y fechas).
- `node scripts/e2e.mjs`: pruebas de extremo a extremo en Chromium sobre `dist/index.html` (acceso y separación, recarga, cierre de sesión, cambio de usuario, ejemplos de texto, flujo consulta→orden, stock, pagos, suscripción, móvil sin scroll horizontal, modo oscuro, sin errores de consola). Requiere Playwright con Chromium instalado.

## 6. Limitaciones (para decirlas con honestidad)
- La consigna recibida estaba **truncada** en la sección 11 (punto 3); se implementó todo lo anterior y lo indicado explícitamente.
- Los permisos son una **simulación del frontend**, no seguridad real (ver `docs/arquitectura.md`). El código del panel de administración está dentro del mismo paquete.
- Contraseñas del MVP con SHA-256 + sal (demostración).
- La mejora de texto usa **reglas locales**; es buena con los casos típicos de taller pero no entiende cualquier frase libre. «no se q le pasa» queda como «no se que le pasa» (sin acentuar «sé/qué»).
- Probado en Chromium; no se probó en otros navegadores. Los datos viven en el navegador (si se borran los datos del sitio, se pierden; hay exportar/importar en Mantenimiento).
