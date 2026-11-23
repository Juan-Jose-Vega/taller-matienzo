// Motor de mejora de textos por REGLAS LOCALES (sin internet, sin IA externa, sin claves).
// Qué hace: ortografía, tildes, puntuación, mayúsculas, muletillas, repeticiones y — para la descripción de un problema —
// reorganiza la frase ("Se informa un ruido al accionar los frenos, acompañado de vibraciones durante la frenada").
// Qué NO hace: no inventa causas ni diagnósticos. Si el usuario dice "ruido al frenar", jamás aparece "pastillas gastadas".
import {
  ABREVIATURAS, ERRORES, TILDES, VERBOS_SE_PASADO, ACRONIMOS, PROPIOS, MULETILLAS, REGISTRO, ADJETIVOS, PARTES,
  SUJETOS_VEHICULO, SUJETOS_PARTE, LEXICO_CAUSAS,
} from '../../config/textRules.js';

/* ------------------------------ utilidades ------------------------------ */
const strip = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').normalize('NFC');
const par = (o) => ({ o, p: strip(o).toLowerCase() });                 // o = texto con tildes, p = minúsculas sin tildes (misma longitud)
const cortar = (t, i, j) => par((t.o.slice(0, i) + ' ' + t.o.slice(j)).replace(/\s+/g, ' ').trim());
const desde = (t, i) => par(t.o.slice(i).trim());
const cap = (s) => (s ? s.charAt(0).toUpperCase() + s.slice(1) : s);
const unir = (l) => (l.length <= 1 ? l.join('') : l.slice(0, -1).join(', ') + ' y ' + l[l.length - 1]);
const conservarMayus = (w, r) => {
  if (w.length > 1 && w === w.toUpperCase()) return r.toUpperCase();
  if (w[0] !== w[0].toLowerCase()) return cap(r);
  return r;
};

function nuevoRegistro() {
  const r = { ortografia: 0, tildes: 0, puntuacion: 0, mayusculas: 0, repeticiones: 0, redaccion: 0, detalles: [] };
  r.add = (cat, de, a) => { r[cat]++; if (r.detalles.length < 12 && de !== a) r.detalles.push({ categoria: cat, de, a }); };
  return r;
}

/* ------------------------- paso 1: limpieza general ------------------------- */
function limpiar(texto, reg) {
  let t = String(texto).normalize('NFC').replace(/\r\n?/g, '\n');
  const ref = t.trim();
  t = t.replace(/[ \t]+/g, ' ').replace(/ *\n */g, '\n').trim();
  t = t.replace(/\s+([,.;:!?])/g, '$1');
  t = t.replace(/([,;:])(?=\p{L})/gu, '$1 ').replace(/([.!?])(?=\p{Lu})/gu, '$1 ');
  t = t.replace(/\.{2,}/g, '.').replace(/!{2,}/g, '!').replace(/\?{2,}/g, '?').replace(/,{2,}/g, ',').replace(/^[,.;:\s]+/, '');
  if (t !== ref) reg.add('puntuacion', '', '');
  const letras = t.replace(/[^\p{L}]/gu, '');
  if (letras.length > 8 && letras.replace(/[^\p{Lu}]/gu, '').length / letras.length > 0.6) { t = t.toLowerCase(); reg.add('mayusculas', 'TODO EN MAYÚSCULAS', 'minúsculas'); }
  return t;
}

/* ------------------------- paso 2: ortografía y tildes ------------------------- */
const reSe = new RegExp(`(?<![\\p{L}])(se) (${VERBOS_SE_PASADO.join('|')})(?![\\p{L}])(?=\\s+(?:el|la|los|las|un|una|unos|unas|de|del|todo|todos|todas|por|y|en|con)(?![\\p{L}]))`, 'giu');
function corregirPalabras(t, reg) {
  t = t.replace(/\p{L}+/gu, (w) => {
    const lw = w.toLowerCase(); const k = strip(lw);
    let r = null; let cat = 'ortografia';
    if (Object.hasOwn(ABREVIATURAS, k)) r = ABREVIATURAS[k];
    else if (Object.hasOwn(ERRORES, k) && ERRORES[k] !== lw) r = ERRORES[k];
    else if (lw === k && Object.hasOwn(TILDES, k) && TILDES[k] !== lw) { r = TILDES[k]; cat = 'tildes'; }
    else if (lw === k && /^[a-z]{3,}(?:c|s)ion$/.test(k)) { r = lw.slice(0, -3) + 'ión'; cat = 'tildes'; }
    if (r == null) return w;
    r = conservarMayus(w, r); reg.add(cat, w, r); return r;
  });
  t = t.replace(reSe, (m, se, v) => { const r = `${se} ${v.slice(0, -1)}${v.endsWith('o') ? 'ó' : v.slice(-1)}`; reg.add('tildes', m, r); return r; });
  return t;
}
function repeticionesYMuletillas(t, reg) {
  t = t.replace(/(?<![\p{L}])(\p{L}{2,})(?:\s+\1(?![\p{L}]))+/giu, (m, w) => { reg.add('repeticiones', m, w); return w; });
  t = t.replace(MULETILLAS, (m) => { reg.add('redaccion', m.trim(), ''); return ''; });
  t = t.replace(/\s+/g, ' ').replace(/\s+([,.;:])/g, '$1').replace(/^[,\s]+/, '').replace(/,\s*,/g, ',').trim();
  REGISTRO.forEach(([re, a]) => { t = t.replace(re, (m) => { reg.add('redaccion', m, a); return a; }); });
  return t;
}
function mayusculasEspeciales(t, reg) {
  t = t.replace(new RegExp(`(?<![\\p{L}])(${ACRONIMOS.join('|')})(?![\\p{L}])`, 'giu'), (m) => { const r = m.toUpperCase(); if (r !== m) reg.add('mayusculas', m, r); return r; });
  t = t.replace(new RegExp(`(?<![\\p{L}])(${PROPIOS.join('|')})(?![\\p{L}])`, 'giu'), (m) => { const r = cap(m.toLowerCase()); if (r !== m) reg.add('mayusculas', m, r); return r; });
  return t;
}

