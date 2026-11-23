<script setup>
import PaginationBar from '../../components/PaginationBar.vue'; import { usePaginacion } from '../../composables/usePaginacion.js';
import { computed, reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import AppModal from '../../components/AppModal.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue';
import { db, get } from '../../services/storageService.js'; import { usuario } from '../../services/authService.js'; import { claveTemporal } from '../../services/authService.js';
import { estadoTaller, crearCuenta, importeDe } from '../../services/subscriptionService.js'; import { mostrarClave } from '../../services/uiService.js';
import { vUsuario, vTelefono, vEmail } from '../../utils/validators.js'; import { hoy, addMeses, fecha } from '../../utils/dates.js'; import { norm } from '../../utils/formatters.js';
const route = useRoute(); const router = useRouter(); const f = computed(() => route.query.f || ''); const q = ref('');
const lista = computed(() => db.talleres.filter((t) => { const e = estadoTaller(t.id); const m = !q.value || norm(`${t.nombre} ${get('usuarios', t.dueno_id).nombre}`).includes(norm(q.value)); const k = { '': true, activas: t.estado === 'activo', suspendidas: t.estado === 'suspendido', porvencer: e.estado === 'proximo', morosas: ['vencido', 'gracia', 'bloqueado'].includes(e.estado) }[f.value]; return m && k; }));
const abierto = ref(false); const error = ref(''); const d = reactive({});
function abrir() { if (db.talleres.length) return; Object.assign(d, { nombre: '', usuario: '', taller: '', telefono: '', email: '', modalidad: 'mensual', inicio: hoy() }); error.value = ''; abierto.value = true; }
const existe = computed(() => db.talleres.length >= 1);
function crear() {
  const e = (!d.nombre || !d.taller ? 'Completá el nombre del dueño y del taller.' : '') || vUsuario(d.usuario) || (d.telefono ? vTelefono(d.telefono) : '') || vEmail(d.email) || (db.usuarios.some((u) => u.usuario.toLowerCase() === d.usuario.toLowerCase()) ? 'Ese usuario ya existe.' : '');
  if (e) { error.value = e; return; }
  const clave = claveTemporal(); const r = crearCuenta(usuario.value, d, clave); if (!r.ok) { error.value = r.error; return; } abierto.value = false; mostrarClave('Cuenta de dueño creada', r.dueno.usuario, clave); router.push('/superadmin/cuentas/' + r.taller.id);
}
const pag = usePaginacion(() => lista.value, { reiniciarCon: () => [q.value, f.value] });
</script>
<template>
  <PageHeader titulo="Cuenta del taller" subtitulo="El sistema administra un único taller"><button v-if="!existe" class="btn" type="button" @click="abrir">Crear cuenta</button></PageHeader>
  <div v-if="existe" class="hint">Ya existe la cuenta de Taller Matienzo. No se pueden crear otras cuentas de taller.</div>
  <div class="filtros"><div class="campo" style="margin:0"><label>Buscar</label><input v-model="q" placeholder="Taller o dueño" /></div><div class="campo" style="margin:0"><label>Filtro</label><select :value="f" @change="router.replace({ query: $event.target.value ? { f: $event.target.value } : {} })"><option value="">Todas</option><option value="activas">Activas</option><option value="suspendidas">Suspendidas</option><option value="porvencer">Por vencer</option><option value="morosas">Vencidas o bloqueadas</option></select></div></div>
  <div v-if="lista.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Taller</th><th>Dueño</th><th>Vence</th><th>Suscripción</th><th>Cuenta</th></tr></thead><tbody>
    <tr v-for="t in pag.items" :key="t.id" class="click" @click="router.push('/superadmin/cuentas/' + t.id)"><td data-l="Taller"><b>{{ t.nombre }}</b></td><td data-l="Dueño">{{ get('usuarios', t.dueno_id).nombre }}</td><td data-l="Vence">{{ fecha(estadoTaller(t.id).vencimiento) }}</td><td data-l="Suscripción"><StatusTag tipo="sub" :valor="estadoTaller(t.id).estado" /></td><td data-l="Cuenta"><span class="tag" :class="t.estado === 'activo' ? 't-ok' : 't-err'">{{ t.estado === 'activo' ? 'Activa' : 'Suspendida' }}</span></td></tr></tbody></table></div>
  <PaginationBar v-if="lista.length" :pag="pag" />
  <EmptyState v-else icono="users" titulo="No hay cuentas para mostrar" mensaje="Probá con otro filtro o creá la cuenta del taller." />
  <AppModal v-if="abierto" titulo="Crear cuenta de dueño" :ancho="760" @cerrar="abierto = false"><form id="fc" novalidate @submit.prevent="crear"><div class="form-grid"><FormField v-model="d.nombre" label="Nombre del dueño" req /><FormField v-model="d.usuario" label="Usuario" req /><FormField v-model="d.taller" label="Nombre del taller" req /><FormField v-model="d.telefono" label="Teléfono" /><FormField v-model="d.email" label="Correo" /><FormField v-model="d.modalidad" label="Modalidad" type="select" :opciones="[['mensual', 'Mensual'], ['anual', 'Anual']]" /><FormField v-model="d.inicio" label="Inicio" type="date" /></div><p class="hint">Se genera una contraseña temporal que se muestra una sola vez; el dueño deberá cambiarla al ingresar.</p><div class="msg-err" role="alert">{{ error }}</div></form><template #pie><button class="btn sec" type="button" @click="abierto = false">Cancelar</button><button class="btn" type="submit" form="fc">Crear cuenta</button></template></AppModal>
</template>
