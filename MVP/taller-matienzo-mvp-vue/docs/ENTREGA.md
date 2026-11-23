# Entrega — Funcionalidades, errores corregidos y limitaciones

## 1. Funcionalidades implementadas
**General**
- Vue 3 + Vue Router + CSS + JavaScript; datos en `localStorage` (se conservan al recargar; el reinicio de datos pide confirmación y no duplica nada).
- Diseño rojo oscuro, modo claro/oscuro, adaptable a PC, tablet y celular; menú principal con íconos grandes y botón «Volver» en secciones secundarias.
- Datos de demostración con volumen suficiente para probar buscadores y paginación (16 clientes, 17 vehículos, 21 consultas, 12 presupuestos, 11 órdenes, 17 artículos de stock, movimientos, pagos, notificaciones y actividad).

**Paginación (componente `PaginationBar` + `usePaginacion`)**
- 5, 10, 20 o 50 por página, anterior/siguiente, «Página X de Y», registros encontrados e indicador «1–10 de 35».
- Vuelve a la página 1 al buscar o filtrar y corrige la página si queda vacía tras eliminar.
- Aplicada a: clientes, vehículos, consultas, presupuestos, trabajos (incluido el historial del mecánico), mecánicos, stock, historial de movimientos de stock, pagos y saldos, notificaciones, actividad, listas de las fichas de cliente y mecánico, pagos y períodos de suscripción, comisiones y liquidaciones y, en administración, cuenta, pagos, actividad e intentos de acceso.

**SuperAdmin** (acceso independiente, no aparece en el login normal): iniciar/cerrar sesión; administrar la cuenta del dueño de **un único taller** (si ya existe no permite crear otra); plan de suscripción único con modalidad **mensual o anual** (sin otros planes ni duraciones) e importes de cada modalidad; fecha de inicio (el vencimiento se calcula); registrar pagos de demostración (efectivo, transferencia o combinado); confirmar o rechazar pagos (la confirmación no renueva dos veces); restablecer credenciales con clave temporal; notificaciones de vencimientos; actividad del sistema; herramientas de demostración (simular vencimientos, respaldo JSON, restaurar datos).

**Administrador (dueño)**: clientes, vehículos, consultas, revisión técnica, presupuestos (borrador, presentar, aceptado/rechazado), creación de la orden de trabajo (una sola por presupuesto), asignar y reasignar mecánicos, estado de trabajos, stock con movimientos (nunca negativo) y alertas, pagos de clientes (efectivo, transferencia, Mercado Pago o combinado), mecánicos (alta, edición, disponibilidad, activar/desactivar, restablecer contraseña), **comisiones y liquidaciones de mecánicos** (porcentaje por trabajo, comisión sobre la mano de obra, adelantos, liquidación por período, pago y anulación; ver docs/comisiones_y_liquidaciones.md), reportes, actividad, suscripción propia, notificaciones y ayuda. Altas, ediciones y **eliminaciones** (con confirmación y con reglas para no dejar datos huérfanos).

**Mecánico**: ve solo sus trabajos; acepta o rechaza (con motivo), inicia, registra avances y repuestos usados, finaliza; consulta clientes y vehículos de sus trabajos, el stock disponible y su historial; crea consultas.

**Consultas**: primera consulta gratuita y siguientes con decisión de cobro e importe; detección de clientes duplicados; aviso por WhatsApp con vista previa (nunca se envía solo).

**Mejora de texto (modo local de demostración)**: reglas configurables de ortografía, tildes, puntuación, mayúsculas, repeticiones y claridad; muestra original y propuesta; permite aceptar, editar o descartar; conserva el texto original; no inventa diagnósticos; no usa ni simula una IA externa.

## 2. Errores encontrados y corregidos
- El acceso del SuperAdmin estaba mezclado con el login normal: ahora es una entrada independiente con su propio panel, y los perfiles no pueden entrar al área del otro (ni escribiendo la dirección, ni recargando, ni cambiando de usuario).
- El buscador de clientes devolvía **todos** los clientes cuando se escribía texto sin números (la comparación de teléfonos coincidía con un texto vacío). Corregido.
- Una orden de trabajo podía duplicarse con un doble clic en «Crear orden»: ahora hay una sola por consulta y presupuesto.
- Confirmar dos veces el mismo pago de suscripción podía renovar dos veces: ahora la confirmación es idempotente.
- El stock de demostración no coincidía con sus movimientos (un artículo mostraba 4 con una entrada de 6, y otros no tenían entrada): ahora cantidad y movimientos son coherentes.
- La mejora de texto funcionaba solo con dos frases fijas: se reemplazó por un motor de reglas configurable (ejemplos: «el auto hace un ruido cuando freno…», «el motor hace un ruido raro cuando lo prendo…», «ruido en la rueda delantera derecha cuando doblo»).
- El código estaba en un único archivo: se separó en componentes, vistas, servicios, estilos, utilidades y paginación.
- Las listas mostraban todos los registros: ahora están paginadas.

## 3. Funciones demostrativas o con limitaciones
- **Permisos y contraseñas simulados**: sin backend, el control de acceso se hace en el navegador y las contraseñas se guardan con un hash simple (SHA-256 con sal). No es seguridad real; el código del panel de administración viaja en el mismo paquete.
- **Datos locales**: viven en un solo navegador; borrar los datos del sitio los elimina (hay exportar/importar en Mantenimiento).
- **Mejora de texto local**: cubre los casos típicos de taller, pero no entiende cualquier frase libre; por ejemplo «no se q le pasa» queda «no se que le pasa».
- **WhatsApp**: abre el enlace `wa.me` con el mensaje preparado; no envía nada automáticamente.
- **Pagos y suscripciones**: no hay cobro real ni conexión con Mercado Pago; son registros de demostración.
- **Pruebas**: hechas en Chromium; no se probó en otros navegadores.
- **Consigna anterior truncada** (sección 11): se implementó todo lo que indicaba el texto recibido.
- No se incluye base de datos ni scripts SQL (se trabajan por separado en MySQL Workbench).
