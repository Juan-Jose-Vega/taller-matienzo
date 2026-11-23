<script setup>
import { computed } from 'vue';
import MenuTile from '../../components/MenuTile.vue'; import KpiCard from '../../components/KpiCard.vue'; import PageHeader from '../../components/PageHeader.vue';
import { db } from '../../services/storageService.js'; import { usuario } from '../../services/authService.js'; import { estadoTaller } from '../../services/subscriptionService.js'; import { noLeidas } from '../../services/notificationService.js'; import { nombreCorto } from '../../utils/formatters.js';
const est = computed(() => db.talleres.map((t) => estadoTaller(t.id)));
const n = (fn) => est.value.filter(fn).length;
const pend = computed(() => db.pagos_suscripcion.filter((p) => ['pendiente', 'registrado'].includes(p.estado)).length);
</script>
<template>
  <PageHeader :titulo="`Hola, ${nombreCorto(usuario.nombre)}`" subtitulo="Administración de la plataforma" :volver="null" />
  <div class="menu">
    <MenuTile to="/superadmin/cuentas" icono="users" texto="Cuenta del taller" color="c1" /><MenuTile to="/superadmin/planes" icono="card" texto="Plan de suscripción" color="c2" /><MenuTile to="/superadmin/pagos" icono="dollar" texto="Pagos del sistema" color="c4" :extra="pend ? `${pend} por resolver` : ''" />
    <MenuTile to="/superadmin/actividad" icono="activity" texto="Actividad" color="c7" /><MenuTile to="/superadmin/mantenimiento" icono="server" texto="Mantenimiento" color="c5" /><MenuTile to="/superadmin/notificaciones" icono="bell" texto="Notificaciones" color="c3" :extra="noLeidas(usuario) ? `${noLeidas(usuario)} sin leer` : ''" /><MenuTile to="/superadmin/perfil" icono="user" texto="Mi perfil" color="c6" />
  </div>
  <h2>Resumen de cuentas</h2>
  <div class="kpis">
    <KpiCard to="/superadmin/cuentas" :valor="db.talleres.length" texto="Cuentas en total" /><KpiCard to="/superadmin/cuentas?f=activas" :valor="db.talleres.filter((t) => t.estado === 'activo').length" texto="Cuentas activas" /><KpiCard to="/superadmin/cuentas?f=suspendidas" :valor="db.talleres.filter((t) => t.estado === 'suspendido').length" texto="Cuentas suspendidas" />
    <KpiCard to="/superadmin/cuentas?f=porvencer" :valor="n((e) => e && e.estado === 'proximo')" texto="Por vencer" /><KpiCard to="/superadmin/cuentas?f=morosas" :valor="n((e) => e && ['vencido', 'gracia', 'bloqueado'].includes(e.estado))" texto="Vencidas o bloqueadas" :alerta="n((e) => e && e.estado === 'bloqueado') > 0" /><KpiCard to="/superadmin/pagos?f=pendiente" :valor="pend" texto="Pagos por resolver" :alerta="pend > 0" />
  </div>
  <p class="hint">Este panel gestiona la cuenta del taller, el plan y los pagos. No muestra clientes, vehículos, consultas ni trabajos de los talleres.</p>
</template>
