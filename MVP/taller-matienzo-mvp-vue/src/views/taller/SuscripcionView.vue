<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, reactive, ref } from 'vue';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import FormField from '../../components/FormField.vue';
import { db, get } from '../../services/storageService.js'; import { usuario, tallerId } from '../../services/authService.js';
import { estadoTaller, suscripcionDe, informarPago, pendienteDe, mediosDePago, textoModalidad } from '../../services/subscriptionService.js'; import { textoDias } from '../../services/subscriptionRules.js';
import { toast } from '../../services/uiService.js'; import { money } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js';
const e = computed(() => estadoTaller(tallerId.value)); const s = computed(() => suscripcionDe(tallerId.value));
const pend = computed(() => pendienteDe(tallerId.value));
const pagos = computed(() => db.pagos_suscripcion.filter((p) => p.taller_id === tallerId.value).sort((a, b) => b.id - a.id));
const periodos = computed(() => db.periodos_suscripcion.filter((p) => p.suscripcion_id === s.value.id).sort((a, b) => b.id - a.id));
const pag = usePaginacion(() => pagos.value);
const pagP = usePaginacion(() => periodos.value, { porPagina: 5 });
const f = reactive({ medio: 'transferencia', referencia: '', efectivo: '', transferencia: '' }); const error = ref('');
function informar() { error.value = ''; const r = informarPago(usuario.value, f); if (!r.ok) { error.value = r.error; return; } toast('Pago informado: queda pendiente de confirmación.'); f.referencia = ''; }
const mt = (p) => mediosDePago(p.id).map((m) => `${get('medios_pago', m.medio_id).nombre} ${money(m.importe)}`).join(' + ');
</script>
<template>
  <PageHeader titulo="Mi suscripción" subtitulo="Estado del plan y pagos al sistema" />
  <div v-if="e" class="hint" :class="e.nivel === 'err' ? 'err' : e.nivel === 'warn' ? 'warn' : 'ok'" role="status"><StatusTag tipo="sub" :valor="e.estado" /> {{ e.msg }}</div>
  <div v-if="e" class="card"><div class="dl"><div><span>Plan</span><b>Plan de suscripción · {{ textoModalidad(s.modalidad) }}</b></div><div><span>Importe</span><b>{{ money(s.importe) }} / {{ s.modalidad === 'anual' ? 'año' : 'mes' }}</b></div><div><span>Inicio</span><b>{{ fecha(s.fecha_inicio) }}</b></div><div><span>Vencimiento</span><b>{{ fecha(s.fecha_vencimiento) }}</b></div><div><span>Situación</span><b>{{ textoDias(e) }}</b></div></div></div>
  <div class="card"><h2>Informar un pago</h2>
    <div v-if="pend" class="hint warn">Hay un pago de {{ money(pend.importe) }} pendiente de confirmación por el administrador del sistema.</div>
    <form v-else novalidate @submit.prevent="informar"><p>Importe del plan: <b>{{ money(s.importe) }}</b></p><FormField v-model="f.medio" label="Medio" type="select" :opciones="[['efectivo', 'Efectivo'], ['transferencia', 'Transferencia'], ['combinado', 'Combinado (efectivo + transferencia)']]" /><div v-if="f.medio === 'combinado'" class="form-grid"><FormField v-model="f.efectivo" label="Efectivo" type="number" /><FormField v-model="f.transferencia" label="Transferencia" type="number" /></div><FormField v-if="f.medio !== 'efectivo'" v-model="f.referencia" label="Referencia de la transferencia" /><div class="msg-err" role="alert">{{ error }}</div><button class="btn">Informar pago</button></form></div>
  <h2>Mis pagos</h2><div v-if="pagos.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Fecha</th><th>Importe</th><th>Medio</th><th>Estado</th><th>Nuevo vencimiento</th></tr></thead><tbody><tr v-for="p in pag.items" :key="p.id"><td data-l="Fecha">{{ fecha(p.fecha) }}</td><td data-l="Importe">{{ money(p.importe) }}</td><td data-l="Medio">{{ mt(p) }}</td><td data-l="Estado"><StatusTag tipo="pagoSis" :valor="p.estado" /><small v-if="p.motivo_rechazo"><br>{{ p.motivo_rechazo }}</small></td><td data-l="Nuevo vencimiento">{{ p.nuevo_vencimiento ? fecha(p.nuevo_vencimiento) : '—' }}</td></tr></tbody></table></div><PaginationBar v-if="pagos.length" :pag="pag" /><p v-else class="hint">Sin pagos todavía.</p>
  <h2>Períodos</h2><div class="card tight"><div v-for="p in pagP.items" :key="p.id" class="linea"><span class="f">{{ fecha(p.desde) }}</span><span>hasta {{ fecha(p.hasta) }}</span></div></div><PaginationBar :pag="pagP" />
</template>
