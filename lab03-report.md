# Звіт з лабораторної роботи 3. Модифікація даних та транзакції

**Виконав:** Дмитерчук Віталій Вадимович               
**Група:** ІПЗ-33                            
**Варіант:** Система управління бібліотекою                             
**Рівень складності:** 3 (виконано завдання рівнів 1, 2 і 3)                          

## Мета роботи

Навчитися додавати, оновлювати та видаляти дані, використовувати транзакції, обмеження цілісності, аудит і відновлення.

## Виконання роботи

Для роботи використовую Supabase (PostgreSQL). Таблиці бібліотеки розміщені в окремій схемі `library_lab3`.

### Рівень 1. Базові операції модифікації

#### Крок 1. Створення структури бази даних

Для бібліотеки потрібні чотири таблиці: автори, книги, читачі та видачі. Обмеження перевіряють унікальність записів, кількість примірників, дати та зв’язки між таблицями.

```sql
-- Створення окремого простору імен та всіх основних таблиць.
BEGIN;
CREATE SCHEMA library_lab3;
REVOKE ALL ON SCHEMA library_lab3 FROM PUBLIC;
CREATE TABLE library_lab3.authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL CHECK (btrim(first_name) <> ''),
    last_name VARCHAR(50) NOT NULL CHECK (btrim(last_name) <> ''),
    birth_year INTEGER CHECK (birth_year BETWEEN 1000 AND EXTRACT(YEAR FROM CURRENT_DATE)),
    country VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE library_lab3.books (
    book_id SERIAL PRIMARY KEY,
    isbn VARCHAR(17) UNIQUE NOT NULL CHECK (btrim(isbn) <> ''),
    title VARCHAR(200) NOT NULL CHECK (btrim(title) <> ''),
    author_id INTEGER NOT NULL REFERENCES library_lab3.authors(author_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    publication_year INTEGER CHECK (publication_year BETWEEN 1450 AND EXTRACT(YEAR FROM CURRENT_DATE)),
    genre VARCHAR(50),
    total_copies INTEGER NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INTEGER NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CHECK (available_copies <= total_copies)
);
CREATE TABLE library_lab3.readers (
    reader_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    library_card_number VARCHAR(20) UNIQUE NOT NULL,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (status IN ('Active', 'Blocked', 'Inactive'))
);
CREATE TABLE library_lab3.lendings (
    lending_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES library_lab3.books(book_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    reader_id INTEGER NOT NULL REFERENCES library_lab3.readers(reader_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    lending_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    CHECK (due_date > lending_date),
    CHECK (return_date IS NULL OR return_date >= lending_date)
);
CREATE INDEX idx_books_author ON library_lab3.books(author_id);
CREATE INDEX idx_lendings_book ON library_lab3.lendings(book_id);
CREATE INDEX idx_lendings_reader ON library_lab3.lendings(reader_id);
CREATE UNIQUE INDEX uq_active_lending
    ON library_lab3.lendings(book_id, reader_id) WHERE return_date IS NULL;
COMMIT;
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'library_lab3' AND table_type = 'BASE TABLE'
ORDER BY table_name;
```
