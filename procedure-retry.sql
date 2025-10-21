USE Biblioteca;

-- 1) Eliminalo si existe (en vez de OR REPLACE)
DROP PROCEDURE IF EXISTS sp_tx_biblioteca_segura;

-- 2) Cambiamos el delimitador para que el cuerpo pueda usar ';'
DELIMITER $$

-- Firma del procedimiento que recibe:
CREATE PROCEDURE sp_tx_biblioteca_segura(
    IN p_id_libro INT,  					-- libro a modificar
    IN p_nueva_estanteria VARCHAR(20),		-- nuevo nro de estantería
    IN p_nuevo_idioma     VARCHAR(30)		-- nuevo idioma
)

 -- Variables locales para registrar el log de operaciones
BEGIN
  DECLARE v_done TINYINT DEFAULT 0;		-- flag de operación exitosa
  DECLARE v_tries INT DEFAULT 0;		-- contador de reintentos
  DECLARE v_errno INT;					-- código de error
  DECLARE v_sqlstate VARCHAR(5);		-- status
  DECLARE v_msg VARCHAR(500); 			-- msg de error
  DECLARE v_fatal INT;					-- corte de ejecución

 -- Loop de reintentos con handlers
  main_loop: REPEAT
    BEGIN
      -- Deadlock (1213) o lock wait timeout (1205) -> log + retry
      DECLARE CONTINUE HANDLER FOR 1213, 1205
      BEGIN
		-- Se obtienen los datos del error y se almacenan en variables para luego generar el log con los resultados
        GET DIAGNOSTICS CONDITION 1 v_errno = MYSQL_ERRNO, v_msg = MESSAGE_TEXT, v_sqlstate = RETURNED_SQLSTATE;
        INSERT INTO TxLog(sesion, codigo, sql_state, mensaje, detalle)   						-- log fill
        VALUES (CONNECTION_ID(), v_errno, v_sqlstate, v_msg, CONCAT('Reintento #', v_tries+1));
        ROLLBACK;		-- ROLLBACK de la operación incompleta para volver a intentar
        SET v_done = 0;	-- se indica que falló la operación
      END;

      -- Cualquier otro error -> log + aborta sin retry
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
      BEGIN
        GET DIAGNOSTICS CONDITION 1 v_errno = MYSQL_ERRNO, v_msg = MESSAGE_TEXT, v_sqlstate = RETURNED_SQLSTATE;
        INSERT INTO TxLog(sesion, codigo, sql_state, mensaje, detalle)
        VALUES (CONNECTION_ID(), v_errno, v_sqlstate, v_msg, 'Error no recuperable');
        ROLLBACK;
		SET v_fatal = 1;	-- marca la salida del loop
      END;
	  
      -- caso de error
      IF v_fatal = 1 THEN 
		LEAVE main_loop; 
      END IF;
	  
      -- primer try
      SET v_done = 1;
      START TRANSACTION;

      -- 1) Lee y bloquea la fila relacionada
      SELECT id_ficha INTO @v_ficha
      FROM Libro
      WHERE id_Libro = p_id_libro
      FOR UPDATE;

      -- 2) Actualiza Libro
      UPDATE Libro
      SET eliminado = 0
      WHERE id_Libro = p_id_libro;

      -- 3) Actualiza Ficha
      UPDATE FichaBibliografica
      SET estanteria = p_nueva_estanteria,
          idioma     = p_nuevo_idioma
      WHERE id_ficha = @v_ficha;

      COMMIT;
    END;
	
    
    IF v_done = 0 THEN
      SET v_tries = v_tries + 1;
      DO SLEEP(0.25 * v_tries);  -- backoff (tiempo de espera): 0.25s, 0.5s
    END IF;

  UNTIL v_done = 1 OR v_tries >= 2 END REPEAT;		-- fin del loop luego del 2do retry

  IF v_done = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reintentos agotados.';
  END IF;
END$$

-- 3) Volvemos al delimitador normal
DELIMITER ;


-- ------------------------------- TEST HANDLER -----------------------------------------------

SELECT DATABASE() AS db, CONNECTION_ID() AS conn;

-- 2) ¿Existe la tabla y con las columnas correctas?
SHOW COLUMNS FROM Biblioteca.TxLog;

-- 3) ¿El procedimiento está creado aquí?
SELECT ROUTINE_SCHEMA, ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME='sp_tx_biblioteca_segura';
