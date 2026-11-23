<script setup>
import { useId } from 'vue';
const p = defineProps({ label: String, modelValue: [String, Number], type: { type: String, default: 'text' }, opciones: Array, req: Boolean, placeholder: String, hint: String, rows: { type: Number, default: 3 }, min: [String, Number], step: [String, Number], autocomplete: { type: String, default: 'off' }, name: String });
const emit = defineEmits(['update:modelValue', 'change']);
const id = 'f' + useId();
const val = (e) => emit('update:modelValue', e.target.value);
</script>
<template>
  <div class="campo">
    <label :for="id">{{ label }}<template v-if="req"> *</template></label>
    <select v-if="type === 'select'" :id="id" :name="name" :value="modelValue" @change="val($event); emit('change', $event.target.value)">
      <option v-for="o in opciones" :key="Array.isArray(o) ? o[0] : o" :value="Array.isArray(o) ? o[0] : o">{{ Array.isArray(o) ? o[1] : o }}</option>
    </select>
    <textarea v-else-if="type === 'textarea'" :id="id" :name="name" :rows="rows" :value="modelValue" :placeholder="placeholder" @input="val"></textarea>
    <input v-else :id="id" :name="name" :type="type" :value="modelValue" :placeholder="placeholder" :min="min" :step="step" :autocomplete="autocomplete" @input="val" @change="emit('change', $event.target.value)" />
    <small v-if="hint">{{ hint }}</small>
  </div>
</template>
