\echo Q1. Історія видач читача
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.issued_on, l.returned_on, b.title, c.inventory_code
FROM readers r
JOIN loans l USING (reader_id)
JOIN copies c USING (copy_id)
JOIN books b USING (book_id)
WHERE r.email = 'bench371@example.test'
  AND l.issued_on >= DATE '2024-06-01'
ORDER BY l.issued_on DESC;

\echo Q2. Видачі за тиждень за жанрами
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.genre, count(*) AS loan_count,
       count(*) FILTER (WHERE l.returned_on > l.due_on) AS returned_late
FROM loans l
JOIN copies c USING (copy_id)
JOIN books b USING (book_id)
WHERE l.issued_on >= DATE '2025-12-20' AND l.issued_on < DATE '2025-12-27'
GROUP BY b.genre ORDER BY loan_count DESC, b.genre;

\echo Q3. Історія бронювань читача
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.title, rs.status, rs.requested_at
FROM readers r
JOIN reservations rs USING (reader_id)
JOIN books b USING (book_id)
WHERE r.email = 'bench371@example.test'
ORDER BY rs.requested_at DESC;