/* ------------------------- paso 3: segmentación ------------------------- */
const INICIO_CLAUSULA = '(?:parece|ademas|tambien|despues|luego|a veces|aveces|de vez en cuando|ahora|encima|aparte|no|se|me|le|hace|hacen|tiene|tienen|sale|salen|pierde|vibra|vibran|tiembla|huele|suena|tira|esta|estan|queda|quedan|cuesta|siento|escucho|oigo|noto|veo|sigue|cuando|al|si|en|con|por|mientras)';
function oraciones(t) { return t.split(/(?<=[.!?])\s+|\n+/).map((s) => s.trim()).filter(Boolean); }
function clausulas(oracion) {
  const o = oracion.replace(/[.!?]+$/, '').trim(); const t = par(o);
  const re = new RegExp(`\\s*(?:[,;]\\s*(?=${INICIO_CLAUSULA}\\b|y\\b|pero\\b|e\\b)|\\s(?:y|pero|e|entonces|aparte)\\s+(?=(?:parece|ademas|tambien|despues|luego|a veces|aveces|de vez en cuando|ahora|encima|no|se|me|le|hace|hacen|tiene|tienen|sale|salen|pierde|vibra|vibran|tiembla|huele|suena|tira|queda|quedan|cuesta|siento|escucho|oigo|sigue)\\b))\\s*`, 'g');
  const out = []; let ult = 0; let m;
  while ((m = re.exec(t.p))) { if (m[0].length === 0) { re.lastIndex++; continue; } out.push(o.slice(ult, m.index)); ult = m.index + m[0].length; }
  out.push(o.slice(ult));
  return out.map((s) => s.replace(/^[,;\s]+|[,;\s]+$/g, '')).filter(Boolean).map(par);
}

