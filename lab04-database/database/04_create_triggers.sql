CREATE OR REPLACE FUNCTION validate_loan() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.returned_on IS NOT NULL THEN
        RETURN NEW;
    END IF;

    -- Блокування примірника узгоджує видачу зі списанням.
    PERFORM 1 FROM copies WHERE copy_id = NEW.copy_id AND NOT retired FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Примірник не знайдено або списано';
    END IF;

    -- Блокування читача зберігає ліміт видач під час паралельної роботи.
    PERFORM 1 FROM readers WHERE reader_id = NEW.reader_id AND active FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Читача не знайдено або його обліковий запис неактивний';
    END IF;

    IF (SELECT count(*) FROM loans
        WHERE reader_id = NEW.reader_id AND returned_on IS NULL
          AND loan_id IS DISTINCT FROM NEW.loan_id) >= 5 THEN
        RAISE EXCEPTION 'Перевищено ліміт активних видач';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER loans_validate_active
BEFORE INSERT OR UPDATE OF copy_id, reader_id, returned_on ON loans
FOR EACH ROW EXECUTE FUNCTION validate_loan();

CREATE OR REPLACE FUNCTION guard_copy_retirement() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.retired AND NOT OLD.retired AND EXISTS (
        SELECT 1 FROM loans WHERE copy_id = NEW.copy_id AND returned_on IS NULL
    ) THEN
        RAISE EXCEPTION 'Не можна списати примірник з активною видачею';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER copies_guard_retirement
BEFORE UPDATE OF retired ON copies
FOR EACH ROW EXECUTE FUNCTION guard_copy_retirement();
