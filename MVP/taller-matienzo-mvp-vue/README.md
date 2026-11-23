# Taller Matienzo — MVP (Vue 3)

Aplicación **solo frontend** hecha con Vue 3, Vue Router, HTML (plantillas de componentes), CSS y JavaScript. No usa backend, API ni base de datos: los datos de demostración se guardan en `localStorage` del navegador.

## Instalar y ejecutar
Requisito: Node.js 18 o superior (solo para Vue/Vite; no hay servidor propio).
```
npm install
npm run dev        # abre la aplicación en modo desarrollo (la dirección aparece en la terminal)
npm run build      # genera dist/index.html (un único archivo que también se abre con doble clic)
npm test           # pruebas unitarias (motor de texto, paginación, suscripciones)
```
Para presentar sin instalar nada: abrir `dist/index.html` en el navegador.

## Accesos
- **Taller** (`#/login`): dueño `roberto` / `Dueno123` · mecánico `juan` / `Mecanico123` (también `pedro` / `Mecanico123`).
- **Administración de la plataforma** (SuperAdmin): acceso independiente en `dist/superadmin.html` o `#/superadmin/login`. Usuario `superadmin` / contraseña `Super123`. (No aparece en el login normal.)
- Para volver a los datos de demostración: SuperAdmin → Mantenimiento → *Restaurar datos de demostración* (pide confirmación).

## Estructura
```
src/
  components/     componentes reutilizables (PaginationBar, AppModal, FormField, AiTextField, KpiCard…)
  composables/    usePaginacion.js (paginación real)
  views/          pantallas del taller y de la administración
  layouts/        TallerLayout y SuperAdminLayout
  router/         rutas y protección por perfil
  services/       reglas de negocio, almacenamiento (localStorage), notificaciones, auditoría, suscripciones, datos de demostración
  config/         permisos y reglas configurables del corrector de texto
  utils/ styles/ assets/
docs/             arquitectura, guía de demostración y lista de entrega
```
Más información: `docs/ENTREGA.md` (funcionalidades, errores corregidos y limitaciones), `docs/guia_demostracion.md`, `docs/arquitectura.md`.

> Los permisos son una simulación en el navegador para la demostración; no son seguridad real.
