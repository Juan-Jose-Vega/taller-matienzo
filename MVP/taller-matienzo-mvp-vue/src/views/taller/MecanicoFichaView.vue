<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue';
import * as W from '../../services/workshopService.js'; import { get } from '../../services/storageService.js'; import { tallerId } from '../../services/authService.js'; import { useRouter } from 'vue-router'; import { confirmar, mostrarClave, toast } from '../../services/uiService.js';
const route = useRoute(); const m = computed(() => { const x = get('mecanicos', Number(route.params.id)); return x && x.taller_id === tallerId.value ? x : null; });
const u = computed(() => get('usuarios', m.value.usuario_id)); const ords = computed(() => W.mine('ordenes_trabajo').filter((o) => o.mecanico_id === m.value.id).sort((a, b) => b.id - a.id));
const pag = usePaginacion(() => ords.value, { porPagina: 5 });
const f = reactive({}); const error = ref(''); const cargar = () => Object.assign(f, { nombre: u.value.nombre, usuario: u.value.usuario, telefono: u.value.telefono || '', especialidad: m.value.especialidad || '' }); if (m.value) cargar();
function guardar() { const r = W.editarMecanico(m.value.id, f); if (!r.ok) { error.value = r.error; return; } error.value = ''; toast('Datos guardados.'); }
async function cuenta() { const activa = u.value.estado === 'activo'; if (activa && W.trabajosActivosDe(m.value.id) && !(await confirmar({ mensaje: 'Tiene trabajos activos. ¿Desactivar igual la cuenta?', ok: 'Desactivar' }))) return; W.alternarCuentaMecanico(m.value.id); }
const router = useRouter();
async function borrar() { if (!(await confirmar({ mensaje: `¿Eliminar la cuenta de ${u.value.nombre}?`, ok: 'Eliminar', cls: 'pel' }))) return; const r = W.eliminarMecanico(m.value.id); if (!r.ok) { toast(r.error, 'error'); return; } toast('Mecánico eliminado.'); router.replace('/mecanicos'); }
async function reset() { if (await confirmar({ mensaje: '¿Restablecer la contraseña de este mecánico?', ok: 'Restablecer' })) { const r = W.resetClaveMecanico(m.value.id); mostrarClave('Contraseña temporal', r.usuario, r.clave); } }
</script>
<template>
  <template v-if="m">
    <PageHeader :titulo="u.nombre" subtitulo="Ficha del mecánico"><button class="btn sec chico" type="button" @click="W.alternarDisponibilidad(m.id)">{{ m.disponible ? 'Marcar no disponible' : 'Marcar disponible' }}</button><button class="btn sec chico" type="button" @click="cuenta">{{ u.estado === 'activo' ? 'Desactivar cuenta' : 'Activar cuenta' }}</button><button class="btn sec chico" type="button" @click="reset">Restablecer contraseña</button><button class="btn pel chico" type="button" @click="borrar">Eliminar</button></PageHeader>
    <div class="card"><form novalidate @submit.prevent="guardar"><div class="form-grid"><FormField v-model="f.nombre" label="Nombre" req /><FormField v-model="f.usuario" label="Usuario" hint="No se puede cambiar." /><FormField v-model="f.telefono" label="Teléfono" /><FormField v-model="f.especialidad" label="Especialidad" /></div><div class="msg-err" role="alert">{{ error }}</div><button class="btn">Guardar</button></form></div>
    <h2>Trabajos asignados</h2><div v-if="ords.length" class="card tight"><router-link v-for="o in pag.items" :key="o.id" class="linea" :to="'/trabajos/' + o.id"><span class="f">{{ o.numero }}</span><span style="flex:1">{{ o.descripcion.slice(0, 90) }}</span><StatusTag tipo="orden" :valor="o.estado" /></router-link><PaginationBar :pag="pag" /></div><p v-else class="hint">Sin trabajos asignados.</p>
  </template>
  <EmptyState v-else icono="user" titulo="Mecánico no encontrado" mensaje="No existe o no pertenece a tu taller."><router-link class="btn" to="/mecanicos">Volver</router-link></EmptyState>
</template>
