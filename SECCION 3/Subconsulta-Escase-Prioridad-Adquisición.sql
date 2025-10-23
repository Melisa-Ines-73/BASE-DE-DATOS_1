SELECT
    L.titulo,
    F.isbn,
    I.nombre_idioma AS Idioma_Menos_Stock
FROM
    Libro AS L
JOIN
    FichaBibliografica AS F ON L.id_ficha = F.id_ficha
JOIN
    Idioma AS I ON F.id_idioma = I.id_idioma
WHERE
    F.id_idioma = (
        SELECT id_idioma
        FROM FichaBibliografica
        GROUP BY id_idioma
        ORDER BY COUNT(*) ASC
        LIMIT 1
    )
ORDER BY
    L.titulo
LIMIT 50;