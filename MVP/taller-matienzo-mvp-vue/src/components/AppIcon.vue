<script setup>
import { computed } from 'vue';
import { ICONOS } from '../assets/icons.js';
const p = defineProps({ name: { type: String, required: true } });
const html = computed(() => ICONOS[p.name] || '');
</script>
<template><svg class="ic" viewBox="0 0 24 24" aria-hidden="true" v-html="html"></svg></template>
