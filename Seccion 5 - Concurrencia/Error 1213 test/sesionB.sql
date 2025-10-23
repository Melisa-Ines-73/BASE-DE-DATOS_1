-- SCRIPT B: Simulación deadlock transaccional --
USE Biblioteca;
SELECT CONNECTION_ID();

-- Forzar modo transaccional en esta sesión
SET autocommit = 0;
START TRANSACTION;

-- B1) Bloqueo en FICHA (id_ficha 2)
UPDATE Biblioteca.FichaBibliografica
SET estanteria = 'ZB'
WHERE id_ficha = 2;

-- --------------------------------------------------------- --

-- B2) B intenta ahora tocar LIBRO (id 1), ya que bloqueó A
UPDATE Biblioteca.Libro
SET titulo = CONCAT(titulo, ' *B')
WHERE id_Libro = 1;

-- Esperando MySQL detecta el ciclo de espera y levanta:
-- ERROR 123 (40001): Deadlock found when trying to get lock; try restarting transaction

ROLLBACK