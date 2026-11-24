\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path TO biblioteca;
LOCK TABLE libro, ejemplar, prestamo, lector, usuario, rol IN ACCESS EXCLUSIVE MODE;
CREATE TEMP TABLE antes_libro ON COMMIT DROP AS SELECT * FROM libro;
CREATE TEMP TABLE antes_ejemplar ON COMMIT DROP AS SELECT * FROM ejemplar;
CREATE TEMP TABLE antes_prestamo ON COMMIT DROP AS SELECT * FROM prestamo;
\echo ==== ANTES
SELECT (SELECT count(*) FROM libro) libros,(SELECT count(*) FROM lector) lectores,(SELECT count(*) FROM ejemplar) ejemplares,(SELECT count(*) FROM prestamo) prestamos,(SELECT sum(ejemplares_disponibles) FROM libro) stock;
-- Supuesto de migracion: el stock semilla representa el total de copias.
DO $$ BEGIN
IF EXISTS (SELECT 1 FROM libro l WHERE (SELECT count(*) FROM ejemplar e WHERE e.isbn=l.isbn)>l.ejemplares_disponibles) THEN RAISE EXCEPTION 'Stock inferior al inventario existente'; END IF;
END $$;
INSERT INTO ejemplar(isbn,id_ejemplar,tipo)
SELECT l.isbn,g.n,'Físico' FROM libro l
CROSS JOIN LATERAL (SELECT count(*) AS cantidad,coalesce(max(id_ejemplar),0) AS maximo FROM ejemplar e WHERE e.isbn=l.isbn) x
CROSS JOIN LATERAL generate_series(x.maximo+1,x.maximo+(l.ejemplares_disponibles-x.cantidad)::integer) g(n);
CREATE UNIQUE INDEX prestamo_abierto_uk ON prestamo(isbn,id_ejemplar) WHERE fecha_devolucion IS NULL;
ALTER TABLE rol ADD CONSTRAINT rol_tipo_rol_uk UNIQUE(tipo_rol);
ALTER TABLE prestamo ADD CONSTRAINT prestamo_fechas_ck CHECK(fecha_limite>=fecha_prestamo AND (fecha_devolucion IS NULL OR fecha_devolucion>=fecha_prestamo));
\echo ==== VERIFICACION ANTES DE ELIMINAR COLUMNAS
SELECT count(*) AS ejemplares_originales_perdidos FROM (SELECT * FROM antes_ejemplar EXCEPT SELECT * FROM ejemplar) q;
SELECT count(*) AS prestamos_modificados FROM (SELECT * FROM antes_prestamo EXCEPT SELECT * FROM prestamo) q;
SELECT count(*) AS libros_modificados FROM (SELECT * FROM antes_libro EXCEPT SELECT * FROM libro) q;
SELECT count(*) AS stock_no_reconciliado FROM antes_libro l WHERE l.ejemplares_disponibles<>(SELECT count(*) FROM ejemplar e WHERE e.isbn=l.isbn);
DO $$ BEGIN
IF EXISTS (SELECT * FROM antes_ejemplar EXCEPT SELECT * FROM ejemplar) OR EXISTS (SELECT * FROM antes_prestamo EXCEPT SELECT * FROM prestamo) OR EXISTS (SELECT * FROM antes_libro EXCEPT SELECT * FROM libro) OR EXISTS (SELECT 1 FROM antes_libro l WHERE l.ejemplares_disponibles<>(SELECT count(*) FROM ejemplar e WHERE e.isbn=l.isbn)) THEN RAISE EXCEPTION 'Verificacion fallida'; END IF;
END $$;
ALTER TABLE libro DROP COLUMN ejemplares_disponibles;
ALTER TABLE prestamo DROP COLUMN estado;
CREATE VIEW libro_disponibilidad AS SELECT l.isbn,l.titulo,l.autor,l.categoria,count(e.id_ejemplar)::integer AS ejemplares,count(p.id_prestamo)::integer AS prestados,(count(e.id_ejemplar)-count(p.id_prestamo))::integer AS disponibles FROM libro l LEFT JOIN ejemplar e ON e.isbn=l.isbn LEFT JOIN prestamo p ON p.isbn=e.isbn AND p.id_ejemplar=e.id_ejemplar AND p.fecha_devolucion IS NULL GROUP BY l.isbn;
CREATE VIEW prestamo_con_estado AS SELECT p.*,CASE WHEN fecha_devolucion IS NOT NULL THEN 'devuelto' WHEN fecha_limite<CURRENT_DATE THEN 'en mora' ELSE 'activo' END AS estado FROM prestamo p;
\echo ==== DESPUES
SELECT (SELECT count(*) FROM libro) libros,(SELECT count(*) FROM lector) lectores,(SELECT count(*) FROM ejemplar) ejemplares,(SELECT count(*) FROM prestamo) prestamos;
SELECT sum(ejemplares) ejemplares,sum(prestados) prestados,sum(disponibles) disponibles,count(*) FILTER(WHERE disponibles<0) negativos FROM libro_disponibilidad;
SELECT estado,count(*) FROM prestamo_con_estado GROUP BY estado ORDER BY estado;
COMMIT;
