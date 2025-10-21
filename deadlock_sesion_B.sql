-- SCRIPT B: Simulación deadlock transaccional --
SELECT CONNECTION_ID();

-- Ver y fijar el esquema
SELECT DATABASE() AS actual_schema, CONNECTION_ID() AS conn_id, @@autocommit AS autocommit_status;
USE Biblioteca;

-- Forzar modo transaccional en esta sesión
SET autocommit = 0;
START TRANSACTION;

-- B1) Bloqueo en FICHA (id_ficha 2)
UPDATE Biblioteca.FichaBibliografica
SET estanteria = 'ZB'
WHERE id_ficha = 2;

-- --------------------------------------------------------------------------- --

-- B2) B intenta ahora tocar LIBRO (id 1), que ya bloqueó A
UPDATE Biblioteca.Libro
SET titulo = CONCAT(titulo, ' *B')
WHERE id_Libro = 1;

-- Esperado: MySQL detecta el ciclo de espera y levanta:
-- ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction

ROLLBACK