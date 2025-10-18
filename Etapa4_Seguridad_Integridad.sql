-- =============================================
-- ETAPA 4: SEGURIDAD E INTEGRIDAD
-- Base de Datos Biblioteca - Universidad
-- Autor: Fabricio Puccio
-- =============================================

-- ====================================================
-- CONFIGURACIÓN INICIAL
-- ====================================================

-- Base de datos Biblioteca
USE Biblioteca;

/* 
OBJETIVO: Preparar el entorno para las pruebas de seguridad
*/

-- Guardar configuración actual
SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
-- Desactivar verificación temporalmente
SET FOREIGN_KEY_CHECKS = 0;

-- ====================================================
-- CREACIÓN DE USUARIOS CON MÍNIMOS PRIVILEGIOS
-- ====================================================

/* 
OBJETIVO: Aplicar el principio de mínimo privilegio creando
3 usuarios con diferentes niveles de acceso
*/

-- Eliminar usuarios si existen (para pruebas)
DROP USER IF EXISTS 'lector_universidad'@'localhost';
DROP USER IF EXISTS 'asistente_biblioteca'@'localhost';
DROP USER IF EXISTS 'estudiante_biblioteca'@'localhost';
DROP USER IF EXISTS 'bibliotecario'@'localhost';
DROP USER IF EXISTS 'admin_biblioteca'@'localhost';

-- Usuario LECTOR: Solo puede consultar información pública
CREATE USER IF NOT EXISTS 'lector_universidad'@'localhost'
IDENTIFIED BY 'LectorUniv2024!';

-- Ejemplo: Usuario SOLO LECTURA (Estudiante)
CREATE USER IF NOT EXISTS 'estudiante_biblioteca'@'localhost' 
IDENTIFIED BY 'clave_estudiante123';

-- Usuario ASISTENTE: Puede gestionar préstamos y registros básicos
CREATE USER IF NOT EXISTS 'asistente_biblioteca'@'localhost'
IDENTIFIED BY 'AsistenteBib2024!';

-- Usuario OPERACIONES BÁSICAS (Bibliotecario)
CREATE USER IF NOT EXISTS 'bibliotecario'@'localhost' 
IDENTIFIED BY 'clave_bibliotecario123';

-- Usuario ADMINISTRADOR (Admin Biblioteca)
CREATE USER IF NOT EXISTS 'admin_biblioteca'@'localhost' 
IDENTIFIED BY 'clave_admin123';

-- ====================================================
-- ASIGNACIÓN DE PRIVILEGIOS
-- ====================================================

/*
OBJETIVO: Asignar solo los permisos necesarios para cada rol
*/

-- Limpiar privilegios existentes (por si acaso)              (Ver sintaxis o error)
-- REVOKE ALL PRIVILEGES ON *.* FROM 'estudiante_biblioteca'@'localhost';
-- REVOKE ALL PRIVILEGES ON *.* FROM 'bibliotecario'@'localhost';
-- REVOKE ALL PRIVILEGES ON *.* FROM 'admin_biblioteca'@'localhost';}
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'lector_universidad'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'asistente_biblioteca'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'estudiante_biblioteca'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'bibliotecario'@'localhost'; 
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'admin_biblioteca'@'localhost';

-- Asignar privilegios al LECTOR (MÍNIMOS PRIVILEGIOS)
GRANT SELECT ON Biblioteca.vista_libros_publicos TO 'lector_universidad'@'localhost';
GRANT SELECT ON Biblioteca.vista_catalogo_completo TO 'lector_universidad'@'localhost';
GRANT EXECUTE ON PROCEDURE Biblioteca.buscar_libros_por_titulo TO 'lector_universidad'@'localhost';

-- Asignar privilegios al ASISTENTE (PRIVILEGIOS LIMITADOS)
GRANT SELECT, INSERT, UPDATE ON Biblioteca.vista_catalogo_completo TO 'asistente_biblioteca'@'localhost';
GRANT EXECUTE ON PROCEDURE Biblioteca.buscar_libros_por_titulo TO 'asistente_biblioteca'@'localhost';
GRANT EXECUTE ON PROCEDURE Biblioteca.insertar_ficha_bibliografica TO 'asistente_biblioteca'@'localhost';
GRANT SELECT ON Biblioteca.Idioma TO 'asistente_biblioteca'@'localhost';

-- Asignar privilegios específicos
-- Estudiante: Solo puede leer la vista pública
GRANT SELECT ON Biblioteca.vista_libros_publicos TO 'estudiante_biblioteca'@'localhost';

