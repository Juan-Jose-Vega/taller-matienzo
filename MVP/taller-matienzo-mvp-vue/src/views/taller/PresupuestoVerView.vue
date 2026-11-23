<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import EmptyState from '../../components/EmptyState.vue';
import { get } from '../../services/storageService.js'; import { getMine, detallesDe, presEstado, presTotal } from '../../services/workshopService.js'; 
import { money } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js';
const route = useRoute(); const p = computed(() => getMine('presupuestos', Number(route.params.id))); const c = computed(() => p.value && get('consultas', p.value.consulta_id));
</script>
<template>
  <template v-if="p">
    <PageHeader :titulo="p.numero" :subtitulo="`${c.nombre_contacto} · ${c.marca} ${c.modelo}`"><StatusTag tipo="presupuesto" :valor="presEstado(p)" /><router-link class="btn sec chico" :to="'/consultas/' + c.id">Ver consulta</router-link></PageHeader>
    <div class="card"><div class="dl"><div><span>Creado</span><b>{{ fecha(p.fecha_creacion) }}</b></div><div><span>Válido hasta</span><b>{{ fecha(p.valido_hasta) }}</b></div><div><span>Decisión</span><b>{{ p.fecha_decision ? fecha(p.fecha_decision) : '—' }}</b></div></div>
      <div class="tabla-wrap"><table class="resp"><thead><tr><th>Tipo</th><th>Descripción</th><th>Cant.</th><th>Precio</th><th>Subtotal</th></tr></thead><tbody><tr v-for="d in detallesDe(p.id)" :key="d.id"><td data-l="Tipo">{{ d.tipo.replace('_', ' ') }}</td><td data-l="Descripción">{{ d.descripcion }}</td><td data-l="Cant.">{{ d.cantidad }}</td><td data-l="Precio">{{ money(d.precio_unitario) }}</td><td data-l="Subtotal">{{ money(d.cantidad * d.precio_unitario) }}</td></tr></tbody></table></div><div class="total-box">Total: {{ money(presTotal(p)) }}</div></div>
  </template>
  <EmptyState v-else icono="file" titulo="Presupuesto no encontrado" mensaje="No existe o no pertenece a tu taller."><router-link class="btn" to="/presupuestos">Volver</router-link></EmptyState>
</template>
