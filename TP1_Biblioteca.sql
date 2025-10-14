CREATE DATABASE Biblioteca

use Biblioteca

create table FichaBibliografica (
id_ficha int PRIMARY KEY,
eliminado BOOLEAN,
isbn VARCHAR(17) UNIQUE,
clasificacionDewey VARCHAR(20),
estanteria VARCHAR(20),
idioma VARCHAR(30)
);

create table Libro (
id_Libro int PRIMARY KEY, 
eliminado BOOLEAN,
titulo VARCHAR(150) NOT NULL,
autor VARCHAR(120) NOT NULL,
editorial VARCHAR(100),
anioEdicion INT,
id_ficha INT UNIQUE,
FOREIGN KEY (id_ficha) REFERENCES FichaBibliografica(id_ficha)
);

