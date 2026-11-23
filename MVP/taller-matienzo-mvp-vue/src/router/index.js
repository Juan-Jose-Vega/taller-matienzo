// Rutas y protección por ámbito. La separación taller / SuperAdmin se mantiene al iniciar y cerrar sesión, recargar,
// navegar y escribir una dirección a mano. AVISO: sin backend esto es una SIMULACIÓN de permisos, no seguridad real.
import { createRouter, createWebHashHistory } from 'vue-router';
import { usuario, esSuperAdmin, esTaller, rol, can, tallerId } from '../services/authService.js';
import { tallerBloqueado, sincronizar } from '../services/subscriptionService.js';
import { toast, ui } from '../services/uiService.js';

import LoginView from '../views/LoginView.vue';
import SuperAdminLoginView from '../views/superadmin/SuperAdminLoginView.vue';
import TallerLayout from '../layouts/TallerLayout.vue';
import SuperAdminLayout from '../layouts/SuperAdminLayout.vue';
import HomeView from '../views/HomeView.vue';
import ConsultasView from '../views/taller/ConsultasView.vue';
import ConsultaNuevaView from '../views/taller/ConsultaNuevaView.vue';
import ConsultaDetalleView from '../views/taller/ConsultaDetalleView.vue';
import ClientesView from '../views/taller/ClientesView.vue';
import VehiculosView from '../views/taller/VehiculosView.vue';
import ClienteFichaView from '../views/taller/ClienteFichaView.vue';
import PresupuestosView from '../views/taller/PresupuestosView.vue';
import PresupuestoVerView from '../views/taller/PresupuestoVerView.vue';
import TrabajosView from '../views/taller/TrabajosView.vue';
import TrabajoDetalleView from '../views/taller/TrabajoDetalleView.vue';
import MecanicosView from '../views/taller/MecanicosView.vue';
import MecanicoFichaView from '../views/taller/MecanicoFichaView.vue';
import StockView from '../views/taller/StockView.vue';
import PagosView from '../views/taller/PagosView.vue';
import ReportesView from '../views/taller/ReportesView.vue';
import ComisionesView from '../views/taller/ComisionesView.vue';
import MisComisionesView from '../views/taller/MisComisionesView.vue';
import SuscripcionView from '../views/taller/SuscripcionView.vue';
import ActividadView from '../views/taller/ActividadView.vue';
import NotificacionesView from '../views/NotificacionesView.vue';
import PerfilView from '../views/PerfilView.vue';
import AyudaView from '../views/AyudaView.vue';
import SaDashboardView from '../views/superadmin/SuperAdminDashboardView.vue';
import SaCuentasView from '../views/superadmin/SaCuentasView.vue';
import SaCuentaView from '../views/superadmin/SaCuentaView.vue';
import SaPlanesView from '../views/superadmin/SaPlanesView.vue';
import SaPagosView from '../views/superadmin/SaPagosView.vue';
import SaActividadView from '../views/superadmin/SaActividadView.vue';
import SaMantenimientoView from '../views/superadmin/SaMantenimientoView.vue';
import NoEncontradoView from '../views/NoEncontradoView.vue';

