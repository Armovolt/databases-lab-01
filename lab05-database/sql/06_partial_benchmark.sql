\echo P1. Активні видачі зі строком повернення сьогодні
EXPLAIN (ANALYZE, BUFFERS)
SELECT loan_id, reader_id, due_on
FROM loans WHERE returned_on IS NULL AND due_on = CURRENT_DATE
ORDER BY due_on, loan_id;

\echo P2. Незавершені бронювання зі строком завершення сьогодні
EXPLAIN (ANALYZE, BUFFERS)
SELECT reservation_id, book_id, expires_on
FROM reservations WHERE status = 'pending' AND expires_on = CURRENT_DATE
ORDER BY expires_on, reservation_id;
