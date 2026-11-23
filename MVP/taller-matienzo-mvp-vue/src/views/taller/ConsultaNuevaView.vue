<script setup>
import { reactive, ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../../components/PageHeader.vue'; import FormField from '../../components/FormField.vue'; import AiTextField from '../../components/AiTextField.vue';
import { coincidencias, crearConsulta, getMine, vehiculosDe } from '../../services/workshopService.js';
import { vincularPropuestas } from '../../services/aiTextService.js';
import { toast } from '../../services/uiService.js';
const route = useRoute(); const router = useRouter();
const f = reactive({ nombre: '', telefono: '', marca: '', modelo: '', anio: '', patente: '', km: '', problema: '', problema_original: '', observaciones: '', cliente_id: null, vehiculo_id: null });
const ids = ref([]); const error = ref('');
const pre = route.query.cliente ? getMine('clientes', Number(route.query.cliente)) : null;
if (pre) { Object.assign(f, { nombre: pre.nombre, telefono: pre.telefono, cliente_id: pre.id }); const v = route.query.vehiculo ? vehiculosDe(pre.id).find((x) => x.id === Number(route.query.vehiculo)) : null; if (v) usarVeh(v); }
function usarVeh(v) { Object.assign(f, { marca: v.marca, modelo: v.modelo, anio: v.anio || '', patente: v.patente || '', km: v.km || '', vehiculo_id: v.id }); }
const coinc = computed(() => (f.cliente_id ? [] : coincidencias(f.nombre, f.telefono, f.patente)));
function usarCliente(c, v) { Object.assign(f, { nombre: c.cliente.nombre, telefono: c.cliente.telefono, cliente_id: c.cliente.id }); if (v) usarVeh(v); }
function limpiarVinculo() { f.cliente_id = null; f.vehiculo_id = null; }
function guardar() {
  error.value = ''; const r = crearConsulta(f); if (!r.ok) { error.value = r.error; return; }
  vincularPropuestas(ids.value, 'consultas', r.consulta.id); toast('Consulta registrada.'); router.replace('/consultas/' + r.consulta.id);
}
</script>
<template>
  <PageHeader titulo="Nueva consulta" subtitulo="Registrala en segundos: lo esencial primero" />
  <form class="card" novalidate @submit.prevent="guardar">
    <div v-if="coinc.length" class="coinc"><b>¿Es alguno de estos clientes?</b>
      <div v-for="c in coinc" :key="c.cliente.id" class="it"><span>{{ c.cliente.nombre }} · {{ c.cliente.telefono }}</span><span class="fila-btn" style="margin:0"><button class="btn sec chico" type="button" @click="usarCliente(c)">Usar este cliente</button><button v-for="v in c.vehiculos" :key="v.id" class="btn sec chico" type="button" @click="usarCliente(c, v)">{{ v.marca }} {{ v.modelo }} ({{ v.patente }})</button></span></div></div>
    <div v-if="f.cliente_id" class="hint ok">Cliente existente seleccionado. <button class="txt-btn" type="button" @click="limpiarVinculo">Cambiar</button></div>
    <div class="form-grid"><FormField v-model="f.nombre" label="Nombre y apellido" req /><FormField v-model="f.telefono" label="Teléfono" req type="tel" /><FormField v-model="f.marca" label="Marca" req /><FormField v-model="f.modelo" label="Modelo" req /><FormField v-model="f.anio" label="Año" type="number" /><FormField v-model="f.patente" label="Patente" placeholder="AB123CD" /><FormField v-model="f.km" label="Kilometraje" type="number" /></div>
    <AiTextField v-model="f.problema" v-model:original="f.problema_original" v-model:ids="ids" label="Problema que informa el cliente" req entidad="consultas" campo="problema" contexto="problema" :rows="4" placeholder="Ej.: el auto hace un ruido cuando freno y parece que vibra todo" />
    <FormField v-model="f.observaciones" label="Observaciones (opcional)" type="textarea" />
    <div class="msg-err" role="alert">{{ error }}</div>
    <div class="fila-btn"><button class="btn">Guardar consulta</button><router-link class="btn sec" to="/consultas">Cancelar</router-link></div>
  </form>
</template>
