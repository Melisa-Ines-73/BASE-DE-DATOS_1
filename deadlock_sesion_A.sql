-- SCRIPT A: Simulación deadlock transaccional --
SELECT CONNECTION_ID();

-- Ver y fijar el esquema
SELECT DATABASE() AS actual_schema, CONNECTION_ID() AS conn_id, @@autocommit AS autocommit_status;
USE Biblioteca;

-- Forzar modo transaccional en esta sesión
SET autocommit = 0;
START TRANSACTION;

-- A1) Bloquea primero una fila de LIBRO (por ejemplo id 1)
UPDATE Biblioteca.Libro
SET titulo = CONCAT(titulo, ' *A')
WHERE id_Libro = 1;

-- (No se realiza el COMMIT todavía)
-- --------------------------------------------------------------------------- --

-- A2) Ahora A intenta tocar la misma FICHA que va a tocar B (id_ficha 2)
UPDATE Biblioteca.FichaBibliografica
SET estanteria = 'ZA'
WHERE id_ficha = 2;
-- Esto debería quedar esperando (B tiene el lock)

ROLLBACK;
SET autocommit = 1;  -- volver al comportamiento por defecto