/* ------------------------- paso 4: análisis de un síntoma ------------------------- */
const ACENTOS_SUJ = { direccion: 'dirección', suspension: 'suspensión', bateria: 'batería', calefaccion: 'calefacción', 'cano de escape': 'caño de escape', baul: 'baúl', camion: 'camión', vehiculo: 'vehículo' };
const SUJ_KEYS = [...Object.keys(SUJETOS_PARTE).map(strip), ...SUJETOS_VEHICULO].sort((a, b) => b.length - a.length);
const SUJ_RE = new RegExp(`^(el|la|los|las|mi|mis)\\s+(${SUJ_KEYS.join('|')})(?![a-z])\\s*`);
const SONIDOS = 'ruido|ruidos|golpe|golpes|golpeteo|chirrido|chirridos|chillido|zumbido|silbido|traqueteo|crujido|crujidos|chasquido|rechinido|cascabeleo|tintineo|roce|rozamiento|quejido';
const VERBOS_RUIDO = 'hace|hacen|tiene|tienen|emite|emiten|tira|da|genera|produce|se escucha|se escuchan|se oye|se oyen|se siente|escucho|oigo|siento|suena|sale|salen|hay|aparece|aparecen|se produce|se genera|mete|larga|empezo a hacer|empieza a hacer|empezo a sonar';
const R_RUIDO1 = new RegExp(`^(?:me\\s+)?(?:${VERBOS_RUIDO})\\s+(?:(un|una|unos|unas)\\s+)?(?:algun\\s+)?(${SONIDOS})(?![a-z])(.*)$`);
const R_RUIDO2 = new RegExp(`^(?:(un|una|unos|unas)\\s+)?(${SONIDOS})(?![a-z])(.*)$`);
const R_SUENA = /^(?:suena|suenan|hace un sonido|hace sonidos)\s+(.*)$/;
const R_VIB = /^(?:(?:hay|tiene|siento|se siente|hace|hacen|genera|produce)\s+(?:una |unas |como |que )?)?(vibra|vibran|vibracion|vibraciones|tiembla|tiemblan|temblor|temblores|trepida|trepidan|trepidacion|se sacude|se sacuden|sacudones|se agita|se estremece|zamarreo)(?![a-z])(.*)$/;
const FLUIDOS = { aceite: 'aceite', agua: 'agua', combustible: 'combustible', nafta: 'nafta', gasoil: 'gasoil', 'liquido de frenos': 'líquido de frenos', 'liquido refrigerante': 'líquido refrigerante', refrigerante: 'refrigerante', liquido: 'líquido', liquidos: 'líquidos', gas: 'gas', 'liquido de direccion': 'líquido de dirección' };
const R_PERDIDA = new RegExp(`^(?:me\\s+)?(?:pierde|pierden|esta perdiendo|estan perdiendo|gotea|gotean|chorrea|larga|suelta|derrama|le sale|sale|perdio|tiene perdida de|hay perdida de|hay una perdida de|tiene una perdida de)\\s+(?:mucho |poco |bastante )?(${Object.keys(FLUIDOS).sort((a, b) => b.length - a.length).join('|')})(?![a-z])(.*)$`);
const R_HUMO = /^(?:sale|salen|echa|tira|larga|hay|suelta|esta largando|esta tirando|sale mucho|sale poco)\s+(mucho |poco |bastante )?humo\s*(blanco|negro|azul|gris)?(?![a-z])(.*)$/;
const R_OLOR = /^(?:huele|huelo|se huele|hay olor|siento olor|se siente olor|sale olor|tiene olor|larga olor|percibo olor|hay un olor|tiene un olor)\s*(?:(?:a|de)\s+)?(.*)$/;
const R_NOARRANCA = /^no\s+(arranca|prende|enciende|da arranque|arrancan)(?![a-z])(.*)$/;
const R_NOFUNC = /^no\s+(anda|funciona|responde|carga|sirve|levanta|gira|cierra|abre|traba|sube|baja|frena|acelera|cambia|entra|pasa|marca|calienta|enfria|refrigera|prende|enciende)(?![a-z])(.*)$/;
const R_CUESTA = /^(?:le |me )?(?:cuesta|costo)\s+(?:mucho\s+)?(arrancar|prender|encender|arranque)(?![a-z])(.*)$|^arranca\s+(?:mal|dificil|con dificultad|lento)(?![a-z])(.*)$/;
const R_APAGA = /^(se apaga|se apagan|se para|se paro|se corta|se cortan|se muere|se cala|se detiene|se ahoga)(?![a-z])(?:\s+solo)?(.*)$/;
const R_CALIENTA = /^(?:se )?(calienta|recalienta|sobrecalienta|hierve)(?![a-z])(.*)$/;
const R_TIRONES = /^(?:da |pega |tiene |hace )?(tirones|tironea|tironeo|cabecea|titubea|se entrecorta|falla|fallan)(?![a-z])(.*)$/;
const R_POTENCIA = /^(?:pierde|perdio|le falta|me falta|no tiene|esta sin|anda sin|tiene poca)\s+(?:mucha |bastante |algo de )?(fuerza|potencia)(?![a-z])(.*)$/;
const R_TESTIGO = /^(?:se )?(?:prende|prendio|enciende|encendio|aparece|aparecio|esta prendida|esta encendida|queda prendida|se queda prendida)\s+(?:(la|el|una|un|las) )?(luz|luces|testigo|lampara|alarma|aviso|indicador|check)(?:\s+(?:de|del|de la|de los)\s+(.+?))?(?:\s+en el tablero)?$/;
const R_DIRECCION = /^(?:tira|se va|se desvia|se corre|se carga|tiende|se arrastra)\s+(?:un poco |bastante |mucho )?(?:para|hacia|a)\s+(?:el |la |un )?(izquierda|derecha|un lado|costado|banquina)(?![a-z])(.*)$/;
const R_FRENA = /^(frena|frenan)\s+(mal|poco|menos|con dificultad|lento)(?![a-z])(.*)$/;
const R_PEDAL = /^(?:el )?pedal(?: del freno| de freno| de embrague)?\s+(?:esta |queda |se siente |se pone |va )?(duro|blando|esponjoso|bajo|flojo|largo|se hunde)(?![a-z])(.*)$/;

const FREC = [[/\b(?:a veces|aveces|de vez en cuando|por momentos|en ocasiones|de tanto en tanto)\b/, 'de forma intermitente'], [/\b(?:siempre|todo el tiempo|constantemente|todo el dia|todos los dias)\b/, 'de forma constante']];
const HEDGES = /^(?:me parece que|parece que|parece|creo que|capaz que|siento que|noto que|veo que|escucho que|oigo que|me di cuenta (?:de )?que|dice que|comenta que|cuenta que|manifiesta que|informa que|el cliente (?:dice|comenta|cuenta|manifiesta|informa|refiere|indica) que|el cliente refiere|refiere que|indica que|como que)\s+/;
const CONECT = /^(?:y ademas|y tambien|y|pero|e|ni|entonces|ademas|tambien|encima|aparte|ahora|ya|igual|incluso|mas que nada|principalmente|bueno)\s+/;

