<script setup>
// Login del taller (dueño y mecánico). No contiene ninguna referencia a la administración de la plataforma.
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import AppIcon from '../components/AppIcon.vue';
import { ingresarTaller, usuario } from '../services/authService.js';
import { sincronizar } from '../services/subscriptionService.js';
import { toast, alternarTema } from '../services/uiService.js';
const router = useRouter();
const f = reactive({ usuario: '', clave: '' }); const error = ref(''); const campo = ref(''); const ver = ref(false);
function entrar() {
  error.value = ''; campo.value = '';
  const r = ingresarTaller(f.usuario.trim(), f.clave);
  if (!r.ok) { error.value = r.error; campo.value = r.campo || ''; return; }
  sincronizar(); router.replace('/'); toast(`¡Bienvenido/a, ${usuario.value.nombre}!`);
}
</script>
<template>
  <div class="login"><div class="login-card" style="grid-template-columns:1fr;width:min(460px,100%)">
    <section>
      <div class="logo-g"><AppIcon name="car" /></div><h1>Taller Matienzo</h1>
      <p style="color:var(--txt-2);margin-top:0">Sistema de gestión para un taller mecánico</p>
      <form novalidate @submit.prevent="entrar">
        <div class="campo" :class="{ err: campo === 'usuario' }"><label for="u">Usuario</label><input id="u" v-model="f.usuario" autocomplete="username" autofocus placeholder="Tu usuario" /></div>
        <div class="campo" :class="{ err: campo === 'clave' }"><label for="c">Contraseña</label>
          <div class="pass-box"><input id="c" v-model="f.clave" :type="ver ? 'text' : 'password'" autocomplete="current-password" placeholder="Tu contraseña" /><button type="button" aria-label="Mostrar u ocultar contraseña" @click="ver = !ver"><AppIcon :name="ver ? 'eyeoff' : 'eye'" /></button></div></div>
        <div class="msg-err" role="alert" id="login-error">{{ error }}</div>
        <button class="btn" style="width:100%;margin-top:.6rem">Ingresar</button>
      </form>
      <p style="font-size:.85rem;color:var(--txt-2)">¿Olvidaste tu contraseña? Un mecánico se la pide al dueño; el dueño, al administrador del sistema (se restablece con una clave temporal).</p>
      <button class="btn sec chico" type="button" @click="alternarTema"><AppIcon name="moon" /> Modo claro / oscuro</button>
      <details style="margin-top:1rem;font-size:.85rem"><summary style="cursor:pointer;color:var(--txt-2)">Cuentas de demostración del taller</summary>
        <p class="hint warn" style="margin-top:.5rem">Demo sin servidor: los datos viven en este navegador y estas claves de prueba <b>no son seguridad real</b>.</p>
        <table><tbody><tr><td>Dueño</td><td><code>roberto</code></td><td><code>Dueno123</code></td></tr><tr><td>Mecánico</td><td><code>juan</code></td><td><code>Mecanico123</code></td></tr><tr><td>Mecánico</td><td><code>pedro</code></td><td><code>Mecanico123</code></td></tr><tr><td>Otro dueño</td><td><code>lucia</code></td><td><code>Dueno123</code></td></tr></tbody></table></details>
    </section>
  </div></div>
</template>
