SELECT current_database() AS restored_database,
       (SELECT count(*) FROM books) AS books,
       (SELECT count(*) FROM loans) AS loans,
       (SELECT count(*) FROM reservations) AS reservations,
       (SELECT count(*) FROM audit_log) AS audit_entries,
       (SELECT sum(loan_count) FROM mv_lab05_daily_loans) AS loans_in_summary,
       (SELECT count(*) FROM maintenance_log) AS maintenance_entries;

DO $$
BEGIN
    IF (SELECT sum(loan_count) FROM mv_lab05_daily_loans) IS DISTINCT FROM
       (SELECT count(*)::numeric FROM loans)
       OR NOT EXISTS (SELECT FROM maintenance_log)
       OR NOT has_table_privilege('lab05_viewer', 'public.books', 'SELECT')
       OR has_table_privilege('lab05_viewer', 'public.readers', 'UPDATE') THEN
        RAISE EXCEPTION 'Перевірка відновленої бази не пройшла';
    END IF;
END;
$$;