/* condiciones ("cuando freno", "al acelerar"...) -> frase verbal y su forma nominal */
const V0 = '(?:cuando|al|si|apenas|en cuanto|mientras)';
const COND = [
  { re: new RegExp(`\\b${V0}\\s+(?:freno|frenar|frena|se frena|piso (?:el|los) frenos?|pisa (?:el|los) frenos?|toco (?:el|los) frenos?|aprieto (?:el|los) frenos?|aplico (?:el|los) frenos?|pongo (?:el|los) frenos?)(?![a-z])`), verbal: 'al accionar los frenos', nominal: 'la frenada' },
  { re: new RegExp(`\\b${V0}\\s+(?:acelero|acelerar|acelera|se acelera|le doy gas|le doy mas gas|piso (?:el )?acelerador|pisar (?:el )?acelerador|pateo (?:el )?acelerador|le meto pata)(?![a-z])`), verbal: 'al acelerar', nominal: 'la aceleración' },
  { re: new RegExp(`\\b(?:cuando|al|si)\\s+(?:uso|usar|prendo|prender|enciendo|encender|pongo|activo)\\s+(?:el |la )?(aire acondicionado|aire|calefaccion|calefactor|desempanador)(?![a-z])`), verbal: (m) => ({ 'aire acondicionado': 'al usar el aire acondicionado', aire: 'al usar el aire acondicionado', calefaccion: 'al usar la calefacción', calefactor: 'al usar la calefacción', desempanador: 'al usar el desempañador' }[m[1]]) },
  { re: new RegExp(`\\b(?:cuando|al|si)\\s+(?:prendo|enciendo|pongo|uso)\\s+las luces(?![a-z])`), verbal: 'al encender las luces' },
  { re: new RegExp(`\\b${V0}\\s+(?:(?:lo|la)\\s+)?(?:prendo|prender|prenderlo|prenderla|enciendo|encender|encenderlo|encenderla)(?:\\s+(?:el|la)\\s+(?:motor|auto|coche|vehiculo|camioneta|moto))?(?![a-z])|\\b${V0}\\s+(?:pongo en marcha|poner en marcha|doy arranque|le doy arranque|doy contacto|giro la llave|pongo la llave|arranco (?:el )?(?:motor|auto|coche|vehiculo))(?![a-z])`), verbal: 'al encender {SUJ}', nominal: 'el encendido' },
  { re: new RegExp(`\\b${V0}\\s+(?:arranco|arrancar|arranca)(?![a-z])`), verbal: 'al arrancar', nominal: 'el arranque' },
  { re: new RegExp(`\\b${V0}\\s+(?:doblo|doblar|giro|girar|giro el volante|girar el volante|muevo el volante|doy vuelta (?:el )?volante|manejo en curvas?|tomo (?:una )?curvas?|maniobro|hago maniobras)(?![a-z])`), verbal: 'al girar el volante', nominal: 'el giro del volante' },
  { re: new RegExp(`\\b(?:cuando|al|si)\\s+(?:paso|pasa|pasar|piso|pisa|caigo|cae|entro|entra)\\s+(?:por |en |sobre )?(?:(un|una|los|las|el|la) )?(pozos?|baches?|lomos? de burro|baden(?:es)?|lomas?|reductores?|ripio|empedrado|adoquines|irregularidades|desniveles)(?![a-z])`), verbal: (m) => `al pasar por ${m[1] ? m[1] + ' ' : ''}${m[2].replace('baden', 'badén')}` },
  { re: new RegExp(`\\b(?:cuando|si|con|en|al)\\s+(?:esta |el motor esta |el auto esta |el motor |el auto |estoy )?(?:en )?(frio|fria|caliente)(?![a-z])`), verbal: (m) => (m[1] === 'caliente' ? 'con el motor caliente' : 'con el motor frío') },
  { re: new RegExp(`\\b(?:cuando|al|si)\\s+(?:cambio|cambiar|paso|pasar|meto|meter|engrano)\\s+(?:de |la )?(?:marcha|marchas|cambio|cambios|primera|segunda|tercera|cuarta|quinta)(?![a-z])`), verbal: 'al cambiar de marcha' },
  { re: new RegExp(`\\b(?:cuando|al|si)\\s+(?:pongo|meto|doy)\\s+(?:la )?(?:reversa|marcha atras)(?![a-z])`), verbal: 'al colocar la marcha atrás' },
  { re: new RegExp(`\\b(?:cuando|al|si)\\s+(?:piso|pisar|pisa|suelto|soltar|aprieto|apretar|toco)\\s+(?:el )?embrague(?![a-z])`), verbal: 'al accionar el embrague' },
  { re: new RegExp(`\\b(?:cuando|al|si)\\s+(voy|ando|circulo|manejo|llego|paso|supero)\\s+(?:a |a los |los )?(\\d{2,3})(?:\\s*(?:km\\/?h|kilometros|km por hora|km|por hora))?`), verbal: (m) => (/^(paso|supero|llego)/.test(m[1]) ? `al superar los ${m[2]} km/h` : `a unos ${m[2]} km/h`) },
  { re: /\b(?:cuando|si|con|en)\s+(?:esta |estoy |el auto esta |el motor esta )?(?:parado|detenido|quieto|en el semaforo|en punto muerto)(?![a-z])/, verbal: 'con el vehículo detenido' },
  { re: /\b(?:a|hacia los|pasando los)\s+(\d{2,3})\s*(?:km\/?h|kilometros por hora|km por hora)(?![a-z])/, verbal: (m) => `a unos ${m[1]} km/h` },
  { re: /\b(?:en|al)\s+ralenti(?![a-z])/, verbal: 'en ralentí' },
  { re: /\b(?:cuando|si|con)\s+(?:llueve|hay lluvia|esta lloviendo|llovizna|hay humedad)(?![a-z])/, verbal: 'cuando llueve' },
  { re: /\b(?:cuando|en|si)\s+(?:subo|subir|las subidas|una subida|subidas|cuesta arriba|una pendiente|pendientes?)(?![a-z])/, verbal: 'en subidas' },
  { re: /\b(?:cuando|en|si)\s+(?:bajo|bajar|las bajadas|una bajada|bajadas|cuesta abajo)(?![a-z])/, verbal: 'en bajadas' },
  { re: /\ben (?:la )?(?:autopista|ruta|carretera)(?![a-z])/, verbal: 'en ruta' },
  { re: /\ben (?:las )?curvas?(?![a-z])/, verbal: 'en curvas' },
];
function extraerCondiciones(t) {
  const conds = []; let cur = t;
  for (let n = 0; n < 4; n++) {
    let mejor = null;
    for (const d of COND) { const m = d.re.exec(cur.p); if (m && (!mejor || m.index < mejor.m.index)) mejor = { d, m }; }
    if (!mejor) break;
    conds.push({ verbal: typeof mejor.d.verbal === 'function' ? mejor.d.verbal(mejor.m) : mejor.d.verbal, nominal: mejor.d.nominal || null });
    cur = cortar(cur, mejor.m.index, mejor.m.index + mejor.m[0].length);
  }
  if (!conds.length) return { cond: null, t };
  return { cond: { verbal: [...new Set(conds.map((c) => c.verbal))].join(' y '), nominal: conds[0].nominal }, t: cur };
}

