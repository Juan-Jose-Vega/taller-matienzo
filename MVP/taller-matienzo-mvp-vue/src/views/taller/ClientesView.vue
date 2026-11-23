<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import EmptyState from '../../components/EmptyState.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue';
import { mine, vehiculosDe, guardarCliente, eliminarCliente } from '../../services/workshopService.js';
import { norm, digits } from '../../utils/formatters.js'; import { toast, confirmar } from '../../services/uiService.js';
const router = useRouter(); const q = ref(''); const abierto = ref(false); const error = ref(''); const f = reactive({ nombre: '', telefono: '', email: '', direccion: '' });
const lista = computed(() => mine('clientes').filter((c) => !q.value || norm(c.nombre).includes(norm(q.value)) || (digits(q.value) && digits(c.telefono).includes(digits(q.value))) || vehiculosDe(c.id).some((v) => norm(v.patente).includes(norm(q.value)))).sort((a, b) => a.nombre.localeCompare(b.nombre)));
async function borrar(c) { if (!(await confirmar({ mensaje: `¿Eliminar al cliente ${c.nombre}? Se eliminan también sus vehículos sin consultas.`, ok: 'Eliminar', cls: 'pel' }))) return; const r = eliminarCliente(c.id); toast(r.ok ? 'Cliente eliminado.' : r.error, r.ok ? '' : 'error'); }
function guardar() { const r = guardarCliente(f); if (!r.ok) { error.value = r.error; return; } toast('Cliente agregado.'); abierto.value = false; router.push('/clientes/' + r.cliente.id); }
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [q.value] });
</script>
<template>
  <PageHeader titulo="Clientes" subtitulo="Fichas con vehículos, consultas y pagos"><button class="btn" type="button" @click="abierto = true; error = ''">Agregar cliente</button></PageHeader>
  <div class="filtros"><div class="campo" style="margin:0"><label>Buscar</label><input v-model="q" placeholder="Nombre, teléfono o patente" /></div></div>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Cliente</th><th>Teléfono</th><th>Vehículos</th><th></th></tr></thead><tbody>
    <tr v-for="c in pag.items" :key="c.id" class="click" @click="router.push('/clientes/' + c.id)"><td data-l="Cliente"><b>{{ c.nombre }}</b></td><td data-l="Teléfono">{{ c.telefono }}</td><td data-l="Vehículos">{{ vehiculosDe(c.id).map((v) => `${v.marca} ${v.modelo}`).join(', ') || '—' }}</td><td><button class="btn pel chico" type="button" @click.stop="borrar(c)">Eliminar</button></td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="users" titulo="No hay clientes" mensaje="Los clientes se crean al registrar consultas o desde acá." />
  <AppModal v-if="abierto" titulo="Agregar cliente" @cerrar="abierto = false"><form novalidate @submit.prevent="guardar" id="fcli"><FormField v-model="f.nombre" label="Nombre y apellido" req /><FormField v-model="f.telefono" label="Teléfono" req /><FormField v-model="f.email" label="Correo (opcional)" /><FormField v-model="f.direccion" label="Dirección (opcional)" /><div class="msg-err" role="alert">{{ error }}</div></form>
    <template #pie><button class="btn sec" type="button" @click="abierto = false">Cancelar</button><button class="btn" type="submit" form="fcli">Guardar</button></template></AppModal>
</template>
