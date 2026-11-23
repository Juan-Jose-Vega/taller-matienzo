<script setup>
import { useRoute, useRouter } from 'vue-router';
import AppIcon from './AppIcon.vue';
const p = defineProps({ titulo: String, subtitulo: String, volver: { type: String, default: undefined } });
const route = useRoute(); const router = useRouter();
const destino = () => p.volver ?? route.meta.padre ?? null;
</script>
<template>
  <div class="cab">
    <button v-if="destino()" type="button" class="btn-volver" @click="router.push(destino())"><AppIcon name="back" /> Volver</button>
    <div class="tit"><h1 v-if="titulo">{{ titulo }}</h1><p v-if="subtitulo">{{ subtitulo }}</p></div>
    <div class="fila-btn" style="margin:0"><slot /></div>
  </div>
</template>
