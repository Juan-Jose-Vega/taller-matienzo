# Arquitectura — Taller Matienzo (MVP en Vue 3)

## Capas
- **Vistas** (`src/views`, `src/layouts`, `src/components`): Vue 3 `<script setup>` + CSS propio. Sin lógica de negocio pesada.
- **Servicios** (`src/services`): reglas de negocio (`workshopService`, `subscriptionService`, `authService`, `notificationService`, `auditService`, `aiTextService`, `storageService`).
- **Reglas puras** (`subscriptionRules.js`, `ai/reglasLocales.js`, `config/*`): sin base de datos, testeables en Node.
- **Persistencia**: `localStorage` (clave `tm_vue_v1`) con un store reactivo. No hay backend, API propia, Express, PHP ni MySQL en el MVP.
- **Datos**: colecciones en memoria (`db.clientes`, `db.consultas`…) guardadas como JSON en `localStorage`.

## Separación SuperAdmin / taller
| Aspecto | Taller (dueño y mecánico) | SuperAdmin |
|---|---|---|
| Entrada | `#/login` | `#/superadmin/login` (independiente; nadie la enlaza desde el login del taller) |
| Layout | `TallerLayout` | `SuperAdminLayout` (cabecera y navegación propias) |
| Sesión | `{usuario_id, ambito:'taller'}` | `{usuario_id, ambito:'superadmin'}` |
| Rutas | `/…` | `/superadmin/…` |

Guardia del router (`src/router/index.js`): sin sesión → login del ámbito; dueño/mecánico en `/superadmin/*` → `/`; SuperAdmin en pantallas del taller → `/superadmin`; usuario logueado en una pantalla de login → su inicio; permisos por pantalla con `can()`; cambio de clave temporal obligatorio; taller bloqueado → solo Suscripción/Ayuda/Perfil/Notificaciones.
`ingresarTaller` rechaza las cuentas de tipo SuperAdmin con el mismo mensaje genérico que una clave incorrecta (no revela que existe).

> **Importante:** sin servidor, estos permisos son una **simulación en el frontend**. El código del panel SuperAdmin viaja dentro del mismo paquete y los datos están en el navegador; cualquiera con las herramientas del navegador podría alterarlos. En producción cada regla debe aplicarse en el backend (autenticación por sesión/JWT, autorización por rol/permiso en cada endpoint, hashes bcrypt/argon2, auditoría).

## Mejora de textos
`aiTextService.js` define una interfaz de proveedor `{ id, nombre, disponible, mejorar(texto, opciones) }`.
- **Proveedor local (activo)**: `reglasLocales.js` aplica reglas configurables (`src/config/textRules.js`): ortografía, tildes, puntuación, mayúsculas, repeticiones y muletillas, claridad, registro profesional y organización de la frase. Funciona sin conexión. La interfaz muestra «Modo local de demostración» y nunca dice que una IA analizó el texto.
- **Guarda de seguridad**: el léxico de causas (`LEXICO_CAUSAS`) impide que el motor agregue piezas o diagnósticos que la persona no escribió.
- **Flujo**: validar que no esté vacío → mostrar original y propuesta → editar → aceptar o descartar → se guarda el texto aceptado **junto con el original** (`problema_original`, `problemas_original`, `texto_original`) y el registro en `ia_propuestas`.
- **Proveedor remoto**: `proveedorRemoto` es un marcador **deshabilitado**; no hace llamadas ni se simula una.

### Para usar una IA real
Se necesita un backend propio, por ejemplo `POST /api/texto/mejorar`:
1. Autentica al usuario y controla su permiso `ia.usar` y límites de uso.
2. Guarda la **clave del proveedor solo en variables de entorno del servidor**; nunca en archivos `.js`, en variables públicas de Vite (`VITE_*`) ni en el navegador.
3. Envía el texto con instrucciones fijas (reescribir sin agregar causas ni diagnósticos) y valida/filtra la respuesta.
4. Devuelve la propuesta; el frontend usa el mismo flujo de aceptar/editar/descartar y registra `proveedor` en `ia_propuestas`.
El frontend solo tendría que registrar un proveedor `fetch('/api/texto/mejorar')` con `disponible: true`.

## Contraseñas
MVP: SHA-256 con sal (`hashClave`) — simulación para la demostración. En un sistema real el hash (bcrypt/argon2) lo calcula el backend.

## Suscripciones
Estados: vigente → próximo (≤ 7 días) → vencido → gracia (3 días) → bloqueado; o suspendida. Confirmar un pago es **idempotente** (se controla `periodos_suscripcion.pago_id` y `periodo_venc`). La renovación continúa desde el vencimiento anterior; si estaba bloqueado, empieza hoy.
