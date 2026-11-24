CREATE SCHEMA biblioteca;
SET search_path TO biblioteca;

-- 1. TABLA LIBRO (Estructura requerida por carga-libros.sql)
CREATE TABLE libro (
    isbn                    varchar(13)   PRIMARY KEY CHECK (isbn ~ '^[0-9]{13}$'),
    titulo                  varchar(200)  NOT NULL CHECK (titulo <> ''),
    autor                   varchar(120)  NOT NULL CHECK (autor <> ''),
    categoria               varchar(40)   NOT NULL CHECK (categoria <> ''),
    anio_publicacion        smallint      NOT NULL CHECK (anio_publicacion BETWEEN 1450 AND 2100)
);

-- 2. RESTO DE TABLAS DEL MODELO
CREATE TABLE rol (
    id_rol    integer PRIMARY KEY,
    tipo_rol  varchar(255) NOT NULL UNIQUE
);

CREATE TABLE usuario (
    id_usuario  integer PRIMARY KEY,
    id_rol      integer NOT NULL REFERENCES rol(id_rol),
    correo      varchar(255) UNIQUE NOT NULL,
    contrasena  varchar(255) NOT NULL,
    nombre      varchar(255) NOT NULL,
    telefono    varchar(255)
);

CREATE TABLE lector (
    documento VARCHAR(15) PRIMARY KEY
        CHECK (documento ~ '^[0-9]{6,15}$'),
    nombres VARCHAR(100) NOT NULL
        CHECK (nombres <> ''),
    apellidos VARCHAR(100) NOT NULL
        CHECK (apellidos <> ''),
    correo VARCHAR(255) NOT NULL UNIQUE
        CHECK (correo ~ '^[^@ ]+@[^@ ]+[.][^@ ]+$'),
    telefono VARCHAR(15) NOT NULL
        CHECK (telefono ~ '^[0-9]{7,15}$')
);

CREATE TABLE ejemplar (
    isbn         varchar(13) REFERENCES libro(isbn) ON DELETE CASCADE,
    id_ejemplar  integer,
    tipo         varchar(255) NOT NULL,
    PRIMARY KEY (isbn, id_ejemplar)
);

CREATE TABLE prestamo (
    id_prestamo     serial PRIMARY KEY,
    documento varchar(15) NOT NULL REFERENCES lector(documento),
    isbn            varchar(13) NOT NULL,
    id_ejemplar     integer NOT NULL,
    fecha_prestamo  date NOT NULL,
    fecha_limite    date NOT NULL,
    fecha_devolucion date,
    CONSTRAINT prestamo_fechas_ck CHECK (fecha_limite >= fecha_prestamo AND (fecha_devolucion IS NULL OR fecha_devolucion >= fecha_prestamo)),
    FOREIGN KEY (isbn, id_ejemplar) REFERENCES ejemplar(isbn, id_ejemplar)
);

-- 3. BITÁCORA Y TABLAS DE PASO
CREATE TABLE rechazo_carga (
    id         integer      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    archivo    text         NOT NULL,
    linea      integer      NOT NULL,
    contenido  text         NOT NULL,
    motivo     text         NOT NULL,
    fecha      timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE stg_linea (
    n      integer  GENERATED ALWAYS AS IDENTITY,
    linea  text
);

CREATE TABLE stg_libro (
    linea_csv               integer,
    contenido               text,
    num_campos              integer,
    isbn                    text,
    titulo                  text,
    autor                   text,
    categoria               text,
    anio_publicacion        text,
    ejemplares_disponibles  text,   -- columna del CSV: se interpreta como total de copias (ver carga-libros.sql)
    motivo                  text
);

-- 4. TABLA DE PASO LECTORES

CREATE TABLE stg_lector (
    linea_csv INTEGER,
    contenido TEXT,
    num_campos INTEGER,
    documento TEXT,
    nombres TEXT,
    apellidos TEXT,
    correo TEXT,
    telefono TEXT,
    motivo TEXT
);

CREATE UNIQUE INDEX prestamo_abierto_uk ON prestamo(isbn,id_ejemplar) WHERE fecha_devolucion IS NULL;
CREATE VIEW libro_disponibilidad AS SELECT l.isbn,l.titulo,l.autor,l.categoria,count(e.id_ejemplar)::integer AS ejemplares,count(p.id_prestamo)::integer AS prestados,(count(e.id_ejemplar)-count(p.id_prestamo))::integer AS disponibles FROM libro l LEFT JOIN ejemplar e ON e.isbn=l.isbn LEFT JOIN prestamo p ON p.isbn=e.isbn AND p.id_ejemplar=e.id_ejemplar AND p.fecha_devolucion IS NULL GROUP BY l.isbn;
CREATE VIEW prestamo_con_estado AS SELECT p.*, CASE WHEN fecha_devolucion IS NOT NULL THEN 'devuelto' WHEN fecha_limite < CURRENT_DATE THEN 'en mora' ELSE 'activo' END AS estado FROM prestamo p;
