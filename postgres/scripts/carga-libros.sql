\set ON_ERROR_STOP on
\if :{?archivo}
\else
    \set archivo /scripts/datos/libros_semilla.csv
\endif

SET search_path TO biblioteca;

BEGIN;

TRUNCATE stg_linea, stg_libro RESTART IDENTITY;

COPY stg_linea (linea) FROM :'archivo' WITH (FORMAT text);
DELETE FROM stg_linea WHERE n = 1;

INSERT INTO stg_libro (
    linea_csv, contenido, num_campos, isbn, titulo,
    autor, categoria, anio_publicacion, ejemplares_disponibles
)
SELECT
    n, linea,
    array_length(string_to_array(linea, ','), 1),
    trim(split_part(linea, ',', 1)),
    trim(split_part(linea, ',', 2)),
    trim(split_part(linea, ',', 3)),
    trim(split_part(linea, ',', 4)),
    trim(split_part(linea, ',', 5)),
    trim(split_part(linea, ',', 6))
FROM stg_linea;

-- Validaciones de los campos
UPDATE stg_libro SET motivo = CASE
    WHEN num_campos <> 6 THEN 'tiene ' || num_campos || ' columnas, se esperaban 6'
    WHEN isbn = '' THEN 'isbn vacío'
    WHEN isbn !~ '^[0-9]{13}$' THEN 'isbn no tiene 13 dígitos'
    WHEN titulo = '' THEN 'título vacío'
    WHEN autor = '' THEN 'autor vacío'
    WHEN categoria = '' THEN 'categoría vacía'
    WHEN anio_publicacion !~ '^[0-9]{1,4}$' THEN 'año no numérico'
    WHEN anio_publicacion::integer NOT BETWEEN 1450 AND 2100 THEN 'año fuera de rango'
    WHEN ejemplares_disponibles !~ '^-?[0-9]{1,6}$' THEN 'ejemplares no numérico'
    WHEN ejemplares_disponibles::integer < 0 THEN 'ejemplares negativo'
END;

-- Detectar ISBN repetidos dentro del mismo archivo
UPDATE stg_libro s
SET motivo = 'isbn repetido en el archivo'
WHERE s.motivo IS NULL
  AND EXISTS (
      SELECT 1
      FROM stg_libro anterior
      WHERE anterior.isbn = s.isbn
        AND anterior.motivo IS NULL
        AND anterior.linea_csv < s.linea_csv
  );

-- Preparar solo libros válidos que todavía no existen
CREATE TEMP TABLE tmp_libros_cargar ON COMMIT PRESERVE ROWS AS
SELECT s.isbn, s.titulo, s.autor, s.categoria,
       s.anio_publicacion::smallint AS anio_publicacion,
       s.ejemplares_disponibles::integer AS ejemplares_disponibles
FROM stg_libro s
WHERE s.motivo IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM libro l WHERE l.isbn = s.isbn
  );

-- Insertar los nuevos
INSERT INTO libro (
    isbn, titulo, autor, categoria,
    anio_publicacion, ejemplares_disponibles
)
SELECT isbn, titulo, autor, categoria,
       anio_publicacion, ejemplares_disponibles
FROM tmp_libros_cargar;

-- Registrar únicamente errores reales
INSERT INTO rechazo_carga (archivo, linea, contenido, motivo)
SELECT :'archivo', linea_csv, contenido, motivo
FROM stg_libro
WHERE motivo IS NOT NULL;

COMMIT;

-- Resumen: nuevos insertados y filas realmente rechazadas
SELECT (SELECT count(*) FROM tmp_libros_cargar) AS cargadas,
       (SELECT count(*) FROM stg_libro WHERE motivo IS NOT NULL) AS rechazadas;

SELECT linea_csv AS linea, motivo, contenido
FROM stg_libro
WHERE motivo IS NOT NULL
ORDER BY linea_csv;

DROP TABLE tmp_libros_cargar;