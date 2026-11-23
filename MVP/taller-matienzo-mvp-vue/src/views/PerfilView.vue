<script setup>
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import PageHeader from '../components/PageHeader.vue'; import FormField from '../components/FormField.vue'; import AppIcon from '../components/AppIcon.vue';
import { usuario, rol, taller, cambiarClave, esSuperAdmin } from '../services/authService.js';
import { vClaveNueva } from '../utils/validators.js';
import { toast } from '../services/uiService.js';
const router = useRouter();
const f = reactive({ actual: '', nueva: '', repetir: '' }); const error = ref('');
const rolTxt = { superadmin: 'SuperAdmin', admin: 'Dueño (Admi)', mecanico: 'Mecánico' };
function guardar() {
  error.value = '';
  if (!usuario.value.debe_cambiar_clave && !f.actual) { error.value = 'Escribí tu contraseña actual.'; return; }
  const e = vClaveNueva(f.nueva); if (e) { error.value = e; return; }
  if (f.nueva !== f.repetir) { error.value = 'Las contraseñas nuevas no coinciden.'; return; }
  const r = cambiarClave(f.actual, f.nueva); if (!r.ok) { error.value = r.error; return; }
  toast('Contraseña actualizada.'); router.push(esSuperAdmin.value ? '/superadmin' : '/');
}
</script>
<template>
  <PageHeader titulo="Mi perfil" subtitulo="Datos de tu cuenta" />
  <div v-if="usuario.debe_cambiar_clave" class="hint warn"><b>Tenés una contraseña temporal.</b> Cambiala ahora para continuar.</div>
  <div class="grid g2">
    <div class="card"><h2>Mis datos</h2><div class="dl"><div><span>Nombre</span><b>{{ usuario.nombre }}</b></div><div><span>Usuario</span><b>{{ usuario.usuario }}</b></div><div><span>Rol</span><b>{{ rolTxt[rol] }}</b></div><div v-if="taller"><span>Taller</span><b>{{ taller.nombre }}</b></div><div><span>Teléfono</span><b>{{ usuario.telefono || '—' }}</b></div></div></div>
    <div class="card"><h2>Cambiar contraseña</h2>
      <form novalidate @submit.prevent="guardar">
        <FormField v-if="!usuario.debe_cambiar_clave" v-model="f.actual" label="Contraseña actual" type="password" req autocomplete="current-password" />
        <FormField v-model="f.nueva" label="Contraseña nueva" type="password" req autocomplete="new-password" hint="Mínimo 8 caracteres, con letras y números." />
        <FormField v-model="f.repetir" label="Repetí la contraseña nueva" type="password" req autocomplete="new-password" />
        <div class="msg-err" role="alert">{{ error }}</div><button class="btn"><AppIcon name="key" /> Guardar contraseña</button>
      </form></div>
  </div>
</template>
