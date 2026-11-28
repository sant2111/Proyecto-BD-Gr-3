-- Regla: registrar un préstamo solo para un lector y ejemplar existentes,
-- y si ese ejemplar no tiene otro préstamo abierto.
-- Se usa un procedimiento para reunir el registro y sus validaciones en
-- una operación que la API podrá llamar con CALL.
CREATE OR REPLACE PROCEDURE biblioteca.registrar_prestamo(
    IN p_documento varchar(15),
    IN p_isbn varchar(13),
    IN p_id_ejemplar integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM biblioteca.lector
        WHERE documento = p_documento
    ) THEN
        RAISE EXCEPTION 'No existe el lector con documento %', p_documento;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM biblioteca.ejemplar
        WHERE isbn = p_isbn
          AND id_ejemplar = p_id_ejemplar
    ) THEN
        RAISE EXCEPTION 'No existe el ejemplar % del libro %',
            p_id_ejemplar, p_isbn;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM biblioteca.prestamo
        WHERE isbn = p_isbn
          AND id_ejemplar = p_id_ejemplar
          AND fecha_devolucion IS NULL
    ) THEN
        RAISE EXCEPTION 'El ejemplar % del libro % ya está prestado',
            p_id_ejemplar, p_isbn;
    END IF;

    INSERT INTO biblioteca.prestamo (
        documento,
        isbn,
        id_ejemplar,
        fecha_prestamo,
        fecha_limite
    )
    VALUES (
        p_documento,
        p_isbn,
        p_id_ejemplar,
        CURRENT_DATE,
        CURRENT_DATE + 14
    );
END;
$$;

-- Regla: un lector con algún préstamo vencido sin devolver,
-- o con tres préstamos abiertos, no puede recibir otro préstamo.
-- Se usa un trigger BEFORE INSERT para aplicar la regla aunque el préstamo
-- se intente registrar sin llamar al procedimiento.
CREATE OR REPLACE FUNCTION biblioteca.validar_prestamo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_prestamos_abiertos integer;
BEGIN
    -- Bloquea al lector durante esta validación para evitar que dos
    -- préstamos simultáneos superen el máximo.
    PERFORM 1
    FROM biblioteca.lector
    WHERE documento = NEW.documento
    FOR UPDATE;

    IF EXISTS (
        SELECT 1
        FROM biblioteca.prestamo
        WHERE documento = NEW.documento
          AND fecha_devolucion IS NULL
          AND fecha_limite < CURRENT_DATE
    ) THEN
        RAISE EXCEPTION
            'El lector % tiene préstamos vencidos sin devolver',
            NEW.documento;
    END IF;

    SELECT count(*)
    INTO v_prestamos_abiertos
    FROM biblioteca.prestamo
    WHERE documento = NEW.documento
      AND fecha_devolucion IS NULL;

    IF v_prestamos_abiertos >= 3 THEN
        RAISE EXCEPTION
            'El lector % ya tiene el máximo de 3 préstamos abiertos',
            NEW.documento;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validar_prestamo_antes_insertar
ON biblioteca.prestamo;

CREATE TRIGGER validar_prestamo_antes_insertar
BEFORE INSERT ON biblioteca.prestamo
FOR EACH ROW
EXECUTE FUNCTION biblioteca.validar_prestamo();