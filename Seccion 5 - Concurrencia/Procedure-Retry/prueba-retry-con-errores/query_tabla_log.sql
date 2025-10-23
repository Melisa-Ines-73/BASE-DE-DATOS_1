SELECT ts, sesion, codigo, sql_state, mensaje, detalle
FROM Biblioteca.TxLog
ORDER BY id DESC;