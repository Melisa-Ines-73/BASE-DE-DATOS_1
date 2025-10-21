-- ============================================================
-- VISTAS DE SEGURIDAD 
-- ============================================================

USE Biblioteca;

-- VISTA 1: PARA BUSQUEDA RÁPIDA
-- Propósito: Mostrar la información mas básica de un libro
-- Seguridad: Solo lectura
CREATE OR REPLACE VIEW vista_busqueda_rapida AS
SELECT
    l.titulo AS 'Titulo',
    l.autor AS 'Autor',
    f.isbn AS 'ISBN'
FROM Libro l
INNER JOIN FichaBibliografica f ON l.id_ficha = f.id_ficha
WHERE l.eliminado = FALSE AND f.eliminado = FALSE;

-- SELECT * FROM vista_busqueda_rapida;

-- VISTA 2: PARA ESTUDIANTES (Información limitada)
-- Propósito: Mostrar solo libros disponibles con datos básicos
-- Seguridad: Oculta libros eliminados y IDs internos, información técnica
CREATE OR REPLACE VIEW vista_estudiante AS
SELECT 
    l.titulo AS 'Titulo',
    l.autor AS 'Autor',
    l.editorial AS 'Editorial',
    l.anioEdicion AS 'Año',
    f.isbn AS 'ISBN',
    f.clasificacionDewey AS 'Clasificacion',
    f.estanteria AS 'Ubicacion'
FROM Libro l
JOIN FichaBibliografica f ON l.id_ficha = f.id_ficha
WHERE l.eliminado = FALSE 
AND f.eliminado = FALSE;

-- SELECT * FROM vista_estudiante;

-- VISTA 3: PARA BIBLIOTECARIOS (Información extendida)
-- Propósito: Mostrar información completa para gestión diaria
-- Seguridad: Incluye estado de libros pero mantiene controles
CREATE OR REPLACE VIEW vista_bibliotecario AS
SELECT 
    l.id_Libro AS 'Codigo',
    l.titulo AS 'Titulo',
    l.autor AS 'Autor',
    l.editorial AS 'Editorial',
    l.anioEdicion AS 'Año',
    l.eliminado AS 'Eliminado',  -- Los bibliotecarios ven este campo
    f.isbn AS 'ISBN',
    f.clasificacionDewey AS 'Clasificacion',
    f.estanteria AS 'Ubicacion',
    f.eliminado AS 'Ficha_Eliminada'  -- Información interna visible
FROM Libro l
JOIN FichaBibliografica f ON l.id_ficha = f.id_ficha;

-- SELECT * FROM vista_bibliotecario;

-- VERIFICAR VISTAS CREADAS
SHOW FULL TABLES IN Biblioteca WHERE TABLE_TYPE LIKE 'VIEW';