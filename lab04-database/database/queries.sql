-- Рівень 1. Фільтрація за жанром і роком
SELECT title, published_year FROM books
WHERE genre = 'Проза' AND published_year >= 1900 ORDER BY published_year, title;

-- Рівень 1. Співавторство книги
SELECT b.title, a.full_name AS author
FROM books b JOIN book_authors ba USING (book_id) JOIN authors a USING (author_id)
WHERE b.book_id = 7 ORDER BY a.full_name;

-- Рівень 1. Кількість книг за жанрами
SELECT genre, count(*) AS titles FROM books GROUP BY genre ORDER BY titles DESC, genre;

-- Рівень 1. Видання, які ще не видавалися
SELECT b.title FROM books b
WHERE NOT EXISTS (
    SELECT 1 FROM copies c JOIN loans l USING (copy_id) WHERE c.book_id = b.book_id
)
ORDER BY b.title;

-- Рівень 1. Найближчі дати повернення
SELECT title, reader, due_on, overdue_days
FROM v_active_loans ORDER BY due_on, loan_id LIMIT 5;

-- Рівень 2. Фактичні видачі та прострочення за жанрами
SELECT b.genre, count(*) AS loans,
       count(*) FILTER (WHERE l.returned_on IS NULL AND l.due_on < CURRENT_DATE) AS overdue
FROM loans l JOIN copies c USING (copy_id) JOIN books b USING (book_id)
GROUP BY b.genre ORDER BY loans DESC, b.genre;

-- Рівень 2. Читачі з двома або більше видачами
SELECT r.full_name, count(*) AS total, count(*) FILTER (WHERE l.returned_on IS NULL) AS active
FROM readers r JOIN loans l USING (reader_id)
GROUP BY r.reader_id HAVING count(*) >= 2 ORDER BY total DESC, r.full_name;

-- Рівень 2. Місячна статистика видач
SELECT date_trunc('month', issued_on)::date AS month, count(*) AS issued,
       count(returned_on) AS returned,
       round(avg(returned_on-issued_on) FILTER (WHERE returned_on IS NOT NULL), 1) AS avg_days
FROM loans GROUP BY month ORDER BY month;
