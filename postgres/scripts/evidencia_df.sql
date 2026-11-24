-- Evidencia de dependencias funcionales sobre el esquema NORMALIZADO.
-- Una DF solo se puede refutar con datos: 0 filas = no hay contraejemplo en la muestra;
-- la DF la garantiza la clave/UNIQUE, no la muestra.
SET search_path TO biblioteca;

\echo ==== F1. lector: correo -> documento (0 filas = sin contraejemplo)
SELECT correo, count(DISTINCT documento) AS documentos
FROM lector GROUP BY correo HAVING count(DISTINCT documento) > 1;

\echo ==== F2. ejemplar: (isbn, id_ejemplar) -> tipo (0 filas = sin contraejemplo)
SELECT isbn, id_ejemplar, count(DISTINCT tipo) AS tipos
FROM ejemplar GROUP BY isbn, id_ejemplar HAVING count(DISTINCT tipo) > 1;

\echo ==== F3. libro: titulo -> isbn (0 filas en la muestra, pero NO se asume: dos ediciones pueden compartir titulo)
SELECT titulo, count(DISTINCT isbn) AS isbns
FROM libro GROUP BY titulo HAVING count(DISTINCT isbn) > 1;

\echo ==== F4. prestamo: (isbn, id_ejemplar) -> documento se REFUTA: una copia pasa por varios lectores
SELECT isbn, id_ejemplar, count(DISTINCT documento) AS lectores
FROM prestamo GROUP BY isbn, id_ejemplar HAVING count(DISTINCT documento) > 1;

\echo ==== F5. prestamo: (isbn, id_ejemplar, fecha_prestamo) como clave alterna? (0 filas = unica en la muestra)
SELECT isbn, id_ejemplar, fecha_prestamo, count(*) FROM prestamo
GROUP BY isbn, id_ejemplar, fecha_prestamo HAVING count(*) > 1;

\echo ==== F6. libro: autor -> categoria (0 filas = sin contraejemplo; no se asume como DF)
SELECT autor, count(DISTINCT categoria) AS categorias
FROM libro GROUP BY autor HAVING count(DISTINCT categoria) > 1;
