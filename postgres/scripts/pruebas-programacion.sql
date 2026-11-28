\set ON_ERROR_STOP on

SET search_path TO biblioteca;

-- Se desactiva el trigger solo durante la carga de los casos de prueba S16.
ALTER TABLE biblioteca.prestamo
DISABLE TRIGGER validar_prestamo_antes_insertar;

\i /scripts/Pruebas-Hito_2/datos-prueba.sql

-- El trigger vuelve a estar activo para todas las pruebas siguientes.
ALTER TABLE biblioteca.prestamo
ENABLE TRIGGER validar_prestamo_antes_insertar;

BEGIN;

-- Para probar el máximo de préstamos sin que la mora interfiera,
-- los tres préstamos abiertos del lector 1000000004 quedan dentro del plazo.
UPDATE biblioteca.prestamo
SET fecha_prestamo = CURRENT_DATE,
    fecha_limite = CURRENT_DATE + 14
WHERE documento = '1000000004'
  AND fecha_devolucion IS NULL;

-- Debe pasar: el lector 1000000006 toma el ejemplar disponible.
-- Resultado esperado: CALL y una fila con fecha límite de hoy + 14 días.
CALL biblioteca.registrar_prestamo(
    '1000000006',
    '9780000000004',
    1
);

SELECT documento, isbn, id_ejemplar, fecha_prestamo, fecha_limite
FROM biblioteca.prestamo
WHERE documento = '1000000006'
  AND isbn = '9780000000004'
  AND id_ejemplar = 1
  AND fecha_devolucion IS NULL;

-- Debe fallar: el ejemplar 1 del libro 9780000000001 está prestado.
-- Resultado esperado: error indicando que el ejemplar ya está prestado.
DO $$
BEGIN
    BEGIN
        CALL biblioteca.registrar_prestamo(
            '1000000006',
            '9780000000001',
            1
        );
        RAISE EXCEPTION 'PRUEBA FALLIDA: se prestó un ejemplar ocupado';
    EXCEPTION
        WHEN OTHERS THEN
            IF position('ya está prestado' IN SQLERRM) = 0 THEN
                RAISE;
            END IF;
            RAISE NOTICE 'Correcto: %', SQLERRM;
    END;
END;
$$;

-- Debe fallar: el lector 1000000003 tiene un préstamo vencido sin devolver.
-- La inserción directa comprueba que el trigger aplica la regla.
-- Resultado esperado: error indicando que el lector tiene préstamos vencidos.
DO $$
BEGIN
    BEGIN
        INSERT INTO biblioteca.prestamo
            (documento, isbn, id_ejemplar, fecha_prestamo, fecha_limite)
        VALUES
            ('1000000003', '9780000000004', 3, CURRENT_DATE, CURRENT_DATE + 14);

        RAISE EXCEPTION 'PRUEBA FALLIDA: se prestó a un lector en mora';
    EXCEPTION
        WHEN OTHERS THEN
            IF position('tiene préstamos vencidos sin devolver' IN SQLERRM) = 0 THEN
                RAISE;
            END IF;
            RAISE NOTICE 'Correcto: %', SQLERRM;
    END;
END;
$$;

-- Debe fallar: el lector 1000000004 ya tiene tres préstamos abiertos.
-- Resultado esperado: error indicando que alcanzó el máximo de 3.
DO $$
BEGIN
    BEGIN
        INSERT INTO biblioteca.prestamo
            (documento, isbn, id_ejemplar, fecha_prestamo, fecha_limite)
        VALUES
            ('1000000004', '9780000000004', 3, CURRENT_DATE, CURRENT_DATE + 14);

        RAISE EXCEPTION 'PRUEBA FALLIDA: se superó el máximo de préstamos';
    EXCEPTION
        WHEN OTHERS THEN
            IF position('ya tiene el máximo de 3 préstamos abiertos' IN SQLERRM) = 0 THEN
                RAISE;
            END IF;
            RAISE NOTICE 'Correcto: %', SQLERRM;
    END;
END;
$$;

-- Deshace el préstamo válido y el ajuste de fechas de esta batería.
ROLLBACK;