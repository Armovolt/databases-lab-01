CREATE VIEW v_lab05_reader_activity AS
SELECT r.reader_id, r.full_name, count(l.loan_id) AS total_loans,
       count(l.loan_id) FILTER (WHERE l.returned_on IS NULL) AS open_loans,
       max(l.issued_on) AS last_loan
FROM readers r LEFT JOIN loans l USING (reader_id)
GROUP BY r.reader_id, r.full_name;

CREATE VIEW v_lab05_pending_queue AS
SELECT b.book_id, b.title, rs.reservation_id, rs.expires_on,
       row_number() OVER (
           PARTITION BY b.book_id ORDER BY rs.requested_at, rs.reservation_id
       ) AS queue_position
FROM books b JOIN reservations rs USING (book_id)
WHERE rs.status = 'pending'
  AND rs.expires_on >= (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::date;

CREATE TABLE audit_log (
    audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name text NOT NULL,
    operation text NOT NULL,
    record_id integer NOT NULL,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    changed_by name NOT NULL,
    old_values jsonb,
    new_values jsonb
);

CREATE FUNCTION lab05_log_reader_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, changed_by, old_values, new_values)
    VALUES (TG_TABLE_NAME, TG_OP, NEW.reader_id, current_user, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
END;
$$;

CREATE TRIGGER lab05_reader_update
AFTER UPDATE ON readers
FOR EACH ROW EXECUTE FUNCTION lab05_log_reader_update();

CREATE ROLE lab05_viewer LOGIN;
REVOKE CONNECT ON DATABASE library_lab05 FROM PUBLIC;
GRANT CONNECT ON DATABASE library_lab05 TO lab05_viewer;
GRANT USAGE ON SCHEMA public TO lab05_viewer;
GRANT SELECT ON books, authors, v_lab05_pending_queue, v_catalog TO lab05_viewer;
