<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import EmptyState from '../../components/EmptyState.vue';
import { mine, nombreMecanico } from '../../services/workshopService.js'; import { rol, mecanicoActual } from '../../services/authService.js'; import { get } from '../../services/storageService.js'; import { fecha } from '../../utils/dates.js';
const route = useRoute(); const router = useRouter();
const estado = computed(() => route.query.estado || ''); const hist = computed(() => !!route.query.hist);
const base = computed(() => mine('ordenes_trabajo').filter((o) => rol.value === 'admin' || (mecanicoActual.value && o.mecanico_id === mecanicoActual.value.id)));
const lista = computed(() => base.value.filter((o) => { const cerrado = ['finalizado', 'cancelado'].includes(o.estado); if (estado.value === 'en_curso') return ['aceptado', 'en_proceso'].includes(o.estado); if (estado.value) return o.estado === estado.value; return hist.value ? cerrado : (rol.value === 'admin' ? true : !cerrado); }).sort((a, b) => b.id - a.id));
const set = (v) => router.replace({ query: v ? { estado: v } : (hist.value ? { hist: 1 } : {}) });
const veh = (id) => get('vehiculos', id) || {}; const cli = (id) => get('clientes', id) || {};
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [estado.value, hist.value] });
</script>
<template>
  <PageHeader :titulo="hist ? 'Mi historial' : rol === 'admin' ? 'Trabajos' : 'Mis trabajos'" subtitulo="Órdenes de trabajo del taller" />
  <div class="filtros"><div class="campo" style="margin:0"><label>Estado</label><select :value="estado" @change="set($event.target.value)"><option value="">{{ hist ? 'Cerrados' : 'Todos' }}</option><option value="sin_asignar">Sin asignar</option><option value="pendiente_aceptacion">Pendiente de aceptación</option><option value="en_curso">En curso</option><option value="en_proceso">En proceso</option><option value="finalizado">Finalizado</option><option value="cancelado">Cancelado</option></select></div></div>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Orden</th><th>Cliente</th><th>Vehículo</th><th>Mecánico</th><th>Entrega</th><th>Estado</th></tr></thead><tbody>
    <tr v-for="o in pag.items" :key="o.id" class="click" @click="router.push('/trabajos/' + o.id)"><td data-l="Orden"><b>{{ o.numero }}</b></td><td data-l="Cliente">{{ cli(o.cliente_id).nombre }}</td><td data-l="Vehículo">{{ veh(o.vehiculo_id).marca }} {{ veh(o.vehiculo_id).modelo }}</td><td data-l="Mecánico">{{ o.mecanico_id ? nombreMecanico(o.mecanico_id) : '—' }}</td><td data-l="Entrega">{{ o.entrega_prevista ? fecha(o.entrega_prevista) : '—' }}</td><td data-l="Estado"><StatusTag tipo="orden" :valor="o.estado" /></td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="tool" titulo="No hay trabajos para mostrar" mensaje="Cambiá el filtro o esperá una nueva asignación." />
</template>
