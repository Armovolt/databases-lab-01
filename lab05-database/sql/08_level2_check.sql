INSERT INTO readers (full_name, email) VALUES ('Перевірка RULE', 'rule.before@example.test');
SELECT reader_id, email, total_loans FROM v_lab05_reader_contacts WHERE email = 'rule.before@example.test';

UPDATE v_lab05_reader_contacts SET email = 'rule.after@example.test'
WHERE email = 'rule.before@example.test';

SELECT reader_id, email FROM readers WHERE email = 'rule.after@example.test';
DELETE FROM readers WHERE email = 'rule.after@example.test';

SELECT table_name, operation, changed_by, changed_at,
       old_values->>'email' AS old_email, new_values->>'email' AS new_email
FROM audit_log
WHERE record_id = (SELECT max(record_id) FROM audit_log)
ORDER BY audit_id;
