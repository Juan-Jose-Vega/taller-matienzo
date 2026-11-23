<script setup>
defineProps({ to: [String, Object], valor: [String, Number], texto: String, alerta: Boolean });
</script>
<template>
  <router-link v-if="to" :to="to" class="kpi" :class="{ alerta }"><b>{{ valor }}</b><span>{{ texto }}</span></router-link>
  <div v-else class="kpi" :class="{ alerta }" style="cursor:default"><b>{{ valor }}</b><span>{{ texto }}</span></div>
</template>
