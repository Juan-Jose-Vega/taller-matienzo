# Registro de cambios

## MVP
| Cambio | Archivos |
|---|---|
| Eliminada la función de fotografías | seedData.js, workshopService.js, ConsultaDetalleView.vue, components.css, docs/ENTREGA.md |
| Limpieza de `consulta_fotos` en datos guardados e importaciones | storageService.js |
| Sin subrayado en enlaces (todos los estados, claro/oscuro); excepción en enlaces de frase de avisos | base.css, layout.css |
| Consultas repetidas no gratuitas en la demo | seedData.js |
| 5 pruebas e2e nuevas | scripts/e2e.mjs |
Error propio corregido: un comentario `//` rompió el build tras editar storageService.js; se cambió a `/* */`.

## Base de datos (SQL original → final)
- **Eliminada:** `archivos_trabajos`.
- **Agregadas columnas** a usuarios (email, teléfono, especialidad, disponible), consultas (observaciones_inspeccion, importe_estimado, cobro_*, motivo_cierre), entre otras necesarias para el MVP (ver diccionario).
- **Nueva tabla:** `avances_ordenes` (avances del mecánico). Total: 30 tablas (30 − archivos_trabajos + avances_ordenes). 57 claves foráneas.
- **Restricciones:** CHECK de taller único, tolerancia de 3 días, tipo de cuenta/rol, destinatario único de notificaciones, ámbito de auditoría, importes positivos, cobro (corregido tras la prueba 4.10); UNIQUE de presupuesto por consulta y orden por presupuesto; columna generada `detalles_presupuestos.monto`.
- **Pruebas:** de 42 originales a 151; corregidas las de IA (contexto) y liquidaciones (totales).
- **Datos de demo:** regenerados desde el seed del MVP con fecha fija 2026-11-20; coherentes.
- El SQL final es **un único archivo** con estructura, datos y pruebas. El original se conserva intacto.

---
# SEGUNDA CORRECCIÓN (sobre lo ya entregado, sin empezar de cero)

## MVP
| Decisión | Cambio | Archivos principales |
|---|---|---|
| 1. Un solo taller | Seed con un único taller (se quitó el 2.º taller y su suscripción); `crearCuenta` rechaza una segunda cuenta; la pantalla no ofrece «Crear cuenta» si ya existe | seedData.js, subscriptionService.js, SaCuentasView.vue, SaCuentaView.vue, SuperAdminDashboardView.vue |
| 2. SuperAdmin separado | Roles = Administrador (1) y Mecánico (2), iguales a MySQL; SuperAdmin = `tipo_cuenta 'superadmin'`, `rol_id` null, permisos propios; roles resueltos por código | permisos.js, rolesService.js (nuevo), authService.js, notificationService.js, workshopService.js, seedData.js |
| 3. Plan mensual/anual | Eliminados el plan trimestral y la colección de planes; `MODALIDADES`; importes en parámetros; vencimiento calculado; tolerancia 3 días | permisos.js, subscriptionService.js, SaPlanesView.vue, SaCuentaView.vue, SuscripcionView.vue |
| 4. Comisiones y liquidaciones | Cálculo, adelantos, liquidación por período, pago/anulación, sin doble liquidación; vistas para Administrador y Mecánico | utils/comisiones.js, commissionService.js, ComisionesView.vue, MisComisionesView.vue, router, HomeView.vue, AyudaView.vue, docs/comisiones_y_liquidaciones.md |
| 5. Mejora de redacción | Se conservó el componente (original, propuesta editable, aceptar/descartar); se verificó con pruebas; documentada la integración futura vía Flask | tests/propuestasIA.test.mjs |
| 7. Pruebas | 52 unitarias (antes 22) y 50 e2e (antes 40) | tests/*.mjs, scripts/e2e.mjs |

## Base de datos
- Sigue en **30 tablas**; no se agregaron tablas.
- `movimientos_mecanicos`: nuevo `UNIQUE (orden_id, tipo)` (una comisión por orden) y CHECK `ck_movmec_tipo_orden` (comisión ⇒ con orden; adelanto ⇒ sin orden).
- Datos de demo regenerados desde el seed del MVP: un taller, SuperAdmin por tipo de cuenta, roles por código, comisiones, adelantos, liquidaciones (pagada/pendiente/anulada), propuestas de IA y un pago del sistema informado.
- Pruebas SQL: de 151 a **165** (nuevas: un solo taller, SuperAdmin sin rol, sin plan trimestral, comisión por mano de obra, adelantos descontados, sin doble liquidación, anulación, UNIQUE/CHECK de movimientos). Se ajustaron 6.3, 10.3, 10.4, 11.2, 11.5–11.7, 13.5, 18.1; 12.10, 13.8 y 16.7 pasaron a verificarse por `information_schema` (el error ENUM 1265 no es capturable en un handler).
- Corrección del ayudante `sp_esperar_error` (el diagnóstico se leía tras un IF y devolvía NULL).
- Originales intactos: `BASE_DE_DATOS/original/` y `MVP_ORIGINAL_SIN_MODIFICAR/`.
