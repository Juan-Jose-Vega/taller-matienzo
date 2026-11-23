# -*- coding: utf-8 -*-
"""Ejecuta REALMENTE cada prueba de pruebas_def.py contra MySQL y guarda resultados.json.
Uso: python3 ejecutar_pruebas.py resultados.json   (la base taller_matienzo debe estar cargada)"""
import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pymysql
import pruebas_def
from generar_sql import sentencias

con = pymysql.connect(host='127.0.0.1', user=os.environ.get('MYSQL_USER', 'root'), password=os.environ.get('MYSQL_PWD', ''),
                      database='taller_matienzo', charset='utf8mb4', autocommit=True,
                      unix_socket=os.environ.get('MYSQL_SOCK') or None)
cur = con.cursor()


def contar():
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='taller_matienzo' AND table_type='BASE TABLE' ORDER BY 1")
    ts = [r[0] for r in cur.fetchall()]
    d = {}
    for t_ in ts:
        cur.execute('SELECT COUNT(*) FROM `%s`' % t_)
        d[t_] = cur.fetchone()[0]
    return d


def ser(v):
    return v if isinstance(v, (int, float, str, type(None))) else str(v)


antes = contar()
res = []
for p in pruebas_def.P:
    r = dict(id=p['id'], modulo=p['modulo'], nombre=p['nombre'], kind=p['kind'], expect=p['expect'])
    try:
        if p['kind'] == 'error':
            cur.execute('START TRANSACTION')
            cur.execute('SET @sql_prueba = %s', (p['sql'],))
            try:
                cur.execute('PREPARE st FROM @sql_prueba')
                cur.execute('EXECUTE st')
                r['obtenido'] = 'sin error'; r['ok'] = False
            except pymysql.MySQLError as e:
                r['obtenido'] = 'ERROR %d' % e.args[0]; r['mensaje'] = str(e.args[1])[:150]
                r['ok'] = (e.args[0] == p['expect'][1])
            finally:
                try: cur.execute('DEALLOCATE PREPARE st')
                except Exception: pass
                cur.execute('ROLLBACK')
        else:
            rows = None; cols = None
            for s in sentencias(p['sql']):
                cur.execute(s)
                if cur.description is not None:
                    cols = [c[0] for c in cur.description]; rows = cur.fetchall()
            r['columnas'] = cols
            r['filas'] = [[ser(x) for x in row] for row in (rows or [])][:40]
            r['n'] = len(rows or [])
            e = p['expect']
            if e[0] == 'rows0': r['ok'] = r['n'] == 0
            elif e[0] == 'rowsgt': r['ok'] = r['n'] >= 1
            elif e[0] == 'rowsN': r['ok'] = r['n'] == e[1]
            elif e[0] == 'ok': r['ok'] = bool(rows) and rows[0][0] == 'OK'
            r['obtenido'] = ('%d fila(s)' % r['n']) if e[0] != 'ok' else (rows[0][0] if rows else 'sin resultado')
    except Exception as ex:
        try: cur.execute('ROLLBACK')
        except Exception: pass
        r['ok'] = False; r['obtenido'] = 'EXCEPCIÓN'; r['mensaje'] = str(ex)[:200]
    res.append(r)
despues = contar()
cambios = {k: (antes[k], despues[k]) for k in antes if antes[k] != despues[k]}
cur.execute('SELECT VERSION()')
ver = cur.fetchone()[0]
out = dict(version_mysql=ver, fecha=time.strftime('%Y-%m-%d %H:%M:%S'), total=len(res), ok=sum(1 for x in res if x['ok']),
           fallas=[x['id'] for x in res if not x['ok']], filas_antes=antes, filas_despues=despues, tablas_con_cambios=cambios, pruebas=res)
json.dump(out, open(sys.argv[1], 'w', encoding='utf-8'), ensure_ascii=False, indent=1, default=str)
print(ver, 'total', out['total'], 'ok', out['ok'], 'fallas', out['fallas'], 'cambios', cambios)
for x in res:
    if not x['ok']:
        print(x['id'], x['nombre'], '|', x.get('obtenido'), '|', x.get('mensaje', ''), '|', (x.get('filas') or [])[:3])
