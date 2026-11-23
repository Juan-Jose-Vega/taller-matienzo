// Etiquetas y colores de los estados (coinciden con los ENUM de la base de datos).
export const ESTADOS = {
  orden: { sin_asignar: ['Sin asignar', 't-gris'], pendiente_aceptacion: ['Pendiente de aceptación', 't-warn'], aceptado: ['Aceptado', 't-info'], en_proceso: ['En proceso', 't-warn'], finalizado: ['Finalizado', 't-ok'], cancelado: ['Cancelado', 't-err'] },
  consulta: { pendiente: ['Pendiente', 't-warn'], en_presupuesto: ['Con presupuesto', 't-info'], aprobada: ['Aprobada (con trabajo)', 't-ok'], cerrada: ['Finalizada sin trabajo', 't-gris'] },
  presupuesto: { borrador: ['Borrador', 't-gris'], pendiente: ['Pendiente de aceptación', 't-warn'], aceptado: ['Aceptado', 't-ok'], rechazado: ['Rechazado', 't-err'], vencido: ['Vencido', 't-gris'] },
  pagoSis: { pendiente: ['Pendiente de confirmación', 't-warn'], registrado: ['Registrado', 't-info'], confirmado: ['Confirmado', 't-ok'], rechazado: ['Rechazado', 't-err'] },
  sub: { vigente: ['Vigente', 't-ok'], proximo: ['Próximo a vencer', 't-info'], vencido: ['Vencido', 't-warn'], gracia: ['En período de gracia', 't-warn'], bloqueado: ['Bloqueado por falta de pago', 't-err'], suspendida: ['Cuenta suspendida', 't-err'] },
};
export const estTxt = (tipo, k) => ((ESTADOS[tipo] || {})[k] || [k])[0];
export const estCls = (tipo, k) => ((ESTADOS[tipo] || {})[k] || [k, 't-gris'])[1];
export const MEDIOS = { efectivo: 'Efectivo', transferencia: 'Transferencia', mercadopago: 'Mercado Pago', combinado: 'Pago combinado' };
export const TIPOS_DETALLE = [['mano_obra', 'Mano de obra'], ['repuesto', 'Repuesto'], ['servicio', 'Servicio adicional'], ['otro', 'Otro']];
