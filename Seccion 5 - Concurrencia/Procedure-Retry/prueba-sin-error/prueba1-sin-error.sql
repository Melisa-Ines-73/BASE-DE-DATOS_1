-- Llamada normal
CALL sp_tx_biblioteca_segura(1, 'E7', 'Español');

-- Ver cambios y logs
SELECT id_ficha, estanteria, idioma FROM FichaBibliografica WHERE id_ficha = 1;
SELECT ts, sesion, codigo, sql_state, mensaje, detalle FROM TxLog ORDER BY id DESC LIMIT 5;