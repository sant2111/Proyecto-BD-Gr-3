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