<script setup>
import { computed, reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import EmptyState from '../../components/EmptyState.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue'; import PaginationBar from '../../components/PaginationBar.vue';
import { usePaginacion } from '../../composables/usePaginacion.js';
import { mine, clienteDeVehiculo, guardarVehiculo, eliminarVehiculo } from '../../services/workshopService.js'; import { confirmar, toast } from '../../services/uiService.js'; import { norm } from '../../utils/formatters.js';
const router = useRouter(); const q = ref('');
const lista = computed(() => mine('vehiculos').filter((v) => { const c = clienteDeVehiculo(v.id); return !q.value || norm(`${v.marca} ${v.modelo} ${v.patente || ''} ${c ? c.nombre : ''}`).includes(norm(q.value)); }).sort((a, b) => a.marca.localeCompare(b.marca)));
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [q.value] });
const abierto = ref(false); const error = ref(''); const f = reactive({}); let vid = null;
function abrir(v) { vid = v ? v.id : null; Object.assign(f, { cliente: '', marca: v?.marca || '', modelo: v?.modelo || '', anio: v?.anio || '', patente: v?.patente || '', km: v?.km || '' }); error.value = ''; abierto.value = true; }
function guardar() { if (!vid && !f.cliente) { error.value = 'Elegí el cliente propietario.'; return; } const r = guardarVehiculo(f, Number(f.cliente), vid); if (!r.ok) { error.value = r.error; return; } abierto.value = false; toast('Vehículo guardado.'); }
async function borrar(v) { if (!(await confirmar({ mensaje: `¿Eliminar el vehículo ${v.marca} ${v.modelo}?`, ok: 'Eliminar', cls: 'pel' }))) return; const r = eliminarVehiculo(v.id); toast(r.ok ? 'Vehículo eliminado.' : r.error, r.ok ? '' : 'error'); }
</script>
<template>
  <PageHeader titulo="Vehículos" subtitulo="Todos los vehículos del taller y su propietario"><button class="btn" type="button" @click="abrir(null)">Agregar vehículo</button></PageHeader>
  <div class="filtros"><div class="campo" style="margin:0"><label>Buscar</label><input v-model="q" placeholder="Marca, modelo, patente o propietario" /></div></div>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Vehículo</th><th>Patente</th><th>Año</th><th>Km</th><th>Propietario</th><th></th></tr></thead><tbody>
    <tr v-for="v in pag.items" :key="v.id"><td data-l="Vehículo"><b>{{ v.marca }} {{ v.modelo }}</b></td><td data-l="Patente">{{ v.patente || '—' }}</td><td data-l="Año">{{ v.anio || '—' }}</td><td data-l="Km">{{ v.km || '—' }}</td><td data-l="Propietario"><a v-if="clienteDeVehiculo(v.id)" href="#" @click.prevent="router.push('/clientes/' + clienteDeVehiculo(v.id).id)">{{ clienteDeVehiculo(v.id).nombre }}</a></td>
      <td><button class="btn sec chico" type="button" @click="abrir(v)">Editar</button> <button class="btn pel chico" type="button" @click="borrar(v)">Eliminar</button></td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="car" titulo="No hay vehículos para mostrar" mensaje="Probá con otra búsqueda o agregá un vehículo." />
  <AppModal v-if="abierto" :titulo="vid ? 'Editar vehículo' : 'Agregar vehículo'" @cerrar="abierto = false"><form id="fv" novalidate @submit.prevent="guardar"><FormField v-if="!vid" v-model="f.cliente" label="Propietario" type="select" req :opciones="[['', 'Elegir cliente…'], ...mine('clientes').map((c) => [c.id, c.nombre])]" /><div class="form-grid"><FormField v-model="f.marca" label="Marca" req /><FormField v-model="f.modelo" label="Modelo" req /><FormField v-model="f.anio" label="Año" type="number" /><FormField v-model="f.patente" label="Patente" /><FormField v-model="f.km" label="Kilometraje" type="number" /></div><div class="msg-err" role="alert">{{ error }}</div></form><template #pie><button class="btn sec" type="button" @click="abierto = false">Cancelar</button><button class="btn" type="submit" form="fv">Guardar</button></template></AppModal>
</template>
