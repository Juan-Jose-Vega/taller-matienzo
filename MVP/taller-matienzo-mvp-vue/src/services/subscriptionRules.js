// Reglas PURAS de suscripción (sin base de datos): estado, avisos y renovación. Es el único lugar donde se calcula el estado.
import { diffDias, fecha, addDias, addMeses } from '../utils/dates.js';
import { plural } from '../utils/formatters.js';

export const LABELS = { vigente: 'Vigente', proximo: 'Próximo a vencer', vencido: 'Vencido', gracia: 'En período de gracia', bloqueado: 'Bloqueado por falta de pago', suspendida: 'Cuenta suspendida' };
export const TAG_SUB = { vigente: 't-ok', proximo: 't-info', vencido: 't-warn', gracia: 't-warn', bloqueado: 't-err', suspendida: 't-err' };

export function estadoSuscripcion({ vencimiento, hoy, suspendida = false, gracia = 3, aviso = 7 }) {
  const dias = diffDias(hoy, vencimiento); const atraso = dias < 0 ? -dias : 0;
  let estado; let msg; let nivel;
  if (suspendida) { estado = 'suspendida'; msg = 'La cuenta está suspendida. Comunicate con el administrador del sistema.'; nivel = 'err'; }
  else if (dias > aviso) { estado = 'vigente'; msg = `Tu plan vence el ${fecha(vencimiento)}.`; nivel = 'ok'; }
  else if (dias > 1) { estado = 'proximo'; msg = `Faltan ${dias} días para que venza tu plan.`; nivel = 'info'; }
  else if (dias === 1) { estado = 'proximo'; msg = 'Tu plan vence mañana.'; nivel = 'warn'; }
  else if (dias === 0) { estado = 'proximo'; msg = 'Tu plan vence hoy.'; nivel = 'warn'; }
  else if (atraso === 1) { estado = 'vencido'; msg = `Tu plan está vencido. Tenés ${gracia} días para regularizar el pago.`; nivel = 'warn'; }
  else if (atraso <= gracia) {
    const quedan = gracia - atraso + 1;
    estado = 'gracia'; nivel = 'warn';
    msg = `Pago pendiente: pasaron ${atraso} días desde el vencimiento. ` + (quedan === 1 ? 'Hoy es el último día para regularizar.' : `Te quedan ${quedan} días para regularizar.`);
  } else { estado = 'bloqueado'; msg = 'Tu acceso está restringido por falta de pago. Podés consultar tu situación y registrar el pago.'; nivel = 'err'; }
  return { estado, label: LABELS[estado], dias, atraso, msg, nivel, vencimiento, bloqueado: estado === 'bloqueado' || estado === 'suspendida' };
}
// Hito de aviso (para no repetir notificaciones): devuelve null si no corresponde avisar
export function hitoAviso(e, aviso = 7) {
  if (e.estado === 'vigente' || e.estado === 'suspendida') return null;
  if (e.estado === 'bloqueado') return 'bloqueado';
  if (e.estado === 'vencido' || e.estado === 'gracia') return 'vencido';
  if (e.dias === 0) return 'hoy'; if (e.dias === 1) return '1d'; if (e.dias <= 3) return '3d'; if (e.dias <= aviso) return '7d';
  return null;
}
// Renovación: se continúa desde el vencimiento anterior; si ya estaba BLOQUEADO el nuevo período empieza hoy.
export function renovar({ inicio, vencimiento, diaAncla, duracionMeses, bloqueado, hoy }) {
  const base = bloqueado ? hoy : vencimiento;
  const ancla = base === hoy && bloqueado ? Number(hoy.slice(8, 10)) : (diaAncla || Number(inicio.slice(8, 10)));
  return { inicio: base, vencimiento: addMeses(base, duracionMeses, ancla), diaAncla: ancla };
}
export const textoDias = (e) => (e.dias >= 0 ? `Vence en ${plural(e.dias, 'día', 'días')}` : `Vencida hace ${plural(e.atraso, 'día', 'días')}`);
export { addDias };
