USE Biblioteca;

-- read commited --> Los SELECT recuperan sólo los valores ya commiteados por otras transacciones
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;

UPDATE Libro
SET eliminado = 1
WHERE id_Libro = 1;

COMMIT;