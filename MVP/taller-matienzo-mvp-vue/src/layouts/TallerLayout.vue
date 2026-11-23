<script setup>
import { computed } from 'vue';
import TopBar from '../components/TopBar.vue'; import AppIcon from '../components/AppIcon.vue';
import { rol, tallerId } from '../services/authService.js';
import { estadoTaller } from '../services/subscriptionService.js';
const e = computed(() => estadoTaller(tallerId.value));
const mostrar = computed(() => e.value && e.value.estado !== 'vigente');
</script>
<template>
  <TopBar variante="taller" />
  <template v-if="mostrar">
    <div v-if="rol === 'admin'" class="banner" :class="e.nivel"><span><AppIcon name="bell" /> {{ e.msg }}</span><router-link to="/suscripcion">Ver suscripción y pagar</router-link></div>
    <div v-else-if="e.bloqueado" class="banner err"><AppIcon name="lock" /> El taller tiene el acceso restringido. Avisale al dueño.</div>
  </template>
  <main class="wrap"><router-view /></main>
</template>
