CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `v_inventario_actualizado` AS
    SELECT 
        `l`.`titulo` AS `titulo`,
        `l`.`autor` AS `autor`,
        `f`.`isbn` AS `isbn`,
        `f`.`estanteria` AS `estanteria`,
        `i`.`nombre_idioma` AS `Idioma_Nombre`,
        `f`.`clasificacionDewey` AS `clasificacionDewey`
    FROM
        ((`libro` `l`
        JOIN `fichabibliografica` `f` ON ((`l`.`id_ficha` = `f`.`id_ficha`)))
        JOIN `idioma` `i` ON ((`f`.`id_idioma` = `i`.`id_idioma`)))
    WHERE
        (`l`.`eliminado` = 0)