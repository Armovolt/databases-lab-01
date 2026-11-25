CREATE VIEW v_lab05_reader_contacts AS
SELECT r.reader_id, r.full_name, r.email, r.active, a.total_loans
FROM readers r
JOIN v_lab05_reader_activity a USING (reader_id);

CREATE RULE lab05_contact_update AS
ON UPDATE TO v_lab05_reader_contacts DO INSTEAD
    UPDATE readers SET email = NEW.email
    WHERE reader_id = OLD.reader_id;

CREATE FUNCTION lab05_validate_email() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.email IS NULL OR NEW.email !~ '^[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$' THEN
        RAISE EXCEPTION USING
            ERRCODE = '23514', MESSAGE = 'Некоректна адреса електронної пошти';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER lab05_reader_validate_email
BEFORE INSERT OR UPDATE OF email ON readers
FOR EACH ROW EXECUTE FUNCTION lab05_validate_email();

DROP TRIGGER lab05_reader_update ON readers;
DROP FUNCTION lab05_log_reader_update();

CREATE FUNCTION lab05_audit_reader() RETURNS trigger LANGUAGE plpgsql
SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    actor name := COALESCE(NULLIF(current_setting('role', true), 'none'), session_user::text);
BEGIN
    INSERT INTO public.audit_log (table_name, operation, record_id, changed_by, old_values, new_values)
    VALUES (TG_TABLE_NAME, TG_OP, COALESCE(NEW.reader_id, OLD.reader_id), actor,
            CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END,
            CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END);
    RETURN NULL;
END;
$$;

CREATE TRIGGER lab05_reader_audit
AFTER INSERT OR UPDATE OR DELETE ON readers
FOR EACH ROW EXECUTE FUNCTION lab05_audit_reader();

REVOKE EXECUTE ON FUNCTION lab05_audit_reader() FROM PUBLIC;
