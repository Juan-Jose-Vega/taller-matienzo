<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue';
import { mecanicosDelTaller, nombreMecanico, trabajosActivosDe, crearMecanico } from '../../services/workshopService.js'; import { get } from '../../services/storageService.js'; import { mostrarClave, toast } from '../../services/uiService.js';
const router = useRouter(); const lista = computed(() => mecanicosDelTaller()); const abierto = ref(false); const f = reactive({ nombre: '', usuario: '', telefono: '', especialidad: '' }); const error = ref('');
function crear() { const r = crearMecanico(f); if (!r.ok) { error.value = r.error; return; } abierto.value = false; mostrarClave('Cuenta creada', r.usuario.usuario, r.clave); Object.assign(f, { nombre: '', usuario: '', telefono: '', especialidad: '' }); }
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [lista.value.length] });
</script>
<template>
  <PageHeader titulo="Mecánicos" subtitulo="Cuentas, disponibilidad y carga de trabajo"><button class="btn" type="button" @click="abierto = true; error = ''">Agregar mecánico</button></PageHeader>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Mecánico</th><th>Usuario</th><th>Cuenta</th><th>Disponible</th><th>Trabajos activos</th></tr></thead><tbody>
    <tr v-for="m in pag.items" :key="m.id" class="click" @click="router.push('/mecanicos/' + m.id)"><td data-l="Mecánico"><b>{{ nombreMecanico(m.id) }}</b></td><td data-l="Usuario">{{ get('usuarios', m.usuario_id).usuario }}</td><td data-l="Cuenta"><span class="tag" :class="get('usuarios', m.usuario_id).estado === 'activo' ? 't-ok' : 't-gris'">{{ get('usuarios', m.usuario_id).estado === 'activo' ? 'Activa' : 'Inactiva' }}</span></td><td data-l="Disponible">{{ m.disponible ? 'Sí' : 'No' }}</td><td data-l="Trabajos activos">{{ trabajosActivosDe(m.id) }}</td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="user" titulo="Todavía no hay mecánicos" mensaje="Creá la cuenta del primero." />
  <AppModal v-if="abierto" titulo="Agregar mecánico" @cerrar="abierto = false"><form id="fm" novalidate @submit.prevent="crear"><FormField v-model="f.nombre" label="Nombre y apellido" req /><FormField v-model="f.usuario" label="Usuario" req hint="Letras y números, sin espacios." /><FormField v-model="f.telefono" label="Teléfono" /><FormField v-model="f.especialidad" label="Especialidad" /><div class="msg-err" role="alert">{{ error }}</div><p class="hint">Se genera una contraseña temporal que se muestra una sola vez.</p></form><template #pie><button class="btn sec" type="button" @click="abierto = false">Cancelar</button><button class="btn" type="submit" form="fm">Crear cuenta</button></template></AppModal>
</template>
