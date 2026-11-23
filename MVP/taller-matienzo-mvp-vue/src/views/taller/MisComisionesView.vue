<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, ref } from 'vue';
import PageHeader from '../../components/PageHeader.vue'; import KpiCard from '../../components/KpiCard.vue'; import EmptyState from '../../components/EmptyState.vue'; import AppModal from '../../components/AppModal.vue';
import { mecanicoActual } from '../../services/authService.js'; import * as C from '../../services/commissionService.js';
import { money } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js';
const mid = computed(() => (mecanicoActual.value ? mecanicoActual.value.id : -1));
const res = computed(() => C.resumenMecanico(mid.value)); const movs = computed(() => C.movimientosDe(mid.value)); const liqs = computed(() => C.liquidacionesDe(mid.value));
const pagM = usePaginacion(() => movs.value); const pagL = usePaginacion(() => liqs.value, { porPagina: 5 });
const estLiq = { pendiente: ['Pendiente', 't-warn'], pagada: ['Pagada', 't-ok'], anulada: ['Anulada', 't-err'] };
const ver = ref(null); const detalle = computed(() => (ver.value ? C.detalleDeLiquidacion(ver.value.id) : []));
const num = (m) => (m.orden_id ? C.ordenNumero(m.orden_id) : '—');
</script>
<template>
  <PageHeader titulo="Mis comisiones" subtitulo="Solo lectura: lo registra y liquida el dueño del taller" />
  <div class="kpis"><KpiCard :valor="money(res.comisiones)" texto="Comisiones generadas" /><KpiCard :valor="money(res.adelantos)" texto="Adelantos recibidos" /><KpiCard :valor="money(res.pendienteNeto)" texto="Pendiente de liquidar (neto)" /><KpiCard :valor="money(res.pagado)" texto="Liquidaciones pagadas" /></div>
  <h2>Mis liquidaciones</h2>
  <div v-if="liqs.length" class="tabla-wrap"><table class="resp"><thead><tr><th>N.º</th><th>Período</th><th>Comisiones</th><th>Adelantos</th><th>Total a pagar</th><th>Estado</th><th></th></tr></thead><tbody>
    <tr v-for="l in pagL.items" :key="l.id"><td data-l="N.º">#{{ l.id }}</td><td data-l="Período">{{ fecha(l.periodo_desde) }} a {{ fecha(l.periodo_hasta) }}</td><td data-l="Comisiones">{{ money(l.total_comisiones) }}</td><td data-l="Adelantos">{{ money(l.total_adelantos) }}</td><td data-l="Total"><b>{{ money(l.total_a_pagar) }}</b></td><td data-l="Estado"><span class="tag" :class="estLiq[l.estado][1]">{{ estLiq[l.estado][0] }}</span></td><td><button class="btn sec chico" type="button" @click="ver = l">Ver</button></td></tr></tbody></table></div>
  <PaginationBar v-if="liqs.length" :pag="pagL" /><p v-else class="hint">Todavía no tenés liquidaciones.</p>
  <h2>Mis movimientos</h2>
  <div v-if="movs.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Fecha</th><th>Tipo</th><th>Trabajo</th><th>Importe</th><th>Liquidación</th></tr></thead><tbody>
    <tr v-for="m in pagM.items" :key="m.id"><td data-l="Fecha">{{ fecha(m.fecha) }}</td><td data-l="Tipo">{{ m.tipo === 'comision' ? 'Comisión' : 'Adelanto' }}</td><td data-l="Trabajo">{{ num(m) }}</td><td data-l="Importe"><b>{{ m.tipo === 'adelanto' ? '−' : '' }}{{ money(m.monto) }}</b></td><td data-l="Liquidación">{{ C.liquidacionDeMovimiento(m.id) ? '#' + C.liquidacionDeMovimiento(m.id).id : 'Sin liquidar' }}</td></tr></tbody></table></div>
  <PaginationBar v-if="movs.length" :pag="pagM" /><EmptyState v-else icono="dollar" titulo="Sin movimientos" mensaje="Cuando el dueño registre tus comisiones o adelantos, los vas a ver acá." />
  <AppModal v-if="ver" :titulo="'Liquidación #' + ver.id" :ancho="720" @cerrar="ver = null"><p>{{ fecha(ver.periodo_desde) }} a {{ fecha(ver.periodo_hasta) }} · <span class="tag" :class="estLiq[ver.estado][1]">{{ estLiq[ver.estado][0] }}</span></p>
    <div v-if="detalle.length" class="card tight"><div v-for="x in detalle" :key="x.detalle.id" class="linea"><span class="f">{{ fecha(x.movimiento.fecha) }}</span><span style="flex:1">{{ x.movimiento.tipo === 'comision' ? 'Comisión' : 'Adelanto' }} · {{ x.movimiento.descripcion }}</span><b>{{ x.movimiento.tipo === 'adelanto' ? '−' : '' }}{{ money(x.detalle.importe_incluido) }}</b></div></div>
    <div class="dl"><div><span>Comisiones</span><b>{{ money(ver.total_comisiones) }}</b></div><div><span>Adelantos</span><b>{{ money(ver.total_adelantos) }}</b></div><div><span>Total a pagar</span><b>{{ money(ver.total_a_pagar) }}</b></div></div><template #pie><button class="btn sec" type="button" @click="ver = null">Cerrar</button></template></AppModal>
</template>
