<script setup>
// Acceso independiente de la administración de la plataforma (#/superadmin/login). No se enlaza desde el login del taller.
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import AppIcon from '../../components/AppIcon.vue';
import { ingresarSuperAdmin } from '../../services/authService.js';
import { sincronizar } from '../../services/subscriptionService.js';
const router = useRouter();
const f = reactive({ usuario: '', clave: '' }); const error = ref(''); const campo = ref(''); const ver = ref(false);
function entrar() {
  error.value = ''; campo.value = '';
  const r = ingresarSuperAdmin(f.usuario.trim(), f.clave);
  if (!r.ok) { error.value = r.error; campo.value = r.campo || ''; return; }
  sincronizar(); router.replace('/superadmin');
}
</script>
<template>
  <div class="login login-sa"><div class="login-card">
    <section>
      <div class="logo-g" style="background:#2a2a35"><AppIcon name="shield" /></div><h1>Administración de la plataforma</h1>
      <p style="color:var(--txt-2);margin-top:0">Acceso restringido a administradores generales.</p>
      <form novalidate @submit.prevent="entrar">
        <div class="campo" :class="{ err: campo === 'usuario' }"><label for="su">Usuario</label><input id="su" v-model="f.usuario" autocomplete="username" autofocus /></div>
        <div class="campo" :class="{ err: campo === 'clave' }"><label for="sc">Contraseña</label>
          <div class="pass-box"><input id="sc" v-model="f.clave" :type="ver ? 'text' : 'password'" autocomplete="current-password" /><button type="button" aria-label="Mostrar u ocultar contraseña" @click="ver = !ver"><AppIcon :name="ver ? 'eyeoff' : 'eye'" /></button></div></div>
        <div class="msg-err" role="alert" id="sa-login-error">{{ error }}</div>
        <button class="btn" style="width:100%;margin-top:.6rem">Ingresar</button>
      </form>
      <p class="hint warn" style="margin-top:1rem;font-size:.82rem">Demostración sin servidor: este control de acceso es una simulación del frontend, no seguridad real.</p>
    </section>
  </div></div>
</template>
