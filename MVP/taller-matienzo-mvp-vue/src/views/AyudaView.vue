<script setup>
import PageHeader from '../components/PageHeader.vue';
import { rol } from '../services/authService.js';
const guia = { admin: ['Registrá una consulta desde “Nueva consulta”.', 'Completá la revisión técnica y armá el presupuesto.', 'Cuando el cliente acepta, aprobá la consulta: se crea la orden de trabajo y la asignás a un mecánico.', 'Seguí el trabajo, cobralo en “Pagos de clientes” y avisá al cliente por WhatsApp.', 'En “Comisiones” definí el porcentaje de cada trabajo finalizado, registrá la comisión, cargá adelantos y generá la liquidación del período para pagarla.'], mecanico: ['Aceptá o rechazá (con motivo) los trabajos que te asignan.', 'Iniciá el trabajo y registrá avances y repuestos usados.', 'Marcá el trabajo como finalizado: el dueño recibe un aviso.', 'En “Mis comisiones” ves lo que generaste, tus adelantos y tus liquidaciones.'] }[rol.value] || [];
</script>
<template>
  <PageHeader titulo="Ayuda" subtitulo="Pasos básicos y recuperación de cuenta" />
  <div class="card"><h2>Cómo se usa (tu rol)</h2><ol><li v-for="g in guia" :key="g">{{ g }}</li></ol></div>
  <div class="card"><h2>No puedo ingresar</h2><ul><li><b>Mecánico:</b> pedile al dueño que restablezca tu contraseña (te dará una clave temporal que tenés que cambiar).</li><li><b>Dueño:</b> pedile al administrador del sistema que restablezca tu acceso.</li><li>Las contraseñas no se pueden “ver”: solo se restablecen con una clave temporal que se muestra una única vez.</li></ul></div>
  <div class="card"><h2>Contacto del soporte (ejemplo)</h2><p>Correo: soporte@tallermatienzo.example · Teléfono: 381-0000000</p><p class="hint">Esta es una demostración: la información de contacto es ficticia.</p></div>
</template>
