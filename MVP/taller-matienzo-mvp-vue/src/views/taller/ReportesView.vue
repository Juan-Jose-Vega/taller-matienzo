<script setup>
import { computed, ref } from 'vue';
import PageHeader from '../../components/PageHeader.vue'; import KpiCard from '../../components/KpiCard.vue';
import { mine, nombreMecanico, mecanicosDelTaller, ordenTotal } from '../../services/workshopService.js'; import { get, db } from '../../services/storageService.js';
import { money } from '../../utils/formatters.js'; import { mesDe, mesTxt, hoy } from '../../utils/dates.js'; import { estTxt } from '../../utils/estados.js';
const mes = ref(mesDe(hoy()));
const meses = computed(() => [...new Set([hoy(), ...mine('pagos_cliente').map((p) => p.fecha)].map(mesDe))].sort().reverse());
const pagos = computed(() => mine('pagos_cliente').filter((p) => mesDe(p.fecha) === mes.value));
const porMedio = computed(() => { const r = {}; pagos.value.forEach((p) => db.pago_cliente_medios.filter((m) => m.pago_id === p.id).forEach((m) => { const n = get('medios_pago', m.medio_id).nombre; r[n] = (r[n] || 0) + m.importe; })); return Object.entries(r); });
const total = computed(() => pagos.value.reduce((s, p) => s + p.importe, 0));
const porEstado = computed(() => { const r = {}; mine('ordenes_trabajo').forEach((o) => { r[o.estado] = (r[o.estado] || 0) + 1; }); return Object.entries(r); });
const porMec = computed(() => mecanicosDelTaller().map((m) => [nombreMecanico(m.id), mine('ordenes_trabajo').filter((o) => o.mecanico_id === m.id && o.estado === 'finalizado').length]));
const consultas = computed(() => mine('consultas').filter((c) => mesDe(c.fecha) === mes.value).length);
const facturado = computed(() => mine('ordenes_trabajo').filter((o) => o.estado !== 'cancelado').reduce((s, o) => s + ordenTotal(o), 0));
const max = (a) => Math.max(1, ...a.map((x) => x[1]));
</script>
<template>
  <PageHeader titulo="Reportes" subtitulo="Indicadores del taller" />
  <div class="filtros"><div class="campo" style="margin:0"><label>Mes</label><select v-model="mes"><option v-for="m in meses" :key="m" :value="m">{{ mesTxt(m) }}</option></select></div></div>
  <div class="kpis"><KpiCard :valor="money(total)" texto="Cobrado en el mes" /><KpiCard :valor="consultas" texto="Consultas del mes" /><KpiCard :valor="money(facturado)" texto="Total presupuestado en órdenes" /></div>
  <div class="grid g2"><div class="card"><h2>Cobros por medio</h2><div v-for="m in porMedio" :key="m[0]" class="linea"><span style="width:130px">{{ m[0] }}</span><div style="flex:1;background:var(--gris-bg);border-radius:6px"><div :style="{ width: (m[1] / max(porMedio) * 100) + '%', background: 'var(--rojo)', height: '14px', borderRadius: '6px' }"></div></div><b>{{ money(m[1]) }}</b></div><p v-if="!porMedio.length" class="hint">Sin cobros en el mes.</p></div>
    <div class="card"><h2>Trabajos por estado</h2><div v-for="m in porEstado" :key="m[0]" class="linea"><span style="width:170px">{{ estTxt('orden', m[0]) }}</span><div style="flex:1;background:var(--gris-bg);border-radius:6px"><div :style="{ width: (m[1] / max(porEstado) * 100) + '%', background: 'var(--rojo)', height: '14px', borderRadius: '6px' }"></div></div><b>{{ m[1] }}</b></div></div></div>
  <div class="card"><h2>Trabajos finalizados por mecánico</h2><div v-for="m in porMec" :key="m[0]" class="linea"><span style="width:170px">{{ m[0] }}</span><b>{{ m[1] }}</b></div></div>
</template>
