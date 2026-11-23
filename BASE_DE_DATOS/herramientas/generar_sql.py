# -*- coding: utf-8 -*-
"""Ensambla BASE_DE_DATOS/taller_matienzo_final.sql = cabecera + esquema + datos + pruebas.
Uso: python3 generar_sql.py seed.json salida.sql"""
import sys, os, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import datos_demo, pruebas_def

AQUI = os.path.dirname(os.path.abspath(__file__))


def q(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "''") + "'"


def sentencias(sql):
    """Divide un bloque en sentencias (todas terminan en ';' al final de línea)."""
    out, cur = [], []
    for ln in sql.split('\n'):
        cur.append(ln)
        if ln.rstrip().endswith(';'):
            out.append('\n'.join(cur).strip()); cur = []
    if cur and ''.join(cur).strip():
        out.append('\n'.join(cur).strip())
    return out


HEADER = """-- ============================================================================
-- TALLER MATIENZO — BASE DE DATOS MySQL 8 (VERSIÓN FINAL, ARCHIVO ÚNICO)
-- ============================================================================
-- Contenido: 1) estructura de 30 tablas  2) datos de demostración coherentes
--            3) pruebas SQL (INSERT / SELECT / UPDATE / DELETE / INNER JOIN /
--               integridad / procesos), organizadas por módulo.
--
-- CÓMO IMPORTARLO
--   mysql -u root -p < taller_matienzo_final.sql
--   (o, en MySQL Workbench: File > Open SQL Script > ejecutar todo con el rayo).
--
-- ADVERTENCIAS
--   * Este script BORRA y vuelve a crear la base "taller_matienzo".
--   * Requiere MySQL 8.0.16 o superior (usa restricciones CHECK y columnas generadas).
--   * Las pruebas de la sección 3 que modifican datos están dentro de transacciones
--     que terminan en ROLLBACK: los datos de demostración quedan intactos.
--   * Las contraseñas de demostración están guardadas como hash bcrypt, nunca en
--     texto plano. Credenciales de DEMOSTRACIÓN: ver DOCUMENTACION/documentacion_general.md.
--   * Todos los datos son ficticios.
-- ============================================================================

DROP DATABASE IF EXISTS taller_matienzo;
CREATE DATABASE taller_matienzo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE taller_matienzo;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

"""

PROC = """DROP PROCEDURE IF EXISTS sp_esperar_error;
DELIMITER $$
CREATE PROCEDURE sp_esperar_error(IN p_id VARCHAR(10), IN p_sql TEXT, IN p_codigo INT)
BEGIN
  -- Ejecuta una sentencia que DEBE fallar y compara el código de error de MySQL.
  DECLARE v_err INT DEFAULT NULL;
  DECLARE v_msg TEXT DEFAULT NULL;
  DECLARE v_e2 INT DEFAULT NULL;
  DECLARE v_m2 TEXT DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN GET DIAGNOSTICS CONDITION 1 v_e2 = MYSQL_ERRNO, v_m2 = MESSAGE_TEXT; IF v_err IS NULL THEN SET v_err = v_e2, v_msg = v_m2; END IF; END;
  SET @sql_prueba = p_sql;
  PREPARE st FROM @sql_prueba;
  EXECUTE st;
  DEALLOCATE PREPARE st;
  SELECT p_id AS prueba, p_codigo AS error_esperado, v_err AS error_obtenido,
         IF(v_err = p_codigo, 'OK', 'FALLA') AS resultado, LEFT(v_msg, 120) AS mensaje;
END$$
DELIMITER ;

"""


def seccion_pruebas():
    out = ["""
-- ============================================================================
-- SECCIÓN 3. PRUEBAS SQL
-- ============================================================================
-- Tipos: integridad (debe devolver 0 filas), info (consulta informativa),
-- op (INSERT/UPDATE/DELETE dentro de una transacción con ROLLBACK, devuelve
-- resultado = OK) y error (la sentencia DEBE fallar con el código indicado).
-- Fecha de referencia de la demostración: 2026-11-20.
-- ============================================================================
""", PROC]
    mod = None
    nombres = dict(pruebas_def.MODULOS)
    for p in pruebas_def.P:
        if p['modulo'] != mod:
            mod = p['modulo']
            out.append("\n-- ----------------------------------------------------------------------------\n-- MÓDULO %s. %s\n-- ----------------------------------------------------------------------------\n" % (mod, nombres[mod].upper()))
        out.append("-- PRUEBA %s — %s [%s]\n-- Objetivo: %s\n-- Esperado: %s\n" % (p['id'], p['nombre'], p['kind'], p['objetivo'], p['esperado']))
        if p['kind'] == 'error':
            out.append("START TRANSACTION;\nCALL sp_esperar_error(%s, %s, %d);\nROLLBACK;\n" % (q(p['id']), q(p['sql']), p['expect'][1]))
        elif p['kind'] == 'op':
            out.append("SELECT %s AS prueba;\n%s\n" % (q(p['id']), p['sql']))
        else:
            out.append("SELECT %s AS prueba, %s AS tipo;\n%s\n" % (q(p['id']), q(p['kind']), p['sql']))
    out.append("\nDROP PROCEDURE IF EXISTS sp_esperar_error;\n-- FIN DEL ARCHIVO\n")
    return ''.join(out)


def main(seed, salida):
    datos, meta = datos_demo.generar(seed)
    esquema = open(os.path.join(AQUI, 'esquema.sql'), encoding='utf-8').read()
    txt = HEADER + esquema.rstrip() + "\n\nSET FOREIGN_KEY_CHECKS = 1;\n\n"
    txt += "-- ============================================================================\n-- SECCIÓN 2. DATOS DE DEMOSTRACIÓN (fecha de referencia %s)\n-- ============================================================================\nSET FOREIGN_KEY_CHECKS = 0;\n" % meta['hoy_demo']
    txt += datos.rstrip() + "\nSET FOREIGN_KEY_CHECKS = 1;\n"
    txt += seccion_pruebas()
    open(salida, 'w', encoding='utf-8').write(txt)
    print('escrito', salida, len(txt))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
