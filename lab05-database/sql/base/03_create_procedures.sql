-- Блокування книги серіалізує видачу й бронювання одного видання.
CREATE OR REPLACE PROCEDURE issue_copy(p_copy_id integer, p_reader_id integer, p_days integer)
LANGUAGE plpgsql AS $$
DECLARE
    v_book_id integer;
    v_reservation reservations%ROWTYPE;
BEGIN
    IF p_days IS NULL OR p_days NOT BETWEEN 1 AND 60 THEN
        RAISE EXCEPTION 'Строк видачі має бути від 1 до 60 днів';
    END IF;

    SELECT b.book_id INTO v_book_id
    FROM books b JOIN copies c USING (book_id)
    WHERE c.copy_id = p_copy_id
    FOR UPDATE OF b;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Примірник не знайдено';
    END IF;

    SELECT * INTO v_reservation
    FROM reservations
    WHERE book_id = v_book_id AND status = 'pending'
      AND expires_on >= (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::date
    ORDER BY requested_at, reservation_id
    LIMIT 1 FOR UPDATE;

    IF FOUND AND v_reservation.reader_id <> p_reader_id THEN
        RAISE EXCEPTION 'Книга заброньована іншим читачем';
    END IF;

    INSERT INTO loans (copy_id, reader_id, due_on)
    VALUES (p_copy_id, p_reader_id, CURRENT_DATE + p_days);

    IF v_reservation.reservation_id IS NOT NULL THEN
        UPDATE reservations SET status = 'fulfilled'
        WHERE reservation_id = v_reservation.reservation_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE return_loan(p_loan_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE loans SET returned_on = CURRENT_DATE
    WHERE loan_id = p_loan_id AND returned_on IS NULL;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Активну видачу не знайдено';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE reserve_book(p_book_id integer, p_reader_id integer, p_days integer)
LANGUAGE plpgsql AS $$
DECLARE
    v_today date := (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::date;
BEGIN
    IF p_days IS NULL OR p_days NOT BETWEEN 1 AND 30 THEN
        RAISE EXCEPTION 'Строк бронювання має бути від 1 до 30 днів';
    END IF;
    PERFORM 1 FROM books WHERE book_id = p_book_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Книгу не знайдено';
    END IF;
    PERFORM 1 FROM readers WHERE reader_id = p_reader_id AND active FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Читача не знайдено або його обліковий запис неактивний';
    END IF;

    UPDATE reservations SET status = 'expired'
    WHERE book_id = p_book_id AND reader_id = p_reader_id AND status = 'pending'
      AND expires_on < v_today;

    INSERT INTO reservations (book_id, reader_id, expires_on)
    VALUES (p_book_id, p_reader_id, v_today + p_days);
END;
$$;
