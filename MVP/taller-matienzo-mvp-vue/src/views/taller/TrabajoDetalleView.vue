<script setup>
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import FormField from '../../components/FormField.vue'; import AiTextField from '../../components/AiTextField.vue'; import AppModal from '../../components/AppModal.vue'; import EmptyState from '../../components/EmptyState.vue'; import AppIcon from '../../components/AppIcon.vue';
import * as W from '../../services/workshopService.js'; import { get } from '../../services/storageService.js';
import { vincularPropuestas } from '../../services/aiTextService.js';
import { rol, mecanicoActual, taller, can } from '../../services/authService.js';
import { toast, confirmar, abrirWhatsapp } from '../../services/uiService.js';
import { money, vehTxt } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js';
const route = useRoute(); const id = computed(() => Number(route.params.id));
const o = computed(() => { const x = W.getMine('ordenes_trabajo', id.value); if (!x) return null; return rol.value === 'admin' || (mecanicoActual.value && x.mecanico_id === mecanicoActual.value.id) ? x : null; });
const esAdmin = computed(() => rol.value === 'admin'); const esMio = computed(() => o.value && mecanicoActual.value && o.value.mecanico_id === mecanicoActual.value.id);
const cli = computed(() => get('clientes', o.value.cliente_id)); const veh = computed(() => get('vehiculos', o.value.vehiculo_id));
const hist = computed(() => W.historialDe(id.value)); const avs = computed(() => W.avancesDe(id.value).slice().reverse()); const usados = computed(() => W.repuestosUsadosDe(id.value));
const stock = computed(() => W.mine('repuestos').filter((s) => s.cantidad > 0));
const res = (r, ok) => { if (!r.ok) toast(r.error, 'error'); else if (ok) toast(ok); return r.ok; };
const rechazo = ref(''); const abrirR = ref(false); const errR = ref('');
function rechazar() { errR.value = ''; const r = W.rechazarTrabajo(id.value, rechazo.value); if (!r.ok) { errR.value = r.error; return; } abrirR.value = false; rechazo.value = ''; toast('Trabajo rechazado: el dueño lo reasignará.'); }
const av = reactive({ texto: '', original: '' }); const idsA = ref([]);
function avance() { const r = W.agregarAvance(id.value, av.texto, av.original); if (!res(r, 'Avance registrado.')) return; vincularPropuestas(idsA.value, 'orden_avances', r.avance.id); idsA.value = []; av.texto = ''; av.original = ''; }
const rep = reactive({ id: '', cant: 1 });
function usar() { if (res(W.usarRepuesto(id.value, Number(rep.id), rep.cant), 'Repuesto registrado y descontado del stock.')) { rep.id = ''; rep.cant = 1; } }
async function fin() { if (await confirmar({ mensaje: '¿Marcar el trabajo como finalizado?', ok: 'Finalizar' })) res(W.finalizarTrabajo(id.value), 'Trabajo finalizado.'); }
const nuevoMec = ref(''); const mecs = computed(() => W.mecanicosDelTaller().filter((m) => get('usuarios', m.usuario_id).estado === 'activo'));
function asignar() { if (!nuevoMec.value) return toast('Elegí un mecánico.', 'error'); if (res(W.asignarTrabajo(id.value, nuevoMec.value), 'Trabajo asignado.')) nuevoMec.value = ''; }
async function cancelar() { if (await confirmar({ mensaje: '¿Cancelar el trabajo? Los repuestos usados se devuelven al stock.', ok: 'Cancelar trabajo', cls: 'pel' })) res(W.cancelarOrden(id.value), 'Trabajo cancelado.'); }
function wa() { abrirWhatsapp(cli.value.telefono, `Hola ${cli.value.nombre}, tu ${vehTxt(veh.value)} ya está listo para retirar en ${taller.value.nombre}. Saldo pendiente: ${money(W.ordenSaldo(o.value))}.`, 'Aviso al cliente'); }
</script>
<template>
  <template v-if="o">
    <PageHeader :titulo="`${o.numero} · ${veh.marca} ${veh.modelo}`" :subtitulo="`Cliente: ${cli.nombre}`"><StatusTag tipo="orden" :valor="o.estado" /><button v-if="esAdmin && o.estado === 'finalizado'" class="btn wa chico" type="button" @click="wa"><AppIcon name="wa" /> Avisar al cliente</button></PageHeader>
    <div class="card"><p style="white-space:pre-wrap;margin-top:0">{{ o.descripcion }}</p><div class="dl"><div><span>Mecánico</span><b>{{ o.mecanico_id ? W.nombreMecanico(o.mecanico_id) : 'Sin asignar' }}</b></div><div><span>Inicio previsto</span><b>{{ o.inicio_previsto ? fecha(o.inicio_previsto) : '—' }}</b></div><div><span>Entrega prevista</span><b>{{ o.entrega_prevista ? fecha(o.entrega_prevista) : '—' }}</b></div><div v-if="esAdmin"><span>Total / pagado / saldo</span><b>{{ money(W.ordenTotal(o)) }} / {{ money(W.ordenPagado(o)) }} / {{ money(W.ordenSaldo(o)) }}</b></div></div>
      <p v-if="o.repuestos_previstos"><b>Repuestos previstos:</b> {{ o.repuestos_previstos }}</p><p v-if="o.observaciones"><b>Observaciones:</b> {{ o.observaciones }}</p>
      <div class="fila-btn"><template v-if="esMio && can('ordenes.ejecutar')"><button v-if="o.estado === 'pendiente_aceptacion'" class="btn ok" type="button" @click="res(W.aceptarTrabajo(id), 'Trabajo aceptado.')">Aceptar trabajo</button><button v-if="o.estado === 'pendiente_aceptacion'" class="btn pel" type="button" @click="abrirR = true">Rechazar</button><button v-if="o.estado === 'aceptado'" class="btn" type="button" @click="res(W.iniciarTrabajo(id), 'Trabajo iniciado.')">Iniciar trabajo</button><button v-if="o.estado === 'en_proceso'" class="btn ok" type="button" @click="fin">Finalizar trabajo</button></template>
        <router-link v-if="esAdmin" class="btn sec" :to="`/pagos?orden=${o.id}`">Cobrar / ver pagos</router-link><router-link v-if="esAdmin" class="btn sec" :to="'/consultas/' + o.consulta_id">Ver consulta</router-link></div></div>
    <div v-if="esAdmin && !['finalizado', 'cancelado'].includes(o.estado)" class="card"><h2>{{ o.mecanico_id ? 'Reasignar' : 'Asignar' }} mecánico</h2><div class="filtros"><FormField v-model="nuevoMec" label="Mecánico" type="select" :opciones="[['', 'Elegir…'], ...mecs.map((m) => [m.id, W.nombreMecanico(m.id) + (m.disponible ? '' : ' (no disponible)')])]" /><button class="btn" type="button" @click="asignar">Asignar</button><button class="btn pel" type="button" @click="cancelar">Cancelar trabajo</button></div></div>
    <div v-if="['aceptado', 'en_proceso', 'finalizado'].includes(o.estado)" class="card"><h2>Avances</h2>
      <form v-if="o.estado !== 'finalizado' && (esMio || esAdmin)" novalidate @submit.prevent="avance"><AiTextField v-model="av.texto" v-model:original="av.original" v-model:ids="idsA" label="Nuevo avance u observación" entidad="orden_avances" campo="texto" contexto="avance" /><button class="btn">Registrar avance</button></form>
      <div class="card tight"><div v-for="a in avs" :key="a.id" class="linea"><span class="f">{{ fecha(a.created_at) }}</span><span style="flex:1">{{ a.texto }}<details v-if="a.texto_original && a.texto_original !== a.texto"><summary>Texto original</summary>{{ a.texto_original }}</details></span><small>{{ W.nombreUsuario(a.usuario_id) }}</small></div><p v-if="!avs.length" class="hint">Todavía no hay avances.</p></div></div>
    <div v-if="['aceptado', 'en_proceso', 'finalizado'].includes(o.estado)" class="card"><h2>Repuestos usados</h2>
      <form v-if="o.estado === 'en_proceso' && (can('stock.consumir') || can('stock.gestionar'))" class="filtros" novalidate @submit.prevent="usar"><FormField v-model="rep.id" label="Repuesto" type="select" :opciones="[['', 'Elegir…'], ...stock.map((s) => [s.id, `${s.nombre} (hay ${s.cantidad})`])]" /><FormField v-model="rep.cant" label="Cantidad" type="number" min="1" /><button class="btn">Usar</button></form>
      <div class="card tight"><div v-for="r in usados" :key="r.id" class="linea"><span class="f">{{ fecha(r.created_at) }}</span><span style="flex:1">{{ get('repuestos', r.repuesto_id).nombre }} × {{ r.cantidad }} <span v-if="r.anulado" class="tag t-gris">Revertido</span></span></div><p v-if="!usados.length" class="hint">Sin repuestos registrados.</p></div></div>
    <div class="card"><h2>Historial de estados</h2><div v-for="h in hist" :key="h.id" class="linea"><span class="f">{{ fecha(h.created_at) }}</span><span style="flex:1"><StatusTag tipo="orden" :valor="h.estado" /> {{ h.nota }}</span><small>{{ W.nombreUsuario(h.usuario_id) }}</small></div></div>
    <AppModal v-if="abrirR" titulo="Rechazar trabajo" @cerrar="abrirR = false"><FormField v-model="rechazo" label="Motivo del rechazo" type="textarea" req /><div class="msg-err" role="alert">{{ errR }}</div><template #pie><button class="btn sec" type="button" @click="abrirR = false">Volver</button><button class="btn pel" type="button" @click="rechazar">Rechazar</button></template></AppModal>
  </template>
  <EmptyState v-else icono="tool" titulo="Trabajo no disponible" mensaje="No existe o no está asignado a vos."><router-link class="btn" to="/trabajos">Volver a trabajos</router-link></EmptyState>
</template>
