\echo Кількість повернених видач за сьогодні до і після тестової вставки
BEGIN;
SELECT COALESCE((SELECT returned_count FROM mv_lab05_daily_loans WHERE issued_on = CURRENT_DATE), 0) AS before_insert;
INSERT INTO loans (copy_id, reader_id, issued_on, due_on, returned_on)
SELECT c.copy_id, r.reader_id, CURRENT_DATE, CURRENT_DATE + 21, CURRENT_DATE
FROM copies c CROSS JOIN readers r
WHERE c.inventory_code = 'LAB05-9999' AND r.email = 'bench371@example.test';
SELECT returned_count AS after_insert FROM mv_lab05_daily_loans WHERE issued_on = CURRENT_DATE;
ROLLBACK;

\echo Оновлення контактів модератором через RULE
BEGIN;
SET LOCAL ROLE lab05_moderator;
UPDATE v_lab05_reader_contacts SET email = 'bench371.changed@example.test'
WHERE email = 'bench371@example.test';
SELECT reader_id, email FROM readers WHERE email = 'bench371.changed@example.test';
ROLLBACK;

\echo Каскад: читач -> бронювання -> журнал сповіщень
BEGIN;
SELECT r.active, rs.status AS before_update
FROM readers r JOIN reservations rs USING (reader_id)
WHERE r.email = 'bench371@example.test' AND rs.status = 'pending';

SET LOCAL ROLE lab05_moderator;
UPDATE readers SET active = false WHERE email = 'bench371@example.test';
RESET ROLE;

SELECT r.active, rs.status AS after_update, n.message, a.changed_by
FROM readers r
JOIN reservations rs USING (reader_id)
JOIN reservation_notices n USING (reservation_id)
JOIN audit_log a ON a.record_id = r.reader_id AND a.table_name = 'readers'
WHERE r.email = 'bench371@example.test'
  AND a.old_values->>'active' = 'true' AND a.new_values->>'active' = 'false';
ROLLBACK;

\echo Матриця дозволів
SELECT roles.role_name,
       has_table_privilege(roles.role_name, 'books', 'SELECT') AS read_catalog,
       has_column_privilege(roles.role_name, 'readers', 'email', 'UPDATE') AS edit_email,
       has_table_privilege(roles.role_name, 'books', 'DELETE') AS delete_books,
       has_table_privilege(roles.role_name, 'audit_log', 'SELECT') AS read_audit,
       has_function_privilege(roles.role_name, 'lab05_maintain_database()', 'EXECUTE') AS run_maintenance
FROM (VALUES (1, 'lab05_user'), (2, 'lab05_moderator'), (3, 'lab05_admin')) roles(n, role_name)
ORDER BY roles.n;

\echo Обслуговування від імені адміністратора
SET ROLE lab05_admin;
CALL lab05_maintain_database();
SELECT table_name, operation, executed_at FROM maintenance_log ORDER BY run_id;
RESET ROLE;
