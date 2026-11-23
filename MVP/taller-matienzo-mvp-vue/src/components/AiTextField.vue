<script setup>
// Campo de texto con "Mejorar redacción". Conserva el texto original, permite comparar, editar, aceptar o descartar.
import { ref } from 'vue';
import AppIcon from './AppIcon.vue'; import AppModal from './AppModal.vue';
import { mejorarTexto, proveedorActivo, registrarPropuesta } from '../services/aiTextService.js';
import { usuario } from '../services/authService.js';
import { toast } from '../services/uiService.js';
const p = defineProps({ label: String, modelValue: String, original: String, ids: { type: Array, default: () => [] }, entidad: String, campo: String, contexto: { type: String, default: 'general' }, rows: { type: Number, default: 3 }, placeholder: String, req: Boolean });
const emit = defineEmits(['update:modelValue', 'update:original', 'update:ids']);
const abierto = ref(false); const cargando = ref(false); const res = ref(null); const edit = ref(''); const verOrig = ref(false);
async function mejorar() {
  cargando.value = true; const r = await mejorarTexto(p.modelValue, { contexto: p.contexto }); cargando.value = false;
  if (!r.ok) { toast(r.error, 'aviso'); return; }
  res.value = r; edit.value = r.propuesta; abierto.value = true;
}
function cerrar(estado) {
  const final = edit.value.trim();
  if (estado !== 'descartada') {
    if (!final) { toast('La propuesta no puede quedar vacía.', 'aviso'); return; }
    const editada = final !== res.value.propuesta;
    const pr = registrarPropuesta({ usuario: usuario.value, entidad: p.entidad || 'consultas', campo: p.campo || 'texto', original: res.value.original, propuesta: res.value.propuesta, final, estado: editada ? 'editada' : 'aceptada' });
    if (!p.original) emit('update:original', res.value.original);
    emit('update:ids', [...p.ids, pr.id]); emit('update:modelValue', final); toast('Texto actualizado. Revisalo y guardá los cambios.');
  } else { registrarPropuesta({ usuario: usuario.value, entidad: p.entidad || 'consultas', campo: p.campo || 'texto', original: res.value.original, propuesta: res.value.propuesta, final: null, estado: 'descartada' }); toast('Propuesta descartada. Se mantiene tu texto.', 'info'); }
  abierto.value = false;
}
const resumen = () => { const c = res.value.cambios; return [['ortografía', c.ortografia], ['tildes', c.tildes], ['puntuación', c.puntuacion], ['mayúsculas', c.mayusculas], ['repeticiones', c.repeticiones], ['redacción', c.redaccion]].filter((x) => x[1]).map((x) => `${x[1]} de ${x[0]}`).join(' · '); };
</script>
<template>
  <div class="campo">
    <label>{{ label }}<template v-if="req"> *</template></label>
    <textarea :rows="rows" :value="modelValue" :placeholder="placeholder" @input="emit('update:modelValue', $event.target.value)"></textarea>
    <div class="fila-btn" style="margin-top:.2rem">
      <button type="button" class="btn sec chico" :disabled="cargando" @click="mejorar"><AppIcon name="spark" /> Mejorar redacción</button>
      <span class="sello-demo" :title="proveedorActivo().descripcion">{{ proveedorActivo().nombre }}</span>
      <button v-if="original && original !== modelValue" type="button" class="btn sec chico" @click="verOrig = true">Ver texto original</button>
    </div>
    <AppModal v-if="abierto" titulo="Mejorar redacción" :ancho="780" @cerrar="cerrar('descartada')">
      <div class="hint warn"><b>Modo local de demostración:</b> {{ proveedorActivo().descripcion }} Solo mejora la forma de expresar lo que escribiste; <b>no agrega causas ni diagnósticos</b>.</div>
      <div v-if="res.sinCambios" class="hint ok">El texto ya está bien redactado: no hay cambios para proponer.</div>
      <div class="comparar">
        <div><h3>Texto original</h3><p style="white-space:pre-wrap;margin:0">{{ res.original }}</p></div>
        <div><h3>Propuesta (podés editarla)</h3><textarea v-model="edit" rows="5"></textarea></div>
      </div>
      <p v-if="resumen()" class="cambios"><b>Qué se corrigió:</b> {{ resumen() }}.</p>
      <ul v-if="res.detalles.filter((d) => d.de).length" class="cambios"><li v-for="(d, i) in res.detalles.filter((x) => x.de)" :key="i">«{{ d.de }}» → «{{ d.a || '(se quitó)' }}»</li></ul>
      <p class="hint" style="margin-top:.8rem">Solo se usa la versión corregida si la aceptás. El texto original queda guardado para poder compararlo.</p>
      <template #pie><button class="btn sec" type="button" @click="cerrar('descartada')">Descartar</button><button class="btn ok" type="button" @click="cerrar('aceptada')"><AppIcon name="check" /> Aceptar propuesta</button></template>
    </AppModal>
    <AppModal v-if="verOrig" titulo="Texto original" @cerrar="verOrig = false"><p style="white-space:pre-wrap">{{ original }}</p><template #pie><button class="btn sec" type="button" @click="verOrig = false">Cerrar</button></template></AppModal>
  </div>
</template>
