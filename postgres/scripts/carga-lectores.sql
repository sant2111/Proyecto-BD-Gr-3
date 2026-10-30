\set ON_ERROR_STOP on
\if :{?archivo}
\else
    \set archivo /scripts/datos/lectores_semilla.csv
\endif

SET search_path TO biblioteca;

BEGIN;

TRUNCATE stg_linea, stg_lector RESTART IDENTITY;

-- 1. Leer el CSV
COPY stg_linea (linea) FROM :'archivo' WITH (FORMAT text);
DELETE FROM stg_linea WHERE n = 1;

-- 2. Separar los campos
INSERT INTO stg_lector (
    linea_csv, contenido, num_campos,
    documento, nombres, apellidos, correo, telefono
)
SELECT
    n,
    linea,
    array_length(string_to_array(linea, ','), 1),
    trim(split_part(linea, ',', 1)),
    trim(split_part(linea, ',', 2)),
    trim(split_part(linea, ',', 3)),
    lower(trim(split_part(linea, ',', 4))),
    trim(split_part(linea, ',', 5))
FROM stg_linea;

-- 3. Validar los campos
UPDATE stg_lector SET motivo = CASE
    WHEN num_campos <> 5
        THEN 'tiene ' || num_campos || ' columnas, se esperaban 5'
    WHEN documento = ''
        THEN 'documento vacío'
    WHEN documento !~ '^[0-9]{6,15}$'
        THEN 'documento no numérico o de longitud inválida'
    WHEN nombres = ''
        THEN 'nombres vacío'
    WHEN apellidos = ''
        THEN 'apellidos vacío'
    WHEN correo = ''
        THEN 'correo vacío'
    WHEN correo !~ '^[^@ ]+@[^@ ]+\.[^@ ]+$'
        THEN 'correo mal formado'
    WHEN telefono !~ '^[0-9]{7,15}$'
        THEN 'teléfono no numérico o de longitud inválida'
END;

-- 4. Detectar documentos o correos repetidos en el archivo
UPDATE stg_lector s
SET motivo = 'documento o correo repetido en el archivo'
WHERE s.motivo IS NULL
  AND EXISTS (
      SELECT 1
      FROM stg_lector anterior
      WHERE (
          anterior.documento = s.documento
          OR anterior.correo = s.correo
      )
        AND anterior.motivo IS NULL
        AND anterior.linea_csv < s.linea_csv
  );

-- 5. Preparar lectores válidos que aún no existen
CREATE TEMP TABLE tmp_lectores_cargar
ON COMMIT PRESERVE ROWS AS
SELECT
    s.documento, s.nombres, s.apellidos, s.correo, s.telefono
FROM stg_lector s
WHERE s.motivo IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM lector l
      WHERE l.documento = s.documento
         OR l.correo = s.correo
  );

-- 6. Insertar los nuevos lectores
INSERT INTO lector (
    documento, nombres, apellidos, correo, telefono
)
SELECT documento, nombres, apellidos, correo, telefono
FROM tmp_lectores_cargar;

-- 7. Registrar únicamente las filas inválidas
INSERT INTO rechazo_carga (archivo, linea, contenido, motivo)
SELECT :'archivo', linea_csv, contenido, motivo
FROM stg_lector
WHERE motivo IS NOT NULL;

COMMIT;

-- 8. Resumen de la ejecución
SELECT
    (SELECT count(*) FROM tmp_lectores_cargar) AS cargados,
    (SELECT count(*) FROM stg_lector
     WHERE motivo IS NOT NULL) AS rechazados;

-- 9. Mostrar las filas rechazadas
SELECT linea_csv AS linea, motivo, contenido
FROM stg_lector
WHERE motivo IS NOT NULL
ORDER BY linea_csv;

DROP TABLE tmp_lectores_cargar;