-- ============================================================
-- TRABAJO FINAL INTEGRADOR - BASE DE DATOS I
-- ETAPA 4: SEGURIDAD E INTEGRIDAD
-- Objetivo: Demostrar principios de seguridad, control de acceso y protección de datos
-- ============================================================

-- ============================================================
-- CONFIGURACIÓN INICIAL
-- ============================================================
USE Biblioteca;

-- 1. Guardar configuración actual por si algo se modifica
SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;

/* 
OBJETIVO: Preparar el entorno para las pruebas de seguridad
*/

-- ============================================================
-- SECCIÓN 1: CREACIÓN DE USUARIOS CON ROLES ESPECÍFICOS
-- ESCENARIO: BIBLIOTECA UNIVERSITARIA "CAMPUS CENTRAL"
-- ============================================================

/* 
OBJETIVO: Aplicar el principio de mínimo privilegio creando
usuarios con diferentes niveles de acceso
*/

-- Eliminar usuarios si existen (para pruebas)
DROP USER IF EXISTS 'estudiante_consulta'@'localhost';
DROP USER IF EXISTS 'bibliotecario_gestor'@'localhost';
DROP USER IF EXISTS 'admin_biblioteca'@'localhost';

-- USUARIO 1: ESTUDIANTE (Solo consultas)
-- Propósito: Representa a un estudiante que solo necesita buscar libros
-- Permisos: Mínimos necesarios - solo lectura de datos públicos
CREATE USER IF NOT EXISTS 'estudiante_consulta'@'localhost' 
IDENTIFIED BY 'estudiante123';

-- USUARIO 2: BIBLIOTECARIO (Gestión diaria)
-- Propósito: Representa al personal que atiende en mostrador
-- Permisos: Puede gestionar préstamos y ver información interna
CREATE USER IF NOT EXISTS 'bibliotecario_gestor'@'localhost' 
IDENTIFIED BY 'bibliotecario123';

-- USUARIO 3: ADMINISTRADOR (Gestión completa)
-- Propósito: Representa al jefe de biblioteca
-- Permisos: Control total sobre datos, pero no sobre estructura
CREATE USER IF NOT EXISTS 'admin_biblioteca'@'localhost' 
IDENTIFIED BY 'admin123';

-- ============================================================
-- SECCIÓN 2: ASIGNACIÓN DE PERMISOS
-- ============================================================

/*
OBJETIVO: Asignar solo los permisos necesarios para cada rol
*/

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'estudiante_consulta'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'bibliotecario_gestor'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'admin_biblioteca'@'localhost';

-- VERIFICAR SI LAS VISTAS YA FUERON CREADAS
SHOW FULL TABLES IN Biblioteca WHERE TABLE_TYPE LIKE 'VIEW';

-- PERMISOS DEL ESTUDIANTE
-- Propósito: Solo puede consultar libros disponibles
-- Seguridad: No puede modificar, eliminar ni ver datos internos
GRANT SELECT ON Biblioteca.vista_estudiante TO 'estudiante_consulta'@'localhost';

-- PERMISOS DEL BIBLIOTECARIO  
-- Propósito: Puede gestionar el día a día de la biblioteca
-- Seguridad: Puede modificar datos pero no la estructura de la base
GRANT SELECT, INSERT, UPDATE ON Biblioteca.vista_bibliotecario TO 'bibliotecario_gestor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Biblioteca.Libro TO 'bibliotecario_gestor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Biblioteca.FichaBibliografica TO 'bibliotecario_gestor'@'localhost';

-- PERMISOS DEL ADMINISTRADOR
-- Propósito: Gestión completa de los datos de la biblioteca
-- Seguridad: Todas las operaciones sobre datos, pero limitado a esta base
GRANT SELECT, INSERT, UPDATE, DELETE ON Biblioteca.* TO 'admin_biblioteca'@'localhost';

-- ============================================================
-- SECCIÓN 3: PROCEDIMIENTO ALMACENADO SEGURO (Anti-inyección SQL)
-- ============================================================

-- PROCEDIMIENTO: Búsqueda segura de libros
-- Propósito: Permitir búsquedas sin riesgo de inyección SQL
-- Seguridad: Usa parámetros preparados, no concatenación de strings
DELIMITER //

CREATE PROCEDURE buscar_libros_por_titulo(
    IN titulo_busqueda VARCHAR(150)
)
BEGIN
    -- Esta consulta es SEGURA porque usa parámetros, no concatena SQL
    -- Neutraliza ataques como: "' OR '1'='1" o "'; DROP TABLE Libro; --"
    SELECT 
        l.id_Libro AS 'Codigo',
        l.titulo AS 'Titulo', 
        l.autor AS 'Autor',
        l.editorial AS 'Editorial',
        l.anioEdicion AS 'Año',
        f.isbn AS 'ISBN',
        f.estanteria AS 'Ubicacion'
    FROM Libro l
    JOIN FichaBibliografica f ON l.id_ficha = f.id_ficha
    WHERE l.titulo LIKE CONCAT('%', titulo_busqueda, '%')
    AND l.eliminado = FALSE
    AND f.eliminado = FALSE
    ORDER BY l.titulo;
END //

CREATE PROCEDURE buscar_libros_por_autor( IN patron_autor VARCHAR(150))
BEGIN
    SELECT 
        l.id_Libro AS 'Codigo',
        l.titulo AS 'Titulo', 
        l.autor AS 'Autor',
        l.editorial AS 'Editorial',
        l.anioEdicion AS 'Año',
        f.isbn AS 'ISBN',
        f.estanteria AS 'Ubicacion'
    FROM Libro l
    JOIN FichaBibliografica f ON l.id_ficha = f.id_ficha
    WHERE l.autor LIKE CONCAT('%', patron_autor, '%')
    AND l.eliminado = FALSE
    AND f.eliminado = FALSE
    ORDER BY l.autor;
