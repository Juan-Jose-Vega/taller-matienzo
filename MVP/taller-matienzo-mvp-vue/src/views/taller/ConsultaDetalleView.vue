<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import FormField from '../../components/FormField.vue'; import AiTextField from '../../components/AiTextField.vue'; import AppIcon from '../../components/AppIcon.vue'; import AppModal from '../../components/AppModal.vue'; import EmptyState from '../../components/EmptyState.vue';
import * as W from '../../services/workshopService.js';
import { vincularPropuestas } from '../../services/aiTextService.js';
import { can, rol, taller } from '../../services/authService.js';
import { toast, confirmar, abrirWhatsapp } from '../../services/uiService.js';
import { money, num, waLink } from '../../utils/formatters.js'; import { fecha, hoy, addDias } from '../../utils/dates.js'; import { TIPOS_DETALLE } from '../../utils/estados.js';
const route = useRoute(); const router = useRouter(); const id = computed(() => Number(route.params.id));
const c = computed(() => W.getMine('consultas', id.value));
const rev = computed(() => W.revisionDe(id.value));
const pres = computed(() => W.presupuestoDe(id.value)); const orden = computed(() => W.ordenDeConsulta(id.value));
const previas = computed(() => (c.value ? W.previas(c.value) : []));
const esAdmin = computed(() => rol.value === 'admin');
const pasos = computed(() => { const e = c.value.estado; const p = pres.value; return [['Consulta', true], ['Revisión', !!rev.value], ['Presupuesto', !!p && p.estado !== 'borrador'], ['Aceptado', !!p && p.estado === 'aceptado'], ['Trabajo', !!orden.value]]; });
// ---- revisión
const fr = reactive({ problemas: '', problemas_original: '', tecnicas: '', tecnicas_original: '', repuestos: '', trabajo: '', importe: '' }); const idsR = ref([]); const errR = ref('');
function cargarRev() { const r = rev.value; Object.assign(fr, { problemas: r?.problemas || '', problemas_original: r?.problemas_original || '', tecnicas: r?.tecnicas || '', tecnicas_original: r?.tecnicas_original || '', repuestos: r?.repuestos_necesarios || '', trabajo: r?.trabajo_recomendado || '', importe: r?.importe_estimado || '' }); }
watch(id, cargarRev, { immediate: true });
function guardarRev() { errR.value = ''; const r = W.guardarRevision(id.value, fr); if (!r.ok) { errR.value = r.error; return; } vincularPropuestas(idsR.value, 'consulta_revisiones', rev.value.id); idsR.value = []; toast('Revisión técnica guardada.'); }
// ---- cobro repetida
const cobro = reactive({ decision: 'gratis', importe: '' }); const errC = ref('');
function guardarCobro() { errC.value = ''; const r = W.decidirCobro(id.value, cobro.decision, cobro.importe); if (!r.ok) errC.value = r.error; else toast('Decisión registrada.'); }
// ---- presupuesto
const items = ref([]); const valido = ref(addDias(hoy(), 15)); const errP = ref('');
function cargarPres() { const p = pres.value; items.value = p ? W.detallesDe(p.id).map((d) => ({ tipo: d.tipo, descripcion: d.descripcion, cantidad: d.cantidad, precio_unitario: d.precio_unitario })) : [{ tipo: 'mano_obra', descripcion: '', cantidad: 1, precio_unitario: '' }]; if (p && p.valido_hasta) valido.value = p.valido_hasta; }
watch(id, cargarPres, { immediate: true });
const total = computed(() => items.value.reduce((s, i) => s + num(i.cantidad) * num(i.precio_unitario), 0));
const editable = computed(() => pres.value ? ['borrador', 'pendiente', 'rechazado'].includes(pres.value.estado) : true);
function guardarPres(enviar) { errP.value = ''; const r = W.guardarPresupuesto(id.value, items.value, valido.value, enviar); if (!r.ok) { errP.value = r.error; return; } toast(enviar ? 'Presupuesto presentado al cliente.' : 'Borrador guardado.'); }
async function decidir(acepta) { if (!(await confirmar({ mensaje: acepta ? '¿Registrar que el cliente ACEPTÓ el presupuesto?' : '¿Registrar que el cliente RECHAZÓ el presupuesto?', ok: acepta ? 'Aceptó' : 'Rechazó' }))) return; const r = W.decidirPresupuesto(pres.value.id, acepta); if (!r.ok) toast(r.error, 'error'); }
// ---- aprobar → orden
const fo = reactive({ descripcion: '', mecanico_id: '', inicio: '', entrega: '', repuestos: '', obs: '' }); const errO = ref(''); const abrirO = ref(false);
function prepararO() { fo.descripcion = rev.value?.trabajo_recomendado || ''; errO.value = ''; abrirO.value = true; }
const mecs = computed(() => W.mecanicosDelTaller().filter((m) => m.disponible));
function aprobar() { errO.value = ''; const r = W.aprobarConsulta(id.value, fo); if (!r.ok) { errO.value = r.error; return; } abrirO.value = false; toast(r.repetida ? 'Ya existía una orden para esta consulta.' : `Orden ${r.orden.numero} creada.`); router.push('/trabajos/' + r.orden.id); }
async function borrarC() { if (!(await confirmar({ mensaje: '¿Eliminar esta consulta con su revisión y presupuesto?', ok: 'Eliminar', cls: 'pel' }))) return; const r = W.eliminarConsulta(id.value); if (!r.ok) { toast(r.error, 'error'); return; } toast('Consulta eliminada.'); router.replace('/consultas'); }
async function cerrarSin() { if (!(await confirmar({ mensaje: '¿Finalizar la consulta sin realizar trabajo?', ok: 'Finalizar' }))) return; W.finalizarSinTrabajo(id.value, 'Sin trabajo'); toast('Consulta finalizada.'); }
function wa() { const p = pres.value; const t = p && p.estado !== 'borrador' ? `Hola ${c.value.nombre_contacto}, te paso el presupuesto ${p.numero} de ${taller.value.nombre} por ${money(W.presTotal(p))}, válido hasta el ${fecha(p.valido_hasta)}. ¿Lo aceptás?` : `Hola ${c.value.nombre_contacto}, te escribimos de ${taller.value.nombre} por la consulta de tu ${c.value.marca} ${c.value.modelo}.`; abrirWhatsapp(c.value.telefono_contacto, t, 'Mensaje para ' + c.value.nombre_contacto); }
</script>
<template>
  <template v-if="c">
    <PageHeader :titulo="`${c.marca} ${c.modelo} · ${c.nombre_contacto}`" :subtitulo="`Consulta del ${fecha(c.fecha)}`"><StatusTag tipo="consulta" :valor="c.estado" /><button class="btn wa chico" type="button" @click="wa"><AppIcon name="wa" /> WhatsApp</button></PageHeader>
    <div class="pasos"><span v-for="(p, i) in pasos" :key="i" class="paso" :class="{ hecho: p[1] }">{{ p[0] }}</span></div>
    <div class="card"><div class="dl"><div><span>Teléfono</span><b>{{ c.telefono_contacto }}</b></div><div><span>Patente</span><b>{{ c.patente || '—' }}</b></div><div><span>Año / Km</span><b>{{ c.anio || '—' }} / {{ c.km || '—' }}</b></div><div><span>Consulta</span><b>{{ c.es_gratuita ? 'Primera (gratuita)' : 'Repetida' }}</b></div></div>
      <h3>Problema informado</h3><p style="white-space:pre-wrap">{{ c.problema }}</p><details v-if="c.problema_original && c.problema_original !== c.problema"><summary>Ver texto original</summary><p style="white-space:pre-wrap">{{ c.problema_original }}</p></details><p v-if="c.observaciones"><b>Observaciones:</b> {{ c.observaciones }}</p></div>
    <div v-if="!c.es_gratuita && esAdmin" class="card"><h2>Consulta repetida</h2><p>El cliente ya tiene {{ previas.length }} consulta(s) anterior(es). Decidí si se cobra.</p>
      <div v-if="c.cobro_decision" class="hint ok">Decisión: {{ c.cobro_decision === 'cobrar' ? 'cobrar ' + money(c.cobro_importe) : 'sin cargo' }} ({{ fecha(c.cobro_fecha) }}).</div>
      <form v-else novalidate @submit.prevent="guardarCobro"><div class="form-grid"><FormField v-model="cobro.decision" label="Decisión" type="select" :opciones="[['gratis', 'Sin cargo'], ['cobrar', 'Cobrar']]" /><FormField v-if="cobro.decision === 'cobrar'" v-model="cobro.importe" label="Importe" type="number" /></div><div class="msg-err" role="alert">{{ errC }}</div><button class="btn">Guardar decisión</button></form></div>
    <template v-if="c.estado !== 'cerrada' && c.estado !== 'aprobada' || rev">
      <div class="card"><h2>Revisión técnica</h2>
        <form novalidate @submit.prevent="guardarRev">
          <AiTextField v-model="fr.problemas" v-model:original="fr.problemas_original" v-model:ids="idsR" label="Problemas encontrados" entidad="consulta_revisiones" campo="problemas" contexto="problema" />
          <AiTextField v-model="fr.tecnicas" v-model:original="fr.tecnicas_original" v-model:ids="idsR" label="Observaciones técnicas" entidad="consulta_revisiones" campo="tecnicas" contexto="general" />
          <div class="form-grid"><FormField v-model="fr.repuestos" label="Repuestos necesarios" /><FormField v-model="fr.trabajo" label="Trabajo recomendado" /><FormField v-model="fr.importe" label="Importe estimado" type="number" /></div>
          <div class="msg-err" role="alert">{{ errR }}</div><button class="btn">Guardar revisión</button>
        </form></div>
    </template>
    <div v-if="rev && c.estado !== 'cerrada' && (esAdmin || can('presupuestos.gestionar'))" class="card"><h2>Presupuesto <StatusTag v-if="pres" tipo="presupuesto" :valor="W.presEstado(pres)" /></h2>
      <form novalidate @submit.prevent>
        <div v-for="(it, i) in items" :key="i" class="item-row"><select v-model="it.tipo" :disabled="!editable"><option v-for="t in TIPOS_DETALLE" :key="t[0]" :value="t[0]">{{ t[1] }}</option></select><input v-model="it.descripcion" placeholder="Descripción" :disabled="!editable" /><input v-model="it.cantidad" type="number" min="0" step="any" :disabled="!editable" /><input v-model="it.precio_unitario" type="number" min="0" step="any" placeholder="Precio" :disabled="!editable" /><span class="sub">{{ money(num(it.cantidad) * num(it.precio_unitario)) }}</span><button v-if="editable && items.length > 1" class="txt-btn" type="button" aria-label="Quitar" @click="items.splice(i, 1)"><AppIcon name="x" /></button></div>
        <button v-if="editable" class="btn sec chico" type="button" @click="items.push({ tipo: 'repuesto', descripcion: '', cantidad: 1, precio_unitario: '' })">Agregar concepto</button>
        <div class="total-box">Total: {{ money(total) }}</div><FormField v-model="valido" label="Válido hasta" type="date" />
        <div class="msg-err" role="alert">{{ errP }}</div>
        <div v-if="editable" class="fila-btn"><button class="btn sec" type="button" @click="guardarPres(false)">Guardar borrador</button><button class="btn" type="button" @click="guardarPres(true)">Presentar al cliente</button></div>
      </form>
      <div v-if="pres && pres.estado === 'pendiente' && esAdmin" class="fila-btn"><button class="btn ok" type="button" @click="decidir(true)">El cliente aceptó</button><button class="btn pel" type="button" @click="decidir(false)">El cliente rechazó</button></div>
    </div>
    <div v-if="esAdmin && c.estado !== 'cerrada'" class="card"><h2>Resolución</h2>
      <div class="fila-btn"><button v-if="pres && pres.estado === 'aceptado' && !orden" class="btn ok" type="button" @click="prepararO">Aprobar y crear orden de trabajo</button><router-link v-if="orden" class="btn" :to="'/trabajos/' + orden.id">Ver orden {{ orden.numero }}</router-link><button v-if="!orden" class="btn sec" type="button" @click="cerrarSin">Finalizar sin trabajo</button><button v-if="!orden" class="btn pel" type="button" @click="borrarC">Eliminar consulta</button></div></div>
    <AppModal v-if="abrirO" titulo="Crear orden de trabajo" @cerrar="abrirO = false"><form id="fo" novalidate @submit.prevent="aprobar"><FormField v-model="fo.descripcion" label="Trabajo a realizar" type="textarea" req /><FormField v-model="fo.mecanico_id" label="Asignar a (opcional)" type="select" :opciones="[['', 'Sin asignar por ahora'], ...mecs.map((m) => [m.id, W.nombreMecanico(m.id)])]" /><div class="form-grid"><FormField v-model="fo.inicio" label="Inicio previsto" type="date" /><FormField v-model="fo.entrega" label="Entrega prevista" type="date" /></div><FormField v-model="fo.repuestos" label="Repuestos previstos" /><FormField v-model="fo.obs" label="Observaciones" /><div class="msg-err" role="alert">{{ errO }}</div></form><template #pie><button class="btn sec" type="button" @click="abrirO = false">Cancelar</button><button class="btn ok" type="submit" form="fo">Crear orden</button></template></AppModal>
  </template>
  <EmptyState v-else icono="search" titulo="Consulta no encontrada" mensaje="No existe o no pertenece a tu taller."><router-link class="btn" to="/consultas">Volver a consultas</router-link></EmptyState>
</template>
