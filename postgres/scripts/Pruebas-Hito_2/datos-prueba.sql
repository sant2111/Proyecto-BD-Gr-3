SET search_path TO biblioteca;

TRUNCATE TABLE prestamo, ejemplar CASCADE;

INSERT INTO ejemplar (isbn, id_ejemplar, tipo) VALUES
    ('9780000000001', 1, 'Físico'),
    ('9780000000001', 2, 'Físico'),
    ('9780000000001', 3, 'Físico'),
    ('9780000000003', 1, 'Físico'),
    ('9780000000004', 1, 'Físico'),
    ('9780000000004', 2, 'Físico'),
    ('9780000000004', 3, 'Físico'),
    ('9780000000005', 1, 'Físico'),
    ('9780000000005', 2, 'Físico'),
    ('9780000000007', 1, 'Físico'),
    ('9780000000007', 2, 'Físico'),
    ('9780000000009', 1, 'Físico'),
    ('9780000000010', 1, 'Físico'),
    ('9780000000011', 1, 'Físico');

INSERT INTO prestamo (documento, isbn, id_ejemplar, fecha_prestamo, fecha_limite, fecha_devolucion, estado)
SELECT 
    v.documento,
    v.isbn,
    v.id_ejemplar,
    CURRENT_DATE - v.prestado                   AS fecha_prestamo,
    CURRENT_DATE - v.prestado + 14              AS fecha_limite,
    CASE 
        WHEN v.devuelto IS NOT NULL THEN CURRENT_DATE - v.devuelto 
        ELSE NULL 
    END                                         AS fecha_devolucion,
    CASE 
        WHEN v.devuelto IS NOT NULL THEN 'devuelto'
        WHEN (CURRENT_DATE - v.prestado + 14) < CURRENT_DATE THEN 'en mora'
        ELSE 'activo'
    END                                         AS estado
FROM (VALUES

    ('1000000001', '9780000000001', 1, 120, 110),
    ('1000000001', '9780000000004', 1, 100,  90),
    ('1000000001', '9780000000007', 1,  80,  70),

    ('1000000002', '9780000000001', 2,  95,  85),
    ('1000000002', '9780000000005', 1,  75,  65),
    ('1000000002', '9780000000009', 1,  60,  40),

    ('1000000003', '9780000000001', 3,  70,  60),
    ('1000000003', '9780000000010', 1,  30, NULL),
    ('1000000003', '9780000000003', 1,   5, NULL),

    ('1000000004', '9780000000001', 1,  20, NULL),
    ('1000000004', '9780000000007', 2,  40, NULL),
    ('1000000004', '9780000000004', 2,  14, NULL),

    ('1000000005', '9780000000004', 3,  50,  45),
    ('1000000005', '9780000000011', 1,  35,  30),
    ('1000000005', '9780000000005', 2,  16, NULL)

) AS v (documento, isbn, id_ejemplar, prestado, devuelto);
