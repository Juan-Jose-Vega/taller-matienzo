<script setup>
import { computed } from 'vue';
import MenuTile from '../components/MenuTile.vue'; import KpiCard from '../components/KpiCard.vue'; import PageHeader from '../components/PageHeader.vue';
import EmptyState from '../components/EmptyState.vue'; import StatusTag from '../components/StatusTag.vue';
import { db } from '../services/storageService.js';
import { usuario, rol, tallerId, taller, mecanicoActual } from '../services/authService.js';
import { estadoTaller } from '../services/subscriptionService.js';
import { textoDias } from '../services/subscriptionRules.js';
import { noLeidas } from '../services/notificationService.js';
import { trabajosFinalizados } from '../services/commissionService.js';
import { mine, presEstado, nombreMecanico, mecanicosDelTaller } from '../services/workshopService.js';
import { money, nombreCorto } from '../utils/formatters.js';
import { hoy, addDias } from '../utils/dates.js';
const hace = (iso, n) => iso >= addDias(hoy(), -n);
const e = computed(() => estadoTaller(tallerId.value));
const ords = computed(() => mine('ordenes_trabajo')); const cons = computed(() => mine('consultas')); const pres = computed(() => mine('presupuestos'));
const bajos = computed(() => mine('repuestos').filter((s) => s.cantidad <= s.minimo).length);
const ingresos = computed(() => mine('pagos_cliente').filter((p) => hace(p.fecha, 30)).reduce((s, p) => s + p.importe, 0));
const mecs = computed(() => mecanicosDelTaller());
const disp = computed(() => mecs.value.filter((m) => m.disponible && db.usuarios.find((u) => u.id === m.usuario_id).estado === 'activo').length);
const cerradaReciente = (o) => db.orden_estados_historial.some((h) => h.orden_id === o.id && h.estado === 'finalizado' && hace(h.created_at.slice(0, 10), 7));
const recientes = computed(() => ords.value.slice().sort((a, b) => b.id - a.id).slice(0, 5));
const misOrds = computed(() => (mecanicoActual.value ? ords.value.filter((o) => o.mecanico_id === mecanicoActual.value.id) : []));
const n = (s) => misOrds.value.filter((o) => o.estado === s).length;
const activos = computed(() => misOrds.value.filter((o) => ['pendiente_aceptacion', 'aceptado', 'en_proceso'].includes(o.estado)));
const pend = computed(() => cons.value.filter((c) => c.estado === 'pendiente').length);
const veh = (id) => db.vehiculos.find((v) => v.id === id) || {}; const cli = (id) => db.clientes.find((c) => c.id === id) || {};
const porRegistrar = computed(() => (rol.value === 'admin' ? trabajosFinalizados().filter((x) => !x.registrada && x.comision > 0).length : 0));
const bloqueado = computed(() => e.value && e.value.bloqueado);
</script>
<template>
  <template v-if="rol === 'admin'">
    <PageHeader :titulo="`Hola, ${nombreCorto(usuario.nombre)}`" :subtitulo="`Panel del dueño · ${taller.nombre}`" :volver="null" />
    <div class="menu">
      <MenuTile to="/consultas/nueva" icono="plus" texto="Nueva consulta" color="c1" extra="Registrarla en segundos" destacado />
      <MenuTile to="/consultas" icono="search" texto="Consultas" color="c2" /><MenuTile to="/clientes" icono="users" texto="Clientes" color="c3" /><MenuTile to="/vehiculos" icono="car" texto="Vehículos" color="c5" /><MenuTile to="/presupuestos" icono="file" texto="Presupuestos" color="c6" />
      <MenuTile to="/trabajos" icono="tool" texto="Trabajos" color="c4" /><MenuTile to="/mecanicos" icono="user" texto="Mecánicos" color="c5" /><MenuTile to="/stock" icono="box" texto="Stock" color="c8" />
      <MenuTile to="/pagos" icono="dollar" texto="Pagos de clientes" color="c4" /><MenuTile to="/comisiones" icono="clip" texto="Comisiones" color="c6" :extra="porRegistrar ? `${porRegistrar} por registrar` : ''" /><MenuTile to="/reportes" icono="chart" texto="Reportes" color="c7" /><MenuTile to="/suscripcion" icono="card" texto="Mi suscripción" color="c1" :extra="e ? e.label : ''" />
      <MenuTile to="/actividad" icono="activity" texto="Actividad" color="c7" /><MenuTile to="/ayuda" icono="help" texto="Ayuda" color="c3" />
    </div>
    <h2>Resumen del taller</h2>
    <div class="kpis">
      <KpiCard to="/consultas?estado=pendiente" :valor="cons.filter((c) => c.estado === 'pendiente').length" texto="Consultas pendientes" />
      <KpiCard to="/presupuestos?estado=pendiente" :valor="pres.filter((p) => presEstado(p) === 'pendiente').length" texto="Presupuestos por responder" />
      <KpiCard to="/trabajos?estado=en_curso" :valor="ords.filter((o) => ['aceptado', 'en_proceso'].includes(o.estado)).length" texto="Trabajos en curso" />
      <KpiCard to="/trabajos?estado=sin_asignar" :valor="ords.filter((o) => o.estado === 'sin_asignar').length" texto="Pendientes de asignación" :alerta="ords.some((o) => o.estado === 'sin_asignar')" />
      <KpiCard to="/trabajos?estado=pendiente_aceptacion" :valor="ords.filter((o) => o.estado === 'pendiente_aceptacion').length" texto="Esperando que el mecánico acepte" />
      <KpiCard to="/trabajos?estado=finalizado" :valor="ords.filter((o) => o.estado === 'finalizado' && cerradaReciente(o)).length" texto="Finalizados (últimos 7 días)" />
      <KpiCard to="/mecanicos" :valor="`${disp} de ${mecs.length}`" texto="Mecánicos disponibles" />
      <KpiCard to="/stock?f=bajo" :valor="bajos" texto="Artículos con stock bajo" :alerta="bajos > 0" />
      <KpiCard to="/pagos" :valor="money(ingresos)" texto="Ingresos (últimos 30 días)" />
      <KpiCard to="/suscripcion" :valor="e ? e.label : '—'" :texto="e ? textoDias(e) : ''" />
    </div>
    <h2>Últimos trabajos</h2>
    <div v-if="recientes.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Trabajo</th><th>Cliente</th><th>Mecánico</th><th>Estado</th></tr></thead><tbody>
      <tr v-for="o in recientes" :key="o.id" class="click" @click="$router.push('/trabajos/' + o.id)"><td data-l="Trabajo"><b>{{ o.numero }}</b></td><td data-l="Cliente">{{ cli(o.cliente_id).nombre }}</td><td data-l="Mecánico">{{ o.mecanico_id ? nombreMecanico(o.mecanico_id) : '—' }}</td><td data-l="Estado"><StatusTag tipo="orden" :valor="o.estado" /></td></tr></tbody></table></div>
    <EmptyState v-else icono="tool" titulo="Todavía no hay trabajos" mensaje="Cuando un cliente acepte un presupuesto se crea la orden de trabajo. Empezá registrando una consulta."><router-link class="btn" to="/consultas/nueva">Registrar la primera consulta</router-link></EmptyState>
  </template>
  <template v-else>
    <PageHeader :titulo="`Hola, ${nombreCorto(usuario.nombre)}`" subtitulo="Panel del mecánico" :volver="null" />
    <div v-if="bloqueado" class="hint err">El taller tiene el acceso restringido por falta de pago. Avisale al dueño.</div>
    <div class="menu">
      <MenuTile to="/consultas/nueva" icono="plus" texto="Nueva consulta" color="c1" extra="Registrarla en segundos" destacado />
      <MenuTile to="/consultas" icono="search" texto="Consultas" color="c2" :extra="pend ? `${pend} para atender` : ''" /><MenuTile to="/trabajos" icono="tool" texto="Mis trabajos" color="c4" />
      <MenuTile to="/trabajos?hist=1" icono="clip" texto="Mi historial" color="c6" /><MenuTile to="/mis-comisiones" icono="dollar" texto="Mis comisiones" color="c4" /><MenuTile to="/notificaciones" icono="bell" texto="Notificaciones" color="c2" :extra="noLeidas(usuario) ? `${noLeidas(usuario)} sin leer` : ''" />
      <MenuTile to="/perfil" icono="user" texto="Mi perfil" color="c5" /><MenuTile to="/ayuda" icono="help" texto="Ayuda" color="c3" />
    </div>
    <h2>Mi trabajo de hoy</h2>
    <div class="kpis">
      <KpiCard to="/trabajos?estado=pendiente_aceptacion" :valor="n('pendiente_aceptacion')" texto="Pendientes de aceptación" :alerta="n('pendiente_aceptacion') > 0" />
      <KpiCard to="/trabajos?estado=aceptado" :valor="n('aceptado')" texto="Aceptados" /><KpiCard to="/trabajos?estado=en_proceso" :valor="n('en_proceso')" texto="En proceso" />
      <KpiCard to="/trabajos?estado=finalizado" :valor="misOrds.filter((o) => o.estado === 'finalizado' && cerradaReciente(o)).length" texto="Finalizados (últimos 7 días)" />
      <KpiCard to="/consultas?estado=pendiente" :valor="pend" texto="Consultas que requieren atención" :alerta="pend > 0" />
    </div>
    <h2>Trabajos activos</h2>
    <template v-if="activos.length"><router-link v-for="o in activos" :key="o.id" :to="'/trabajos/' + o.id" class="tile" style="width:100%;flex-direction:row;justify-content:space-between;min-height:0;margin-bottom:.6rem;text-align:left"><span><b>{{ o.numero }}</b> · {{ veh(o.vehiculo_id).marca }} {{ veh(o.vehiculo_id).modelo }} ({{ veh(o.vehiculo_id).patente }})<br><small>{{ o.descripcion }}</small></span><StatusTag tipo="orden" :valor="o.estado" /></router-link></template>
    <EmptyState v-else icono="tool" titulo="No tenés trabajos activos" mensaje="Cuando el dueño te asigne un trabajo, te llega una notificación y aparece acá."><router-link class="btn" to="/consultas">Ver consultas para atender</router-link></EmptyState>
  </template>
</template>
