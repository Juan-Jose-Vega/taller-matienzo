#!/usr/bin/env python3
"""Genera la SECCIÓN 2 del SQL final (datos de demostración) a partir de los datos de demostración del MVP.

Entrada : seed.json (salida de dump_seed.mjs: crearSeed() del MVP con fecha de referencia fija)
Salida  : texto SQL con los INSERT, aplicando el mapeo MVP -> MySQL documentado en DOCUMENTACION/mapeo_mvp_mysql.md

Reglas de alcance (el sistema administra UN solo taller):
  * Solo se cargan los datos del "Taller Matienzo" (taller_id = 1 del MVP). El segundo taller de la demo del MVP
    ("Mecánica del Sur", su dueña y sus pagos) no tiene representación en este modelo y se documenta como decisión pendiente.
  * Los datos que el MVP no genera (comisiones, adelantos, liquidación, historial de precios) se agregan como DATOS DE
    PRUEBA controlados y rotulados, para poder probar las tablas que el MVP todavía no usa.
"""
import json, os, sys
from datetime import date, timedelta

AQUI = os.path.dirname(os.path.abspath(__file__))


def lit(v):
    """Literal SQL."""
    if v is None:
        return 'NULL'
    if isinstance(v, bool):
        return '1' if v else '0'
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace('\\', '\\\\').replace("'", "''") + "'"


def dts(s):
    """Fecha/hora del MVP ('AAAA-MM-DD' o 'AAAA-MM-DD HH:MM') -> DATETIME de MySQL."""
    if s is None:
        return None
    s = str(s)
    if len(s) == 10:
        return s + ' 00:00:00'
    if len(s) == 16:
        return s + ':00'
    return s


def insert(tabla, cols, filas, comentario=None):
    if not filas:
        return ''
    out = []
    if comentario:
        out.append(f'-- {comentario}')
    out.append(f'INSERT INTO {tabla} ({", ".join(cols)}) VALUES')
    out.append(',\n'.join('  (' + ', '.join(lit(x) for x in f) + ')' for f in filas) + ';')
    return '\n'.join(out) + '\n'


def hashes_demo():
    """Hashes bcrypt de las contraseñas de DEMOSTRACIÓN (se generan una vez y se guardan para que el SQL sea estable)."""
    ruta = os.path.join(AQUI, 'hashes_demo.json')
    claves = {'superadmin': 'Super123', 'roberto': 'Dueno123', 'juan': 'Mecanico123', 'pedro': 'Mecanico123', 'carlos': 'Mecanico123'}
    if os.path.exists(ruta):
        return json.load(open(ruta, encoding='utf-8'))
    import bcrypt
    h = {u: bcrypt.hashpw(c.encode(), bcrypt.gensalt(rounds=10)).decode() for u, c in claves.items()}
    json.dump(h, open(ruta, 'w', encoding='utf-8'), indent=1)
    return h


