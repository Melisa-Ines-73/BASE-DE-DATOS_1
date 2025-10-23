USE Biblioteca;

-- Se reduce el tiempo de espera de locks en esta sesión B unos 3s o 2s para evitar el error 2013
SET SESSION innodb_lock_wait_timeout = 3;

SELECT CONNECTION_ID() AS connB, @@innodb_lock_wait_timeout AS lock_wait;

-- Ejecutá el procedimiento que intenta tocar el mismo libro 1
CALL sp_tx_biblioteca_segura(1, 'E9', 'Inglés');