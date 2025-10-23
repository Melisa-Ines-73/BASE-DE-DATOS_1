USE Biblioteca;

DROP PROCEDURE IF EXISTS sp_tx_biblioteca_segura;
DELIMITER $$

CREATE PROCEDURE sp_tx_biblioteca_segura(
    IN p_id_libro INT,                 -- libro a modificar
    IN p_nueva_estanteria VARCHAR(20), -- nuevo nro de estantería
    IN p_nuevo_idioma     VARCHAR(30)  -- nuevo idioma
)
BEGIN
  -- Variables de control y logging
  DECLARE v_done     TINYINT DEFAULT 0;   -- flag de intento exitoso
  DECLARE v_tries    INT     DEFAULT 0;   -- contador de reintentos
  DECLARE v_errno    INT;                 -- código de error MySQL
  DECLARE v_sqlstate VARCHAR(5);          -- SQLSTATE devuelto por el motor
  DECLARE v_msg      VARCHAR(500);        -- mensaje de error
  DECLARE v_fatal    INT     DEFAULT 0;   -- marca salida por error no recuperable
  DECLARE v_ficha    INT;                 -- variable local para el id_ficha

  main_loop: REPEAT
    BEGIN
 --     --------------------------------------------------------------------
      -- Handler de contención: deadlock (1213) o lock wait timeout (1205)
 --     --------------------------------------------------------------------
      DECLARE CONTINUE HANDLER FOR 1213, 1205
      BEGIN
        GET DIAGNOSTICS CONDITION 1 
          v_errno    = MYSQL_ERRNO, 
          v_msg      = MESSAGE_TEXT, 
          v_sqlstate = RETURNED_SQLSTATE;

        INSERT INTO TxLog(sesion, codigo, sql_state, mensaje, detalle)
        VALUES (CONNECTION_ID(), v_errno, v_sqlstate, v_msg, CONCAT('Reintento #', v_tries+1));

        ROLLBACK;          -- deshace intento parcial
        SET v_done = 0;    -- marca que este intento falló (habrá retry)
      END;

--      -------------------------------------------------------------
      -- Handler genérico: cualquier otro error SQL (sin reintento)
--      -------------------------------------------------------------
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
      BEGIN
        GET DIAGNOSTICS CONDITION 1 
          v_errno    = MYSQL_ERRNO, 
          v_msg      = MESSAGE_TEXT, 
          v_sqlstate = RETURNED_SQLSTATE;

        INSERT INTO TxLog(sesion, codigo, sql_state, mensaje, detalle)
        VALUES (CONNECTION_ID(), v_errno, v_sqlstate, v_msg, 'Error no recuperable');

        ROLLBACK;
        SET v_fatal = 1;   -- salida del loop fuera del handler
        SET v_done  = 0;
      END;

	-- ===== intento N =====
      SET v_done = 1;
      START TRANSACTION;

      -- 1) Se lee y bloquea (FOR UPDATE) la fila del libro
      SELECT id_ficha INTO v_ficha
      FROM Libro
      WHERE id_Libro = p_id_libro
      FOR UPDATE;

      -- 2) Se actualiza Libro
      UPDATE Libro
      SET eliminado = 0
      WHERE id_Libro = p_id_libro;

      -- 3) Se actualiza Ficha asociada
      UPDATE FichaBibliografica
      SET estanteria = p_nueva_estanteria,
          idioma     = p_nuevo_idioma
      WHERE id_ficha = v_ficha;

      COMMIT;
    END;

    -- Corte inmediato si hubo error no recuperable
    IF v_fatal = 1 THEN 
      LEAVE main_loop; 
    END IF;

    -- Backoff y conteo de retry si falló por 1213/1205
    IF v_done = 0 THEN
      SET v_tries = v_tries + 1;
      DO SLEEP(0.25 * v_tries);   -- 0.25s (retry 1), 0.5s (retry 2)
    END IF;

  UNTIL v_done = 1 OR v_tries >= 2 END REPEAT;

  -- Señalización final (para el cliente)
  IF v_fatal = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error no recuperable (ver TxLog).';
  ELSEIF v_done = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reintentos agotados.';
  END IF;
END$$

DELIMITER ;
