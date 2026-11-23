<script setup>
import AppIcon from './AppIcon.vue';
defineProps({ icono: { type: String, default: 'search' }, titulo: String, mensaje: String });
</script>
<template><div class="vacio"><AppIcon :name="icono" /><h3>{{ titulo }}</h3><p>{{ mensaje }}</p><slot /></div></template>