/* adjetivo + lugar a partir del "resto" de la frase */
function adjYLugar(resto) {
  let r = par(resto.o.replace(/^[,\s]+|[,\s]+$/g, ''));
  let adj = null; let lugar = null; let sobra = '';
  if (!r.p) return { adj, lugar, sobra };
  for (const [re, a] of ADJETIVOS) { const m = re.exec(r.p); if (m) { adj = a; r = desde(r, m[0].length); break; } }
  r = r.p ? r : par('');
  let m;
  if ((m = /^(?:de\s+)?(adelante|delante|atras|abajo|arriba|costado)(?![a-z])\s*(.*)$/.exec(r.p))) { lugar = PARTES[m[1]]; r = desde(r, r.p.length - m[2].length); }
  else if ((m = /^(en|del|de la|de los|de las|desde|por|a la altura de|cerca de|proveniente de)\s+(.+)$/.exec(r.p))) {
    const resto2 = r.o.slice(r.p.length - m[2].length);
    lugar = ({ en: 'en ', del: 'en el ', 'de la': 'en la ', 'de los': 'en los ', 'de las': 'en las ', desde: 'desde ', por: 'por ', 'a la altura de': 'a la altura de ', 'cerca de': 'cerca de ', 'proveniente de': 'desde ' }[m[1]]) + resto2;
    r = par('');
  }
  sobra = r.o.replace(/^[,\s]+|[,\s]+$/g, '');
  return { adj, lugar, sobra };
}
const LUGAR_ADJ_FIN = (lugar, sobra) => [lugar, sobra].filter(Boolean).join(' ');

/* sujeto de la frase */
function detSujeto(ctx) {
  if (!ctx.suj || SUJETOS_VEHICULO.includes(ctx.suj.noun)) return 'el vehículo';
  return `${ctx.suj.det} ${ctx.suj.nombre}`;
}
const esVehiculo = (ctx) => !ctx.suj || SUJETOS_VEHICULO.includes(ctx.suj.noun);

