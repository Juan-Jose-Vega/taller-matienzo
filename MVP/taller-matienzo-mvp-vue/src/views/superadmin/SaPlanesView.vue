<script setup>
import { reactive, ref } from 'vue';
import PageHeader from '../../components/PageHeader.vue'; import FormField from '../../components/FormField.vue';
import { usuario } from '../../services/authService.js';
import { guardarPrecios, importeDe } from '../../services/subscriptionService.js';
import { toast } from '../../services/uiService.js'; import { money } from '../../utils/formatters.js';
const f = reactive({ mensual: importeDe('mensual'), anual: importeDe('anual') }); const error = ref('');
function guardar() { const r = guardarPrecios(usuario.value, f); error.value = r.ok ? '' : r.error; if (r.ok) toast('Importes actualizados.'); }
</script>
<template>
  <PageHeader titulo="Plan de suscripción" subtitulo="Un único plan, con modalidad mensual o anual" />
  <div class="card"><h2>Modalidades disponibles</h2>
    <div class="dl"><div><span>Mensual</span><b>{{ money(importeDe('mensual')) }} / mes</b></div><div><span>Anual</span><b>{{ money(importeDe('anual')) }} / año</b></div><div><span>Tolerancia</span><b>3 días corridos después del vencimiento</b></div></div>
  </div>
  <div class="card"><h2>Actualizar importes</h2>
    <form novalidate @submit.prevent="guardar"><div class="form-grid"><FormField v-model="f.mensual" label="Importe mensual" type="number" req /><FormField v-model="f.anual" label="Importe anual" type="number" req /></div><div class="msg-err" role="alert">{{ error }}</div><button class="btn">Guardar importes</button></form>
  </div>
  <p class="hint">No existen otros planes ni duraciones personalizadas. Cambiar un importe no modifica el importe de la suscripción ya vigente: se aplica cuando se guarda la suscripción de la cuenta o se crea una nueva.</p>
</template>