-- Bibliotecario: Puede leer, insertar y modificar
GRANT SELECT, INSERT, UPDATE ON Biblioteca.* TO 'bibliotecario'@'localhost';

-- Administrador: Acceso completo a la base Biblioteca
GRANT ALL PRIVILEGES ON Biblioteca.* TO 'admin_biblioteca'@'localhost';

-- Aplicar cambios de privilegios
FLUSH PRIVILEGES;

-- ====================================================
-- VISTAS DE SEGURIDAD (OCULTAN INFORMACIÓN SENSIBLE)
-- ====================================================

/*
OBJETIVO: Crear vistas que oculten información sensible
y simplifiquen el acceso a los datos
*/

-- Vista 1: Información Pública para Estudiantes y Profesores
-- OCULTA: eliminado, IDs internos, información técnica
CREATE OR REPLACE VIEW vista_libros_publicos AS
SELECT 
    l.titulo,
    l.autor,
    l.editorial,
    l.anioEdicion,
    f.isbn,
    f.clasificacionDewey,
    f.estanteria,
    i.nombre_idioma as idioma
FROM Libro l 
    JOIN FichaBibliografica f ON l.id_ficha = f.id_ficha
    JOIN Idioma i ON f.id_idioma = i.id_idioma
WHERE l.eliminado = FALSE AND f.eliminado = FALSE;

-- Vista 2: Catálogo Completo para Asistentes (oculta algunos campos sensibles)
-- OCULTA: campo 'eliminado', pero muestra IDs necesarios para gestión
CREATE OR REPLACE VIEW vista_catalogo_completo AS
SELECT 
    l.id_Libro,
    l.titulo,
    l.autor,
    l.editorial,
    l.anioEdicion,
    f.id_ficha,
    f.isbn,
    f.clasificacionDewey,
    f.estanteria,
    i.nombre_idioma as idioma
FROM Libro l 
    JOIN FichaBibliografica f ON l.id_ficha = f.id_ficha
    JOIN Idioma i ON f.id_idioma = i.id_idioma;

-- Mostrar las vistas creadas
SHOW FULL TABLES IN Biblioteca WHERE TABLE_TYPE LIKE 'VIEW';

-- ====================================================
-- VALIDACIÓN DE RESTRICCIONES DE INTEGRIDAD
-- ====================================================

-- Agregar restricciones CHECK adicionales para mayor integridad
ALTER TABLE Libro 
ADD CONSTRAINT chk_anio_edicion_valido 
CHECK (anioEdicion BETWEEN 1500 AND YEAR(CURDATE()));

-- Probar si es compatible con base de datos actual
ALTER TABLE FichaBibliografica
ADD CONSTRAINT chk_formato_isbn 
CHECK (isbn REGEXP '^978-[0-9]{12}$');

-- ====================================================
-- PRUEBAS DE INTEGRIDAD
-- ====================================================

/*
OBJETIVO: Verificar que las restricciones de la base de datos
se cumplen correctamente
*/

-- Prueba 1: Violación de PRIMARY KEY 
SET @id_existente = (SELECT MIN(id_Libro) FROM Libro);
INSERT INTO Libro (id_Libro, eliminado, titulo, autor, editorial, anioEdicion, id_ficha) 
VALUES (@id_existente, FALSE, 'Libro Duplicado', 'Autor Test', 'Editorial Test', 2020, 1);

-- Prueba 2: Violación de FOREIGN KEY 
INSERT INTO Libro (eliminado, titulo, autor, editorial, anioEdicion, id_ficha)
VALUES (FALSE, 'Libro con Ficha Inexistente', 'Autor Test', 'Editorial Test', 2020, 999999);

-- Prueba 3: Violación de UNIQUE (ISBN duplicado)
-- Esta prueba debe fallar
INSERT INTO FichaBibliografica (eliminado, isbn, clasificacionDewey, estanteria, id_idioma)
VALUES (FALSE, '978-000000000001', '000.00', 'EST-1', 1);
-- ERROR: Duplicate entry '978-000000000001' for key 'isbn'

-- Prueba 4: Violación de CHECK (Año fuera de rango)
-- Esta prueba debe fallar
INSERT INTO Libro (eliminado, titulo, autor, editorial, anioEdicion, id_ficha)
VALUES (FALSE, 'Libro Año Inválido', 'Autor Test', 'Editorial Test', 1499, 1);
-- ERROR: Check constraint 'chk_anio_edicion_valido' is violated

