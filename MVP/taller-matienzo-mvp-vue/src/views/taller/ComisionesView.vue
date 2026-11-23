<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, reactive, ref } from 'vue';
import PageHeader from '../../components/PageHeader.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue'; import KpiCard from '../../components/KpiCard.vue';
import { get } from '../../services/storageService.js'; import { mecanicosDelTaller } from '../../services/workshopService.js';
import * as C from '../../services/commissionService.js';
import { confirmar, toast } from '../../services/uiService.js';
import { money } from '../../utils/formatters.js'; import { fecha, hoy, addDias } from '../../utils/dates.js';

const tab = ref('resumen'); const mec = ref('');
const TABS = [['resumen', 'Resumen'], ['trabajos', 'Comisiones por trabajo'], ['adelantos', 'Adelantos'], ['liquidaciones', 'Liquidaciones']];
const mecs = computed(() => mecanicosDelTaller()); const mecId = computed(() => (mec.value ? Number(mec.value) : null));
const opcMec = computed(() => [['', 'Todos los mecánicos'], ...mecs.value.map((m) => [m.id, C.nombreMec(m.id)])]);

/* resumen */
const resumen = computed(() => mecs.value.map((m) => Object.assign({ m }, C.resumenMecanico(m.id))));
const tot = computed(() => ({ pend: resumen.value.reduce((s, r) => s + r.pendienteNeto, 0), calc: resumen.value.reduce((s, r) => s + r.porCalcular, 0), pagado: resumen.value.reduce((s, r) => s + r.pagado, 0) }));
function registrarTodas() { const r = C.registrarComisionesPendientes(mecId.value); toast(r.registradas ? `${r.registradas} comisión(es) registradas por ${money(r.total)}.` : 'No había comisiones para registrar.', r.registradas ? '' : 'aviso'); if (r.omitidas.length) toast(`${r.omitidas.length} trabajo(s) sin registrar: falta porcentaje o mano de obra.`, 'aviso'); }

/* trabajos */
const trabajos = computed(() => C.trabajosFinalizados(mecId.value));
const pagT = usePaginacion(() => trabajos.value, { reiniciarCon: () => [mec.value, tab.value] });
const pcts = reactive({}); const pctVal = (x) => (pcts[x.orden.id] !== undefined ? pcts[x.orden.id] : x.pct);
function guardarPct(x) { const r = C.establecerPorcentaje(x.orden.id, pctVal(x)); if (!r.ok) { toast(r.error, 'error'); return; } delete pcts[x.orden.id]; toast('Porcentaje guardado.'); }
function registrar(x) { const r = C.registrarComision(x.orden.id); toast(r.ok ? `Comisión registrada: ${money(r.movimiento.monto)}.` : r.error, r.ok ? '' : 'error'); }
const estadoCom = (x) => (x.liquidada ? ['Liquidada', 't-ok'] : x.registrada ? ['Registrada', 't-info'] : x.comision > 0 ? ['Por registrar', 't-warn'] : ['Sin comisión', 't-gris']);

/* adelantos */
const adel = computed(() => C.movimientosDe(mecId.value).filter((m) => m.tipo === 'adelanto'));
const pagA = usePaginacion(() => adel.value, { reiniciarCon: () => [mec.value, tab.value] });
const fa = reactive({ mecanico_id: '', monto: '', fecha: hoy(), descripcion: '' }); const abA = ref(false); const errA = ref('');
function abrirA() { Object.assign(fa, { mecanico_id: mec.value || '', monto: '', fecha: hoy(), descripcion: '' }); errA.value = ''; abA.value = true; }
function guardarA() { const r = C.registrarAdelanto(fa); if (!r.ok) { errA.value = r.error; return; } abA.value = false; toast('Adelanto registrado.'); }
async function quitarA(a) { if (!(await confirmar({ mensaje: `¿Eliminar el adelanto de ${money(a.monto)}?`, ok: 'Eliminar', cls: 'pel' }))) return; const r = C.eliminarAdelanto(a.id); toast(r.ok ? 'Adelanto eliminado.' : r.error, r.ok ? '' : 'error'); }

