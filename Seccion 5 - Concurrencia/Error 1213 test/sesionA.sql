USE Biblioteca;
SELECT CONNECTION_ID();

SET autocommit = 0;
START TRANSACTION;

-- Bloqueamos el libro 1 (queda "ocupado" hasta hacer COMMIT/ROLLBACK)
UPDATE Libro
SET titulo = CONCAT(titulo, ' *LOCK')
WHERE id_Libro = 1;

-- No se realiza todavía el COMMIT
SELECT CONNECTION_ID() AS connA, 'A: bloqueo activo' AS estado;


ROLLBACK