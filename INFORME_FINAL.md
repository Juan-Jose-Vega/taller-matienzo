# INFORME FINAL — Taller Matienzo · Segunda corrección

## 1. Resumen
Sobre el MVP y el SQL ya entregados (sin empezar de cero) se aplicaron las cinco decisiones definitivas: **un solo taller**, **SuperAdmin separado**, **plan único mensual o anual**, **comisiones y liquidaciones reales en el MVP** y **mejora de redacción opcional** (reglas locales). MVP y MySQL quedan alineados; la base sigue con 30 tablas. No se desarrolló Flask, backend ni conexión real a MySQL.

## 2. Qué se hizo por decisión
1. **Un taller:** el MVP muestra uno solo y rechaza crear otro; MySQL lo impone (`taller.id = 1`).
2. **SuperAdmin:** tipo de cuenta (`tipo_cuenta='superadmin'`, `rol_id` nulo), login propio, hash bcrypt; no figura en listas del dueño. Roles Vue = MySQL (Administrador 1, Mecánico 2), resueltos por código. Contraseñas de demo conservadas (no se usó ninguna real).
3. **Suscripción:** mensual (1 mes) o anual (12 meses); trimestral eliminado por completo; importes configurables; tolerancia de 3 días.
4. **Comisiones:** comisión = Σ mano de obra del presupuesto × `comision_pct` ÷ 100 (repuestos excluidos). Consulta por mecánico, adelantos, liquidación por período (comisiones − adelantos), listado pendiente/pagada/anulada, pago, anulación de pendientes y bloqueo de doble liquidación. Vista de solo lectura para el mecánico. No se inventó un porcentaje definitivo: es configurable por orden (por defecto 0; los 30 % de la demo son ejemplos). Detalle: `comisiones_y_liquidaciones.md`.
5. **IA opcional:** se mantiene el componente: original visible, propuesta editable, aceptar/descartar, el original nunca se modifica solo; disponible en consultas, inspecciones y avances; guarda propuesta y resultado en `propuestas_ia`. La IA real irá más adelante vía Flask.
6. **Mapeo:** `DOCUMENTACION/mapeo_mvp_mysql.md` actualizado.

## 3. Verificación REAL (ejecutada en esta sesión)
| Qué | Resultado |
|---|---|
| `npm run build` del MVP | Correcto |
| Pruebas unitarias (`npm test`) | **52 / 52** |
| Pruebas e2e en navegador (`node scripts/e2e.mjs`) | **50 correctas, 0 fallos** |
| Importación del SQL final en MySQL 8.0.46 local | Sin errores |
| Pruebas SQL (77 de integridad, 22 de consulta/INNER JOIN, 36 de INSERT/UPDATE/DELETE y procesos con ROLLBACK, 30 de errores esperados) | **165 / 165**; los datos no cambiaron tras ejecutarlas |
Las pruebas de la lista del punto 7 del pedido (segundo taller, SuperAdmin sin rol, roles Vue = MySQL, sin trimestral, mensual/anual, comisiones, adelantos, sin doble liquidación, IA original/aceptar/descartar) están cubiertas por las pruebas unitarias, e2e y/o SQL anteriores.

## 4. Qué NO se verificó
- Uso real de la app contra la base (no hay backend).
- MySQL Workbench en particular (se usó el servidor MySQL 8.0.46 por línea de comandos).
- Concurrencia, rendimiento, IA real, autenticación real.

## 5. Decisiones que quedan para el taller
1. **Base de la comisión:** hoy solo mano de obra; si se decide otra, se cambia `baseComision()` y la prueba SQL 10.3.
2. **Porcentaje:** se carga por orden; definir un valor general si se desea.
3. **Adelantos mayores a las comisiones:** hoy la liquidación se bloquea; definir si el saldo se arrastra.
4. `comprobantes_pagos_sistema` sigue vacía (eliminar si no se quieren adjuntos).
5. Campos sin uso: `motivo_rechazo` en algunos flujos, estado `rechazada` de consultas, `completada` de asignaciones, tipo `servicio` del catálogo.
6. Mercado Pago/tarjeta solo como medios de cobro a clientes; al sistema, efectivo y transferencia.
7. Permisos y rol-permisos siguen en código en el MVP.

## 6. Entregables
`TALLER_MATIENZO_FINAL/`: `MVP/`, `BASE_DE_DATOS/` (`taller_matienzo_final.sql`, `modelo_entidad_relacion.png`, `resultados_ejecucion.json`, `herramientas/`, `original/`), `DOCUMENTACION/` (general, frontend, mapeo, diccionario, pruebas SQL, comisiones y liquidaciones, registro de cambios, guía de próxima etapa), `MVP_ORIGINAL_SIN_MODIFICAR/` y este informe.

## 7. Próximos pasos
`DOCUMENTACION/guia_proxima_etapa.md`.