function analizarClausula(c0, ctx) {
  let t = c0; const items = [];
  for (let i = 0; i < 3; i++) { // conectores y muletillas del inicio
    let m = CONECT.exec(t.p); if (m) { t = desde(t, m[0].length); continue; }
    m = HEDGES.exec(t.p); if (m) { t = desde(t, m[0].length); continue; }
    break;
  }
  if (!t.p) return items;

  // evolución: "después se va", "al rato desaparece", "sigue igual"
  let m = /^(?:(despues|luego|al rato|enseguida|rapido|al toque|despues de un rato|despues de un tiempo|a los (\d+) (segundos|minutos|dias))\s+)?(?:se (?:va|quita|pasa|le pasa|desaparece|calma|normaliza|termina|corta)|desaparece|deja de (?:sonar|hacer ruido|vibrar|hacerlo)|se (?:va|pasa) solo)(?![a-z])\s*$/.exec(t.p);
  if (m) {
    const w = m[1] || '';
    const txt = !w ? 'desaparece' : /^(despues|luego)$/.test(w) ? 'desaparece después de unos momentos' : /rato|tiempo/.test(w) ? 'desaparece al cabo de un rato' : /enseguida|toque|rapido/.test(w) ? 'desaparece rápidamente' : `desaparece a los ${m[2]} ${m[3]}`;
    return [{ k: 'evol', texto: txt }];
  }
  if ((m = /^(?:(?:despues|luego)\s+)?(no se (?:va|quita|pasa)|sigue(?: igual| asi)?|continua|persiste|se mantiene)\s*$/.exec(t.p))) {
    return [{ k: 'evol', texto: /^no se/.test(m[1]) ? 'no desaparece' : 'persiste' }];
  }

  // sujeto
  const sm = SUJ_RE.exec(t.p);
  if (sm) {
    const noun = sm[2]; const nombre = ACENTOS_SUJ[noun] || noun; const det = (sm[1] === 'mi' || sm[1] === 'mis') ? (SUJETOS_PARTE[Object.keys(SUJETOS_PARTE).find((k) => strip(k) === noun)] || 'el') : sm[1];
    ctx.suj = { noun, nombre, det };
    t = desde(t, sm[0].length);
  }

  // frecuencia
  let freq = null;
  for (const [re, txt] of FREC) { const fm = re.exec(t.p); if (fm) { freq = txt; t = cortar(t, fm.index, fm.index + fm[0].length); } }

  const antesConds = t;
  const { cond: condRaw, t: t2 } = extraerCondiciones(t);
  const cond = condRaw ? { verbal: condRaw.verbal.replace('{SUJ}', esVehiculo(ctx) || (ctx.suj && ctx.suj.noun === 'motor') ? (ctx.suj && ctx.suj.noun === 'motor' ? 'el motor' : 'el vehículo') : detSujeto(ctx)), nominal: condRaw.nominal } : null;
  t = t2;
  if (!t.p) return cond ? [{ k: 'cond', cond }] : items;

  const agregar = (it) => { if (cond && !it.cond) it.cond = cond; if (freq) it.freq = freq; items.push(it); return items; };
  const sint = (o) => agregar(Object.assign({ k: 'sint', forma: 'nom', art: null, nucleo: '', adj: null, lugar: null, sobra: '' }, o));
  const lugarParte = (extra) => { // si el sujeto es una parte (volante, caja...), dónde ocurre
    if (extra) return extra;
    if (ctx.suj && !SUJETOS_VEHICULO.includes(ctx.suj.noun)) return `en ${ctx.suj.det} ${ctx.suj.nombre}`;
    return null;
  };

  // --- ruidos ---
  let r;
  if ((m = R_RUIDO1.exec(t.p)) || (m = R_RUIDO2.exec(t.p))) {
    const art = m[1] || null; const nucleo = m[2]; const rest = desde(t, t.p.length - m[3].length);
    const { adj, lugar, sobra } = adjYLugar(rest);
    return sint({ art, nucleo: t.o.slice(t.p.indexOf(nucleo), t.p.indexOf(nucleo) + nucleo.length), adj, lugar: lugarParte(lugar), sobra, condInSuj: true });
  }
  if ((m = R_SUENA.exec(t.p))) {
    const { adj, lugar, sobra } = adjYLugar(desde(t, t.p.length - m[1].length));
    if (adj || /^(mal|raro)/.test(m[1])) return sint({ art: 'un', nucleo: 'ruido', adj: adj || 'anormal', lugar: lugarParte(lugar), sobra: adj ? sobra : sobra.replace(/^mal\s*/, '') });
  }
  // --- vibraciones ---
  if ((m = R_VIB.exec(t.p))) {
    let resto = desde(t, t.p.length - m[2].length).o.trim(); let adj = null; let lugar = null;
    if (/^(mucho|bastante|fuerte|re fuerte|muy fuerte)\b/.test(strip(resto).toLowerCase())) { adj = 'intensas'; resto = resto.replace(/^\S+(\s+fuerte)?\s*/i, ''); }
    const lm = /^(?:todo\s+)?(?:en\s+)?(el|la|los|las)\s+([\p{L}]+(?:\s+[\p{L}]+)?)/iu.exec(resto);
    if (lm && !SUJETOS_VEHICULO.includes(strip(lm[2]).toLowerCase())) lugar = `en ${lm[1].toLowerCase()} ${lm[2]}`;
    else if (!/^todo\b/i.test(resto)) lugar = lugarParte(null);
    items.push(Object.assign({ k: 'vib', adj, lugar: lugar || lugarParte(null) }, cond ? { cond } : {}, freq ? { freq } : {}));
    return items;
  }
  // --- pérdidas ---
  if ((m = R_PERDIDA.exec(t.p))) {
    const { lugar, sobra } = adjYLugar(desde(t, t.p.length - m[2].length));
    return sint({ art: 'una', nucleo: `pérdida de ${FLUIDOS[m[1]]}`, lugar: lugarParte(lugar), sobra });
  }
  // --- humo ---
  if ((m = R_HUMO.exec(t.p))) {
    const { lugar, sobra } = adjYLugar(desde(t, t.p.length - m[3].length));
    return sint({ nucleo: `salida de humo${m[2] ? ' ' + m[2] : ''}${/mucho|bastante/.test(m[1] || '') ? ' abundante' : ''}`, lugar, sobra });
  }
  // --- olores ---
  if ((m = R_OLOR.exec(t.p))) {
    const resto = desde(t, t.p.length - m[1].length); const { adj } = adjYLugar(resto);
    if (adj && /^(feo|raro|fuerte|desagradable|extrano)/.test(m[1])) return sint({ art: 'un', nucleo: 'olor', adj });
    if (m[1]) return sint({ nucleo: `olor a ${resto.o}` });
    return sint({ art: 'un', nucleo: 'olor', adj: null });
  }
  // --- arranque y funcionamiento ---
  if ((m = R_NOARRANCA.exec(t.p))) {
    const verbo = /prende|enciende/.test(m[1]) && !esVehiculo(ctx) && !(ctx.suj && ctx.suj.noun === 'motor') ? 'enciende' : 'arranca';
    return sint({ forma: 'que', texto: `${detSujeto(ctx)} no ${verbo}`, sobra: m[2].trim() });
  }
  if ((m = R_CUESTA.exec(t.p))) return sint({ nucleo: 'dificultad para arrancar' });
  if ((m = R_POTENCIA.exec(t.p))) return sint({ nucleo: 'pérdida de potencia', lugar: lugarParte(null) });
  if ((m = R_NOFUNC.exec(t.p))) {
    const v = { anda: 'funciona', sirve: 'funciona' }[m[1]] || m[1];
    return sint({ forma: 'que', texto: `${detSujeto(ctx)} no ${v}`, sobra: m[2].trim() });
  }
  if ((m = R_APAGA.exec(t.p))) {
    const v = /apaga|muere|cala/.test(m[1]) ? 'se apaga' : /para|paro|detiene/.test(m[1]) ? 'se detiene' : /corta/.test(m[1]) ? 'se corta' : 'se ahoga';
    return sint({ forma: 'que', texto: `${detSujeto(ctx)} ${v}`, sobra: m[2].trim() });
  }
  if ((m = R_CALIENTA.exec(t.p))) return sint({ forma: 'que', texto: `${detSujeto(ctx)} ${m[1] === 'hierve' ? 'hierve' : m[1] === 'sobrecalienta' ? 'se sobrecalienta' : 'se ' + m[1]}`, sobra: m[2].trim() });
  if ((m = R_TIRONES.exec(t.p))) {
    if (/tirones|tironea|tironeo|cabecea|titubea/.test(m[1])) return sint({ nucleo: 'tirones', lugar: lugarParte(null) });
    return sint({ forma: 'que', texto: `${detSujeto(ctx)} ${/falla/.test(m[1]) ? 'presenta fallas' : 'se entrecorta'}`, sobra: m[2].trim() });
  }
  if ((m = R_TESTIGO.exec(t.p))) {
    const noun = m[2]; const art = m[1] ? m[1] : ({ luz: 'una', luces: '', testigo: 'un', lampara: 'una', alarma: 'una', aviso: 'un', indicador: 'un', check: 'el' }[noun] || 'una');
    const det = m[3] ? ` de ${t.o.slice(t.p.length - m[3].length - (/en el tablero$/.test(t.p) ? 15 : 0), t.p.length - (/en el tablero$/.test(t.p) ? 15 : 0))}` : '';
    return sint({ forma: 'que', texto: `se enciende ${art ? art + ' ' : ''}${noun === 'lampara' ? 'lámpara' : noun}${det} en el tablero` });
  }
  if ((m = R_DIRECCION.exec(t.p))) return sint({ forma: 'que', texto: `${detSujeto(ctx)} se desvía hacia ${m[1] === 'izquierda' || m[1] === 'derecha' ? 'la ' + m[1] : m[1] === 'un lado' ? 'un lado' : 'el ' + m[1]}`, sobra: m[2].trim() });
  if ((m = R_FRENA.exec(t.p))) return sint({ forma: 'que', texto: `${detSujeto(ctx)} frena ${m[2]}`, sobra: m[3].trim() });
  if ((m = R_PEDAL.exec(t.p))) return sint({ forma: 'que', texto: `el pedal del freno ${m[1] === 'se hunde' ? 'se hunde' : 'está ' + m[1]}` });

  // sin patrón: se conserva el texto (con ortografía corregida) y la condición vuelve a su lugar
  return [{ k: 'otro', texto: antesConds.o }];
}

