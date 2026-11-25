-- Окрема база для вимірювань, початкові записи бібліотеки збережено.
INSERT INTO readers (full_name, email)
SELECT 'Тестовий читач ' || n, 'bench' || n || '@example.test'
FROM generate_series(1, 40000) AS g(n);

INSERT INTO copies (book_id, inventory_code)
SELECT 1 + ((n - 1) % 12), 'LAB05-' || n
FROM generate_series(1, 10000) AS g(n);

INSERT INTO loans (copy_id, reader_id, issued_on, due_on, returned_on)
SELECT c.copy_id, r.reader_id, dates.issued,
       dates.issued + 21, dates.issued + (n % 31)
FROM generate_series(1, 200000) AS g(n)
JOIN copies c ON c.inventory_code = 'LAB05-' || (1 + ((n - 1) % 10000))
JOIN readers r ON r.email = 'bench' || (1 + ((n::bigint * 397) % 40000)) || '@example.test'
CROSS JOIN LATERAL (SELECT DATE '2024-01-01' + (n % 730) AS issued) dates;

INSERT INTO loans (copy_id, reader_id, issued_on, due_on)
SELECT c.copy_id, r.reader_id, CURRENT_DATE - 320 + (n % 300),
       CURRENT_DATE - 299 + (n % 300)
FROM generate_series(1, 2400) AS g(n)
JOIN copies c ON c.inventory_code = 'LAB05-' || n
JOIN readers r ON r.email = 'bench' || n || '@example.test';

INSERT INTO reservations (book_id, reader_id, requested_at, expires_on, status)
SELECT 1 + ((n - 1) % 12), r.reader_id,
       CURRENT_DATE - 320 + (n % 300) + TIME '12:00',
       CURRENT_DATE - 290 + (n % 300),
       CASE WHEN n <= 2000 THEN 'pending' ELSE 'fulfilled' END
FROM generate_series(1, 50000) AS g(n)
JOIN readers r ON r.email = 'bench' || (1 + ((n - 1) % 40000)) || '@example.test';

ANALYZE;
SELECT 'loans' AS table_name, count(*) FROM loans
UNION ALL SELECT 'reservations', count(*) FROM reservations
UNION ALL SELECT 'readers', count(*) FROM readers
UNION ALL SELECT 'copies', count(*) FROM copies;
