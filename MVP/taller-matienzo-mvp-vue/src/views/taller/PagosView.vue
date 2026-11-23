<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue'; import KpiCard from '../../components/KpiCard.vue';
import { mine, registrarPagoCliente, textoMedios, ordenSaldo, ordenTotal, getMine } from '../../services/workshopService.js'; import { get } from '../../services/storageService.js'; import { toast } from '../../services/uiService.js';
import { money } from '../../utils/formatters.js'; import { fecha, hoy } from '../../utils/dates.js'; import { MEDIOS } from '../../utils/estados.js';
const route = useRoute(); const ordenId = computed(() => Number(route.query.orden) || null);
const lista = computed(() => mine('pagos_cliente').filter((p) => !ordenId.value || p.orden_id === ordenId.value).sort((a, b) => b.id - a.id));
const pendientes = computed(() => mine('ordenes_trabajo').filter((o) => o.estado !== 'cancelado' && ordenSaldo(o) > 0.001));
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [ordenId.value] });
const pagS = usePaginacion(() => pendientes.value, { porPagina: 5, reiniciarCon: () => [0] });
const f = reactive({ cliente_id: '', orden_id: '', importe: '', medio: 'efectivo', d_efectivo: '', d_transferencia: '', d_mercadopago: '', fecha: hoy(), obs: '' }); const abierto = ref(false); const error = ref('');
function abrir(o) { Object.assign(f, { cliente_id: o ? o.cliente_id : '', orden_id: o ? o.id : (ordenId.value || ''), importe: o ? ordenSaldo(o) : '', medio: 'efectivo', d_efectivo: '', d_transferencia: '', d_mercadopago: '', fecha: hoy(), obs: '' }); if (!o && ordenId.value) { const x = getMine('ordenes_trabajo', ordenId.value); if (x) { f.cliente_id = x.cliente_id; f.importe = ordenSaldo(x); } } error.value = ''; abierto.value = true; }
function guardar() { const r = registrarPagoCliente(f); if (!r.ok) { error.value = r.error; return; } abierto.value = false; toast('Pago registrado.'); }
const ordsCli = computed(() => mine('ordenes_trabajo').filter((o) => o.cliente_id === Number(f.cliente_id) && o.estado !== 'cancelado'));
</script>
<template>
  <PageHeader titulo="Pagos de clientes" subtitulo="Efectivo, transferencia, Mercado Pago o combinado"><button class="btn" type="button" @click="abrir(null)">Registrar pago</button></PageHeader>
  <div class="kpis"><KpiCard :valor="pendientes.length" texto="Trabajos con saldo pendiente" :alerta="pendientes.length > 0" /><KpiCard :valor="money(pendientes.reduce((s, o) => s + ordenSaldo(o), 0))" texto="Saldo total a cobrar" /></div>
  <h2>Saldos pendientes</h2><div v-if="pendientes.length" class="card tight"><div v-for="o in pagS.items" :key="o.id" class="linea"><span class="f">{{ o.numero }}</span><span style="flex:1">{{ get('clientes', o.cliente_id).nombre }} · total {{ money(ordenTotal(o)) }} · saldo <b>{{ money(ordenSaldo(o)) }}</b></span><button class="btn sec chico" type="button" @click="abrir(o)">Cobrar</button></div><PaginationBar :pag="pagS" /></div><p v-else class="hint">No hay saldos pendientes.</p>
  <h2>Pagos registrados <small v-if="ordenId">(filtrados por orden)</small></h2>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Fecha</th><th>Cliente</th><th>Orden</th><th>Importe</th><th>Medio</th></tr></thead><tbody><tr v-for="p in pag.items" :key="p.id"><td data-l="Fecha">{{ fecha(p.fecha) }}</td><td data-l="Cliente">{{ get('clientes', p.cliente_id).nombre }}</td><td data-l="Orden">{{ p.orden_id ? get('ordenes_trabajo', p.orden_id).numero : '—' }}</td><td data-l="Importe"><b>{{ money(p.importe) }}</b></td><td data-l="Medio">{{ textoMedios(p.id) }}</td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="dollar" titulo="Sin pagos registrados" mensaje="Cuando cobres un trabajo, registralo acá." />
  <AppModal v-if="abierto" titulo="Registrar pago" @cerrar="abierto = false"><form id="fp" novalidate @submit.prevent="guardar"><FormField v-model="f.cliente_id" label="Cliente" type="select" req :opciones="[['', 'Elegir…'], ...mine('clientes').map((c) => [c.id, c.nombre])]" /><FormField v-model="f.orden_id" label="Orden (opcional)" type="select" :opciones="[['', 'Sin orden'], ...ordsCli.map((o) => [o.id, `${o.numero} · saldo ${money(ordenSaldo(o))}`])]" /><FormField v-model="f.importe" label="Importe" type="number" req /><FormField v-model="f.medio" label="Medio" type="select" :opciones="Object.entries(MEDIOS)" />
    <div v-if="f.medio === 'combinado'" class="form-grid"><FormField v-model="f.d_efectivo" label="Efectivo" type="number" /><FormField v-model="f.d_transferencia" label="Transferencia" type="number" /><FormField v-model="f.d_mercadopago" label="Mercado Pago" type="number" /></div><FormField v-model="f.fecha" label="Fecha" type="date" /><FormField v-model="f.obs" label="Observaciones" /><div class="msg-err" role="alert">{{ error }}</div></form><template #pie><button class="btn sec" type="button" @click="abierto = false">Cancelar</button><button class="btn" type="submit" form="fp">Registrar</button></template></AppModal>
</template>