/* ------------------------- paso 5: composición ------------------------- */
function lugarFinal(s, ctx) {
  let l = s.lugar;
  const cv = s.cond ? strip(s.cond.verbal.toLowerCase()) : '';
  if (l && ctx.suj && cv && l.startsWith('en ') && cv.includes(ctx.suj.noun)) l = null; // "ruido ... al encender el motor": no repetir "en el motor"
  return LUGAR_ADJ_FIN(l, s.sobra);
}
function renderSint(s, ctx) {
  let t;
  if (s.forma === 'nom') t = [s.art, s.nucleo, s.adj, lugarFinal(s, ctx)].filter(Boolean).join(' ');
  else t = 'que ' + [s.texto, s.sobra].filter(Boolean).join(' ');
  if (s.cond) t += ' ' + s.cond.verbal;
  if (s.freq) t += ' ' + s.freq;
  if (s.evol) t += s.forma === 'nom' ? ' que ' + s.evol : ', y ' + s.evol;
  if (s.acomp && s.acomp.length) {
    const lista = s.acomp.map((a) => [a.adj ? 'vibraciones ' + a.adj : 'vibraciones', a.lugar].filter(Boolean).join(' ') + (!a.cond && s.cond && s.cond.nominal ? ' durante ' + s.cond.nominal : (a.cond ? ' ' + a.cond.verbal : '')));
    t += ', acompañado de ' + unir([...new Set(lista)]);
  }
  return t.replace(/\s+/g, ' ').trim();
}
function componerOracion(items, ctx) {
  const sints = []; const otros = []; let pend = null; let ultimo = null;
  for (const it of items) {
    if (it.k === 'sint') { if (!it.cond && pend) { it.cond = pend; pend = null; } it.acomp = []; sints.push(it); ultimo = it; }
    else if (it.k === 'vib') {
      if (ultimo) ultimo.acomp.push(it);
      else { const s = { k: 'sint', forma: 'nom', art: null, nucleo: 'vibraciones', adj: it.adj, lugar: it.lugar, sobra: '', cond: it.cond || pend, freq: it.freq, acomp: [] }; pend = null; sints.push(s); ultimo = s; }
    } else if (it.k === 'evol') { if (ultimo && !ultimo.evol) ultimo.evol = it.texto; else otros.push(cap(it.texto) + '.'); }
    else if (it.k === 'cond') { if (ultimo && !ultimo.cond) ultimo.cond = it.cond; else pend = it.cond; }
    else if (it.k === 'otro') otros.push(it.texto);
  }
  if (pend && ultimo && !ultimo.cond) ultimo.cond = pend;
  return { sints, otros };
}

