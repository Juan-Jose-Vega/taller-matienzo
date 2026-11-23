<script setup>
// Barra de paginación reutilizable. Se usa con el objeto que devuelve usePaginacion().
import { TAMANOS } from '../composables/usePaginacion.js';
defineProps({ pag: { type: Object, required: true } });
</script>
<template>
  <nav v-if="pag.total > 0" class="paginacion" aria-label="Paginación">
    <label class="pag-tam">Mostrar
      <select :value="pag.tamano" aria-label="Registros por página" @change="pag.cambiarTamano($event.target.value)"><option v-for="n in TAMANOS" :key="n" :value="n">{{ n }}</option></select> por página</label>
    <span class="pag-info" role="status">{{ pag.desde }}–{{ pag.hasta }} de {{ pag.total }} {{ pag.total === 1 ? 'registro encontrado' : 'registros encontrados' }}</span>
    <span class="pag-nav">
      <button type="button" class="btn sec chico" :disabled="pag.pagina <= 1" aria-label="Página anterior" @click="pag.anterior()">‹ Anterior</button>
      <span class="pag-pagina">Página <b>{{ pag.pagina }}</b> de <b>{{ pag.totalPaginas }}</b></span>
      <button type="button" class="btn sec chico" :disabled="pag.pagina >= pag.totalPaginas" aria-label="Página siguiente" @click="pag.siguiente()">Siguiente ›</button>
    </span>
  </nav>
</template>
