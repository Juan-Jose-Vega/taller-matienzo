# Documentación del frontend (MVP Vue)

## Tecnología y estructura
Vue 3 + Vue Router + CSS plano + JavaScript. Datos en `localStorage` (clave `tm_vue_v1`, 37 colecciones en `seedData.js`: sin `consulta_fotos` ni `planes_suscripcion`; con `movimientos_mecanico`, `liquidaciones`, `liquidacion_detalles`).
- `src/views/` pantallas (`taller/`, `superadmin/`), `src/services/` (`workshopService`, `storageService`, `seedData`, etc.), `src/styles/` (`base.css`, `layout.css`, `components.css`), `scripts/e2e.mjs`, `tests/`.

## Perfiles y pantallas
- **Administrador:** **comisiones y liquidaciones**, clientes, vehículos, consultas (nueva, detalle con revisión técnica), presupuestos, trabajos, mecánicos, stock, pagos, reportes, actividad, suscripción, notificaciones, perfil, ayuda.
- **Mecánico:** **mis comisiones** (solo lectura), sus trabajos, clientes/vehículos de sus trabajos, stock disponible, historial, consultas nuevas.
- **SuperAdmin** (`/superadmin/login`): cuenta del taller (una sola), plan único mensual/anual, pagos, actividad, mantenimiento, cuenta.

## Cambios de esta versión
### Fotografías
Eliminadas de `seedData.js`, `workshopService.js` (`fotosDe`, `agregarFoto`, `quitarFoto`), `ConsultaDetalleView.vue` (tarjeta, modal, textos), `components.css` (`.fotos`) y docs. `storageService.js` borra restos `consulta_fotos` de datos guardados con la versión anterior, también al importar un respaldo JSON. No quedan cargas de imágenes (la importación de respaldo JSON de Mantenimiento es un archivo de datos, no una foto).

### Subrayados
`base.css`: `a, a:link, a:visited, a:hover, a:active, a:focus, a:focus-visible { text-decoration: none }`. Excepción deliberada en `layout.css`: los enlaces **dentro de una frase** de un aviso (`.banner a`) conservan el subrayado porque lo identifican como acción. Colores, tamaños y diseño no se tocaron.

### Datos de demostración
Las consultas repetidas de un cliente ya no figuran como gratuitas: se recalculan `es_gratuita` y la decisión de cobro (regla: solo la primera es gratuita).

## Segunda corrección
- **Roles:** `config/permisos.js` define solo `admin` (id 1) y `mecanico` (id 2), iguales a MySQL; `services/rolesService.js` los resuelve por código (`rolId`, `rolCodigoDe`). El SuperAdmin es `tipo_cuenta = 'superadmin'` con `rol_id = null` y permisos `PERMISOS_SUPERADMIN` propios.
- **Taller único:** el seed tiene un taller; `crearCuenta` rechaza una segunda cuenta y la pantalla «Cuenta del taller» no ofrece «Crear cuenta».
- **Plan único:** `MODALIDADES` (mensual = 1 mes, anual = 12 meses), importes en `parametros_sistema` (`importe_mensual`, `importe_anual`); pantalla «Plan de suscripción» solo edita esos dos importes; el vencimiento se calcula; tolerancia de 3 días. No existe plan trimestral.
- **Comisiones/liquidaciones:** `utils/comisiones.js`, `services/commissionService.js`, `ComisionesView.vue`, `MisComisionesView.vue`. Detalle en `comisiones_y_liquidaciones.md`.
- **Mejora de redacción:** se conserva tal cual (modal con original y propuesta editable, aceptar o descartar; disponible en descripción de la consulta, revisión técnica y avances de trabajos). Se guarda en `ia_propuestas` (estado aceptada/editada/descartada, texto original, propuesto y final). Sin claves de API ni llamadas externas; la IA real irá por Flask.

## Verificación realizada (real)
- `npm run build`: correcto. `npm test`: **52/52** (incluye `comisiones.test.mjs`, `modelo.test.mjs`, `propuestasIA.test.mjs`). `node scripts/e2e.mjs`: **50 correctas, 0 fallos** (rutas, formularios, temas, subrayados, taller único, SuperAdmin separado, roles, plan, comisiones de punta a punta, mecánico de solo lectura, IA aceptar/editar/descartar, sin solicitudes externas).
