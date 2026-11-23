// Reglas CONFIGURABLES del corrector local de textos. Agregar una palabra o un patrón acá no requiere tocar el motor.
// Todo lo que está en minúsculas y SIN tildes (el motor compara sin tildes).

// Abreviaturas y escritura "de chat"
export const ABREVIATURAS = { q: 'que', ke: 'que', k: 'que', xq: 'porque', pq: 'porque', porq: 'porque', porke: 'porque', tmb: 'también', tb: 'también', tbn: 'también', xa: 'para', pa: 'para', nose: 'no sé', aveces: 'a veces', osea: 'o sea', };

// Errores de ortografía frecuentes (palabra mal escrita -> correcta)
export const ERRORES = {
  bibra: 'vibra', bibran: 'vibran', bibracion: 'vibración', bibraciones: 'vibraciones', ase: 'hace', ace: 'hace', asen: 'hacen', hasen: 'hacen', haze: 'hace', aser: 'hacer', hiso: 'hizo', haci: 'así',
  aceyte: 'aceite', asite: 'aceite', frenoz: 'frenos',  motro: 'motor',  rudio: 'ruido', ruidoz: 'ruidos', ruidito: 'ruido leve', ruiditos: 'ruidos leves', vien: 'bien', arranka: 'arranca',  
  refrijerante: 'refrigerante',  gasolina: 'nafta', embriague: 'embrague', enbrague: 'embrague', embrage: 'embrague', suspencion: 'suspensión',
  alineasion: 'alineación', direcion: 'dirección', transmicion: 'transmisión',  rulema: 'rulemán', vivracion: 'vibración', trepidacion: 'trepidación', kilometros: 'kilómetros', kilometro: 'kilómetro',  
  haver: 'haber', yebo: 'llevo', llebo: 'llevo', llebar: 'llevar',   mui: 'muy', 
};

// Palabras que llevan tilde (sin tilde -> con tilde)
export const TILDES = {
  despues: 'después', tambien: 'también', ademas: 'además', aqui: 'aquí', asi: 'así', tenia: 'tenía', habia: 'había', podia: 'podía', queria: 'quería', sabia: 'sabía', dia: 'día', dias: 'días',
  electrico: 'eléctrico', electrica: 'eléctrica', electricos: 'eléctricos', electricas: 'eléctricas', electronico: 'electrónico', electronica: 'electrónica', mecanico: 'mecánico', mecanica: 'mecánica', mecanicos: 'mecánicos',
  liquido: 'líquido', liquidos: 'líquidos', neumatico: 'neumático', neumaticos: 'neumáticos', vehiculo: 'vehículo', vehiculos: 'vehículos', perdida: 'pérdida', perdidas: 'pérdidas', debil: 'débil', util: 'útil', facil: 'fácil', dificil: 'difícil',
  rapido: 'rápido', rapida: 'rápida', rapidamente: 'rápidamente', frio: 'frío', fria: 'fría', frias: 'frías', frios: 'fríos', ralenti: 'ralentí', camion: 'camión', cardan: 'cardán', homocinetica: 'homocinética', hidraulico: 'hidráulico', hidraulica: 'hidráulica',
  termico: 'térmico', automatico: 'automático', automatica: 'automática', unico: 'único', numero: 'número', ultimo: 'último', ultima: 'última', proximo: 'próximo', tecnico: 'técnico', tecnica: 'técnica', tecnicas: 'técnicas', tecnicos: 'técnicos',
  sintoma: 'síntoma', sintomas: 'síntomas', metalico: 'metálico', metalica: 'metálica', acustico: 'acústico', maximo: 'máximo', minimo: 'mínimo', basico: 'básico', lampara: 'lámpara', lamparas: 'lámparas', camara: 'cámara',
  baul: 'baúl', garantia: 'garantía', energia: 'energía', ahi: 'ahí', bateria: 'batería', baterias: 'baterías', bujia: 'bujía', bujias: 'bujías', alla: 'allá', alli: 'allí', aun: 'aún', telefono: 'teléfono', 
  quiza: 'quizá', quizas: 'quizás', exito: 'éxito', habito: 'hábito', angulo: 'ángulo', helice: 'hélice', pagina: 'página', tension: 'tensión', presion: 'presión', diesel: 'diésel',
};

// Verbos que, precedidos por "se" y seguidos de un artículo/complemento, van en pasado con tilde ("se cambio el filtro" -> "se cambió el filtro")
export const VERBOS_SE_PASADO = ['cambio', 'reviso', 'ajusto', 'reemplazo', 'limpio', 'arreglo', 'soldo', 'regulo', 'calibro', 'purgo', 'desarmo', 'armo', 'probo', 'monto', 'desmonto', 'instalo', 'reparo', 'controlo', 'verifico', 'detecto', 'encontro', 'observo', 'aprieto', 'engraso', 'lubrico', 'relleno', 'cargo', 'saco', 'coloco', 'inspecciono', 'midio', 'pinto', 'sustituyo', 'recambio', 'drene'].filter(Boolean);

