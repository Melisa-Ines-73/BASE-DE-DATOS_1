CREATE INDEX ix_ficha_idioma ON FichaBibliografica(id_idioma);

CREATE INDEX ix_libro_anio ON Libro(anioEdicion);

CREATE INDEX ix_libro_idficha ON Libro(id_ficha);