END //

DELIMITER ;

-- Listar procedimientos
SHOW PROCEDURE STATUS WHERE Db = 'Biblioteca';

-- PERMISOS PARA USAR EL PROCEDIMIENTO
-- Propósito: Solo personal autorizado puede ejecutar búsquedas
GRANT EXECUTE ON PROCEDURE Biblioteca.buscar_libros_por_titulo TO 
'bibliotecario_gestor'@'localhost', 'admin_biblioteca'@'localhost';
GRANT EXECUTE ON PROCEDURE Biblioteca.buscar_libros_por_autor TO 
'bibliotecario_gestor'@'localhost', 'admin_biblioteca'@'localhost';

-- Aplicar cambios de privilegios
FLUSH PRIVILEGES;

-- ============================================================
-- SECCIÓN 4: VERIFICACIÓN FINAL (Comandos útiles)
-- VALIDACIÓN DE RESTRICCIONES DE INTEGRIDAD
-- ============================================================

-- VERIFICAR USUARIOS CREADOS
SELECT user, host FROM mysql.user WHERE user LIKE '%estudiante%' OR user LIKE '%bibliotecario%' OR user LIKE '%admin%';

-- VERIFICAR PERMISOS ASIGNADOS
SHOW GRANTS FOR 'estudiante_consulta'@'localhost';
SHOW GRANTS FOR 'bibliotecario_gestor'@'localhost';
SHOW GRANTS FOR 'admin_biblioteca'@'localhost';

-- ============================================================
-- SECCIÓN 5: PRUEBAS DE INTEGRIDAD
-- ============================================================

/*
OBJETIVO: Verificar que las restricciones de la base de datos
se cumplen correctamente
*/

-- Verificar la variable FOREIGN_KEY_CHECKS
SELECT @@FOREIGN_KEY_CHECKS;

-- Si es 0, las restricciones están desactivadas
-- SET FOREIGN_KEY_CHECKS = 1;  -- Descomentar para activar restricciones

-- Prueba 1: Violación de PRIMARY KEY 
SET @id_existente = (SELECT MIN(id_Libro) FROM Libro);
INSERT INTO Libro (id_Libro, eliminado, titulo, autor, editorial, anioEdicion, id_ficha) 
VALUES (@id_existente, FALSE, 'Libro Duplicado', 'Autor Test', 'Editorial Test', 2020, 1);

-- Prueba 2: Violación de FOREIGN KEY 
INSERT INTO Libro (eliminado, titulo, autor, editorial, anioEdicion, id_ficha)
VALUES (FALSE, 'Libro con Ficha Inexistente', 'Autor Test', 'Editorial Test', 2020, 999999);

-- Prueba 3: Violación de UNIQUE (ISBN duplicado)
-- Esta prueba debe fallar
SET @isbn_existente = (SELECT MIN(isbn) FROM FichaBibliografica);
INSERT INTO FichaBibliografica (eliminado, isbn, clasificacionDewey, estanteria, id_idioma)
VALUES (FALSE, @isbn_existente, '000.00', 'EST-1', 1);
-- ERROR: Duplicate entry '978-000000000001' for key 'isbn'
-- Intenta insertar un ISBN que ya existe (el primero de la tabla).
-- ERROR - No puede haber dos fichas con el mismo ISBN.
-- Propósito: Verificar que los valores únicos se mantienen únicos.

-- ============================================================
-- SECCIÓN 6: PRUEBAS ANTI-INYECCIÓN SQL
-- ============================================================

/*
OBJETIVO: Demostrar que el procedimiento almacenado
es seguro contra ataques de inyección SQL
*/

-- Prueba: Ataque de inyección SQL en búsqueda
-- Intento malicioso: 
CALL buscar_libros_por_autor("'; DROP TABLE Libro; --");
-- Resultado esperado: NO ejecuta el DROP, solo busca títulos que contengan ese texto
-- Explicación: El parámetro se trata como literal, no como código SQL ejecutable

-- Prueba con ataque básico de inyección
CALL buscar_libros_por_titulo(''' OR ''1''=''1');

-- Prueba con ataque UNION
CALL buscar_libros_por_titulo(''' UNION SELECT * FROM mysql.user; --');

-- Prueba de funcionalidad normal (para comparación)
CALL buscar_libros_por_titulo('Libro 10');

-- ============================================================
-- SECCIÓN 7: PRUEBAS POR ROL
-- ============================================================

-- CONECTAR como 'estudiante_consulta'
USE Biblioteca;
SELECT * FROM vista_estudiante;
-- Prueba Estudiante intenta modificar libro (DEBE FALLAR)
UPDATE vista_estudiante SET Titulo = 'Hackeado' WHERE Codigo = 1;
-- RESULTADO ESPERADO: Error de permisos

-- CONECTAR como 'bibliotecario_gestor'
USE Biblioteca;
SELECT * FROM vista_bibliotecario;
-- Prueba Bibliotecario puede actualizar estado (DEBE FUNCIONAR)  
UPDATE Libro SET eliminado = TRUE WHERE id_Libro = @id_existente;
-- RESULTADO ESPERADO: Éxito

-- Restaurar configuración
SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;

-- ============================================================
-- FIN DEL SCRIPT - ETAPA 4 COMPLETADA
-- ============================================================