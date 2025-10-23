USE Biblioteca;

-- repeatable read --> Las lecturas con SELECT recuperan siempre los mismos valores dentro de una misma transacción
-- 					   Los cambios dentro de otras transacciones no se reflejan
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  
START TRANSACTION;

-- Leemos el estado inicial
SELECT id_Libro, titulo, eliminado
FROM Libro
WHERE id_Libro = 1;
-- → devuelve eliminado = 0

-- Paso 2
SELECT id_Libro, titulo, eliminado
FROM Libro
WHERE id_Libro = 1;

COMMIT;