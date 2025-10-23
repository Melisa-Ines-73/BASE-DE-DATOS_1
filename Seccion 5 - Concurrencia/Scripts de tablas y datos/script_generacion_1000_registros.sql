-- ===========================================
-- 0) (OPCIONAL) Empezar desde cero
-- ===========================================
-- TRUNCATE TABLE Libro;
-- TRUNCATE TABLE FichaBibliografica;

-- ===========================================
-- 1) Tabla temporal de números 1..100000
--    (10^5 vía CROSS JOIN)
-- ===========================================
DROP TEMPORARY TABLE IF EXISTS tmp_nums;
CREATE TEMPORARY TABLE tmp_nums (n INT PRIMARY KEY) ENGINE=Memory;

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
ORDER BY 1;

-- ===========================================
-- 2) Insertar 100.000 FICHAS
--    - isbn único y determinista basado en n (13 dígitos)
--    - eliminado con ~5% en 1
--    - campos textuales/numéricos variados
-- ===========================================
INSERT INTO FichaBibliografica
  (eliminado, isbn, clasificacionDewey, estanteria, idioma)
SELECT
  (RAND(n) < 0.05) + 0 AS eliminado,                               -- 5% eliminadas
  CONCAT('978', LPAD(n, 10, '0')) AS isbn,                          -- único y válido (13 dígitos)
  CONCAT(LPAD(FLOOR(RAND(n*3)*1000), 3, '0'), '.',                 -- p.ej.: "123.45"
         LPAD(FLOOR(RAND(n*5)*100), 2, '0')) AS clasificacionDewey,
  CONCAT('E-', LPAD(FLOOR(RAND(n*7)*500), 3, '0')) AS estanteria,   -- E-000..E-499
  ELT(1+FLOOR(RAND(n*11)*6),
      'Español','Inglés','Portugués','Francés','Alemán','Italiano') AS idioma
FROM tmp_nums
LIMIT 100000;

-- ===========================================
-- 3) Insertar 100.000 LIBROS (1:1 con Fichas)
--    - Sólo crea para fichas que no tengan libro aún
--    - anioEdicion respeta [1450,2025]
--    - autor/editorial de listas fijas, titulo basado en id
-- ===========================================
INSERT INTO Libro
  (eliminado, titulo, autor, editorial, anioEdicion, id_ficha)
SELECT
  (RAND(fb.id_ficha*13) < 0.03) + 0 AS eliminado,                   -- ~3% eliminados
  CONCAT('Libro #', fb.id_ficha) AS titulo,
  ELT(1+FLOOR(RAND(fb.id_ficha*17)*8),
      'Julio Cortázar','Jorge Luis Borges','Isabel Allende','Gabriel García Márquez',
      'Mario Vargas Llosa','Haruki Murakami','Jane Austen','Stephen King') AS autor,
  ELT(1+FLOOR(RAND(fb.id_ficha*19)*6),
      'Alfaguara','Sudamericana','Random House','Planeta','Seix Barral','Anagrama') AS editorial,
  1450 + FLOOR(RAND(fb.id_ficha*23) * (2025-1450+1)) AS anioEdicion,
  fb.id_ficha
FROM FichaBibliografica fb
LEFT JOIN Libro l ON l.id_ficha = fb.id_ficha
WHERE l.id_ficha IS NULL
ORDER BY fb.id_ficha
LIMIT 100000;

-- Limpieza opcional
DROP TEMPORARY TABLE IF EXISTS tmp_nums;

-- ===========================================
-- 4) Verificación rápida
-- ===========================================
SELECT COUNT(*) AS fichas FROM FichaBibliografica;
SELECT COUNT(*) AS libros FROM Libro;
SELECT COUNT(*) AS libros_sin_ficha
FROM Libro l LEFT JOIN FichaBibliografica f USING(id_ficha)
WHERE f.id_ficha IS NULL;  -- debe dar 0

-- Debe haber 1:1 exacta (mismo conteo si se parte de null)
SELECT
  (SELECT COUNT(*) FROM FichaBibliografica) AS total_fichas,
  (SELECT COUNT(*) FROM Libro) AS total_libros;