def generar(seed_path):
    d = json.load(open(seed_path, encoding='utf-8'))
    H = hashes_demo()
    S = []  # bloques SQL
    T = 1   # taller del MVP que se conserva
    hoy = None  # fecha de referencia = fecha del seed (se deduce de la suscripción)

    # ---------------- usuarios ----------------
    mec_por_usuario = {m['usuario_id']: m for m in d['mecanicos'] if m['taller_id'] == T}
    cod_rol = {r['id']: r['codigo'] for r in d['roles']}   # los roles se resuelven por CÓDIGO, no por número
    usuarios_mvp = [u for u in d['usuarios'] if u['tipo_cuenta'] == 'superadmin' or u.get('taller_id') == T]
    uid = {}          # id usuario MVP -> id SQL (contiguo)
    for i, u in enumerate(usuarios_mvp, 1):
        uid[u['id']] = i
    mec2u = {m['id']: uid[m['usuario_id']] for m in d['mecanicos'] if m['taller_id'] == T}  # id mecánico MVP -> id usuario SQL
    login = {uid[u['id']]: u['usuario'] for u in usuarios_mvp}
    rol_sql = {'admin': 1, 'mecanico': 2}   # código de rol del MVP -> id de la tabla roles de MySQL
    estado_u = {'activo': 'activo', 'inactivo': 'pausado', 'suspendido': 'suspendido'}

    S.append(insert('roles', ['id', 'nombre', 'descripcion'], [
        (1, 'Administrador', 'Administra el funcionamiento del taller'),
        (2, 'Mecanico', 'Realiza los trabajos y reparaciones de vehículos')],
        'Roles operativos del taller (el SuperAdmin NO es un rol: usuarios.tipo_cuenta = superadmin)'))
    filas = []
    for u in usuarios_mvp:
        m = mec_por_usuario.get(u['id'])
        sa = u['tipo_cuenta'] == 'superadmin'
        filas.append((uid[u['id']], 'superadmin' if sa else 'taller', None if sa else rol_sql[cod_rol[u['rol_id']]], u['nombre'], u['usuario'],
                      H[u['usuario']], u.get('email'), u.get('telefono'), m['especialidad'] if m else None, m['disponible'] if m else 1,
                      estado_u[u['estado']], u['debe_cambiar_clave'], 0, None, None, dts(u['created_at'])))
    S.append(insert('usuarios', ['id', 'tipo_cuenta', 'rol_id', 'nombre', 'usuario', 'password_hash', 'email', 'telefono', 'especialidad',
                                 'disponible', 'estado', 'debe_cambiar_password', 'intentos_fallidos', 'bloqueado_hasta', 'ultimo_ingreso', 'creado_en'], filas,
                    'Usuarios (contraseñas de DEMOSTRACIÓN almacenadas como hash bcrypt; ver README de la base de datos)'))
    sa0 = d['superadmins'][0]
    S.append(insert('superadmins', ['id', 'usuario_id', 'creado_en', 'observaciones'], [(1, uid[sa0['usuario_id']], dts(sa0['created_at']), sa0['cargo'])]))
    t = [x for x in d['talleres'] if x['id'] == T][0]
    S.append(insert('taller', ['id', 'nombre', 'telefono', 'direccion', 'admin_usuario_id', 'estado_acceso', 'creado_en'],
                    [(1, t['nombre'], t['telefono'], t['direccion'], uid[t['dueno_id']], 'activo', dts(t['created_at']))]))

    # ---------------- clientes y vehículos ----------------
    S.append(insert('clientes', ['id', 'nombre', 'dni', 'telefono', 'email', 'direccion', 'creado_en'],
                    [(c['id'], c['nombre'], None, c['telefono'], c.get('email'), c.get('direccion'), dts(c['created_at'])) for c in d['clientes'] if c['taller_id'] == T],
                    'Clientes'))
    dueno = {p['vehiculo_id']: p['cliente_id'] for p in d['vehiculo_propietarios'] if p['es_actual']}
    S.append(insert('vehiculos', ['id', 'cliente_id', 'patente', 'marca', 'modelo', 'anio', 'color', 'kilometraje', 'observaciones'],
                    [(v['id'], dueno[v['id']], v.get('patente'), v['marca'], v['modelo'], v.get('anio'), None, v.get('km'), None) for v in d['vehiculos'] if v['taller_id'] == T],
                    'Vehículos (cliente_id = propietario actual; ver vehiculo_propietarios en el mapeo)'))

    # ---------------- consultas ----------------
    rev = {r['consulta_id']: r for r in d['consulta_revisiones']}
    est_cons = {'pendiente': 'abierta', 'en_presupuesto': 'esperando_respuesta', 'aprobada': 'aprobada', 'cerrada': 'cerrada'}
    filas = []
    for k in d['consultas']:
        r = rev.get(k['id'])
        tec = (r or {}).get('tecnicas') or None
        filas.append((k['id'], k['cliente_id'], k['vehiculo_id'], k['nombre_contacto'], None, k['telefono_contacto'], k.get('patente'), k.get('marca'), k.get('modelo'),
                      k.get('anio'), k.get('km'), (k['problema'] or '')[:200], k['problema'], k.get('observaciones'), tec,
                      (r or {}).get('importe_estimado') if r else None, est_cons[k['estado']], k['es_gratuita'], k.get('cobro_decision'), k.get('cobro_importe'),
                      uid[k['cobro_por']] if k.get('cobro_por') else None, k.get('cobro_fecha'), k.get('motivo_cierre'), uid[k['creada_por']], dts(k['created_at'])))
    S.append(insert('consultas', ['id', 'cliente_id', 'vehiculo_id', 'contacto_nombre', 'contacto_dni', 'contacto_telefono', 'veh_patente', 'veh_marca', 'veh_modelo',
                                  'veh_anio', 'veh_kilometraje', 'motivo', 'descripcion_problema', 'observaciones', 'observaciones_inspeccion', 'importe_estimado',
                                  'estado', 'es_gratuita', 'cobro_decision', 'cobro_importe', 'cobro_por', 'cobro_fecha', 'motivo_cierre', 'creado_por', 'creado_en'], filas,
                    'Consultas (motivo = primeros 200 caracteres del problema informado)'))
    filas = []
    n = 0
    for r in d['consulta_revisiones']:
        base = dts(r['fecha'] + ' 12:00')
        for tipo, campo in (('verificado', 'problemas'), ('repuestos_necesarios', 'repuestos_necesarios'), ('trabajo_recomendado', 'trabajo_recomendado')):
            if r.get(campo):
                n += 1
                filas.append((n, r['consulta_id'], r[campo], tipo, uid[r['usuario_id']], base))
    S.append(insert('detalles_consultas', ['id', 'consulta_id', 'descripcion', 'tipo', 'registrado_por', 'creado_en'], filas,
                    'Revisión técnica distribuida en filas por tipo (colección consulta_revisiones del MVP)'))

    # ---------------- presupuestos ----------------
    dueno_id = uid[t['dueno_id']]
    tot = {}
    for x in d['presupuesto_detalles']:
        tot[x['presupuesto_id']] = tot.get(x['presupuesto_id'], 0) + x['cantidad'] * x['precio_unitario']
    pct_orden = {o['presupuesto_id']: o.get('comision_pct', 0) for o in d['ordenes_trabajo']}
    est_pres = {'borrador': 'borrador', 'pendiente': 'enviado', 'aceptado': 'aceptado', 'rechazado': 'rechazado'}
    filas = []
    for p in d['presupuestos']:
        comis = pct_orden.get(p['id'], 0)   # el porcentaje se define en la orden; el presupuesto lo conserva igual
        filas.append((p['id'], p['consulta_id'], p['numero'], tot[p['id']], tot[p['id']], comis, est_pres[p['estado']], p.get('valido_hasta'),
                      dts(p.get('fecha_envio')), dts(p.get('fecha_decision')), dueno_id, dts(p['fecha_creacion'] + ' 10:00')))
        assert abs(tot[p['id']] - p['total']) < 0.01, ('total distinto', p['id'])
    S.append(insert('presupuestos', ['id', 'consulta_id', 'numero', 'total_calculado', 'precio_final', 'comision_pct', 'estado', 'valido_hasta', 'fecha_envio',
                                     'fecha_respuesta', 'creado_por', 'creado_en'], filas,
                    'Presupuestos (comision_pct = el de su orden de trabajo; 0 si todavía no tiene orden)'))
    S.append(insert('detalles_presupuestos', ['id', 'presupuesto_id', 'concepto', 'tipo', 'cantidad', 'precio_unitario', 'catalogo_item_id'],
                    [(x['id'], x['presupuesto_id'], x['descripcion'], x['tipo'], x['cantidad'], x['precio_unitario'], None) for x in d['presupuesto_detalles']],
                    'Detalles de presupuestos (monto es columna generada: cantidad x precio_unitario)'))

    # ---------------- catálogo y stock ----------------
    S.append(insert('categorias_catalogo', ['id', 'nombre', 'descripcion', 'activo'], [(c['id'], c['nombre'], None, 1) for c in d['categorias_repuesto'] if c['taller_id'] == T],
                    'Catálogo: categorías (colección categorias_repuesto)'))
    S.append(insert('catalogo_items', ['id', 'categoria_id', 'tipo', 'nombre', 'codigo', 'marca', 'ubicacion', 'precio_compra', 'precio_venta', 'cantidad', 'stock_minimo', 'activo'],
                    [(r['id'], r['categoria_id'], 'repuesto', r['nombre'], r['codigo'], r.get('marca'), r.get('ubicacion'), r['costo'], r.get('precio_referencia') or 0,
                      r['cantidad'], r['minimo'], 1) for r in d['repuestos'] if r['taller_id'] == T],
                    'Catálogo: artículos (colección repuestos; alerta_stock se deduce de cantidad <= stock_minimo)'))
    fil = [r for r in d['repuestos'] if r['codigo'] == 'FIL-OIL'][0]

    # ---------------- órdenes de trabajo ----------------
    est_ord = {'sin_asignar': 'sin_asignar', 'pendiente_aceptacion': 'ofrecido', 'aceptado': 'aceptado', 'en_proceso': 'en_proceso', 'finalizado': 'finalizado', 'cancelado': 'cancelado'}
    pres = {p['id']: p for p in d['presupuestos']}
    hist = {}
    for h in d['orden_estados_historial']:
        hist.setdefault(h['orden_id'], []).append(h)
    filas = []
    for o in d['ordenes_trabajo']:
        hs = hist[o['id']]
        ini = next((h['created_at'] for h in hs if h['estado'] == 'en_proceso'), None)
        fin = next((h['created_at'] for h in hs if h['estado'] == 'finalizado'), None)
        filas.append((o['id'], o['numero'], o['presupuesto_id'], o['cliente_id'], o['vehiculo_id'], mec2u[o['mecanico_id']] if o.get('mecanico_id') else None,
                      o['descripcion'], o.get('repuestos_previstos'), o.get('observaciones'), est_ord[o['estado']], tot[o['presupuesto_id']], o.get('comision_pct', 0), None,
                      dts(o['fecha_creacion'] + ' 11:00'), o.get('inicio_previsto'), o.get('entrega_prevista'), dts(ini), dts(fin)))
    S.append(insert('ordenes_trabajo', ['id', 'numero', 'presupuesto_id', 'cliente_id', 'vehiculo_id', 'mecanico_id', 'descripcion', 'repuestos_previstos', 'observaciones',
                                        'estado', 'precio_final', 'comision_pct', 'observaciones_mecanico', 'creado_en', 'inicio_previsto', 'entrega_prevista', 'fecha_inicio', 'fecha_fin'], filas,
                    'Órdenes de trabajo (pendiente_aceptacion del MVP = ofrecido)'))
    filas = []
    n = 0
    for h in d['orden_estados_historial']:
        n += 1
        previos = [x for x in hist[h['orden_id']] if x['id'] < h['id']]
        ant = est_ord[previos[-1]['estado']] if previos else None
        filas.append((h['id'], h['orden_id'], ant, est_ord[h['estado']], uid[h['usuario_id']], h.get('nota'), dts(h['created_at'])))
    S.append(insert('historial_estados_ordenes', ['id', 'orden_id', 'estado_anterior', 'estado_nuevo', 'cambiado_por', 'observacion', 'fecha'], filas))
    res_asig = {'pendiente': 'ofrecida', 'aceptada': 'aceptada', 'rechazada': 'rechazada', 'reasignada': 'reasignada'}
    S.append(insert('asignaciones_trabajo', ['id', 'orden_id', 'mecanico_id', 'asignado_por', 'resultado', 'motivo_rechazo', 'creado_en', 'resuelto_en'],
                    [(a['id'], a['orden_id'], mec2u[a['mecanico_id']], uid[a['asignado_por']], res_asig[a['respuesta']], a.get('motivo_rechazo'), dts(a['fecha_asignacion']), dts(a.get('fecha_respuesta')))
                     for a in d['orden_asignaciones']], 'Asignaciones de mecánicos (pendiente del MVP = ofrecida)'))
    S.append(insert('avances_ordenes', ['id', 'orden_id', 'usuario_id', 'texto', 'creado_en'],
                    [(a['id'], a['orden_id'], uid[a['usuario_id']], a['texto'], dts(a['created_at'])) for a in d['orden_avances']],
                    'Avances de las órdenes (colección orden_avances)'))

    # ---------------- pagos de clientes ----------------
    medio = {m['id']: m['codigo'] for m in d['medios_pago']}
    medios_pago = {}
    for m in d['pago_cliente_medios']:
        medios_pago.setdefault(m['pago_id'], []).append(m)
    filas = []
    for p in d['pagos_cliente']:
        ms = medios_pago[p['id']]
        metodo = medio[ms[0]['medio_id']] if len(ms) == 1 else 'combinado'
        filas.append((p['id'], 'trabajo' if p.get('orden_id') else 'venta_mostrador', p.get('orden_id'), p['cliente_id'], p['importe'], metodo, uid[p['registrado_por']],
                      dts(p['created_at']), p.get('observaciones')))
    S.append(insert('pagos_clientes', ['id', 'tipo', 'orden_id', 'cliente_id', 'monto', 'metodo', 'registrado_por', 'fecha', 'observaciones'], filas,
                    'Pagos de CLIENTES al taller (colección pagos_cliente)'))
    filas = []
    n = 0
    for p in d['pagos_cliente']:
        for m in medios_pago[p['id']]:
            n += 1
            filas.append((n, p['id'], medio[m['medio_id']], m['importe'], None))
    S.append(insert('detalles_pagos_clientes', ['id', 'pago_cliente_id', 'medio', 'importe', 'referencia'], filas, 'Medios de cada pago de cliente (colección pago_cliente_medios)'))

    # ---------------- movimientos de stock ----------------
    filas = []
    for m in d['movimientos_stock']:
        tipo = 'entrada' if m['tipo'] in ('entrada', 'reversion') else 'salida'
        motivo = m.get('nota') or ('Entrada de stock' if tipo == 'entrada' else 'Salida de stock')
        u = uid[m['usuario_id']]
        filas.append((m['id'], m['repuesto_id'], None, tipo, m['cantidad'], 'confirmado', 0, motivo[:150], m.get('orden_id'), None, u, u, dts(m['created_at'])))
    S.append(insert('movimientos_stock', ['id', 'catalogo_item_id', 'descripcion_libre', 'tipo', 'cantidad', 'estado', 'aportado_cliente', 'motivo', 'orden_id', 'pago_cliente_id',
                                          'solicitado_por', 'resuelto_por', 'fecha'], filas,
                    'Movimientos de stock (uso_orden del MVP = salida con orden_id; reversion = entrada con orden_id)'))

    # ---------------- comisiones, adelantos y liquidaciones (del MVP) ----------------
    ref = date.fromisoformat(d['suscripciones'][0]['fecha_inicio'])   # inicio del ciclo vigente = hoy - 18 días
    hoy = ref + timedelta(days=18)
    S.append(insert('movimientos_mecanicos', ['id', 'mecanico_id', 'tipo', 'monto', 'orden_id', 'registrado_por', 'fecha', 'descripcion'],
                    [(m['id'], mec2u[m['mecanico_id']], m['tipo'], m['monto'], m.get('orden_id'), uid[m['registrado_por']], dts(m['fecha']), m['descripcion']) for m in d['movimientos_mecanico']],
                    'Comisiones y adelantos (colección movimientos_mecanico del MVP; mecanico_id del MVP = mecanicos.id -> usuarios.id)'))
    S.append(insert('liquidaciones_mecanicos', ['id', 'mecanico_id', 'periodo_desde', 'periodo_hasta', 'total_comisiones', 'total_adelantos', 'total_a_pagar', 'estado', 'creado_por', 'fecha_creacion', 'fecha_pago', 'observaciones'],
                    [(l['id'], mec2u[l['mecanico_id']], l['periodo_desde'], l['periodo_hasta'], l['total_comisiones'], l['total_adelantos'], l['total_a_pagar'], l['estado'], uid[l['creado_por']],
                      dts(l['fecha_creacion']), dts(l.get('fecha_pago')), l.get('observaciones')) for l in d['liquidaciones']],
                    'Liquidaciones (colección liquidaciones del MVP: una pagada, una pendiente y una anulada)'))
    S.append(insert('detalles_liquidaciones_mecanicos', ['id', 'liquidacion_id', 'movimiento_mecanico_id', 'importe_incluido'],
                    [(x['id'], x['liquidacion_id'], x['movimiento_id'], x['importe_incluido']) for x in d['liquidacion_detalles']],
                    'Movimientos incluidos en cada liquidación (una liquidación anulada libera los suyos: no tiene detalles)'))
    fil = [r for r in d['repuestos'] if r['codigo'] == 'FIL-OIL'][0]
    S.append('-- DATO DE PRUEBA (no proviene del MVP): el MVP no genera historial de precios del catálogo.\n')
    S.append(insert('historial_precios_catalogo', ['id', 'catalogo_item_id', 'precio_compra_anterior', 'precio_compra_nuevo', 'precio_venta_anterior', 'precio_venta_nuevo', 'cambiado_por', 'fecha'],
                    [(1, fil['id'], 3200, fil['costo'], 6500, fil['precio_referencia'], dueno_id, dts((hoy - timedelta(days=20)).isoformat() + ' 10:00'))],
                    'DATO DE PRUEBA: ajuste de precio del filtro de aceite (los precios "nuevos" coinciden con los actuales del catálogo)'))

    # ---------------- suscripción del taller (planes del MVP: mensual) ----------------
    s1 = [x for x in d['suscripciones'] if x['taller_id'] == T][0]
    pc1 = [x for x in d['pagos_suscripcion'] if x['taller_id'] == T and x['estado'] == 'confirmado'][0]
    pp = [x for x in d['pagos_suscripcion'] if x['taller_id'] == T and x['estado'] == 'pendiente'][0]
    ini2 = date.fromisoformat(s1['fecha_inicio']); ven2 = date.fromisoformat(s1['fecha_vencimiento'])
    ini1 = date.fromisoformat('%04d-%02d-%02d' % ((ini2.year - 1, 12, ini2.day) if ini2.month == 1 else (ini2.year, ini2.month - 1, ini2.day)))
    S.append(insert('periodos_pago_sistema', ['id', 'taller_id', 'numero', 'modalidad', 'fecha_inicio', 'fecha_vencimiento', 'importe', 'dias_tolerancia', 'fecha_fin_tolerancia', 'estado', 'fecha_pago_confirmado', 'creado_en'],
                    [(1, 1, 1, 'mensual', ini1.isoformat(), ini2.isoformat(), s1['importe'], 3, (ini2 + timedelta(days=3)).isoformat(), 'pagado', dts(pc1['fecha_decision'] + ' 09:00'), dts(ini1.isoformat() + ' 09:00')),
                     (2, 1, 2, 'mensual', ini2.isoformat(), ven2.isoformat(), s1['importe'], 3, (ven2 + timedelta(days=3)).isoformat(), 'vigente', None, dts(ini2.isoformat() + ' 09:00'))],
                    'Suscripción: ciclo 1 (pagado) y ciclo 2 (vigente = suscripción actual del MVP, vence en 12 días)'))
    S.append(insert('pagos_sistema', ['id', 'periodo_id', 'importe_total', 'metodo', 'estado', 'registrado_por', 'confirmado_por', 'fecha_registro', 'fecha_confirmacion', 'motivo_rechazo', 'observaciones'],
                    [(1, 1, pc1['importe'], 'combinado', 'confirmado', dueno_id, 1, dts(pc1['fecha'] + ' 09:00'), dts(pc1['fecha_decision'] + ' 09:00'), None, 'Pago informado por el dueño y confirmado por el SuperAdmin'),
                     (2, 2, pp['importe'], 'transferencia', 'informado', dueno_id, None, dts(pp['fecha'] + ' 09:00'), None, None, 'Pago informado por el dueño, pendiente de confirmar')],
                    'Pagos del SISTEMA (el dueño paga la suscripción al SuperAdmin) — distinto de pagos_clientes'))
    S.append(insert('detalles_pagos_sistema', ['id', 'pago_id', 'medio', 'importe', 'referencia'],
                    [(1, 1, 'efectivo', 10000, None), (2, 1, 'transferencia', 20000, pc1.get('referencia')), (3, 2, 'transferencia', pp['importe'], pp.get('referencia'))]))

    # ---------------- notificaciones (el MVP las dirige por rol; MySQL las guarda por destinatario) ----------------
    filas = []
    n = 0
    admin_ids = [dueno_id]
    mec_ids = [uid[u['id']] for u in usuarios_mvp if u['tipo_cuenta'] == 'taller' and cod_rol[u['rol_id']] == 'mecanico']
    for nt in d['notificaciones']:
        if nt.get('rol_destino') == 'superadmin':
            n += 1
            filas.append((n, None, 1, nt['texto'], nt.get('ruta'), nt['tipo'], (nt['clave_unica'] + ':sa') if nt.get('clave_unica') else None, nt['leida'], dts(nt['created_at'])))
            continue
        destinos = [uid[nt['usuario_id']]] if nt.get('usuario_id') else (admin_ids if nt.get('rol_destino') == 'admin' else mec_ids)
        for dest in destinos:
            n += 1
            clave = (nt['clave_unica'] + f':u{dest}') if nt.get('clave_unica') else None
            filas.append((n, dest, None, nt['texto'], nt.get('ruta'), nt['tipo'], clave, nt['leida'], dts(nt['created_at'])))
    S.append(insert('notificaciones', ['id', 'usuario_id', 'superadmin_id', 'texto', 'enlace', 'tipo', 'clave_unica', 'leida', 'creada_en'], filas,
                    'Notificaciones (las de rol del MVP se expanden a un registro por destinatario; la del SuperAdmin es la del pago informado)'))

    # ---------------- auditoría ----------------
    filas = []
    n = 0
    for a in d['auditoria']:
        if a.get('taller_id') not in (T, None):
            continue
        n += 1
        det = json.dumps({'detalle': a['detalle']}, ensure_ascii=False)
        if a['ambito'] == 'sistema':
            filas.append((n, None, 1, login[uid[a['usuario_id']]], 'sistema', a['accion'], a.get('entidad'), a.get('entidad_id'), det, None, dts(a['created_at'])))
        else:
            filas.append((n, uid[a['usuario_id']], None, login[uid[a['usuario_id']]], 'taller', a['accion'], a.get('entidad'), a.get('entidad_id'), det, None, dts(a['created_at'])))
    S.append(insert('auditoria', ['id', 'usuario_id', 'superadmin_id', 'actor_login', 'ambito', 'accion', 'entidad', 'entidad_id', 'detalle', 'ip', 'fecha'], filas, 'Auditoría'))

    # ---------------- propuestas de mejora de redacción ----------------
    rev_c = {r['id']: r['consulta_id'] for r in d['consulta_revisiones']}; av_o = {x['id']: x['orden_id'] for x in d['orden_avances']}
    def ia(p):
        e = p['entidad']
        if e == 'consultas': return ('problema_consulta', p['entidad_id'], None)
        if e == 'consulta_revisiones': return ('inspeccion', rev_c[p['entidad_id']], None)
        return ('observacion_mecanico', None, av_o[p['entidad_id']])
    S.append(insert('propuestas_ia', ['id', 'usuario_id', 'contexto', 'consulta_id', 'orden_id', 'texto_original', 'texto_propuesto', 'texto_final', 'estado', 'proveedor', 'modelo', 'creada_en', 'resuelta_en'],
                    [(p['id'], uid[p['usuario_id']], ia(p)[0], ia(p)[1], ia(p)[2], p['texto_original'], p['texto_propuesto'], p['texto_final'], p['estado'], p['proveedor'], None, dts(p['created_at']), dts(p['created_at'])) for p in d['ia_propuestas']],
                    'Propuestas de mejora de redacción (proveedor local de reglas; no se usa ninguna IA externa)'))
    return '\n'.join(out) + '\n'


