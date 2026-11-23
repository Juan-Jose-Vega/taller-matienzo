# Guía para la próxima etapa (backend) — NO implementada

1. **Decisiones pendientes** (ver INFORME_FINAL.md, sección 9) antes de programar.
2. Backend (p. ej. Flask) con conexión a `taller_matienzo`; capa de servicios que reemplace a `workshopService.js` y `commissionService.js` (hoy sobre localStorage).
3. **Autenticación real:** verificar contra `usuarios.password_hash` (bcrypt), bloqueo por `intentos_fallidos`/`bloqueado_hasta`, sesiones/tokens; login separado para el SuperAdmin (`tipo_cuenta = 'superadmin'`, sin rol operativo).
4. **Permisos por perfil** en el servidor (los del MVP están en código: `ROL_PERMISOS` y `PERMISOS_SUPERADMIN`). Resolver roles por código, no por id fijo.
5. **Transacciones del servidor:** descuento de stock + movimiento, historial de estados, renovación de suscripción al confirmar un pago (mensual +1 mes, anual +12), consulta gratuita, bloqueo tras 3 días de tolerancia, **taller único** (la base ya lo impone con CHECK).
6. **Comisiones y liquidaciones:** replicar en el servidor la fórmula documentada (`comisiones_y_liquidaciones.md`): comisión = mano de obra × `comision_pct` ÷ 100 redondeada a 2 decimales; total = comisiones − adelantos; el cálculo definitivo lo hace el backend, no Vue. Mantener UNIQUE (orden, tipo) y un movimiento en una sola liquidación; generar la liquidación en una transacción.
7. **IA para mejorar la redacción:** hoy son reglas locales en Vue. Más adelante, un endpoint Flask llamará al proveedor de IA (claves solo en el servidor, nunca en Vue) y devolverá la propuesta; se mantiene el flujo original / propuesta editable / aceptar o descartar y el guardado en `propuestas_ia`. Sin inventar diagnósticos ni causas.
8. Migración de datos: partir de la sección de datos del SQL; las contraseñas ya son hashes bcrypt.
9. Pruebas: reutilizar las 165 pruebas SQL como base de integración y agregar pruebas de API.
