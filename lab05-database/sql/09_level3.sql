CREATE MATERIALIZED VIEW mv_lab05_daily_loans AS
SELECT issued_on, count(*) AS loan_count,
       count(*) FILTER (WHERE returned_on IS NOT NULL) AS returned_count
FROM loans
GROUP BY issued_on;

CREATE UNIQUE INDEX lab05_daily_loans_day_idx ON mv_lab05_daily_loans (issued_on);

CREATE FUNCTION lab05_refresh_daily_loans() RETURNS trigger LANGUAGE plpgsql
SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_lab05_daily_loans;
    RETURN NULL;
END;
$$;

CREATE TRIGGER lab05_refresh_after_loan
AFTER INSERT OR UPDATE OR DELETE OR TRUNCATE ON loans
FOR EACH STATEMENT EXECUTE FUNCTION lab05_refresh_daily_loans();

CREATE TABLE reservation_notices (
    notice_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reservation_id integer NOT NULL REFERENCES reservations ON DELETE CASCADE,
    message text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE FUNCTION lab05_cancel_reader_reservations() RETURNS trigger LANGUAGE plpgsql
SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $$
BEGIN
    UPDATE public.reservations SET status = 'cancelled'
    WHERE reader_id = NEW.reader_id AND status = 'pending';
    RETURN NULL;
END;
$$;

CREATE TRIGGER lab05_reader_deactivated
AFTER UPDATE OF active ON readers FOR EACH ROW
WHEN (OLD.active AND NOT NEW.active)
EXECUTE FUNCTION lab05_cancel_reader_reservations();

CREATE FUNCTION lab05_log_reservation_cancellation() RETURNS trigger LANGUAGE plpgsql
SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $$
BEGIN
    INSERT INTO public.reservation_notices (reservation_id, message)
    VALUES (NEW.reservation_id, 'Бронювання скасовано');
    RETURN NULL;
END;
$$;

CREATE TRIGGER lab05_reservation_cancelled
AFTER UPDATE OF status ON reservations FOR EACH ROW
WHEN (OLD.status = 'pending' AND NEW.status = 'cancelled')
EXECUTE FUNCTION lab05_log_reservation_cancellation();

REVOKE EXECUTE ON FUNCTION lab05_refresh_daily_loans(), lab05_cancel_reader_reservations(),
    lab05_log_reservation_cancellation() FROM PUBLIC;

CREATE ROLE lab05_user NOLOGIN;
CREATE ROLE lab05_moderator NOLOGIN;
CREATE ROLE lab05_admin NOLOGIN;
GRANT lab05_user TO lab05_viewer, lab05_moderator;
GRANT lab05_moderator TO lab05_admin;
GRANT CONNECT ON DATABASE library_lab05 TO lab05_user;
GRANT USAGE ON SCHEMA public TO lab05_user;
GRANT SELECT ON books, authors, v_lab05_pending_queue, v_catalog, mv_lab05_daily_loans TO lab05_user;
GRANT SELECT ON readers, reservations, v_lab05_reader_activity, v_lab05_reader_contacts TO lab05_moderator;
GRANT UPDATE (email, active) ON readers TO lab05_moderator;
GRANT UPDATE (email) ON v_lab05_reader_contacts TO lab05_moderator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lab05_admin;
GRANT INSERT, UPDATE, DELETE ON books, authors, book_authors, copies, readers, loans, reservations TO lab05_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lab05_admin;

-- Процедури з №4 залишаються доступними лише власнику й адміністратору.
REVOKE EXECUTE ON PROCEDURE issue_copy(integer, integer, integer),
    reserve_book(integer, integer, integer), return_loan(integer) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE issue_copy(integer, integer, integer),
    reserve_book(integer, integer, integer), return_loan(integer) TO lab05_admin;

CREATE TABLE maintenance_log (
    run_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name text NOT NULL,
    operation text NOT NULL,
    executed_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
GRANT SELECT ON maintenance_log TO lab05_admin;

CREATE PROCEDURE lab05_maintain_database()
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    target text;
BEGIN
    FOREACH target IN ARRAY ARRAY['loans', 'reservations'] LOOP
        EXECUTE format('ANALYZE public.%I', target);
        EXECUTE format('REINDEX TABLE public.%I', target);
        INSERT INTO public.maintenance_log (table_name, operation)
        VALUES (target, 'ANALYZE + REINDEX');
    END LOOP;
END;
$$;

REVOKE EXECUTE ON PROCEDURE lab05_maintain_database() FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE lab05_maintain_database() TO lab05_admin;
