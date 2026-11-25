CREATE TABLE audit_log (
    audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name text NOT NULL,
    operation text NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    actor text NOT NULL,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    old_data jsonb,
    new_data jsonb
);

CREATE INDEX audit_by_table_time_idx ON audit_log (table_name, changed_at DESC);

CREATE OR REPLACE FUNCTION log_data_change() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_old jsonb;
    v_new jsonb;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        v_old := to_jsonb(OLD) - 'password_hash';
    END IF;
    IF TG_OP <> 'DELETE' THEN
        v_new := to_jsonb(NEW) - 'password_hash';
    END IF;
    INSERT INTO audit_log (table_name, operation, actor, old_data, new_data)
    VALUES (TG_TABLE_NAME, TG_OP, COALESCE(NULLIF(current_setting('library.actor', true), ''), current_user),
            v_old, v_new);
    RETURN NULL;
END;
$$;

DO $$
DECLARE
    v_table text;
BEGIN
    FOREACH v_table IN ARRAY ARRAY['authors', 'books', 'book_authors', 'copies',
                                  'readers', 'loans', 'reservations', 'app_users']
    LOOP
        EXECUTE format('CREATE TRIGGER audit_change AFTER INSERT OR UPDATE OR DELETE ON %I
                        FOR EACH ROW EXECUTE FUNCTION log_data_change()', v_table);
    END LOOP;
END;
$$;
