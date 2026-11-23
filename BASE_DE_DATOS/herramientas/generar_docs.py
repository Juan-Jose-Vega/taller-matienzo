# -*- coding: utf-8 -*-
"""Genera DOCUMENTACION/diccionario_datos.md (desde information_schema) y pruebas_sql.md (desde resultados reales)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pymysql, pruebas_def
RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DOC = os.path.join(RAIZ, 'DOCUMENTACION')
c = pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock', user='root', database='taller_matienzo').cursor()
DESC = {
 'roles': 'Roles operativos del taller (Administrador, Mecánico). El SuperAdmin no es un rol.', 'usuarios': 'Cuentas de acceso: administrador, mecánicos y SuperAdmin (tipo_cuenta).',
 'superadmins': 'Datos propios del SuperAdmin (cuenta oculta de la plataforma).', 'taller': 'El único taller que administra el sistema, con su estado de acceso.',
 'clientes': 'Clientes del taller.', 'vehiculos': 'Vehículos; el propietario actual es clientes (cliente_id).',
 'consultas': 'Consultas/recepciones del cliente, con decisión de cobro y cierre.', 'detalles_consultas': 'Revisión técnica de la consulta (verificado, repuestos necesarios, trabajo recomendado).',
 'presupuestos': 'Presupuesto único por consulta, con precio final y comisión.', 'detalles_presupuestos': 'Líneas del presupuesto (monto calculado = cantidad × precio).',
 'categorias_catalogo': 'Categorías de repuestos.', 'catalogo_items': 'Catálogo de repuestos (stock, mínimos, precios).', 'historial_precios_catalogo': 'Cambios de precio de los artículos.',
 'ordenes_trabajo': 'Órdenes de trabajo nacidas de presupuestos aceptados.', 'historial_estados_ordenes': 'Historial de cambios de estado de cada orden.', 'asignaciones_trabajo': 'Ofrecimientos y respuestas de mecánicos para cada orden.',
 'avances_ordenes': 'Avances escritos por el mecánico en una orden.', 'pagos_clientes': 'Cobros del taller a sus clientes (trabajos y ventas de mostrador).', 'detalles_pagos_clientes': 'Medios con que se pagó cada cobro (efectivo, transferencia, etc.).',
 'movimientos_stock': 'Entradas y salidas de stock (incluye repuestos usados en órdenes).', 'movimientos_mecanicos': 'Comisiones y adelantos de mecánicos.', 'liquidaciones_mecanicos': 'Liquidaciones por período de un mecánico.',
 'detalles_liquidaciones_mecanicos': 'Movimientos incluidos en cada liquidación.', 'periodos_pago_sistema': 'Períodos de la suscripción del taller al sistema (plan mensual o anual, 3 días de tolerancia).',
 'pagos_sistema': 'Pagos del taller al sistema, confirmados por el SuperAdmin. Separados de los cobros a clientes.', 'detalles_pagos_sistema': 'Medios de cada pago al sistema (efectivo, transferencia).',
 'comprobantes_pagos_sistema': 'Comprobantes adjuntos de pagos al sistema. Sin uso en el MVP (decisión pendiente).', 'notificaciones': 'Avisos para usuarios del taller o SuperAdmin.',
 'auditoria': 'Registro de acciones (ámbito taller o sistema).', 'propuestas_ia': 'Propuestas de redacción asistida (reglas locales; solo texto).'}
c.execute("select table_name from information_schema.tables where table_schema='taller_matienzo' and table_type='BASE TABLE' order by table_name")
ts = [r[0] for r in c.fetchall()]
L = ['# Diccionario de datos — Taller Matienzo (MySQL 8)', '', 'Generado automáticamente desde `information_schema` de la base cargada con `taller_matienzo_final.sql`. Cada tabla incluye columnas, tipo, nulabilidad, valor por defecto, claves y restricciones.', '', '**Total: %d tablas.**' % len(ts), '', '## Índice', '']
for t in ts: L.append('- [%s](#%s) — %s' % (t, t, DESC.get(t, '')))
for t in ts:
    L += ['', '## %s' % t, '', DESC.get(t, ''), '', '| Columna | Tipo | Nulo | Defecto | Clave | Observación |', '|---|---|---|---|---|---|']
    c.execute("select column_name,column_type,is_nullable,column_default,column_key,extra from information_schema.columns where table_schema='taller_matienzo' and table_name=%s order by ordinal_position", (t,))
    fk = {}
    c2 = pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock', user='root', database='taller_matienzo').cursor()
    c2.execute("select column_name,referenced_table_name,referenced_column_name from information_schema.key_column_usage where table_schema='taller_matienzo' and table_name=%s and referenced_table_name is not null", (t,))
    for a, b, d in c2.fetchall(): fk[a] = '%s.%s' % (b, d)
    for col, ty, nul, df, key, ex in c.fetchall():
        k = {'PRI': 'PK', 'UNI': 'UNIQUE', 'MUL': 'índice'}.get(key, '')
        if col in fk: k = (k + ', ' if k else '') + 'FK → ' + fk[col]
        L.append('| %s | %s | %s | %s | %s | %s |' % (col, ty, 'sí' if nul == 'YES' else 'no', '' if df is None else '`%s`' % df, k, ex.replace('DEFAULT_GENERATED', '').strip()))
    c.execute("select constraint_name,check_clause from information_schema.check_constraints where constraint_schema='taller_matienzo' and constraint_name in (select constraint_name from information_schema.table_constraints where table_schema='taller_matienzo' and table_name=%s)", (t,))
    ck = c.fetchall()
    if ck:
        L += ['', '**Restricciones CHECK:**', '']
        for n, cl in ck: L.append('- `%s`: `%s`' % (n, cl.replace('\n', ' ')))
    c.execute("select constraint_name, column_name from information_schema.key_column_usage where table_schema='taller_matienzo' and table_name=%s and constraint_name like 'uq\\_%%' order by constraint_name, ordinal_position", (t,))
    u = {}
    for n, col in c.fetchall(): u.setdefault(n, []).append(col)
    if u:
        L += ['', '**Restricciones UNIQUE:**', '']
        for n, cols in u.items(): L.append('- `%s` (%s)' % (n, ', '.join(cols)))
open(os.path.join(DOC, 'diccionario_datos.md'), 'w', encoding='utf-8').write('\n'.join(L) + '\n')

# ---- pruebas
R = json.load(open(os.path.join(RAIZ, 'BASE_DE_DATOS', 'resultados_ejecucion.json'), encoding='utf-8'))
res = {p['id']: p for p in R['pruebas']}
K = {'integridad': 'Integridad (debe dar 0 filas)', 'info': 'Consulta (SELECT / INNER JOIN)', 'op': 'Operación INSERT / UPDATE / DELETE con ROLLBACK', 'error': 'Error esperado (debe fallar)'}
M = [ '# Pruebas SQL — Taller Matienzo', '', '## Cómo se ejecutaron', '',
 '- Servidor: **MySQL %s** (instalado en el entorno de trabajo; **no** se usó MySQL Workbench).' % R['version_mysql'],
 '- Fecha de la ejecución: %s.' % R['fecha'],
 '- El archivo `BASE_DE_DATOS/taller_matienzo_final.sql` se importó completo con el cliente `mysql` (sin errores) y luego cada prueba se ejecutó con un script Python (`herramientas/ejecutar_pruebas.py`) que guarda el resultado real en `BASE_DE_DATOS/resultados_ejecucion.json`.',
 '- Las pruebas de la sección 3 del SQL también se ejecutan solas al importar: las de error usan el procedimiento temporal `sp_esperar_error`; las de modificación van dentro de `START TRANSACTION … ROLLBACK`.',
 '- Fecha de referencia de los datos de demostración: 2026-11-20.', '',
 '## Resumen', '', '| Indicador | Valor |', '|---|---|', '| Pruebas definidas y ejecutadas | %d |' % R['total'], '| Resultado correcto (coincide con lo esperado) | %d |' % R['ok'], '| Con falla | %d |' % (R['total'] - R['ok']),
 '| Tablas cuyo contenido cambió tras todas las pruebas | %d (los datos quedaron intactos) |' % len(R['tablas_con_cambios']), '']
M += ['| Tipo | Cantidad |', '|---|---|']
cnt = {}
for p in R['pruebas']: cnt[p['kind']] = cnt.get(p['kind'], 0) + 1
for k, v in cnt.items(): M.append('| %s | %d |' % (K[k], v))
M += ['', '## Pruebas por módulo', '']
mods = dict(pruebas_def.MODULOS)
cur = None
for p in pruebas_def.P:
    if p['modulo'] != cur:
        cur = p['modulo']; M += ['', '### Módulo %s — %s' % (cur, mods[cur]), '', '| Id | Tipo | Prueba | Tablas | Esperado | Obtenido (real) | Estado |', '|---|---|---|---|---|---|---|']
    r = res[p['id']]
    ob = r.get('obtenido', '')
    if r.get('mensaje') and p['kind'] == 'error': ob += ' — ' + r['mensaje'][:70]
    M.append('| %s | %s | %s | %s | %s | %s | %s |' % (p['id'], p['kind'], p['nombre'], p['tablas'], p['esperado'], ob.replace('|', '/'), '✅ OK' if r['ok'] else '❌ FALLA'))
M += ['', '## Detalle de cada prueba', '']
for p in pruebas_def.P:
    r = res[p['id']]
    M += ['#### %s — %s' % (p['id'], p['nombre']), '', '- **Objetivo:** %s' % p['objetivo'], '- **Tablas:** %s' % p['tablas'], '- **Tipo:** %s' % K[p['kind']], '- **Resultado esperado:** %s' % p['esperado'], '- **Resultado obtenido (ejecución real):** %s — %s' % (r.get('obtenido'), 'correcto' if r['ok'] else 'FALLA'), '- **Interpretación:** %s' % p['interp']]
    if p.get('orig'): M.append('- **Equivale a la prueba del SQL original:** %s' % p['orig'])
    M += ['', '```sql', p['sql'], '```', '']
    if p['kind'] == 'info' and r.get('filas'):
        cols = r['columnas']; M += ['Muestra del resultado real (primeras filas):', '', '| ' + ' | '.join(cols) + ' |', '|' + '---|' * len(cols)]
        for f in r['filas'][:5]: M.append('| ' + ' | '.join(str(x).replace('|', '/')[:50] for x in f) + ' |')
        M.append('')
M += ['## Pruebas que no se pudieron ejecutar', '', 'Ninguna: las %d pruebas se ejecutaron en MySQL %s. Quedan **sin** verificar (porque no hay backend): el comportamiento desde la aplicación Vue contra esta base, la concurrencia y el rendimiento con grandes volúmenes.' % (R['total'], R['version_mysql']), '']
M += ['## Hallazgos de las pruebas (corregidos)', '', '- **CHECK `ck_consultas_cobro`:** la prueba 4.10 mostró que cobrar sin importe pasaba la restricción (el valor NULL no la violaba). Se corrigió exigiendo `cobro_importe IS NOT NULL`.',
 '- Las pruebas de valores fuera de ENUM (12.10, 13.8, 16.7) se resuelven consultando `information_schema`, porque MySQL no permite capturar ese error (1265) dentro de un procedimiento con handler.',
 '- El SQL original contenía una prueba cuya condición era incorrecta (exigía una orden para la inspección de IA) y otra sobre liquidaciones con totales mal calculados; están corregidas en las pruebas 16.3 y 11.2.']
open(os.path.join(DOC, 'pruebas_sql.md'), 'w', encoding='utf-8').write('\n'.join(M) + '\n')
print('ok', len(ts), R['ok'])
