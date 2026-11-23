<script setup>
import AppIcon from './AppIcon.vue';
defineProps({ to: [String, Object], icono: String, texto: String, color: { type: String, default: 'c1' }, extra: String, destacado: Boolean });
</script>
<template>
  <router-link :to="to" class="tile" :class="{ destacado }">
    <span class="ico" :class="color"><AppIcon :name="icono" /></span>{{ texto }}<small v-if="extra">{{ extra }}</small>
  </router-link>
</template>
