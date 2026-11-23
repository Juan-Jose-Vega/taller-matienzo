<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import EmptyState from '../../components/EmptyState.vue';
import { mine, presupuestoDe, presEstado } from '../../services/workshopService.js';
import { norm } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js';
const route = useRoute(); const router = useRouter();
const q = ref(''); const estado = computed(() => route.query.estado || '');
const lista = computed(() => mine('consultas').filter((c) => (!estado.value || c.estado === estado.value) && (!q.value || norm(`${c.nombre_contacto} ${c.patente} ${c.marca} ${c.modelo}`).includes(norm(q.value)))).sort((a, b) => b.id - a.id));
const setEstado = (v) => router.replace({ query: v ? { estado: v } : {} });
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [q.value, estado.value] });
</script>
<template>
  <PageHeader titulo="Consultas" subtitulo="Primera consulta gratuita; las siguientes se evalúan"><router-link class="btn" to="/consultas/nueva">Nueva consulta</router-link></PageHeader>
  <div class="filtros">
    <div class="campo" style="margin:0"><label>Buscar</label><input v-model="q" placeholder="Cliente, patente, marca…" /></div>
    <div class="campo" style="margin:0"><label>Estado</label><select :value="estado" @change="setEstado($event.target.value)"><option value="">Todos</option><option value="pendiente">Pendiente</option><option value="en_presupuesto">Con presupuesto</option><option value="aprobada">Aprobada</option><option value="cerrada">Finalizada sin trabajo</option></select></div>
  </div>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Fecha</th><th>Cliente</th><th>Vehículo</th><th>Problema</th><th>Estado</th><th>Presupuesto</th></tr></thead><tbody>
    <tr v-for="c in pag.items" :key="c.id" class="click" @click="router.push('/consultas/' + c.id)">
      <td data-l="Fecha">{{ fecha(c.fecha) }}</td><td data-l="Cliente"><b>{{ c.nombre_contacto }}</b><br><small>{{ c.es_gratuita ? 'Primera consulta (gratis)' : 'Consulta repetida' }}</small></td>
      <td data-l="Vehículo">{{ c.marca }} {{ c.modelo }}<br><small>{{ c.patente || 'sin patente' }}</small></td><td data-l="Problema">{{ c.problema.slice(0, 70) }}{{ c.problema.length > 70 ? '…' : '' }}</td>
      <td data-l="Estado"><StatusTag tipo="consulta" :valor="c.estado" /></td><td data-l="Presupuesto"><StatusTag v-if="presupuestoDe(c.id)" tipo="presupuesto" :valor="presEstado(presupuestoDe(c.id))" /><span v-else>—</span></td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="search" titulo="No hay consultas para mostrar" mensaje="Probá con otro filtro o registrá una consulta nueva."><router-link class="btn" to="/consultas/nueva">Nueva consulta</router-link></EmptyState>
</template>
