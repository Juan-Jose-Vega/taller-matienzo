<script setup>
import { onMounted, onBeforeUnmount } from 'vue';
import AppIcon from './AppIcon.vue';
const p = defineProps({ titulo: String, ancho: { type: Number, default: 680 } });
const emit = defineEmits(['cerrar']);
const esc = (e) => { if (e.key === 'Escape') emit('cerrar'); };
onMounted(() => document.addEventListener('keydown', esc)); onBeforeUnmount(() => document.removeEventListener('keydown', esc));
</script>
<template>
  <div class="fondo" @mousedown.self="emit('cerrar')">
    <div class="modal" role="dialog" aria-modal="true" :style="{ width: `min(${p.ancho}px,100%)` }">
      <header><h2>{{ titulo }}</h2><button class="cerrar" type="button" aria-label="Cerrar" @click="emit('cerrar')"><AppIcon name="x" /></button></header>
      <div class="cuerpo"><slot /></div>
      <footer v-if="$slots.pie"><slot name="pie" /></footer>
    </div>
  </div>
</template>
