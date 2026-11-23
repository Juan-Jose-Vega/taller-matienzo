<script setup>
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import StatusTag from '../../components/StatusTag.vue'; import FormField from '../../components/FormField.vue'; import EmptyState from '../../components/EmptyState.vue';
import { db, get } from '../../services/storageService.js'; import { usuario, restablecerClave } from '../../services/authService.js';
import * as S from '../../services/subscriptionService.js'; import { confirmar, mostrarClave, toast } from '../../services/uiService.js';
import { money } from '../../utils/formatters.js'; import { fecha } from '../../utils/dates.js'; import { textoDias } from '../../services/subscriptionRules.js';
const route = useRoute(); const t = computed(() => get('talleres', Number(route.params.id))); const dueno = computed(() => get('usuarios', t.value.dueno_id));
const e = computed(() => S.estadoTaller(t.value.id)); const s = computed(() => S.suscripcionDe(t.value.id));
const pagos = computed(() => db.pagos_suscripcion.filter((p) => p.taller_id === t.value.id).sort((a, b) => b.id - a.id));
const periodos = computed(() => db.periodos_suscripcion.filter((p) => p.suscripcion_id === s.value.id).sort((a, b) => b.id - a.id));
const fd = reactive({}); const fs = reactive({}); const fp = reactive({ medio: 'efectivo', referencia: '', efectivo: '', transferencia: '' }); const e1 = ref(''); const e2 = ref(''); const e3 = ref('');
function cargar() { if (!t.value) return; Object.assign(fd, { nombre: dueno.value.nombre, taller: t.value.nombre, telefono: dueno.value.telefono || '', email: dueno.value.email || '' }); Object.assign(fs, { modalidad: s.value.modalidad, inicio: s.value.fecha_inicio }); } cargar();
function gd() { const r = S.editarCuenta(usuario.value, t.value.id, fd); e1.value = r.ok ? '' : r.error; if (r.ok) toast('Datos guardados.'); }
function gs() { const r = S.guardarSuscripcion(usuario.value, t.value.id, fs); e2.value = r.ok ? '' : r.error; if (r.ok) toast('Suscripción actualizada.'); }
const venc = computed(() => (fs.inicio ? S.vencimientoDe(fs.inicio, fs.modalidad) : null));
async function alternar() { const act = t.value.estado === 'activo'; if (await confirmar({ mensaje: act ? '¿Suspender la cuenta? El dueño y sus mecánicos no podrán usar el taller.' : '¿Reactivar la cuenta?', ok: act ? 'Suspender' : 'Reactivar', cls: act ? 'pel' : '' })) { S.suspenderOReactivar(usuario.value, t.value.id); toast(act ? 'Cuenta suspendida.' : 'Cuenta reactivada.'); } }
async function reset() { if (await confirmar({ mensaje: '¿Restablecer la contraseña del dueño?', ok: 'Restablecer' })) { const c = restablecerClave(dueno.value.id); mostrarClave('Contraseña temporal', dueno.value.usuario, c); } }
function registrar() { const r = S.registrarPagoSA(usuario.value, t.value.id, fp); e3.value = r.ok ? '' : r.error; if (r.ok) toast('Pago registrado. Falta confirmarlo.'); }
const mt = (p) => S.mediosDePago(p.id).map((m) => `${get('medios_pago', m.medio_id).nombre} ${money(m.importe)}`).join(' + ');
</script>
<template>
  <template v-if="t">
    <PageHeader :titulo="t.nombre" :subtitulo="`Dueño: ${dueno.nombre} (${dueno.usuario})`"><StatusTag tipo="sub" :valor="e.estado" /><button class="btn sec chico" type="button" @click="alternar">{{ t.estado === 'activo' ? 'Suspender cuenta' : 'Reactivar cuenta' }}</button><button class="btn sec chico" type="button" @click="reset">Restablecer contraseña</button></PageHeader>
    <div class="hint" :class="e.nivel === 'err' ? 'err' : e.nivel === 'warn' ? 'warn' : 'ok'">{{ textoDias(e) }} · vence el {{ fecha(e.vencimiento) }}</div>
    <div class="grid g2">
      <div class="card"><h2>Datos de la cuenta</h2><form novalidate @submit.prevent="gd"><FormField v-model="fd.nombre" label="Nombre del dueño" req /><FormField v-model="fd.taller" label="Taller" req /><FormField v-model="fd.telefono" label="Teléfono" /><FormField v-model="fd.email" label="Correo" /><div class="msg-err" role="alert">{{ e1 }}</div><button class="btn">Guardar datos</button></form></div>
      <div class="card"><h2>Suscripción</h2><form novalidate @submit.prevent="gs"><FormField v-model="fs.modalidad" label="Modalidad" type="select" :opciones="[['mensual', 'Mensual'], ['anual', 'Anual']]" /><p class="hint">Plan único. Importe de la modalidad elegida: <b>{{ money(S.importeDe(fs.modalidad)) }}</b>. Tolerancia: 3 días corridos después del vencimiento.</p><FormField v-model="fs.inicio" label="Inicio del período" type="date" /><p>Vencimiento calculado: <b>{{ venc ? fecha(venc) : '—' }}</b></p><div class="msg-err" role="alert">{{ e2 }}</div><button class="btn">Guardar suscripción</button></form></div>
    </div>
    <div class="card"><h2>Registrar un pago</h2><form novalidate @submit.prevent="registrar"><p>Importe del plan ({{ S.textoModalidad(s.modalidad) }}): <b>{{ money(s.importe) }}</b>. Queda «registrado» hasta que lo confirmes en Pagos del sistema.</p><FormField v-model="fp.medio" label="Medio" type="select" :opciones="[['efectivo', 'Efectivo'], ['transferencia', 'Transferencia'], ['combinado', 'Combinado']]" /><div v-if="fp.medio === 'combinado'" class="form-grid"><FormField v-model="fp.efectivo" label="Efectivo" type="number" /><FormField v-model="fp.transferencia" label="Transferencia" type="number" /></div><FormField v-if="fp.medio !== 'efectivo'" v-model="fp.referencia" label="Referencia" /><div class="msg-err" role="alert">{{ e3 }}</div><button class="btn">Registrar pago</button></form></div>
    <h2>Historial de pagos</h2><div v-if="pagos.length" class="tabla-wrap"><table class="resp"><thead><tr><th>Fecha</th><th>Importe</th><th>Medio</th><th>Origen</th><th>Estado</th><th>Nuevo venc.</th></tr></thead><tbody><tr v-for="p in pagos" :key="p.id"><td data-l="Fecha">{{ fecha(p.fecha) }}</td><td data-l="Importe">{{ money(p.importe) }}</td><td data-l="Medio">{{ mt(p) }}</td><td data-l="Origen">{{ p.origen === 'dueno' ? 'Informado por el dueño' : 'Registrado por el administrador' }}</td><td data-l="Estado"><StatusTag tipo="pagoSis" :valor="p.estado" /></td><td data-l="Nuevo venc.">{{ p.nuevo_vencimiento ? fecha(p.nuevo_vencimiento) : '—' }}</td></tr></tbody></table></div><p v-else class="hint">Sin pagos.</p>
    <h2>Historial de vencimientos</h2><div class="card tight"><div v-for="p in periodos" :key="p.id" class="linea"><span class="f">{{ fecha(p.desde) }}</span><span>vence {{ fecha(p.hasta) }}</span></div></div>
  </template>
  <EmptyState v-else icono="users" titulo="Cuenta no encontrada" mensaje="No existe."><router-link class="btn" to="/superadmin/cuentas">Volver a cuentas</router-link></EmptyState>
</template>
