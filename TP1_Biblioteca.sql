CREATE DATABASE Biblioteca

use Biblioteca

create table FichaBibliografica (
id_ficha INT PRIMARY KEY AUTO_INCREMENT,
    eliminado BOOLEAN,
    isbn VARCHAR(17) UNIQUE,
    clasificacionDewey VARCHAR(20),
    estanteria VARCHAR(20),
    id_idioma INT NOT NULL,
    CHECK (eliminado IN (TRUE, FALSE)),
    FOREIGN KEY (id_idioma) REFERENCES Idioma(id_idioma)

);

create table Libro (

    id_Libro INT PRIMARY KEY AUTO_INCREMENT, 
    eliminado BOOLEAN,
    titulo VARCHAR(150) NOT NULL,
    autor VARCHAR(120) NOT NULL,
    editorial VARCHAR(100),
    anioEdicion INT,
    id_ficha INT UNIQUE,
    CHECK (eliminado IN (TRUE, FALSE)),
    CHECK (anioEdicion BETWEEN 1800 AND YEAR(CURDATE())),
    FOREIGN KEY (id_ficha) REFERENCES FichaBibliografica(id_ficha)
);


USE Biblioteca;

CREATE TABLE Idioma (
    id_idioma INT PRIMARY KEY AUTO_INCREMENT,
    nombre_idioma VARCHAR(30) UNIQUE NOT NULL
);

USE Biblioteca;
INSERT INTO Idioma (nombre_idioma) VALUES
('Español'),
('Inglés'),
('Francés'),
('Alemán');
USE Biblioteca;

ALTER TABLE FichaBibliografica DROP COLUMN idioma;
USE Biblioteca;

ALTER TABLE FichaBibliografica ADD COLUMN id_idioma INT NOT NULL;
USE Biblioteca;

ALTER TABLE FichaBibliografica
ADD CONSTRAINT fk_idioma
FOREIGN KEY (id_idioma)
REFERENCES Idioma(id_idioma);

USE Biblioteca;
SHOW TABLES;

USE Biblioteca;

--- Generación de Tabla Numeros 
CREATE TABLE Numeros (
  n INT PRIMARY KEY
);



INSERT INTO FichaBibliografica (eliminado, isbn, clasificacionDewey, estanteria, id_idioma)
SELECT 
  FALSE,
  CONCAT('978-', LPAD(n, 12, '0')),
  CONCAT(FLOOR(RAND() * 999), '.', FLOOR(RAND() * 99)),
  CONCAT('EST-', MOD(n, 100)),
  1 + MOD(n, 4)
FROM Numeros;

INSERT INTO Libro (eliminado, titulo, autor, editorial, anioEdicion, id_ficha)
SELECT 
  FALSE,
  CONCAT('Título ', id_ficha),
  CONCAT('Autor ', CHAR(65 + MOD(id_ficha, 26)), ' ', CHAR(65 + MOD(id_ficha DIV 26, 26))),
  CONCAT('Editorial ', MOD(id_ficha, 50)),
  1900 + MOD(id_ficha, 125),
  id_ficha
FROM FichaBibliografica;



SELECT COUNT(*) FROM FichaBibliografica;

SELECT COUNT(*) FROM Libro;

DROP TABLE Numeros;



