-- ====================================================
-- PROCEDIMIENTOS ALMACENADOS SEGUROS
-- ====================================================

/*
OBJETIVO: Implementar consultas seguras usando parámetros
para prevenir ataques de inyección SQL
*/

-- Procedimiento 1: Búsqueda segura de libros por título
-- ANTI-INYECCIÓN: Usa parámetros, no concatena SQL dinámico
DELIMITER $$
CREATE PROCEDURE buscar_libros_por_titulo(IN patron_titulo VARCHAR(150))
BEGIN
    SELECT titulo, autor, editorial, anioEdicion, isbn, idioma
    FROM vista_libros_publicos
    WHERE titulo LIKE CONCAT('%', patron_titulo, '%')
    LIMIT 100;
END$$
DELIMITER ;

-- Procedimiento 2: Inserción segura de fichas bibliográficas
-- ANTI-INYECCIÓN: Valida parámetros y usa transacciones
DELIMITER $$
CREATE PROCEDURE insertar_ficha_bibliografica(
    IN p_isbn VARCHAR(17),
    IN p_clasificacion VARCHAR(20),
    IN p_estanteria VARCHAR(20),
    IN p_id_idioma INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validar que el idioma existe
    IF NOT EXISTS (SELECT 1 FROM Idioma WHERE id_idioma = p_id_idioma) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Idioma no válido';
    END IF;
    
    -- Validar formato ISBN
    IF p_isbn NOT REGEXP '^978-[0-9]{12}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato ISBN no válido';
    END IF;
    
    -- Insertar la ficha
    INSERT INTO FichaBibliografica (eliminado, isbn, clasificacionDewey, estanteria, id_idioma)
    VALUES (FALSE, p_isbn, p_clasificacion, p_estanteria, p_id_idioma);
    
    COMMIT;
END$$
DELIMITER ;

-- ====================================================
-- PRUEBAS ANTI-INYECCIÓN SQL
-- ====================================================

/*
OBJETIVO: Demostrar que el procedimiento almacenado
es seguro contra ataques de inyección SQL
*/

-- Prueba con ataque básico de inyección
CALL buscar_libros_por_titulo(''' OR ''1''=''1');

-- Prueba con ataque UNION
CALL buscar_libros_por_titulo(''' UNION SELECT * FROM mysql.user; --');

-- Prueba de funcionalidad normal (para comparación)
CALL buscar_libros_por_titulo('programación');

-- Prueba 1: Ataque de inyección SQL en búsqueda
-- Intento malicioso: 
CALL buscar_libros_por_titulo("'; DROP TABLE Libro; --");

-- Resultado esperado: NO ejecuta el DROP, solo busca títulos que contengan ese texto
-- Explicación: El parámetro se trata como literal, no como código SQL ejecutable

-- Prueba 2: Ataque de inyección en inserción
-- Intento malicioso:
CALL insertar_ficha_bibliografica(
    "978-000000000001'; DROP TABLE Libro; --", 
    "000.00", 
    "EST-1", 
    1
);

-- Resultado esperado: Falla por validación de formato ISBN
-- Explicación: El procedimiento valida el formato antes de insertar, evitando la inyección

-- =============================================
-- VERIFICACIÓN FINAL
-- =============================================

-- Mostrar resumen de lo implementado
SELECT 'USUARIOS CREADOS:' as RESUMEN;
SELECT user, host FROM mysql.user WHERE user LIKE '%biblioteca%' OR user LIKE '%universidad%';

SELECT 'VISTAS CREADAS:' as RESUMEN;
SHOW FULL TABLES WHERE Table_type = 'VIEW';

SELECT 'PROCEDIMIENTOS CREADOS:' as RESUMEN;
SHOW PROCEDURE STATUS WHERE Db = 'Biblioteca';

SELECT 'RESTRICCIONES AGREGADAS:' as RESUMEN;
SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'Biblioteca' 
AND CONSTRAINT_NAME LIKE 'chk%';

-- ====================================================
-- LIMPIEZA FINAL
-- ====================================================

/*
OBJETIVO: Restaurar configuración y limpiar datos de prueba
(opcional - comentado para revisión del profesor)
*/

-- Limpiar datos de prueba (OPCIONAL)
-- DELETE FROM Libro WHERE id_libro >= 999990;
-- DELETE FROM FichaBibliografica WHERE id_ficha >= 999990;

-- Restaurar configuración de foreign keys
SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;

-- =============================================
-- FIN DEL SCRIPT - ETAPA 4 COMPLETADA
-- =============================================