/* liquidaciones */
const filtroEst = ref('');
const liqs = computed(() => C.liquidacionesDe(mecId.value, filtroEst.value));
const pagL = usePaginacion(() => liqs.value, { reiniciarCon: () => [mec.value, filtroEst.value, tab.value] });
const fl = reactive({ mecanico_id: '', desde: addDias(hoy(), -30), hasta: hoy(), obs: '' }); const abL = ref(false); const errL = ref('');
const prev = computed(() => (fl.mecanico_id ? C.previsualizarLiquidacion(Number(fl.mecanico_id), fl.desde, fl.hasta) : null));
function abrirL() { Object.assign(fl, { mecanico_id: mec.value || '', desde: addDias(hoy(), -30), hasta: hoy(), obs: '' }); errL.value = ''; abL.value = true; }
function generar() { const r = C.generarLiquidacion({ mecanico_id: fl.mecanico_id, desde: fl.desde, hasta: fl.hasta, observaciones: fl.obs }); if (!r.ok) { errL.value = r.error; return; } abL.value = false; toast('Liquidación generada. Queda pendiente de pago.'); }
async function pagar(l) { if (!(await confirmar({ mensaje: `¿Registrar el pago de ${money(l.total_a_pagar)} a ${C.nombreMec(l.mecanico_id)}?`, ok: 'Registrar pago' }))) return; const r = C.pagarLiquidacion(l.id); toast(r.ok ? 'Pago de la liquidación registrado.' : r.error, r.ok ? '' : 'error'); }
async function anular(l) { if (!(await confirmar({ mensaje: 'Se anula la liquidación y sus comisiones y adelantos quedan libres para liquidarse de nuevo. ¿Continuar?', ok: 'Anular', cls: 'pel' }))) return; const r = C.anularLiquidacion(l.id); toast(r.ok ? 'Liquidación anulada.' : r.error, r.ok ? '' : 'error'); }
const ver = ref(null); const detalle = computed(() => (ver.value ? C.detalleDeLiquidacion(ver.value.id) : []));
const estLiq = { pendiente: ['Pendiente', 't-warn'], pagada: ['Pagada', 't-ok'], anulada: ['Anulada', 't-err'] };
</script>
<template>
  <PageHeader titulo="Comisiones y liquidaciones" subtitulo="Comisiones de los mecánicos, adelantos y pagos" />
  <div class="fila-btn" role="tablist"><button v-for="t in TABS" :key="t[0]" type="button" class="btn chico" :class="{ sec: tab !== t[0] }" role="tab" :aria-selected="tab === t[0]" @click="tab = t[0]">{{ t[1] }}</button></div>
  <div v-if="tab !== 'resumen'" class="filtros"><div class="campo" style="margin:0"><label>Mecánico</label><select v-model="mec"><option v-for="o in opcMec" :key="o[0]" :value="o[0]">{{ o[1] }}</option></select></div>
    <div v-if="tab === 'liquidaciones'" class="campo" style="margin:0"><label>Estado</label><select v-model="filtroEst"><option value="">Todas</option><option value="pendiente">Pendientes</option><option value="pagada">Pagadas</option><option value="anulada">Anuladas</option></select></div></div>

  <template v-if="tab === 'resumen'">
    <div class="kpis"><KpiCard :valor="money(tot.pend)" texto="Pendiente de liquidar (neto)" /><KpiCard :valor="tot.calc" texto="Trabajos con comisión por registrar" :alerta="tot.calc > 0" /><KpiCard :valor="money(tot.pagado)" texto="Pagado en liquidaciones" /></div>
    <div class="fila-btn"><button class="btn" type="button" @click="registrarTodas">Registrar todas las comisiones pendientes</button></div>
    <div v-if="resumen.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Mecánico</th><th>Comisiones generadas</th><th>Adelantos</th><th>Pendiente de liquidar</th><th>Pagado</th><th>Por registrar</th></tr></thead><tbody>
      <tr v-for="r in resumen" :key="r.m.id"><td data-l="Mecánico"><b>{{ C.nombreMec(r.m.id) }}</b></td><td data-l="Comisiones">{{ money(r.comisiones) }}</td><td data-l="Adelantos">{{ money(r.adelantos) }}</td><td data-l="Pendiente"><b>{{ money(r.pendienteNeto) }}</b><br><small>{{ money(r.pendienteComisiones) }} − {{ money(r.pendienteAdelantos) }}</small></td><td data-l="Pagado">{{ money(r.pagado) }}</td><td data-l="Por registrar">{{ r.porCalcular }} trabajo(s) · {{ money(r.montoPorCalcular) }}</td></tr></tbody></table></div>
    <EmptyState v-else icono="user" titulo="No hay mecánicos" mensaje="Cargá mecánicos para poder calcular comisiones." />
    <p class="hint"><b>Fórmula:</b> comisión = (suma de la <u>mano de obra</u> del presupuesto aceptado) × porcentaje de comisión del trabajo ÷ 100. Los repuestos y otros conceptos no suman. El porcentaje se define por trabajo (pestaña «Comisiones por trabajo»); si es 0 no hay comisión. Total a pagar de una liquidación = comisiones − adelantos.</p>
  </template>

  <template v-if="tab === 'trabajos'">
    <div class="fila-btn"><button class="btn" type="button" @click="registrarTodas">Registrar comisiones pendientes</button></div>
    <div v-if="trabajos.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Trabajo</th><th>Mecánico</th><th>Mano de obra</th><th>% comisión</th><th>Comisión</th><th>Estado</th><th></th></tr></thead><tbody>
      <tr v-for="x in pagT.items" :key="x.orden.id"><td data-l="Trabajo"><router-link :to="'/trabajos/' + x.orden.id"><b>{{ x.orden.numero }}</b></router-link><br><small>{{ fecha(C.fechaFinalizacion(x.orden)) }}</small></td><td data-l="Mecánico">{{ C.nombreMec(x.orden.mecanico_id) }}</td><td data-l="Mano de obra">{{ money(x.base) }}</td>
        <td data-l="% comisión"><template v-if="!x.registrada"><input :value="pctVal(x)" type="number" min="0" max="100" step="0.01" style="width:5.5rem" :aria-label="'Porcentaje de ' + x.orden.numero" @input="pcts[x.orden.id] = $event.target.value" /> <button class="btn sec chico" type="button" @click="guardarPct(x)">Guardar %</button></template><template v-else>{{ x.pct }} %</template></td>
        <td data-l="Comisión"><b>{{ money(x.registrada ? x.movimiento.monto : x.comision) }}</b></td><td data-l="Estado"><span class="tag" :class="estadoCom(x)[1]">{{ estadoCom(x)[0] }}</span></td><td><button v-if="!x.registrada" class="btn chico" type="button" :disabled="!(x.comision > 0)" @click="registrar(x)">Registrar comisión</button></td></tr></tbody></table></div>
    <PaginationBar v-if="trabajos.length" :pag="pagT" />
    <EmptyState v-else icono="tool" titulo="No hay trabajos finalizados" mensaje="La comisión se calcula sobre trabajos finalizados con mecánico asignado." />
    <p class="hint">Mano de obra = líneas del tipo «mano de obra» del presupuesto aceptado. Una vez registrada la comisión, el porcentaje queda fijo.</p>
  </template>

  <template v-if="tab === 'adelantos'">
    <div class="fila-btn"><button class="btn" type="button" @click="abrirA">Registrar adelanto</button></div>
    <div v-if="adel.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Fecha</th><th>Mecánico</th><th>Importe</th><th>Detalle</th><th>Liquidación</th><th></th></tr></thead><tbody>
      <tr v-for="a in pagA.items" :key="a.id"><td data-l="Fecha">{{ fecha(a.fecha) }}</td><td data-l="Mecánico">{{ C.nombreMec(a.mecanico_id) }}</td><td data-l="Importe"><b>{{ money(a.monto) }}</b></td><td data-l="Detalle">{{ a.descripcion }}</td><td data-l="Liquidación">{{ C.liquidacionDeMovimiento(a.id) ? '#' + C.liquidacionDeMovimiento(a.id).id : 'Sin liquidar' }}</td><td><button v-if="!C.estaLiquidado(a.id)" class="btn sec chico" type="button" @click="quitarA(a)">Eliminar</button></td></tr></tbody></table></div>
    <PaginationBar v-if="adel.length" :pag="pagA" />
    <EmptyState v-else icono="dollar" titulo="Sin adelantos" mensaje="Registrá los adelantos que le des a un mecánico: se descuentan al liquidar." />
  </template>

  <template v-if="tab === 'liquidaciones'">
    <div class="fila-btn"><button class="btn" type="button" @click="abrirL">Nueva liquidación</button></div>
    <div v-if="liqs.length" class="tabla-wrap"><table class="resp"><thead><tr><th>N.º</th><th>Mecánico</th><th>Período</th><th>Comisiones</th><th>Adelantos</th><th>Total a pagar</th><th>Estado</th><th></th></tr></thead><tbody>
      <tr v-for="l in pagL.items" :key="l.id"><td data-l="N.º">#{{ l.id }}</td><td data-l="Mecánico">{{ C.nombreMec(l.mecanico_id) }}</td><td data-l="Período">{{ fecha(l.periodo_desde) }} a {{ fecha(l.periodo_hasta) }}</td><td data-l="Comisiones">{{ money(l.total_comisiones) }}</td><td data-l="Adelantos">{{ money(l.total_adelantos) }}</td><td data-l="Total a pagar"><b>{{ money(l.total_a_pagar) }}</b></td><td data-l="Estado"><span class="tag" :class="estLiq[l.estado][1]">{{ estLiq[l.estado][0] }}</span><small v-if="l.fecha_pago"><br>{{ fecha(l.fecha_pago) }}</small></td>
        <td><button class="btn sec chico" type="button" @click="ver = l">Ver</button> <button v-if="l.estado === 'pendiente'" class="btn chico" type="button" @click="pagar(l)">Registrar pago</button> <button v-if="l.estado === 'pendiente'" class="btn sec chico" type="button" @click="anular(l)">Anular</button></td></tr></tbody></table></div>
    <PaginationBar v-if="liqs.length" :pag="pagL" />
    <EmptyState v-else icono="clip" titulo="No hay liquidaciones" mensaje="Generá una liquidación eligiendo el mecánico y el período." />
  </template>

  <AppModal v-if="abA" titulo="Registrar adelanto" @cerrar="abA = false"><form id="fad" novalidate @submit.prevent="guardarA"><FormField v-model="fa.mecanico_id" label="Mecánico" type="select" req :opciones="opcMec.map((o, i) => (i ? o : ['', 'Elegir…']))" /><FormField v-model="fa.monto" label="Importe" type="number" req /><FormField v-model="fa.fecha" label="Fecha" type="date" /><FormField v-model="fa.descripcion" label="Detalle (opcional)" /><div class="msg-err" role="alert">{{ errA }}</div></form><template #pie><button class="btn sec" type="button" @click="abA = false">Cancelar</button><button class="btn" type="submit" form="fad">Registrar</button></template></AppModal>

  <AppModal v-if="abL" titulo="Nueva liquidación" :ancho="760" @cerrar="abL = false"><form id="fli" novalidate @submit.prevent="generar">
    <FormField v-model="fl.mecanico_id" label="Mecánico" type="select" req :opciones="opcMec.map((o, i) => (i ? o : ['', 'Elegir…']))" /><div class="form-grid"><FormField v-model="fl.desde" label="Período desde" type="date" /><FormField v-model="fl.hasta" label="Período hasta" type="date" /></div>
    <template v-if="prev && prev.ok"><div class="card tight"><div v-for="m in prev.movimientos" :key="m.id" class="linea"><span class="f">{{ fecha(m.fecha) }}</span><span style="flex:1">{{ m.tipo === 'comision' ? 'Comisión' : 'Adelanto' }} · {{ m.descripcion }}</span><b>{{ m.tipo === 'adelanto' ? '−' : '' }}{{ money(m.monto) }}</b></div><p v-if="!prev.movimientos.length" class="hint">Sin movimientos sin liquidar en ese período.</p></div>
      <div class="dl"><div><span>Total de comisiones</span><b>{{ money(prev.total_comisiones) }}</b></div><div><span>Adelantos a descontar</span><b>{{ money(prev.total_adelantos) }}</b></div><div><span>Total a pagar</span><b>{{ money(prev.total_a_pagar) }}</b></div></div>
      <div v-if="prev.aviso" class="hint warn">{{ prev.aviso }}</div></template>
    <div v-else-if="prev" class="hint warn">{{ prev.error }}</div>
    <FormField v-model="fl.obs" label="Observaciones (opcional)" /><div class="msg-err" role="alert">{{ errL }}</div></form><template #pie><button class="btn sec" type="button" @click="abL = false">Cancelar</button><button class="btn" type="submit" form="fli" :disabled="!(prev && prev.ok && prev.puedeGenerar)">Generar liquidación</button></template></AppModal>

  <AppModal v-if="ver" :titulo="'Liquidación #' + ver.id" :ancho="720" @cerrar="ver = null"><p><b>{{ C.nombreMec(ver.mecanico_id) }}</b> · {{ fecha(ver.periodo_desde) }} a {{ fecha(ver.periodo_hasta) }} · <span class="tag" :class="estLiq[ver.estado][1]">{{ estLiq[ver.estado][0] }}</span></p>
    <div v-if="detalle.length" class="card tight"><div v-for="x in detalle" :key="x.detalle.id" class="linea"><span class="f">{{ fecha(x.movimiento.fecha) }}</span><span style="flex:1">{{ x.movimiento.tipo === 'comision' ? 'Comisión' : 'Adelanto' }} · {{ x.movimiento.descripcion }}</span><b>{{ x.movimiento.tipo === 'adelanto' ? '−' : '' }}{{ money(x.detalle.importe_incluido) }}</b></div></div><p v-else class="hint">Liquidación anulada: sus movimientos quedaron libres.</p>
    <div class="dl"><div><span>Comisiones</span><b>{{ money(ver.total_comisiones) }}</b></div><div><span>Adelantos</span><b>{{ money(ver.total_adelantos) }}</b></div><div><span>Total a pagar</span><b>{{ money(ver.total_a_pagar) }}</b></div></div><p v-if="ver.observaciones" class="hint">{{ ver.observaciones }}</p>
    <template #pie><button class="btn sec" type="button" @click="ver = null">Cerrar</button></template></AppModal>
</template>