def hashes_demo():
    """Hashes bcrypt de las contraseñas de DEMOSTRACIÓN (se generan una vez y se guardan para que el SQL sea estable)."""
    ruta = os.path.join(AQUI, 'hashes_demo.json')
    claves = {'superadmin': 'Super123', 'roberto': 'Dueno123', 'juan': 'Mecanico123', 'pedro': 'Mecanico123', 'carlos': 'Mecanico123'}
    if os.path.exists(ruta):
        return json.load(open(ruta, encoding='utf-8'))
    import bcrypt
    h = {u: bcrypt.hashpw(c.encode(), bcrypt.gensalt(rounds=10)).decode() for u, c in claves.items()}
    json.dump(h, open(ruta, 'w', encoding='utf-8'), indent=1)
    return h


def generar(seed_path):
    d = json.load(open(seed_path, encoding='utf-8'))
    H = hashes_demo()
    S = []  # bloques SQL
    T = 1   # taller del MVP que se conserva
    hoy = None  # fecha de referencia = fecha del seed (se deduce de la suscripción)

    # ---------------- usuarios ----------------
    mec_por_usuario = {m['usuario_id']: m for m in d['mecanicos'] if m['taller_id'] == T}
    cod_rol = {r['id']: r['codigo'] for r in d['roles']}   # los roles se resuelven por CÓDIGO, no por número
    usuarios_mvp = [u for u in d['usuarios'] if u['tipo_cuenta'] == 'superadmin' or u.get('taller_id') == T]
    uid = {}          # id usuario MVP -> id SQL (contiguo)
    for i, u in enumerate(usuarios_mvp, 1):
        uid[u['id']] = i
    mec2u = {m['id']: uid[m['usuario_id']] for m in d['mecanicos'] if m['taller_id'] == T}  # id mecánico MVP -> id usuario SQL
    login = {uid[u['id']]: u['usuario'] for u in usuarios_mvp}
    rol_sql = {'admin': 1, 'mecanico': 2}   # código de rol del MVP -> id de la tabla roles de MySQL
    estado_u = {'activo': 'activo', 'inactivo': 'pausado', 'suspendido': 'suspendido'}

    S.append(insert('roles', ['id', 'nombre', 'descripcion'], [
        (1, 'Administrador', 'Administra el funcionamiento del taller'),
        (2, 'Mecanico', 'Realiza los trabajos y reparaciones de vehículos')],
        'Roles operativos del taller (el SuperAdmin NO es un rol: usuarios.tipo_cuenta = superadmin)'))
    filas = []
    for u in usuarios_mvp:
        m = mec_por_usuario.get(u['id'])
        sa = u['tipo_cuenta'] == 'superadmin'
        filas.append((uid[u['id']], 'superadmin' if sa else 'taller', None if sa else rol_sql[cod_rol[u['rol_id']]], u['nombre'], u['usuario'],
                      H[u['usuario']], u.get('email'), u.get('telefono'), m['especialidad'] if m else None, m['disponible'] if m else 1,
                      estado_u[u['estado']], u['debe_cambiar_clave'], 0, None, None, dts(u['created_at'])))
    S.append(insert('usuarios', ['id', 'tipo_cuenta', 'rol_id', 'nombre', 'usuario', 'password_hash', 'email', 'telefono', 'especialidad',
                                 'disponible', 'estado', 'debe_cambiar_password', 'intentos_fallidos', 'bloqueado_hasta', 'ultimo_ingreso', 'creado_en'], filas,
                    'Usuarios (contraseñas de DEMOSTRACIÓN almacenadas como hash bcrypt; ver README de la base de datos)'))
    sa0 = d['superadmins'][0]
    S.append(insert('superadmins', ['id', 'usuario_id', 'creado_en', 'observaciones'], [(1, uid[sa0['usuario_id']], dts(sa0['created_at']), sa0['cargo'])]))
    t = [x for x in d['talleres'] if x['id'] == T][0]
    S.append(insert('taller', ['id', 'nombre', 'telefono', 'direccion', 'admin_usuario_id', 'estado_acceso', 'creado_en'],
                    [(1, t['nombre'], t['telefono'], t['direccion'], uid[t['dueno_id']], 'activo', dts(t['created_at']))]))

    # ---------------- clientes y vehículos ----------------
    S.append(insert('clientes', ['id', 'nombre', 'dni', 'telefono', 'email', 'direccion', 'creado_en'],
                    [(c['id'], c['nombre'], None, c['telefono'], c.get('email'), c.get('direccion'), dts(c['created_at'])) for c in d['clientes'] if c['taller_id'] == T],
                    'Clientes'))
    dueno = {p['vehiculo_id']: p['cliente_id'] for p in d['vehiculo_propietarios'] if p['es_actual']}
    S.append(insert('vehiculos', ['id', 'cliente_id', 'patente', 'marca', 'modelo', 'anio', 'color', 'kilometraje', 'observaciones'],
                    [(v['id'], dueno[v['id']], v.get('patente'), v['marca'], v['modelo'], v.get('anio'), None, v.get('km'), None) for v in d['vehiculos'] if v['taller_id'] == T],
                    'Vehículos (cliente_id = propietario actual; ver vehiculo_propietarios en el mapeo)'))

    # ---------------- consultas ----------------
    rev = {r['consulta_id']: r for r in d['consulta_revisiones']}
    est_cons = {'pendiente': 'abierta', 'en_presupuesto': 'esperando_respuesta', 'aprobada': 'aprobada', 'cerrada': 'cerrada'}
    filas = []
    for k in d['consultas']:
        r = rev.get(k['id'])
        tec = (r or {}).get('tecnicas') or None
        filas.append((k['id'], k['cliente_id'], k['vehiculo_id'], k['nombre_contacto'], None, k['telefono_contacto'], k.get('patente'), k.get('marca'), k.get('modelo'),
                      k.get('anio'), k.get('km'), (k['problema'] or '')[:200], k['problema'], k.get('observaciones'), tec,
                      (r or {}).get('importe_estimado') if r else None, est_cons[k['estado']], k['es_gratuita'], k.get('cobro_decision'), k.get('cobro_importe'),
                      uid[k['cobro_por']] if k.get('cobro_por') else None, k.get('cobro_fecha'), k.get('motivo_cierre'), uid[k['creada_por']], dts(k['created_at'])))
    S.append(insert('consultas', ['id', 'cliente_id', 'vehiculo_id', 'contacto_nombre', 'contacto_dni', 'contacto_telefono', 'veh_patente', 'veh_marca', 'veh_modelo',
                                  'veh_anio', 'veh_kilometraje', 'motivo', 'descripcion_problema', 'observaciones', 'observaciones_inspeccion', 'importe_estimado',
                                  'estado', 'es_gratuita', 'cobro_decision', 'cobro_importe', 'cobro_por', 'cobro_fecha', 'motivo_cierre', 'creado_por', 'creado_en'], filas,
                    'Consultas (motivo = primeros 200 caracteres del problema informado)'))
    filas = []
    n = 0
    for r in d['consulta_revisiones']:
        base = dts(r['fecha'] + ' 12:00')
        for tipo, campo in (('verificado', 'problemas'), ('repuestos_necesarios', 'repuestos_necesarios'), ('trabajo_recomendado', 'trabajo_recomendado')):
            if r.get(campo):
                n += 1
                filas.append((n, r['consulta_id'], r[campo], tipo, uid[r['usuario_id']], base))
    S.append(insert('detalles_consultas', ['id', 'consulta_id', 'descripcion', 'tipo', 'registrado_por', 'creado_en'], filas,
                    'Revisión técnica distribuida en filas por tipo (colección consulta_revisiones del MVP)'))

    # ---------------- presupuestos ----------------
    dueno_id = uid[t['dueno_id']]
    tot = {}
    for x in d['presupuesto_detalles']:
        tot[x['presupuesto_id']] = tot.get(x['presupuesto_id'], 0) + x['cantidad'] * x['precio_unitario']
    pct_orden = {o['presupuesto_id']: o.get('comision_pct', 0) for o in d['ordenes_trabajo']}
    est_pres = {'borrador': 'borrador', 'pendiente': 'enviado', 'aceptado': 'aceptado', 'rechazado': 'rechazado'}
    filas = []
    for p in d['presupuestos']:
        comis = pct_orden.get(p['id'], 0)   # el porcentaje se define en la orden; el presupuesto lo conserva igual
        filas.append((p['id'], p['consulta_id'], p['numero'], tot[p['id']], tot[p['id']], comis, est_pres[p['estado']], p.get('valido_hasta'),
                      dts(p.get('fecha_envio')), dts(p.get('fecha_decision')), dueno_id, dts(p['fecha_creacion'] + ' 10:00')))
        assert abs(tot[p['id']] - p['total']) < 0.01, ('total distinto', p['id'])
    S.append(insert('presupuestos', ['id', 'consulta_id', 'numero', 'total_calculado', 'precio_final', 'comision_pct', 'estado', 'valido_hasta', 'fecha_envio',
                                     'fecha_respuesta', 'creado_por', 'creado_en'], filas,
                    'Presupuestos (comision_pct = el de su orden de trabajo; 0 si todavía no tiene orden)'))
    S.append(insert('detalles_presupuestos', ['id', 'presupuesto_id', 'concepto', 'tipo', 'cantidad', 'precio_unitario', 'catalogo_item_id'],
                    [(x['id'], x['presupuesto_id'], x['descripcion'], x['tipo'], x['cantidad'], x['precio_unitario'], None) for x in d['presupuesto_detalles']],
                    'Detalles de presupuestos (monto es columna generada: cantidad x precio_unitario)'))

    # ---------------- catálogo y stock ----------------
    S.append(insert('categorias_catalogo', ['id', 'nombre', 'descripcion', 'activo'], [(c['id'], c['nombre'], None, 1) for c in d['categorias_repuesto'] if c['taller_id'] == T],
                    'Catálogo: categorías (colección categorias_repuesto)'))
    S.append(insert('catalogo_items', ['id', 'categoria_id', 'tipo', 'nombre', 'codigo', 'marca', 'ubicacion', 'precio_compra', 'precio_venta', 'cantidad', 'stock_minimo', 'activo'],
                    [(r['id'], r['categoria_id'], 'repuesto', r['nombre'], r['codigo'], r.get('marca'), r.get('ubicacion'), r['costo'], r.get('precio_referencia') or 0,
                      r['cantidad'], r['minimo'], 1) for r in d['repuestos'] if r['taller_id'] == T],
                    'Catálogo: artículos (colección repuestos; alerta_stock se deduce de cantidad <= stock_minimo)'))
    fil = [r for r in d['repuestos'] if r['codigo'] == 'FIL-OIL'][0]

    # ---------------- órdenes de trabajo ----------------
    est_ord = {'sin_asignar': 'sin_asignar', 'pendiente_aceptacion': 'ofrecido', 'aceptado': 'aceptado', 'en_proceso': 'en_proceso', 'finalizado': 'finalizado', 'cancelado': 'cancelado'}
    pres = {p['id']: p for p in d['presupuestos']}
    hist = {}
    for h in d['orden_estados_historial']:
        hist.setdefault(h['orden_id'], []).append(h)
    filas = []
    for o in d['ordenes_trabajo']:
        hs = hist[o['id']]
        ini = next((h['created_at'] for h in hs if h['estado'] == 'en_proceso'), None)
        fin = next((h['created_at'] for h in hs if h['estado'] == 'finalizado'), None)
        filas.append((o['id'], o['numero'], o['presupuesto_id'], o['cliente_id'], o['vehiculo_id'], mec2u[o['mecanico_id']] if o.get('mecanico_id') else None,
                      o['descripcion'], o.get('repuestos_previstos'), o.get('observaciones'), est_ord[o['estado']], tot[o['presupuesto_id']], o.get('comision_pct', 0), None,
                      dts(o['fecha_creacion'] + ' 11:00'), o.get('inicio_previsto'), o.get('entrega_prevista'), dts(ini), dts(fin)))
    S.append(insert('ordenes_trabajo', ['id', 'numero', 'presupuesto_id', 'cliente_id', 'vehiculo_id', 'mecanico_id', 'descripcion', 'repuestos_previstos', 'observaciones',
                                        'estado', 'precio_final', 'comision_pct', 'observaciones_mecanico', 'creado_en', 'inicio_previsto', 'entrega_prevista', 'fecha_inicio', 'fecha_fin'], filas,
                    'Órdenes de trabajo (pendiente_aceptacion del MVP = ofrecido)'))
    filas = []
    n = 0
    for h in d['orden_estados_historial']:
        n += 1
        previos = [x for x in hist[h['orden_id']] if x['id'] < h['id']]
        ant = est_ord[previos[-1]['estado']] if previos else None
        filas.append((h['id'], h['orden_id'], ant, est_ord[h['estado']], uid[h['usuario_id']], h.get('nota'), dts(h['created_at'])))
    S.append(insert('historial_estados_ordenes', ['id', 'orden_id', 'estado_anterior', 'estado_nuevo', 'cambiado_por', 'observacion', 'fecha'], filas))
    res_asig = {'pendiente': 'ofrecida', 'aceptada': 'aceptada', 'rechazada': 'rechazada', 'reasignada': 'reasignada'}
    S.append(insert('asignaciones_trabajo', ['id', 'orden_id', 'mecanico_id', 'asignado_por', 'resultado', 'motivo_rechazo', 'creado_en', 'resuelto_en'],
                    [(a['id'], a['orden_id'], mec2u[a['mecanico_id']], uid[a['asignado_por']], res_asig[a['respuesta']], a.get('motivo_rechazo'), dts(a['fecha_asignacion']), dts(a.get('fecha_respuesta')))
                     for a in d['orden_asignaciones']], 'Asignaciones de mecánicos (pendiente del MVP = ofrecida)'))
    S.append(insert('avances_ordenes', ['id', 'orden_id', 'usuario_id', 'texto', 'creado_en'],
                    [(a['id'], a['orden_id'], uid[a['usuario_id']], a['texto'], dts(a['created_at'])) for a in d['orden_avances']],
                    'Avances de las órdenes (colección orden_avances)'))

    # ---------------- pagos de clientes ----------------
    medio = {m['id']: m['codigo'] for m in d['medios_pago']}
    medios_pago = {}
    for m in d['pago_cliente_medios']:
        medios_pago.setdefault(m['pago_id'], []).append(m)
    filas = []
    for p in d['pagos_cliente']:
        ms = medios_pago[p['id']]
        metodo = medio[ms[0]['medio_id']] if len(ms) == 1 else 'combinado'
        filas.append((p['id'], 'trabajo' if p.get('orden_id') else 'venta_mostrador', p.get('orden_id'), p['cliente_id'], p['importe'], metodo, uid[p['registrado_por']],
                      dts(p['created_at']), p.get('observaciones')))
    S.append(insert('pagos_clientes', ['id', 'tipo', 'orden_id', 'cliente_id', 'monto', 'metodo', 'registrado_por', 'fecha', 'observaciones'], filas,
                    'Pagos de CLIENTES al taller (colección pagos_cliente)'))
    filas = []
    n = 0
    for p in d['pagos_cliente']:
        for m in medios_pago[p['id']]:
            n += 1
            filas.append((n, p['id'], medio[m['medio_id']], m['importe'], None))
    S.append(insert('detalles_pagos_clientes', ['id', 'pago_cliente_id', 'medio', 'importe', 'referencia'], filas, 'Medios de cada pago de cliente (colección pago_cliente_medios)'))

    # ---------------- movimientos de stock ----------------
    filas = []
    for m in d['movimientos_stock']:
        tipo = 'entrada' if m['tipo'] in ('entrada', 'reversion') else 'salida'
        motivo = m.get('nota') or ('Entrada de stock' if tipo == 'entrada' else 'Salida de stock')
        u = uid[m['usuario_id']]
        filas.append((m['id'], m['repuesto_id'], None, tipo, m['cantidad'], 'confirmado', 0, motivo[:150], m.get('orden_id'), None, u, u, dts(m['created_at'])))
    S.append(insert('movimientos_stock', ['id', 'catalogo_item_id', 'descripcion_libre', 'tipo', 'cantidad', 'estado', 'aportado_cliente', 'motivo', 'orden_id', 'pago_cliente_id',
                                          'solicitado_por', 'resuelto_por', 'fecha'], filas,
                    'Movimientos de stock (uso_orden del MVP = salida con orden_id; reversion = entrada con orden_id)'))

    # ---------------- comisiones, adelantos y liquidaciones (del MVP) ----------------
    ref = date.fromisoformat(d['suscripciones'][0]['fecha_inicio'])   # inicio del ciclo vigente = hoy - 18 días
    hoy = ref + timedelta(days=18)
    S.append(insert('movimientos_mecanicos', ['id', 'mecanico_id', 'tipo', 'monto', 'orden_id', 'registrado_por', 'fecha', 'descripcion'],
                    [(m['id'], mec2u[m['mecanico_id']], m['tipo'], m['monto'], m.get('orden_id'), uid[m['registrado_por']], dts(m['fecha']), m['descripcion']) for m in d['movimientos_mecanico']],
                    'Comisiones y adelantos (colección movimientos_mecanico del MVP; mecanico_id del MVP = mecanicos.id -> usuarios.id)'))
    S.append(insert('liquidaciones_mecanicos', ['id', 'mecanico_id', 'periodo_desde', 'periodo_hasta', 'total_comisiones', 'total_adelantos', 'total_a_pagar', 'estado', 'creado_por', 'fecha_creacion', 'fecha_pago', 'observaciones'],
                    [(l['id'], mec2u[l['mecanico_id']], l['periodo_desde'], l['periodo_hasta'], l['total_comisiones'], l['total_adelantos'], l['total_a_pagar'], l['estado'], uid[l['creado_por']],
                      dts(l['fecha_creacion']), dts(l.get('fecha_pago')), l.get('observaciones')) for l in d['liquidaciones']],
                    'Liquidaciones (colección liquidaciones del MVP: una pagada, una pendiente y una anulada)'))
    S.append(insert('detalles_liquidaciones_mecanicos', ['id', 'liquidacion_id', 'movimiento_mecanico_id', 'importe_incluido'],
                    [(x['id'], x['liquidacion_id'], x['movimiento_id'], x['importe_incluido']) for x in d['liquidacion_detalles']],
                    'Movimientos incluidos en cada liquidación (una liquidación anulada libera los suyos: no tiene detalles)'))
    fil = [r for r in d['repuestos'] if r['codigo'] == 'FIL-OIL'][0]
    S.append('-- DATO DE PRUEBA (no proviene del MVP): el MVP no genera historial de precios del catálogo.\n')
    S.append(insert('historial_precios_catalogo', ['id', 'catalogo_item_id', 'precio_compra_anterior', 'precio_compra_nuevo', 'precio_venta_anterior', 'precio_venta_nuevo', 'cambiado_por', 'fecha'],
                    [(1, fil['id'], 3200, fil['costo'], 6500, fil['precio_referencia'], dueno_id, dts((hoy - timedelta(days=20)).isoformat() + ' 10:00'))],
                    'DATO DE PRUEBA: ajuste de precio del filtro de aceite (los precios "nuevos" coinciden con los actuales del catálogo)'))

    # ---------------- suscripción del taller (planes del MVP: mensual) ----------------
    s1 = [x for x in d['suscripciones'] if x['taller_id'] == T][0]
    pc1 = [x for x in d['pagos_suscripcion'] if x['taller_id'] == T and x['estado'] == 'confirmado'][0]
    pp = [x for x in d['pagos_suscripcion'] if x['taller_id'] == T and x['estado'] == 'pendiente'][0]
    ini2 = date.fromisoformat(s1['fecha_inicio']); ven2 = date.fromisoformat(s1['fecha_vencimiento'])
    ini1 = date.fromisoformat('%04d-%02d-%02d' % ((ini2.year - 1, 12, ini2.day) if ini2.month == 1 else (ini2.year, ini2.month - 1, ini2.day)))
    S.append(insert('periodos_pago_sistema', ['id', 'taller_id', 'numero', 'modalidad', 'fecha_inicio', 'fecha_vencimiento', 'importe', 'dias_tolerancia', 'fecha_fin_tolerancia', 'estado', 'fecha_pago_confirmado', 'creado_en'],
                    [(1, 1, 1, 'mensual', ini1.isoformat(), ini2.isoformat(), s1['importe'], 3, (ini2 + timedelta(days=3)).isoformat(), 'pagado', dts(pc1['fecha_decision'] + ' 09:00'), dts(ini1.isoformat() + ' 09:00')),
                     (2, 1, 2, 'mensual', ini2.isoformat(), ven2.isoformat(), s1['importe'], 3, (ven2 + timedelta(days=3)).isoformat(), 'vigente', None, dts(ini2.isoformat() + ' 09:00'))],
                    'Suscripción: ciclo 1 (pagado) y ciclo 2 (vigente = suscripción actual del MVP, vence en 12 días)'))
    S.append(insert('pagos_sistema', ['id', 'periodo_id', 'importe_total', 'metodo', 'estado', 'registrado_por', 'confirmado_por', 'fecha_registro', 'fecha_confirmacion', 'motivo_rechazo', 'observaciones'],
                    [(1, 1, pc1['importe'], 'combinado', 'confirmado', dueno_id, 1, dts(pc1['fecha'] + ' 09:00'), dts(pc1['fecha_decision'] + ' 09:00'), None, 'Pago informado por el dueño y confirmado por el SuperAdmin'),
                     (2, 2, pp['importe'], 'transferencia', 'informado', dueno_id, None, dts(pp['fecha'] + ' 09:00'), None, None, 'Pago informado por el dueño, pendiente de confirmar')],
                    'Pagos del SISTEMA (el dueño paga la suscripción al SuperAdmin) — distinto de pagos_clientes'))
    S.append(insert('detalles_pagos_sistema', ['id', 'pago_id', 'medio', 'importe', 'referencia'],
                    [(1, 1, 'efectivo', 10000, None), (2, 1, 'transferencia', 20000, pc1.get('referencia')), (3, 2, 'transferencia', pp['importe'], pp.get('referencia'))]))

    # ---------------- notificaciones (el MVP las dirige por rol; MySQL las guarda por destinatario) ----------------
    filas = []
    n = 0
    admin_ids = [dueno_id]
    mec_ids = [uid[u['id']] for u in usuarios_mvp if u['tipo_cuenta'] == 'taller' and cod_rol[u['rol_id']] == 'mecanico']
    for nt in d['notificaciones']:
        if nt.get('rol_destino') == 'superadmin':
            n += 1
            filas.append((n, None, 1, nt['texto'], nt.get('ruta'), nt['tipo'], (nt['clave_unica'] + ':sa') if nt.get('clave_unica') else None, nt['leida'], dts(nt['created_at'])))
            continue
        destinos = [uid[nt['usuario_id']]] if nt.get('usuario_id') else (admin_ids if nt.get('rol_destino') == 'admin' else mec_ids)
        for dest in destinos:
            n += 1
            clave = (nt['clave_unica'] + f':u{dest}') if nt.get('clave_unica') else None
            filas.append((n, dest, None, nt['texto'], nt.get('ruta'), nt['tipo'], clave, nt['leida'], dts(nt['created_at'])))
    S.append(insert('notificaciones', ['id', 'usuario_id', 'superadmin_id', 'texto', 'enlace', 'tipo', 'clave_unica', 'leida', 'creada_en'], filas,
                    'Notificaciones (las de rol del MVP se expanden a un registro por destinatario; la del SuperAdmin es la del pago informado)'))

    # ---------------- auditoría ----------------
    filas = []
    n = 0
    for a in d['auditoria']:
        if a.get('taller_id') not in (T, None):
            continue
        n += 1
        det = json.dumps({'detalle': a['detalle']}, ensure_ascii=False)
        if a['ambito'] == 'sistema':
            filas.append((n, None, 1, login[uid[a['usuario_id']]], 'sistema', a['accion'], a.get('entidad'), a.get('entidad_id'), det, None, dts(a['created_at'])))
        else:
            filas.append((n, uid[a['usuario_id']], None, login[uid[a['usuario_id']]], 'taller', a['accion'], a.get('entidad'), a.get('entidad_id'), det, None, dts(a['created_at'])))
    S.append(insert('auditoria', ['id', 'usuario_id', 'superadmin_id', 'actor_login', 'ambito', 'accion', 'entidad', 'entidad_id', 'detalle', 'ip', 'fecha'], filas, 'Auditoría'))

    # ---------------- propuestas de mejora de redacción ----------------
    ctx = {('consultas', 'problema'): 'problema_consulta'}
    S.append(insert('propuestas_ia', ['id', 'usuario_id', 'contexto', 'consulta_id', 'orden_id', 'texto_original', 'texto_propuesto', 'texto_final', 'estado', 'proveedor', 'modelo', 'creada_en', 'resuelta_en'],
                    [(p['id'], uid[p['usuario_id']], ctx[(p['entidad'], p['campo'])], p['entidad_id'], None, p['texto_original'], p['texto_propuesto'], p['texto_final'],
                      {'aceptada': 'aceptada', 'descartada': 'descartada', 'editada': 'editada'}[p['estado']], p['proveedor'], None, dts(p['created_at']), dts(p['created_at'])) for p in d['ia_propuestas']],
                    'Propuestas de mejora de redacción (proveedor local de reglas; no se usa ninguna IA externa)'))
    return '\n'.join(x for x in S if x), {'hoy_demo': hoy.isoformat()}


if __name__ == '__main__':
    sql, meta = generar(sys.argv[1])
    print(sql)
    print('-- meta', meta, file=sys.stderr)
