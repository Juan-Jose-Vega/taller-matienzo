<script setup>
import { estTxt, estCls } from '../utils/estados.js';
defineProps({ tipo: String, valor: String });
</script>
<template><span class="tag" :class="estCls(tipo, valor)">{{ estTxt(tipo, valor) }}</span></template>
