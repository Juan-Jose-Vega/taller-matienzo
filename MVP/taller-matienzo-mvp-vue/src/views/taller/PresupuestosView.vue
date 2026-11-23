<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import EmptyState from '../../components/EmptyState.vue';
import { mine, presEstado, presTotal, eliminarPresupuesto } from '../../services/workshopService.js'; import { money } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js';
const route = useRoute(); const router = useRouter(); import { confirmar, toast } from '../../services/uiService.js';
async function borrar(p) { if (!(await confirmar({ mensaje: `¿Eliminar el presupuesto ${p.numero}?`, ok: 'Eliminar', cls: 'pel' }))) return; const r = eliminarPresupuesto(p.id); toast(r.ok ? 'Presupuesto eliminado.' : r.error, r.ok ? '' : 'error'); }
const estado = computed(() => route.query.estado || '');
const lista = computed(() => mine('presupuestos').filter((p) => !estado.value || presEstado(p) === estado.value).sort((a, b) => b.id - a.id));
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [estado.value] });
</script>
<template>
  <PageHeader titulo="Presupuestos" subtitulo="Se arman desde cada consulta" />
  <div class="filtros"><div class="campo" style="margin:0"><label>Estado</label><select :value="estado" @change="router.replace({ query: $event.target.value ? { estado: $event.target.value } : {} })"><option value="">Todos</option><option value="borrador">Borrador</option><option value="pendiente">Pendiente</option><option value="aceptado">Aceptado</option><option value="rechazado">Rechazado</option><option value="vencido">Vencido</option></select></div></div>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>N.º</th><th>Fecha</th><th>Total</th><th>Válido hasta</th><th>Estado</th><th></th></tr></thead><tbody>
    <tr v-for="p in pag.items" :key="p.id" class="click" @click="router.push('/presupuestos/' + p.id)"><td data-l="N.º"><b>{{ p.numero }}</b></td><td data-l="Fecha">{{ fecha(p.fecha_creacion) }}</td><td data-l="Total">{{ money(presTotal(p)) }}</td><td data-l="Válido hasta">{{ fecha(p.valido_hasta) }}</td><td data-l="Estado"><StatusTag tipo="presupuesto" :valor="presEstado(p)" /></td><td><button class="btn pel chico" type="button" @click.stop="borrar(p)">Eliminar</button></td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="file" titulo="No hay presupuestos" mensaje="Abrí una consulta con revisión técnica para armar el primero."><router-link class="btn" to="/consultas">Ir a consultas</router-link></EmptyState>
</template>
