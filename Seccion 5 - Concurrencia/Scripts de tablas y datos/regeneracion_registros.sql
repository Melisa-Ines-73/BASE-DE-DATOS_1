-- ===========================================
-- Script: 03_reset_and_seed.sql
-- Accion: Truncar y regenerar datos de prueba
-- Requisitos: Haber creado previamente la BD y tablas

-- ===========================================

-- 0) Elegir base de datos
CREATE DATABASE IF NOT EXISTS Biblioteca DEFAULT CHARACTER SET utf8mb4;
USE Biblioteca;

-- 1) Parámetro: cuántos registros querés (por defecto 100000)
SET @N := 100000;

-- 2) Seguridad FK (bajamos chequeos para limpiar los datos en orden)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Libro;
TRUNCATE TABLE FichaBibliografica;
SET FOREIGN_KEY_CHECKS = 1;

-- 3) Generador de números 1..@N (temporal, en memoria si es posible)
DROP TEMPORARY TABLE IF EXISTS tmp_nums;
CREATE TEMPORARY TABLE tmp_nums (n INT PRIMARY KEY) ENGINE=Memory;

-- Generamos hasta 100000 y luego limitamos a @N (si @N<100000)
INSERT INTO tmp_nums(n)
SELECT a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i + 1 AS n
FROM (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
ORDER BY 1
LIMIT @N;

-- 4) Insertar FICHAS
INSERT INTO FichaBibliografica
  (eliminado, isbn, clasificacionDewey, estanteria, idioma)
SELECT
  (RAND(n) < 0.05) + 0 AS eliminado,                               -- ~5% en 1
  CONCAT('978', LPAD(n, 10, '0')) AS isbn,                          -- único (13 dígitos)
  CONCAT(LPAD(FLOOR(RAND(n*3)*1000), 3, '0'), '.',                 -- p.ej. "123.45"
         LPAD(FLOOR(RAND(n*5)*100), 2, '0')) AS clasificacionDewey,
  CONCAT('E-', LPAD(FLOOR(RAND(n*7)*500), 3, '0')) AS estanteria,   -- E-000..E-499
  ELT(1+FLOOR(RAND(n*11)*6),
      'Español','Inglés','Portugués','Francés','Alemán','Italiano') AS idioma
FROM tmp_nums;

-- 5) Insertar LIBROS (1:1 con cada ficha recién creada)
INSERT INTO Libro
  (eliminado, titulo, autor, editorial, anioEdicion, id_ficha)
SELECT
  (RAND(fb.id_ficha*13) < 0.03) + 0 AS eliminado,                   -- ~3% en 1
  CONCAT('Libro #', fb.id_ficha) AS titulo,
  ELT(1+FLOOR(RAND(fb.id_ficha*17)*8),
      'Julio Cortázar','Jorge Luis Borges','Isabel Allende','Gabriel García Márquez',
      'Mario Vargas Llosa','Haruki Murakami','Jane Austen','Stephen King') AS autor,
  ELT(1+FLOOR(RAND(fb.id_ficha*19)*6),
      'Alfaguara','Sudamericana','Random House','Planeta','Seix Barral','Anagrama') AS editorial,
  1450 + FLOOR(RAND(fb.id_ficha*23) * (2025-1450+1)) AS anioEdicion,
  fb.id_ficha
FROM FichaBibliografica fb
ORDER BY fb.id_ficha;

-- 6) Limpieza
DROP TEMPORARY TABLE IF EXISTS tmp_nums;

-- 7) Verificación rápida
SELECT COUNT(*) AS fichas FROM FichaBibliografica;
SELECT COUNT(*) AS libros FROM Libro;
