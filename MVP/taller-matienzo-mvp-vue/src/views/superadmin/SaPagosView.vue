<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue';
import { db, get } from '../../services/storageService.js'; import { usuario } from '../../services/authService.js'; import { confirmarPago, rechazarPago, mediosDePago } from '../../services/subscriptionService.js'; import { confirmar, toast } from '../../services/uiService.js'; import { money } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js';
const route = useRoute(); const router = useRouter(); const f = computed(() => route.query.f || '');
const lista = computed(() => db.pagos_suscripcion.filter((p) => !f.value || p.estado === f.value).slice().sort((a, b) => b.id - a.id));
const mt = (p) => mediosDePago(p.id).map((m) => `${get('medios_pago', m.medio_id).nombre} ${money(m.importe)}`).join(' + ');
const rech = ref(null); const motivo = ref(''); const err = ref('');
async function conf(p) { if (!(await confirmar({ mensaje: `¿Confirmar el pago de ${money(p.importe)} de ${get('talleres', p.taller_id).nombre}? Renueva la suscripción una sola vez.`, ok: 'Confirmar pago' }))) return; const r = confirmarPago(usuario.value, p.id); toast(r.ok ? 'Pago confirmado y suscripción renovada.' : r.error, r.ok ? '' : 'error'); }
function rechazar() { const r = rechazarPago(usuario.value, rech.value.id, motivo.value); if (!r.ok) { err.value = r.error; return; } rech.value = null; motivo.value = ''; toast('Pago rechazado.'); }
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [f.value] });
</script>
<template>
  <PageHeader titulo="Pagos del sistema" subtitulo="Confirmación de pagos de suscripción" />
  <div class="filtros"><div class="campo" style="margin:0"><label>Estado</label><select :value="f" @change="router.replace({ query: $event.target.value ? { f: $event.target.value } : {} })"><option value="">Todos</option><option value="pendiente">Pendiente de confirmación</option><option value="registrado">Registrado</option><option value="confirmado">Confirmado</option><option value="rechazado">Rechazado</option></select></div></div>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Fecha</th><th>Cuenta</th><th>Importe</th><th>Medio</th><th>Referencia</th><th>Estado</th><th></th></tr></thead><tbody>
    <tr v-for="p in pag.items" :key="p.id"><td data-l="Fecha">{{ fecha(p.fecha) }}</td><td data-l="Cuenta"><router-link :to="'/superadmin/cuentas/' + p.taller_id">{{ get('talleres', p.taller_id).nombre }}</router-link></td><td data-l="Importe">{{ money(p.importe) }}</td><td data-l="Medio">{{ mt(p) }}</td><td data-l="Referencia">{{ p.referencia || '—' }}</td><td data-l="Estado"><StatusTag tipo="pagoSis" :valor="p.estado" /><small v-if="p.motivo_rechazo"><br>{{ p.motivo_rechazo }}</small></td>
      <td><template v-if="['pendiente', 'registrado'].includes(p.estado)"><button class="btn ok chico" type="button" @click="conf(p)">Confirmar</button> <button class="btn pel chico" type="button" @click="rech = p; err = ''">Rechazar</button></template></td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="dollar" titulo="No hay pagos" mensaje="Los pagos informados por los dueños aparecen acá." />
  <AppModal v-if="rech" titulo="Rechazar pago" @cerrar="rech = null"><FormField v-model="motivo" label="Motivo" type="textarea" req /><div class="msg-err" role="alert">{{ err }}</div><template #pie><button class="btn sec" type="button" @click="rech = null">Volver</button><button class="btn pel" type="button" @click="rechazar">Rechazar</button></template></AppModal>
</template>
