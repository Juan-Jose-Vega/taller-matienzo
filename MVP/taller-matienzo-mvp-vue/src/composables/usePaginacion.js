// Paginación real y reutilizable. Recibe una función que devuelve la lista YA filtrada y entrega solo la página actual.
//  - vuelve a la página 1 cuando cambia una búsqueda o un filtro (reiniciarCon)
//  - corrige la página si la lista se achica (por ejemplo, al eliminar el último registro de la última página)
import { ref, computed, watch, reactive } from 'vue';
export const TAMANOS = [5, 10, 20, 50];
export function usePaginacion(fuente, { porPagina = 10, reiniciarCon = null } = {}) {
  const tamano = ref(TAMANOS.includes(porPagina) ? porPagina : 10);
  const pedida = ref(1);
  const total = computed(() => fuente().length);
  const totalPaginas = computed(() => Math.max(1, Math.ceil(total.value / tamano.value)));
  const pagina = computed(() => Math.min(Math.max(1, pedida.value), totalPaginas.value)); // corrección automática
  const items = computed(() => fuente().slice((pagina.value - 1) * tamano.value, pagina.value * tamano.value));
  const desde = computed(() => (total.value ? (pagina.value - 1) * tamano.value + 1 : 0));
  const hasta = computed(() => Math.min(total.value, pagina.value * tamano.value));
  const ir = (n) => { pedida.value = Math.min(Math.max(1, Number(n) || 1), totalPaginas.value); };
  const siguiente = () => ir(pagina.value + 1); const anterior = () => ir(pagina.value - 1);
  const cambiarTamano = (n) => { tamano.value = TAMANOS.includes(Number(n)) ? Number(n) : 10; pedida.value = 1; };
  if (reiniciarCon) watch(reiniciarCon, () => { pedida.value = 1; });
  // si la página efectiva cambió por una corrección, la guardamos para que "Siguiente/Anterior" partan desde ahí
  watch(pagina, (p) => { if (pedida.value !== p) pedida.value = p; });
  // reactive(): las propiedades se leen sin .value (pag.items, pag.total…), también dentro de las plantillas
  return reactive({ tamano, pagina, total, totalPaginas, items, desde, hasta, ir, siguiente, anterior, cambiarTamano });
}
