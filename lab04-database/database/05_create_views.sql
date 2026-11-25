CREATE OR REPLACE VIEW v_catalog AS
SELECT b.book_id, b.isbn, b.title, b.genre, b.published_year,
       COALESCE(a.authors, '—') AS authors,
       COALESCE(c.total_copies, 0) AS total_copies,
       COALESCE(c.available_copies, 0) AS available_copies
FROM books b
LEFT JOIN LATERAL (
    SELECT string_agg(a.full_name, ', ' ORDER BY a.full_name) AS authors
    FROM book_authors ba JOIN authors a USING (author_id)
    WHERE ba.book_id = b.book_id
) a ON true
LEFT JOIN LATERAL (
    SELECT count(*) FILTER (WHERE NOT c.retired) AS total_copies,
           count(*) FILTER (WHERE NOT c.retired AND NOT EXISTS (
               SELECT 1 FROM loans l
               WHERE l.copy_id = c.copy_id AND l.returned_on IS NULL
           )) AS available_copies
    FROM copies c WHERE c.book_id = b.book_id
) c ON true;

CREATE OR REPLACE VIEW v_active_loans AS
SELECT l.loan_id, c.inventory_code, b.title, r.full_name AS reader,
       l.issued_on, l.due_on, GREATEST(CURRENT_DATE-l.due_on, 0) AS overdue_days
FROM loans l
JOIN copies c USING (copy_id)
JOIN books b USING (book_id)
JOIN readers r USING (reader_id)
WHERE l.returned_on IS NULL;
