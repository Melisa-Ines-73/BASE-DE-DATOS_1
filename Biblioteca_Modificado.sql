-- ====== Base de datos ======
CREATE DATABASE IF NOT EXISTS Biblioteca
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE Biblioteca;

-- ====== Tabla: FichaBibliografica ======
CREATE TABLE IF NOT EXISTS FichaBibliografica (
  id_ficha INT PRIMARY KEY AUTO_INCREMENT,          -- PK autoincremental
  eliminado BOOLEAN NOT NULL DEFAULT 0,             -- 0=activo, 1=eliminado
  isbn VARCHAR(17) UNIQUE,                          -- evita ISBN duplicados
  clasificacionDewey VARCHAR(20),
  estanteria VARCHAR(20),
  idioma VARCHAR(30),

  -- CHECKs básicos
  CHECK (eliminado IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ====== Tabla: Libro ======
CREATE TABLE IF NOT EXISTS Libro (
  id_Libro INT PRIMARY KEY AUTO_INCREMENT,          -- PK autoincremental
  eliminado BOOLEAN NOT NULL DEFAULT 0,
  titulo VARCHAR(150) NOT NULL,
  autor  VARCHAR(120) NOT NULL,
  editorial VARCHAR(100),
  anioEdicion INT,
  id_ficha INT NOT NULL UNIQUE,                     -- relación 1:1 con Ficha

  -- CHECKs básicos
  CHECK (eliminado IN (0,1)),           -- dominio de valores para eliminado
  CHECK (anioEdicion IS NULL OR (anioEdicion BETWEEN 1450 AND YEAR(CURDATE()))),  -- control sobre el año de edición

  FOREIGN KEY (id_ficha) 
    REFERENCES FichaBibliografica(id_ficha)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