function oracionProblema(oracion, ctx) {
  const items = [];
  for (const c of clausulas(oracion)) items.push(...analizarClausula(c, ctx));
  const { sints, otros } = componerOracion(items, ctx);
  return { sints, otros };
}

function fraseGeneral(oracion, contexto) {
  let o = oracion.replace(/[.!?]+$/, '').trim();
  const corte = /(?:,|\sy)?\s+(?=(?:falta|faltan|queda|quedan|pendiente|resta|restan|hay que|habria que|se recomienda|recomiendo|recomendamos|conviene|corresponde|se deberia)\b)/giu;
  const p = strip(o).toLowerCase(); const partes = []; let ult = 0; let m;
  while ((m = corte.exec(p))) { partes.push(o.slice(ult, m.index)); ult = m.index + m[0].length; }
  partes.push(o.slice(ult));
  return partes.map((s) => s.replace(/\s+/g, ' ').trim()).filter(Boolean);
}

const finalizar = (frases) => frases.map((f) => f.trim()).filter(Boolean).map((f) => cap(f).replace(/[,;:\s]+$/, '').replace(/([^.!?])$/, '$1.')).join(' ');

/* ------------------------- entrada pública ------------------------- */
export function mejorarConReglas(texto, { contexto = 'problema' } = {}) {
  const original = String(texto || '');
  const reg = nuevoRegistro();
  let t = limpiar(original, reg);
  t = corregirPalabras(t, reg);
  t = repeticionesYMuletillas(t, reg);
  t = mayusculasEspeciales(t, reg);
  const base = finalizar(oraciones(t).flatMap((o) => fraseGeneral(o, contexto)));   // versión "solo limpieza"

  let propuesta = base; let reformulado = false;
  const yaFormal = /^\s*(se|el cliente)\s+(informa|observa|detecta|indica|reporta|refiere|comenta)/i.test(t);
  if (contexto === 'problema' && !yaFormal) {
    const ctx = { suj: null }; const allSints = []; const allOtros = []; let ctxFinal = ctx;
    for (const o of oraciones(t)) { const r = oracionProblema(o, ctx); allSints.push(...r.sints); allOtros.push(...r.otros); }
    if (allSints.length) {
      const pl = allSints[0].forma === 'nom' && (/^unos|^unas/.test(allSints[0].art || '') || (!allSints[0].art && /s$/.test(allSints[0].nucleo)));
      const principal = (pl ? 'Se informan ' : 'Se informa ') + unir(allSints.map((s) => renderSint(s, ctxFinal)));
      const otrasFrases = allOtros.map((x) => x.replace(/[.!?]+$/, '')).filter(Boolean);
      propuesta = finalizar([principal, ...otrasFrases]);
      reformulado = true;
    }
  }
  // garantía: no se agregan causas ni diagnósticos que el usuario no escribió
  const entrada = strip(original).toLowerCase(); const salida = strip(propuesta).toLowerCase();
  if (LEXICO_CAUSAS.some((w) => { const k = strip(w); return salida.includes(k) && !entrada.includes(k); })) { propuesta = base; reformulado = false; }

  const igual = (a, b) => strip(a).toLowerCase().replace(/[\s.,;:!?]+/g, ' ').trim() === strip(b).toLowerCase().replace(/[\s.,;:!?]+/g, ' ').trim();
  if (reformulado && !igual(propuesta, original)) reg.add('redaccion', '', '');
  const sinCambios = propuesta.trim() === original.trim();
  if (!sinCambios && cap(original.trim()) !== original.trim() && /^\p{Ll}/u.test(original.trim())) reg.add('mayusculas', 'minúscula inicial', 'mayúscula inicial');
  if (!sinCambios && !/[.!?]$/.test(original.trim())) reg.add('puntuacion', 'sin punto final', 'punto final');
  const { detalles, add, ...resumen } = reg;
  return { propuesta, reformulado, sinCambios, cambios: resumen, detalles };
}
