SELECT
    L.titulo,
    L.autor,
    L.anioEdicion,
    F.estanteria,
    I.nombre_idioma AS Nombre_Idioma -- CORRECCIÓN AQUÍ
FROM
    Libro AS L
JOIN
    FichaBibliografica AS F ON L.id_ficha = F.id_ficha
JOIN
    Idioma AS I ON F.id_idioma = I.id_idioma
WHERE
    L.anioEdicion = 1901
    AND L.eliminado = 0
ORDER BY
    L.autor ASC;