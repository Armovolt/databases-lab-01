SELECT * FROM v_lab05_reader_activity WHERE reader_id BETWEEN 1 AND 5 ORDER BY reader_id;
SELECT * FROM v_lab05_pending_queue ORDER BY book_id, queue_position LIMIT 5;

UPDATE readers SET full_name = 'Тестовий читач для аудиту'
WHERE email = 'bench371@example.test';

SELECT table_name, operation, record_id, changed_by, changed_at,
       old_values->>'full_name' AS old_name, new_values->>'full_name' AS new_name
FROM audit_log ORDER BY audit_id DESC LIMIT 1;
