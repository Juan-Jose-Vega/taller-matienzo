<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import AppIcon from './AppIcon.vue';
import { usuario, rol, salir } from '../services/authService.js';
import { delUsuario, noLeidas, marcarLeida, marcarTodas } from '../services/notificationService.js';
import { ui, alternarTema } from '../services/uiService.js';
import { fecha } from '../utils/dates.js';
const p = defineProps({ variante: { type: String, default: 'taller' } });
const router = useRouter();
const sa = computed(() => p.variante === 'superadmin');
const base = computed(() => (sa.value ? '/superadmin' : '/'));
const lista = computed(() => delUsuario(usuario.value).slice(0, 25));
const rolTxt = computed(() => ({ superadmin: 'SuperAdmin', admin: 'Dueño', mecanico: 'Mecánico' }[rol.value]));
function abrir(n) { marcarLeida(n.id); ui.bell = false; router.push(n.ruta || base.value); }
function cerrarSesion() { const sup = sa.value; salir(); ui.bell = false; router.replace(sup ? '/superadmin/login' : '/login'); }
</script>
<template>
  <header class="top" :class="{ sa }">
    <router-link :to="base" class="marca" aria-label="Ir al inicio"><span class="logo"><AppIcon :name="sa ? 'shield' : 'car'" /></span>{{ sa ? 'Administración' : 'Taller Matienzo' }}<span v-if="sa" class="sa-chip">PLATAFORMA</span></router-link>
    <span class="esp"></span>
    <router-link :to="base" class="btn-top" title="Menú principal"><AppIcon name="home" /><span class="txt-btn">Inicio</span></router-link>
    <button class="btn-top" type="button" title="Notificaciones" aria-label="Notificaciones" @click="ui.bell = !ui.bell"><AppIcon name="bell" /><span v-if="noLeidas(usuario)" class="badge-n">{{ noLeidas(usuario) }}</span></button>
    <button class="btn-top" type="button" title="Cambiar entre modo claro y oscuro" aria-label="Cambiar tema" @click="alternarTema"><AppIcon :name="ui.tema === 'oscuro' ? 'sun' : 'moon'" /></button>
    <router-link :to="sa ? '/superadmin/perfil' : '/perfil'" class="btn-top" title="Mi perfil"><span class="ic-user"><AppIcon name="user" /></span><span class="quien"><b>{{ usuario.nombre }}</b><span>{{ rolTxt }}</span></span></router-link>
    <button class="btn-top" type="button" title="Cerrar sesión" @click="cerrarSesion"><AppIcon name="logout" /><span class="txt-btn">Salir</span></button>
    <div v-if="ui.bell" class="panel-notif" id="panel-notif">
      <header><span>Notificaciones</span><button class="btn sec chico" type="button" @click="marcarTodas(usuario)">Marcar todas como leídas</button></header>
      <template v-if="lista.length"><button v-for="n in lista" :key="n.id" class="notif-item" :class="{ nueva: !n.leida }" type="button" @click="abrir(n)">{{ n.texto }}<small>{{ fecha(n.created_at) }}{{ n.leida ? '' : ' · nueva' }}</small></button></template>
      <p v-else class="vacio">No tenés notificaciones.</p>
      <router-link class="notif-item" :to="sa ? '/superadmin/notificaciones' : '/notificaciones'" @click="ui.bell = false"><b>Ver todas</b></router-link>
    </div>
  </header>
</template>
