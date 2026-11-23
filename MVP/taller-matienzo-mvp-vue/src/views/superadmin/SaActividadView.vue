<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, ref } from 'vue';
import PageHeader from '../../components/PageHeader.vue'; import EmptyState from '../../components/EmptyState.vue';
import { db } from '../../services/storageService.js'; import { nombreUsuario } from '../../services/workshopService.js'; import { fecha } from '../../utils/dates.js'; import { norm } from '../../utils/formatters.js';
const q = ref(''); const lista = computed(() => db.auditoria.filter((a) => a.ambito === 'sistema' && (!q.value || norm(`${a.accion} ${a.detalle}`).includes(norm(q.value)))).slice().reverse());
const ultimos = computed(() => db.intentos_acceso.slice().reverse());
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [q.value] });
const pagI = usePaginacion(() => ultimos.value, { reiniciarCon: () => [0] });
</script>
<template>
  <PageHeader titulo="Actividad del sistema" subtitulo="Acciones administrativas (no incluye datos privados de los talleres)" />
  <div class="filtros"><div class="campo" style="margin:0"><label>Buscar</label><input v-model="q" placeholder="Acción o detalle" /></div></div>
  <div v-if="lista.length" class="card tight"><div v-for="a in pag.items" :key="a.id" class="linea"><span class="f">{{ fecha(a.created_at) }}</span><span style="flex:1"><b>{{ a.accion }}</b><br><small>{{ a.detalle }}</small></span><small>{{ a.usuario_id ? nombreUsuario(a.usuario_id) : '' }}</small></div></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="activity" titulo="Sin actividad" mensaje="Todavía no hay acciones administrativas." />
  <h2>Últimos intentos de acceso</h2><div class="card tight"><div v-for="i in pagI.items" :key="i.id" class="linea"><span class="f">{{ fecha(i.created_at) }}</span><span style="flex:1">{{ i.usuario_ingresado }} · {{ i.ambito }}</span><span class="tag" :class="i.exito ? 't-ok' : 't-err'">{{ i.exito ? 'Correcto' : 'Fallido' }}</span></div><p v-if="!ultimos.length" class="hint">Sin intentos registrados.</p></div><PaginationBar v-if="ultimos.length" :pag="pagI" />
</template>
