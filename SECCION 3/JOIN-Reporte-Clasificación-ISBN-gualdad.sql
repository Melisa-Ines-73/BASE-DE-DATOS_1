SELECT
    L.titulo,
    L.autor,
    F.isbn,
    F.clasificacionDewey
FROM
    Libro AS L
JOIN
    FichaBibliografica AS F ON L.id_ficha = F.id_ficha
WHERE
    L.editorial = 'Editorial 8'
    AND F.clasificacionDewey LIKE '8%';