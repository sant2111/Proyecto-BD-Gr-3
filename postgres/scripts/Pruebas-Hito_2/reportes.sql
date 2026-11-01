SET search_path TO biblioteca;
--Punto 1: 3 de libros más prestados

SELECT 
    l.isbn,
    l.titulo,
    COUNT(p.isbn) AS total_prestamos
FROM libro l
LEFT JOIN ejemplar e ON l.isbn = e.isbn
LEFT JOIN prestamo p ON e.isbn = p.isbn AND e.id_ejemplar = p.id_ejemplar
GROUP BY l.isbn, l.titulo
ORDER BY total_prestamos DESC
FETCH FIRST 3 ROWS WITH TIES;


    
--Punto 2 Lectores con más libros leídos 
WITH conteo_lecturas AS (
    SELECT 
        lec.documento,
        lec.nombres,
        COUNT(p.documento) AS total_leidos
    FROM lector lec
    INNER JOIN prestamo p ON lec.documento = p.documento
    WHERE p.fecha_devolucion IS NOT NULL 
    GROUP BY lec.documento, lec.nombres
)
SELECT 
    documento,
    nombres,
    total_leidos
FROM conteo_lecturas
WHERE total_leidos = (SELECT MAX(total_leidos) FROM conteo_lecturas);


SET search_path TO biblioteca;

-- REPORTE 3: LECTORES MOROSOS
-- Muestra cada lector una sola vez si tiene al menos
-- un préstamo vencido que todavía no ha sido devuelto.

SELECT
    l.documento,
    l.nombres,
    l.apellidos,
    l.correo,
    l.telefono
FROM lector l
WHERE EXISTS (
    SELECT 1
    FROM prestamo p
    WHERE p.documento = l.documento
      AND p.fecha_devolucion IS NULL
      AND p.fecha_limite < CURRENT_DATE
)
ORDER BY l.apellidos, l.nombres;



SET search_path TO biblioteca;

-- REPORTE 4: LISTA DE NOTIFICACIÓN DE PRÉSTAMOS EN MORA
-- Muestra cada préstamo vencido y no devuelto.
-- Incluye los datos de contacto del lector y el libro.
-- Calcula los días de atraso.

SELECT
    l.nombres,
    l.apellidos,
    l.correo,
    l.telefono,
    li.titulo,
    p.fecha_limite,
    (CURRENT_DATE - p.fecha_limite) AS dias_mora
FROM prestamo p
INNER JOIN lector l
    ON p.documento = l.documento
INNER JOIN ejemplar e
    ON p.id_ejemplar = e.id_ejemplar
   AND p.isbn = e.isbn
INNER JOIN libro li
    ON e.isbn = li.isbn
WHERE p.fecha_devolucion IS NULL
  AND p.fecha_limite < CURRENT_DATE
ORDER BY dias_mora DESC;