const t = (path, component, permiso, padre = '/') => ({ path, component, meta: { permiso, padre } });
const s = (path, component, permiso, padre = '/superadmin') => ({ path, component, meta: { permiso, padre } });
const routes = [
  { path: '/login', component: LoginView, meta: { publica: 'taller' } },
  { path: '/superadmin/login', component: SuperAdminLoginView, meta: { publica: 'superadmin' } },
  { path: '/', component: TallerLayout, meta: { ambito: 'taller' }, children: [
    { path: '', component: HomeView, meta: { padre: null } },
    t('consultas', ConsultasView, 'consultas.ver'), t('consultas/nueva', ConsultaNuevaView, 'consultas.crear', '/consultas'), t('consultas/:id', ConsultaDetalleView, 'consultas.ver', '/consultas'),
    t('clientes', ClientesView, 'clientes.gestionar'), t('clientes/:id', ClienteFichaView, 'clientes.gestionar', '/clientes'),
    t('vehiculos', VehiculosView, 'clientes.gestionar'), t('presupuestos', PresupuestosView, 'presupuestos.gestionar'), t('presupuestos/:id', PresupuestoVerView, 'presupuestos.gestionar', '/presupuestos'),
    t('trabajos', TrabajosView, 'ordenes.ver'), t('trabajos/:id', TrabajoDetalleView, 'ordenes.ver', '/trabajos'),
    t('mecanicos', MecanicosView, 'mecanicos.gestionar'), t('mecanicos/:id', MecanicoFichaView, 'mecanicos.gestionar', '/mecanicos'),
    t('stock', StockView, 'stock.gestionar'), t('pagos', PagosView, 'pagos_clientes.gestionar'), t('reportes', ReportesView, 'reportes.ver'),
    t('comisiones', ComisionesView, 'comisiones.gestionar'), t('mis-comisiones', MisComisionesView, 'comisiones.ver_propias'), t('suscripcion', SuscripcionView, 'suscripcion.ver'), t('actividad', ActividadView, 'actividad.ver'),
    t('notificaciones', NotificacionesView, null), t('perfil', PerfilView, null), t('ayuda', AyudaView, null),
  ] },
  { path: '/superadmin', component: SuperAdminLayout, meta: { ambito: 'superadmin' }, children: [
    { path: '', component: SaDashboardView, meta: { padre: null } },
    s('cuentas', SaCuentasView, 'sa.cuentas'), s('cuentas/:id', SaCuentaView, 'sa.cuentas', '/superadmin/cuentas'), s('planes', SaPlanesView, 'sa.planes'),
    s('pagos', SaPagosView, 'sa.pagos'), s('actividad', SaActividadView, 'sa.auditoria'), s('mantenimiento', SaMantenimientoView, 'sa.mantenimiento'),
    s('notificaciones', NotificacionesView, null), s('perfil', PerfilView, null),
  ] },
  { path: '/:resto(.*)*', component: NoEncontradoView, meta: { publica: 'cualquiera' } },
];
const router = createRouter({ history: createWebHashHistory(), routes, scrollBehavior: () => ({ top: 0 }) });

const PERMITIDAS_BLOQUEADO = ['/suscripcion', '/ayuda', '/perfil', '/notificaciones'];
router.beforeEach((to) => {
  ui.bell = false; sincronizar();
  const m = to.meta;
  if (m.publica === 'taller') return esSuperAdmin.value ? '/superadmin' : esTaller.value ? '/' : true;
  if (m.publica === 'superadmin') return esTaller.value ? '/' : esSuperAdmin.value ? '/superadmin' : true;
  if (m.publica === 'cualquiera') return true;
  const raiz = to.matched[0] && to.matched[0].meta.ambito;
  if (raiz === 'superadmin') {
    if (!usuario.value) return '/superadmin/login';
    if (!esSuperAdmin.value) return '/';                       // un dueño o mecánico vuelve a su propia área
    if (m.permiso && !can(m.permiso)) return '/superadmin';
    if (usuario.value.debe_cambiar_clave && to.path !== '/superadmin/perfil') { toast('Primero cambiá tu contraseña temporal.', 'aviso'); return '/superadmin/perfil'; }
    return true;
  }
  if (!usuario.value) return '/login';
  if (esSuperAdmin.value) return '/superadmin';               // el SuperAdmin no entra solo a las pantallas del taller
  const permiso = m.permiso === 'ordenes.ver' ? (can('ordenes.ver_todas') ? 'ordenes.ver_todas' : 'ordenes.ver_propias') : m.permiso;
  if (permiso && !can(permiso)) { toast('Esa sección no está disponible para tu rol.', 'aviso'); return '/'; }
  if (usuario.value.debe_cambiar_clave && to.path !== '/perfil') { toast('Primero cambiá tu contraseña temporal.', 'aviso'); return '/perfil'; }
  if (tallerBloqueado(tallerId.value) && !PERMITIDAS_BLOQUEADO.includes(to.path)) {
    if (rol.value === 'admin') { if (to.path !== '/') toast('Tu acceso está restringido por falta de pago. Regularizá tu suscripción.', 'error'); return '/suscripcion'; }
    if (to.path !== '/') return '/';
  }
  return true;
});
export default router;
