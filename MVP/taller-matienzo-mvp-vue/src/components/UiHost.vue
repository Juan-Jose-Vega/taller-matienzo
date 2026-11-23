<script setup>
import AppModal from './AppModal.vue'; import AppIcon from './AppIcon.vue';
import { ui, responderConfirmacion } from '../services/uiService.js';
import { waLink } from '../utils/formatters.js';
import { toast } from '../services/uiService.js';
function abrirWa() { const l = waLink(ui.wa.tel, ui.wa.texto); if (!l) { toast('Este cliente no tiene un teléfono válido para WhatsApp. Editá sus datos.', 'aviso'); return; } window.open(l, '_blank', 'noopener'); ui.wa = null; }
</script>
<template>
  <div class="tostadas" aria-live="polite"><div v-for="t in ui.toasts" :key="t.id" class="tostada" :class="t.tipo" role="status">{{ t.texto }}</div></div>
  <AppModal v-if="ui.confirmacion" :titulo="ui.confirmacion.titulo" @cerrar="responderConfirmacion(false)">
    <p>{{ ui.confirmacion.mensaje }}</p>
    <template #pie><button class="btn sec" type="button" @click="responderConfirmacion(false)">Cancelar</button><button class="btn" :class="ui.confirmacion.cls" type="button" @click="responderConfirmacion(true)">{{ ui.confirmacion.ok }}</button></template>
  </AppModal>
  <AppModal v-if="ui.clave" :titulo="ui.clave.titulo" @cerrar="ui.clave = null">
    <p>Anotá esta <b>clave temporal</b> y entregásela a la persona. <b>Se muestra una sola vez</b> y tendrá que cambiarla al ingresar.</p>
    <div class="card" style="text-align:center"><div>Usuario: <b>{{ ui.clave.usuario }}</b></div><div id="clave-temporal" style="font-size:1.5rem;font-weight:800;letter-spacing:.05em;margin-top:.3rem">{{ ui.clave.clave }}</div></div>
    <p class="hint">Las contraseñas no se pueden “ver” ni recuperar: solo se restablecen con una clave temporal nueva.</p>
    <template #pie><button class="btn ok" type="button" @click="ui.clave = null">Ya la anoté</button></template>
  </AppModal>
  <AppModal v-if="ui.wa" :titulo="ui.wa.titulo" @cerrar="ui.wa = null">
    <p class="hint">El mensaje <b>no se envía automáticamente</b>: revisalo y, si te parece bien, se abre WhatsApp para que lo envíes vos.</p>
    <textarea v-model="ui.wa.texto" rows="9"></textarea>
    <template #pie><button class="btn sec" type="button" @click="ui.wa = null">Cancelar</button><button class="btn wa" type="button" @click="abrirWa"><AppIcon name="wa" /> Abrir WhatsApp</button></template>
  </AppModal>
</template>
