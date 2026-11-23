<script setup>
import PaginationBar from '../components/PaginationBar.vue'; import { usePaginacion } from '../composables/usePaginacion.js';
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../components/PageHeader.vue'; import EmptyState from '../components/EmptyState.vue'; import AppIcon from '../components/AppIcon.vue';
import { usuario } from '../services/authService.js';
import { delUsuario, marcarLeida, marcarTodas } from '../services/notificationService.js';
import { fecha } from '../utils/dates.js';
const route = useRoute(); const router = useRouter();
const f = computed(() => route.query.f || 'todas');
const lista = computed(() => delUsuario(usuario.value).filter((n) => f.value !== 'noleidas' || !n.leida));
const abrir = (n) => { marcarLeida(n.id); router.push(n.ruta || '/'); };
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [f.value] });
</script>
<template>
  <PageHeader titulo="Notificaciones" subtitulo="Tocá una notificación para ir directo a la pantalla relacionada" />
  <div class="filtros"><div class="campo" style="margin:0"><label>Mostrar</label><select :value="f" @change="router.replace({ query: { f: $event.target.value } })"><option value="todas">Todas</option><option value="noleidas">Solo no leídas</option></select></div><button class="btn sec" type="button" @click="marcarTodas(usuario)"><AppIcon name="check" /> Marcar todas como leídas</button></div>
  <div v-if="lista.length" class="card tight"><div v-for="n in pag.items" :key="n.id" class="linea"><span class="f">{{ fecha(n.created_at) }}</span><span style="flex:1"><span v-if="!n.leida" class="tag t-warn">Nueva</span> {{ n.texto }}</span><button class="btn sec chico" type="button" @click="abrir(n)">Abrir</button></div></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="bell" titulo="No hay notificaciones" :mensaje="f === 'noleidas' ? 'Estás al día: no tenés notificaciones sin leer.' : 'Cuando pase algo importante te avisamos acá.'" />
</template>
