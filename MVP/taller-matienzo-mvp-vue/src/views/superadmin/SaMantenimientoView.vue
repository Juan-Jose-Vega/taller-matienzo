<script setup>
import { ref, computed } from 'vue';
import PageHeader from '../../components/PageHeader.vue';
import { db, reiniciarDemo, exportarJson, importarJson, tamanoKb } from '../../services/storageService.js'; import { usuario } from '../../services/authService.js';
import { simularVencimiento, simularUnDia, estadoTaller } from '../../services/subscriptionService.js'; import { confirmar, toast } from '../../services/uiService.js'; import { fecha } from '../../utils/dates.js';
const tid = ref(db.talleres[0].id); const e = computed(() => estadoTaller(Number(tid.value)));
const presets = [['Vigente (30 días)', 30], ['Vence en 3 días', 3], ['Vence hoy', 0], ['Vencido ayer', -1], ['En gracia (hace 2 días)', -2], ['Bloqueado (hace 6 días)', -6]];
const sim = (d) => { simularVencimiento(usuario.value, Number(tid.value), d); toast('Estado simulado.'); };
async function restaurar() { if (await confirmar({ mensaje: 'Se restauran los datos de demostración y se pierden los cambios hechos. ¿Continuar?', ok: 'Restaurar', cls: 'pel' })) { reiniciarDemo(); toast('Datos de demostración restaurados.'); } }
function exportar() { const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([exportarJson()], { type: 'application/json' })); a.download = 'taller-matienzo-respaldo.json'; a.click(); URL.revokeObjectURL(a.href); }
function importar(ev) { const file = ev.target.files[0]; if (!file) return; const rd = new FileReader(); rd.onload = () => { const r = importarJson(rd.result); toast(r.ok ? 'Respaldo importado.' : r.error, r.ok ? '' : 'error'); }; rd.readAsText(file); ev.target.value = ''; }
</script>
<template>
  <PageHeader titulo="Mantenimiento" subtitulo="Herramientas de demostración y respaldo" />
  <div class="card"><h2>Simular el paso del tiempo</h2><p class="hint warn">Solo para la demostración: cambia el vencimiento de una cuenta para ver los avisos, el período de gracia y el bloqueo.</p>
    <div class="filtros"><div class="campo" style="margin:0"><label>Cuenta</label><select v-model="tid"><option v-for="t in db.talleres" :key="t.id" :value="t.id">{{ t.nombre }}</option></select></div></div>
    <p>Vence el <b>{{ fecha(e.vencimiento) }}</b> · {{ e.label }}</p><div class="fila-btn"><button v-for="p in presets" :key="p[0]" class="btn sec chico" type="button" @click="sim(p[1])">{{ p[0] }}</button><button class="btn sec chico" type="button" @click="simularUnDia(Number(tid))">Pasar un día</button></div></div>
  <div class="card"><h2>Datos de demostración</h2><p>Tamaño guardado en este navegador: {{ tamanoKb() }} KB.</p><div class="fila-btn"><button class="btn pel" type="button" @click="restaurar">Restaurar datos de demostración</button><button class="btn sec" type="button" @click="exportar">Exportar respaldo (JSON)</button><label class="btn sec">Importar respaldo<input type="file" accept="application/json" hidden @change="importar" /></label></div></div>
</template>