// Acrónimos y marcas (para la capitalización correcta)
export const ACRONIMOS = ['abs', 'gnc', 'gnv', 'ecu', 'rpm', 'gps', 'led', 'esp', 'dpf', 'egr', 'cvt', 'vtv', 'dni', 'ac'];
export const PROPIOS = ['fiat', 'ford', 'chevrolet', 'renault', 'peugeot', 'citroën', 'citroen', 'volkswagen', 'toyota', 'honda', 'nissan', 'mercedes', 'bmw', 'audi', 'hyundai', 'kia', 'suzuki', 'mazda', 'jeep', 'iveco', 'scania', 'palio', 'gol', 'corsa', 'clio', 'fiesta', 'kangoo', 'hilux', 'ranger', 'amarok', 'etios', 'onix', 'cruze', 'sandero', 'logan', 'duster', 'siena', 'uno', 'focus', 'kwid', 'tucson', 'ecosport', 'mercado', 'pago'].filter((x) => !['uno', 'mercado', 'pago'].includes(x));

// Muletillas que se eliminan sin cambiar el sentido
export const MULETILLAS = /\b(o sea|osea|como que|la verdad( que)?|digamos|viste|che|eh+|em+|mmm+|bueno|mira|mirá|este,|tipo que)\b[,]?/giu;

// Ajustes de registro: lenguaje coloquial -> lenguaje sencillo y profesional (sin agregar causas)
export const REGISTRO = [
  [/\bno anda\b/giu, 'no funciona'],
  [/\bno sirve\b/giu, 'no funciona'],
  [/\bse (?:murio|muri[oó])\b/giu, 'dejó de funcionar'],
  [/\bse trabo\b/giu, 'se trabó'],
  [/\bfeo\b(?=\s+ruido|\s+olor)/giu, 'anormal'],
  [/\bun poco de\b/giu, 'algo de'],
  [/\bmuchisimo\b/giu, 'mucho'],
  [/\bcosa rara\b/giu, 'anomalía'],
  [/\bcualquier cosa\b/giu, 'cualquier anomalía'],
];

// Adjetivos de los ruidos y olores
export const ADJETIVOS = [
  [/^(?:medio |bastante |re |muy |algo )?(?:raro|rara|extrano|extrana|raros|raras)\b/, 'inusual'],
  [/^(?:medio |bastante |re |muy )?(?:feo|fea|desagradable)\b/, 'anormal'],
  [/^(?:muy |bastante |re )?(?:fuerte|fuertes)\b/, 'fuerte'],
  [/^(?:muy |bastante )?(?:metalico|metalica)\b/, 'metálico'],
  [/^(?:seco|seca)\b/, 'seco'],
  [/^(?:leve|suave|chiquito|chiquita|poco)\b/, 'leve'],
  [/^(?:constante|permanente)\b/, 'constante'],
];

export const PARTES = { adelante: 'en la parte delantera', delante: 'en la parte delantera', atras: 'en la parte trasera', abajo: 'en la parte inferior', arriba: 'en la parte superior', costado: 'en un costado' };

// Sustantivos que pueden ser el sujeto de la frase. "vehiculo" agrupa a todos los sinónimos del vehículo completo.
export const SUJETOS_VEHICULO = ['auto', 'coche', 'carro', 'vehiculo', 'camioneta', 'moto', 'camion', 'utilitario', 'unidad', 'camioneta'];
export const SUJETOS_PARTE = { motor: 'el', volante: 'el', caja: 'la', embrague: 'el', freno: 'el', frenos: 'los', direccion: 'la', escape: 'el', 'caño de escape': 'el', bateria: 'la', radiador: 'el', 'aire acondicionado': 'el', aire: 'el', luces: 'las', luz: 'la', pedal: 'el', rueda: 'la', ruedas: 'las', cubierta: 'la', cubiertas: 'las', neumaticos: 'los', tablero: 'el', amortiguadores: 'los', suspension: 'la', puerta: 'la', capot: 'el', baul: 'el', techo: 'el', ventanilla: 'la', limpiaparabrisas: 'el', alternador: 'el', turbo: 'el', correa: 'la', cadena: 'la', calefaccion: 'la', bocina: 'la', espejo: 'el', 'limpia parabrisas': 'el' };

// Léxico de piezas/causas: el corrector NO puede introducir ninguna de estas palabras si el usuario no la escribió (no inventa diagnósticos).
export const LEXICO_CAUSAS = ['pastilla', 'disco', 'rodamiento', 'rulemán', 'bomba', 'junta', 'tensor', 'correa', 'bujia', 'inyector', 'filtro', 'amortiguador', 'cardan', 'homocinetic', 'alternador', 'termostato', 'cilindro', 'piston', 'biela', 'valvula', 'catalizador', 'sensor', 'fusible', 'rele', 'retén', 'rotula', 'buje', 'bieleta', 'embrague', 'desgast', 'gastad', 'rota', 'roto', 'fisura', 'sucio', 'tapad', 'falla de', 'defect'];
