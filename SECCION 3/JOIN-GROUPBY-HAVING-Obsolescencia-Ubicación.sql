SELECT
    F.estanteria,
    COUNT(L.id_Libro) AS Total_Obras_Obsoletas
FROM
    FichaBibliografica AS F
JOIN
    Libro AS L ON L.id_ficha = F.id_ficha
WHERE
    L.anioEdicion < 1950
GROUP BY
    F.estanteria
HAVING
    COUNT(L.id_Libro) >= 5
ORDER BY
    Total_Obras_Obsoletas DESC;