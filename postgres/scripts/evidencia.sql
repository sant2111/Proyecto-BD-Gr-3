SET search_path TO biblioteca;

\echo ==== E1a. ejemplares_disponibles: resumen
SELECT count(*) AS libros,
       count(*) FILTER (WHERE guardado <> calculado) AS descuadrados
FROM (
  SELECT l.isbn, l.ejemplares_disponibles AS guardado,
         count(e.id_ejemplar) - count(p.id_prestamo) AS calculado
  FROM libro l
  LEFT JOIN ejemplar e ON e.isbn = l.isbn
  LEFT JOIN prestamo p ON p.isbn = e.isbn AND p.id_ejemplar = e.id_ejemplar
                      AND p.fecha_devolucion IS NULL
  GROUP BY l.isbn, l.ejemplares_disponibles
) q;

\echo ==== E1b. libros con ejemplares: guardado vs calculado
SELECT l.isbn, l.titulo, l.ejemplares_disponibles AS guardado,
       count(e.id_ejemplar) AS ejemplares, count(p.id_prestamo) AS abiertos,
       count(e.id_ejemplar) - count(p.id_prestamo) AS calculado
FROM libro l
JOIN ejemplar e ON e.isbn = l.isbn
LEFT JOIN prestamo p ON p.isbn = e.isbn AND p.id_ejemplar = e.id_ejemplar
                    AND p.fecha_devolucion IS NULL
GROUP BY l.isbn, l.titulo, l.ejemplares_disponibles
ORDER BY l.isbn;

\echo ==== E1c. libros con stock guardado pero sin filas en ejemplar
SELECT count(*) AS libros_sin_ejemplares_con_stock
FROM libro l
WHERE l.ejemplares_disponibles > 0
  AND NOT EXISTS (SELECT 1 FROM ejemplar e WHERE e.isbn = l.isbn);

\echo ==== E2a. estado guardado vs calculado HOY
SELECT id_prestamo, estado AS guardado,
       CASE WHEN fecha_devolucion IS NOT NULL THEN 'devuelto'
            WHEN fecha_limite < CURRENT_DATE THEN 'en mora'
            ELSE 'activo' END AS calculado
FROM prestamo
WHERE estado IS DISTINCT FROM
      CASE WHEN fecha_devolucion IS NOT NULL THEN 'devuelto'
           WHEN fecha_limite < CURRENT_DATE THEN 'en mora'
           ELSE 'activo' END;

\echo ==== E2b. lo mismo dentro de 30 dias
SELECT p.id_prestamo, p.estado AS guardado,
       CASE WHEN p.fecha_devolucion IS NOT NULL THEN 'devuelto'
            WHEN p.fecha_limite < h.dia THEN 'en mora'
            ELSE 'activo' END AS calculado_en_30_dias
FROM prestamo p, (SELECT CURRENT_DATE + 30 AS dia) h
WHERE p.estado IS DISTINCT FROM
      CASE WHEN p.fecha_devolucion IS NOT NULL THEN 'devuelto'
           WHEN p.fecha_limite < h.dia THEN 'en mora'
           ELSE 'activo' END;

\echo ==== E3a. columnas con el mismo nombre en usuario y lector
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'biblioteca' AND table_name = 'usuario'
INTERSECT
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'biblioteca' AND table_name = 'lector';

\echo ==== E3b. llaves foraneas del esquema
SELECT conrelid::regclass AS tabla, conname, pg_get_constraintdef(oid) AS definicion
FROM pg_constraint
WHERE contype = 'f' AND connamespace = 'biblioteca'::regnamespace
ORDER BY 1, 2;

\echo ==== E4a. restricciones de prestamo y rol
SELECT conrelid::regclass AS tabla, conname, contype,
       pg_get_constraintdef(oid) AS definicion
FROM pg_constraint
WHERE conrelid IN ('biblioteca.prestamo'::regclass, 'biblioteca.rol'::regclass)
ORDER BY 1, 3, 2;

\echo ==== E4b. ejemplares con mas de un prestamo abierto
SELECT isbn, id_ejemplar, count(*) AS abiertos
FROM prestamo WHERE fecha_devolucion IS NULL
GROUP BY isbn, id_ejemplar HAVING count(*) > 1;

\echo ==== E5a. DF candidata autor -> categoria (solo se puede refutar)
SELECT autor, count(DISTINCT categoria) AS categorias
FROM libro GROUP BY autor HAVING count(DISTINCT categoria) > 1;

\echo ==== E5b. valores de ejemplar.tipo
SELECT tipo, count(*) AS ejemplares FROM ejemplar GROUP BY tipo;

\echo ==== E5c. categorias repetidas como texto
SELECT categoria, count(*) AS libros FROM libro GROUP BY categoria ORDER BY 2 DESC;
