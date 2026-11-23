<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue';
import { getMine, mine, vehiculosDe, guardarCliente, guardarVehiculo, ordenTotal, ordenPagado } from '../../services/workshopService.js';
import { money } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js'; import { toast } from '../../services/uiService.js';
const route = useRoute(); const id = computed(() => Number(route.params.id));
const c = computed(() => getMine('clientes', id.value));
const vehs = computed(() => (c.value ? vehiculosDe(id.value) : []));
const cons = computed(() => mine('consultas').filter((x) => x.cliente_id === id.value).sort((a, b) => b.id - a.id));
const ords = computed(() => mine('ordenes_trabajo').filter((o) => o.cliente_id === id.value).sort((a, b) => b.id - a.id));
const pagos = computed(() => mine('pagos_cliente').filter((p) => p.cliente_id === id.value).sort((a, b) => b.id - a.id));
const pagV = usePaginacion(() => vehs.value, { porPagina: 5 }); const pagC = usePaginacion(() => cons.value, { porPagina: 5 }); const pagO = usePaginacion(() => ords.value, { porPagina: 5 }); const pagP = usePaginacion(() => pagos.value, { porPagina: 5 });
const mod = ref(''); const error = ref(''); const fc = reactive({}); const fv = reactive({}); let vid = null;
const editarC = () => { Object.assign(fc, { nombre: c.value.nombre, telefono: c.value.telefono, email: c.value.email || '', direccion: c.value.direccion || '' }); error.value = ''; mod.value = 'c'; };
const vehiculo = (v) => { vid = v ? v.id : null; Object.assign(fv, { marca: v?.marca || '', modelo: v?.modelo || '', anio: v?.anio || '', patente: v?.patente || '', km: v?.km || '' }); error.value = ''; mod.value = 'v'; };
function gc() { const r = guardarCliente(fc, id.value); if (!r.ok) { error.value = r.error; return; } mod.value = ''; toast('Cliente actualizado.'); }
function gv() { const r = guardarVehiculo(fv, id.value, vid); if (!r.ok) { error.value = r.error; return; } mod.value = ''; toast('Vehículo guardado.'); }
</script>
<template>
  <template v-if="c">
    <PageHeader :titulo="c.nombre" subtitulo="Ficha del cliente"><button class="btn sec" type="button" @click="editarC">Editar</button><router-link class="btn" :to="`/consultas/nueva?cliente=${c.id}`">Nueva consulta</router-link></PageHeader>
    <div class="card"><div class="dl"><div><span>Teléfono</span><b>{{ c.telefono }}</b></div><div><span>Correo</span><b>{{ c.email || '—' }}</b></div><div><span>Dirección</span><b>{{ c.direccion || '—' }}</b></div></div></div>
    <h2>Vehículos</h2><button class="btn sec chico" type="button" @click="vehiculo(null)">Agregar vehículo</button>
    <div v-if="vehs.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Vehículo</th><th>Patente</th><th>Año</th><th>Km</th><th></th></tr></thead><tbody><tr v-for="v in pagV.items" :key="v.id"><td data-l="Vehículo">{{ v.marca }} {{ v.modelo }}</td><td data-l="Patente">{{ v.patente || '—' }}</td><td data-l="Año">{{ v.anio || '—' }}</td><td data-l="Km">{{ v.km || '—' }}</td><td><router-link class="btn sec chico" :to="`/consultas/nueva?cliente=${c.id}&vehiculo=${v.id}`">Consulta</router-link> <button class="btn sec chico" type="button" @click="vehiculo(v)">Editar</button></td></tr></tbody></table></div><PaginationBar v-if="vehs.length" :pag="pagV" /><EmptyState v-else icono="car" titulo="Sin vehículos" mensaje="Agregá el primer vehículo de este cliente." />
    <h2>Consultas</h2><div v-if="cons.length" class="card tight"><router-link v-for="x in pagC.items" :key="x.id" class="linea" :to="'/consultas/' + x.id"><span class="f">{{ fecha(x.fecha) }}</span><span style="flex:1">{{ x.marca }} {{ x.modelo }} — {{ x.problema.slice(0, 80) }}</span><StatusTag tipo="consulta" :valor="x.estado" /></router-link><PaginationBar :pag="pagC" /></div><p v-else class="hint">Sin consultas.</p>
    <h2>Trabajos</h2><div v-if="ords.length" class="card tight"><router-link v-for="o in pagO.items" :key="o.id" class="linea" :to="'/trabajos/' + o.id"><span class="f">{{ o.numero }}</span><span style="flex:1">{{ o.descripcion.slice(0, 80) }} · Total {{ money(ordenTotal(o)) }} · Pagado {{ money(ordenPagado(o)) }}</span><StatusTag tipo="orden" :valor="o.estado" /></router-link><PaginationBar :pag="pagO" /></div><p v-else class="hint">Sin trabajos.</p>
    <h2>Pagos</h2><div v-if="pagos.length" class="card tight"><div v-for="p in pagP.items" :key="p.id" class="linea"><span class="f">{{ fecha(p.fecha) }}</span><span style="flex:1">{{ money(p.importe) }}</span></div><PaginationBar :pag="pagP" /></div><p v-else class="hint">Sin pagos.</p>
    <AppModal v-if="mod === 'c'" titulo="Editar cliente" @cerrar="mod = ''"><form id="f1" novalidate @submit.prevent="gc"><FormField v-model="fc.nombre" label="Nombre" req /><FormField v-model="fc.telefono" label="Teléfono" req /><FormField v-model="fc.email" label="Correo" /><FormField v-model="fc.direccion" label="Dirección" /><div class="msg-err" role="alert">{{ error }}</div></form><template #pie><button class="btn sec" type="button" @click="mod = ''">Cancelar</button><button class="btn" type="submit" form="f1">Guardar</button></template></AppModal>
    <AppModal v-if="mod === 'v'" titulo="Vehículo" @cerrar="mod = ''"><form id="f2" novalidate @submit.prevent="gv"><div class="form-grid"><FormField v-model="fv.marca" label="Marca" req /><FormField v-model="fv.modelo" label="Modelo" req /><FormField v-model="fv.anio" label="Año" type="number" /><FormField v-model="fv.patente" label="Patente" /><FormField v-model="fv.km" label="Kilometraje" type="number" /></div><div class="msg-err" role="alert">{{ error }}</div></form><template #pie><button class="btn sec" type="button" @click="mod = ''">Cancelar</button><button class="btn" type="submit" form="f2">Guardar</button></template></AppModal>
  </template>
  <EmptyState v-else icono="users" titulo="Cliente no encontrado" mensaje="No existe o no pertenece a tu taller."><router-link class="btn" to="/clientes">Volver a clientes</router-link></EmptyState>
</template>
