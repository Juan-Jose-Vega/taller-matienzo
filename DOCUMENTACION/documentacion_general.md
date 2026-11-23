# Documentación general — Taller Matienzo (versión final del MVP y la base de datos)

## 1. Qué es
Sistema de gestión para **un taller mecánico** (Vue 3 + Vite, sin backend por ahora) y su base de datos MySQL 8 de **30 tablas**. En esta etapa se auditó y alineó el MVP con la base; **no** se desarrolló backend, API, conexión real ni autenticación real.

## 2. Reglas de negocio (decisiones definitivas, ya aplicadas en el MVP y en MySQL)
- **Un solo taller** (Taller Matienzo). El MVP ya no muestra ni permite crear un segundo taller; la base lo impone con CHECK (`taller.id = 1`).
- **SuperAdmin separado:** tipo de cuenta independiente (`usuarios.tipo_cuenta = 'superadmin'`, sin `rol_id`, fila propia en `superadmins`, contraseña hash bcrypt). No es dueño ni mecánico ni aparece en listas operativas; su login es aparte.
- **Roles operativos** (idénticos en Vue y MySQL): Administrador y Mecanico. El código resuelve el rol por **código** (`admin`, `mecanico`), no por número.
- **Plan único**, modalidad **mensual o anual** (sin trimestral ni duraciones libres), **3 días corridos de tolerancia**.
- **Comisiones y liquidaciones implementadas en el MVP** (ver `comisiones_y_liquidaciones.md`): comisión = mano de obra × `comision_pct` ÷ 100; adelantos; liquidación por período; pago/anulación; nunca se liquida dos veces un movimiento.
- **Mejora de redacción opcional** (reglas locales): original visible, propuesta editable, aceptar o descartar, sin tocar el original ni inventar diagnósticos; se guarda en `propuestas_ia`. La IA real se integrará más adelante **vía Flask** (nunca con claves en Vue).
- Pagos de clientes y pagos del sistema separados. Hashes bcrypt.

## 3. Cambios de la segunda corrección
Ver `registro_cambios.md`. Resumen: taller único, SuperAdmin/roles, plan mensual/anual, comisiones/liquidaciones, pruebas nuevas, SQL y mapeo actualizados. Sigue sin haber backend.

## 4. Credenciales de DEMOSTRACIÓN
| Usuario | Contraseña | Perfil |
|---|---|---|
| roberto | Dueno123 | Administrador (Taller Matienzo) |
| juan / pedro | Mecanico123 | Mecánicos (carlos, desactivado) |
| superadmin | Super123 | SuperAdmin (`/superadmin/login`) |

Son contraseñas de **demostración**; en el SQL solo hay hashes bcrypt. No se usaron datos personales reales.

## 5. Cómo usar
- **MVP:** `cd MVP/taller-matienzo-mvp-vue && npm ci && npm run dev` (o abrir `dist/index.html` ya compilado). Pruebas: `npm test` (52) y `node scripts/e2e.mjs` (50).
- **Base de datos:** `mysql -u root -p < BASE_DE_DATOS/taller_matienzo_final.sql` (borra y recrea `taller_matienzo`; incluye estructura, datos de demostración y pruebas con ROLLBACK).
- **Diagrama:** `BASE_DE_DATOS/modelo_entidad_relacion.png` (generado desde la base real).
- **Original conservado:** `BASE_DE_DATOS/original/taller_matienzo_tablas_original.sql` y `MVP_ORIGINAL_SIN_MODIFICAR/`.

## 6. Datos de demostración cargados
16 clientes, 17 vehículos, 21 consultas, 12 presupuestos, 11 órdenes, 17 artículos, 29 movimientos de stock, 7 pagos de clientes, 2 períodos de suscripción (mensual), 2 pagos del sistema (1 confirmado, 1 informado), 5 comisiones, 2 adelantos y 3 liquidaciones (pagada, pendiente y anulada). Los porcentajes de comisión (30 %) son datos de ejemplo. Coherentes entre sí (stock = movimientos, total = líneas, estado de orden = último historial, comisión = fórmula).

## 7. Pendientes
Ver `INFORME_FINAL.md` (sección «Pendientes y decisiones»).
