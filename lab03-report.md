# Лабораторна робота 3. Модифікація даних та транзакції

## Загальна інформація

**Здобувач освіти:** Дмитерчук Віталій Вадимович            
**Група:** ІПЗ-33                    
**Обраний рівень складності:** 3                    
**Варіант:** Система управління бібліотекою                        

**Посилання на репозиторій GitHub:** https://github.com/Armovolt/databases-lab-01

## Мета роботи

Здобути практичні навички безпечної модифікації даних у реляційних базах даних, опанувати механізми транзакцій для забезпечення цілісності даних, навчитися працювати з обмеженнями цілісності та каскадними операціями при зміні взаємопов'язаних записів.

---

## Виконання роботи

### Рівень 1. Базові операції модифікації

#### Крок 1. Створення структури бази даних

Створено базу даних для системи управління бібліотекою з чотирма основними таблицями (`authors`, `books`, `readers`, `lendings`) та відповідними обмеженнями цілісності.

```sql
CREATE DATABASE library_lab3;
```

**Таблиця авторів з обмеженнями:**

```sql
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year INTEGER CHECK (birth_year >= 1000 AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

*Обмеження таблиці `authors`:*
- `PRIMARY KEY` на `author_id` забезпечує унікальність кожного автора.
- `NOT NULL` на іменах запобігає створенню анонімних записів.
- `CHECK` на `birth_year` обмежує діапазон коректних років народження.

**Таблиця книг з розширеними обмеженнями:**

```sql
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    isbn VARCHAR(17) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    author_id INTEGER NOT NULL,
    publication_year INTEGER CHECK (publication_year >= 1450),
    genre VARCHAR(50),
    total_copies INTEGER DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INTEGER DEFAULT 1 CHECK (available_copies >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE RESTRICT,
    CHECK (available_copies <= total_copies)
);
```

*Ключові обмеження таблиці `books`:*
- `UNIQUE` на `isbn` гарантує відсутність дублікатів книг за міжнародним номером.
- `FOREIGN KEY` з `ON DELETE RESTRICT` запобігає видаленню авторів, чиї книги є в каталозі.
- `CHECK (available_copies <= total_copies)` унеможливлює ситуацію, коли доступних книг більше за загальну кількість.

**Таблиця читачів:**

```sql
CREATE TABLE readers (
    reader_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    library_card_number VARCHAR(20) UNIQUE NOT NULL,
    registration_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Blocked', 'Inactive'))
);
```

**Таблиця видач книг:**

```sql
CREATE TABLE lendings (
    lending_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL,
    reader_id INTEGER NOT NULL,
    lending_date DATE DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE RESTRICT,
    FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE RESTRICT,
    CHECK (due_date > lending_date),
    CHECK (return_date IS NULL OR return_date >= lending_date)
);
```

**Результат створення структури:**
<img width="1917" height="931" alt="01-create-tables" src="https://github.com/user-attachments/assets/c5046b10-70b4-4c26-915f-bd7bde335445" />

---

#### Крок 2. Додавання тестових даних

Виконано вставку початкових даних у всі створені таблиці.

**Додавання авторів:**

```sql
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES
    ('Тарас', 'Шевченко', 1814, 'Україна'),
    ('Іван', 'Франко', 1856, 'Україна'),
    ('Леся', 'Українка', 1871, 'Україна'),
    ('Михайло', 'Коцюбинський', 1864, 'Україна'),
    ('Панас', 'Мирний', 1849, 'Україна');

SELECT * FROM authors ORDER BY birth_year;
```

**Додавання книг:**

```sql
INSERT INTO books (isbn, title, author_id, publication_year, genre, total_copies, available_copies)
VALUES
    ('978-966-03-4561-2', 'Кобзар', 1, 1840, 'Поезія', 10, 8),
    ('978-966-03-4562-9', 'Захар Беркут', 2, 1883, 'Історична проза', 5, 4),
    ('978-966-03-4563-6', 'Лісова пісня', 3, 1911, 'Драма', 7, 7),
    ('978-966-03-4564-3', 'Тіні забутих предків', 4, 1911, 'Повість', 6, 5),
    ('978-966-03-4565-0', 'Хіба ревуть воли, як ясла повні', 5, 1880, 'Повість', 4, 4);

SELECT * FROM books ORDER BY book_id;
```

**Додавання читачів:**

```sql
INSERT INTO readers (first_name, last_name, email, phone, library_card_number)
VALUES
    ('Олена', 'Петренко', 'olena.petrenko@email.com', '+380501234567', 'LIB-2024-001'),
    ('Андрій', 'Коваленко', 'andrii.kovalenko@email.com', '+380502345678', 'LIB-2024-002'),
    ('Марія', 'Сидоренко', 'maria.sydorenko@email.com', '+380503456789', 'LIB-2024-003'),
    ('Іван', 'Мельник', 'ivan.melnyk@email.com', '+380504567890', 'LIB-2024-004');

SELECT * FROM readers ORDER BY reader_id;
```

**Результат додавання даних:**
<img width="1436" height="926" alt="Знімок екрана 2026-11-16 191919" src="https://github.com/user-attachments/assets/27aeed76-3031-4b2f-9f35-4597651d0a7a" />

---

#### Крок 3. Безпечне оновлення записів

Продемонстровано практику попередньої вибірки (`SELECT`) та обов'язкового використання умови `WHERE` перед виконанням `UPDATE`.

```sql
-- 1. Перевірка поточного стану перед оновленням
SELECT book_id, title, total_copies, available_copies
FROM books
WHERE book_id = 1;

-- 2. Безпечне оновлення з умовою наявності примірників
UPDATE books
SET available_copies = available_copies - 1
WHERE book_id = 1 AND available_copies > 0
RETURNING book_id, title, total_copies, available_copies;

-- 3. Перевірка скільки записів буде змінено за жанром
SELECT COUNT(*) FROM books WHERE genre = 'Поезія';

-- 4. Безпечне оновлення тільки для жанру 'Поезія'
UPDATE books
SET total_copies = total_copies + 2
WHERE genre = 'Поезія'
RETURNING book_id, title, genre, total_copies, available_copies;
```

**Пояснення:** Використання умови `WHERE` гарантує модифікацію лише цільових рядків. Без `WHERE` оператор `UPDATE` змінив би кількість примірників абсолютно для всіх книг у таблиці.

**Результат виконання:**
<img width="1435" height="937" alt="Знімок екрана 2026-11-16 192522" src="https://github.com/user-attachments/assets/190f8add-3bed-489d-9365-d80bb27cc3ae" />

---

#### Крок 4. Операції з транзакціями

Реалізовано процес видачі книги читачу як єдину атомарну транзакцію.

```sql
BEGIN;

-- Додаємо запис про видачу книги
INSERT INTO lendings (book_id, reader_id, due_date)
VALUES (1, 1, CURRENT_DATE + INTERVAL '14 days')
RETURNING lending_id, book_id, reader_id, due_date;

-- Зменшуємо кількість доступних примірників
UPDATE books
SET available_copies = available_copies - 1
WHERE book_id = 1 AND available_copies > 0
RETURNING book_id, title, available_copies;

-- Перевірка коректності операцій перед фіксацією
SELECT l.lending_id, b.title, r.first_name, r.last_name, l.due_date
FROM lendings l
JOIN books b ON l.book_id = b.book_id
JOIN readers r ON l.reader_id = r.reader_id
WHERE l.lending_id = 1;

COMMIT;
```

**Аналіз транзакції:** Завдяки блоку `BEGIN ... COMMIT` операції створення запису в `lendings` та зменшення залишку в `books` виконалися атомарно (`available_copies` зменшилося з 7 до 6). У разі збою на будь-якому етапі база даних скасувала б обидві дії.

**Результат виконання:**
<img width="1437" height="928" alt="Знімок екрана 2026-11-16 192721" src="https://github.com/user-attachments/assets/778bd66d-4d7a-4dad-9ff0-ad4bf88a47b7" />

---

#### Крок 5. Демонстрація ROLLBACK

Продемонстровано відкат транзакції при порушенні обмеження зовнішнього ключа (`ON DELETE RESTRICT`).

```sql
BEGIN;

-- Перевірка наявності книг у автора з author_id = 1
SELECT book_id, title FROM books WHERE author_id = 1;

-- Спроба видалення автора, у якого є книги (викличе помилку)
DELETE FROM authors WHERE author_id = 1;
```

*Отримане повідомлення про помилку:*
`ERROR: update or delete on table "authors" violates foreign key constraint "books_author_id_fkey" on table "books"`

```sql
-- Відкат аварійної транзакції
ROLLBACK;

-- Перевірка, що запис автора залишився неушкодженим
SELECT * FROM authors WHERE author_id = 1;
```

**Висновок:** Обмеження `ON DELETE RESTRICT` захистило дочірні записи від втрати батьківського ключа, а команда `ROLLBACK` вивела транзакцію зі стану помилки та повернула БД до початкового узгодженого стану.

**Результат виконання:**
<img width="1437" height="886" alt="Знімок екрана 2026-11-16 194818" src="https://github.com/user-attachments/assets/67aec60a-cd47-483c-8d24-b4d2e7f21c3c" />

---

#### Крок 6. Безпечне видалення

Виконано видалення неактивних читачів з попередньою перевіркою відсутності активних боргів (неповернених книг).

```sql
-- 1. Перевірка читачів зі статусом Inactive без активних видач
SELECT r.reader_id, r.first_name, r.last_name, r.status,
       COUNT(l.lending_id) AS active_lendings
FROM readers r
LEFT JOIN lendings l ON r.reader_id = l.reader_id AND l.return_date IS NULL
GROUP BY r.reader_id, r.first_name, r.last_name, r.status
HAVING COUNT(l.lending_id) = 0 AND r.status = 'Inactive';

-- 2. Створення тестового неактивного читача для демонстрації видалення
INSERT INTO readers (first_name, last_name, email, library_card_number, status)
VALUES ('Тестовий', 'Читач', 'test@example.com', 'LIB-TEST-001', 'Inactive')
RETURNING reader_id, first_name, last_name, status;

-- 3. Безпечне видалення з підзапитом перевірки активних видач
DELETE FROM readers
WHERE status = 'Inactive'
  AND reader_id NOT IN (
      SELECT DISTINCT reader_id
      FROM lendings
      WHERE return_date IS NULL
  )
RETURNING reader_id, first_name, last_name;

-- 4. Перевірка після видалення
SELECT COUNT(*) AS remaining_test_readers FROM readers WHERE email = 'test@example.com';
```

**Результат виконання:**
<img width="1436" height="886" alt="Знімок екрана 2026-11-16 195556" src="https://github.com/user-attachments/assets/98180b0a-bf56-46a8-86e8-7cc47af37aca" />

---

### Рівень 2. Розширена функціональність

#### Крок 1. Додавання нових таблиць

Створено таблиці для обліку бронювань книг (`reservations` з `ON DELETE CASCADE`) та журналювання змін (`audit_log` з типом `JSONB`).

```sql
-- Таблиця бронювань
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL,
    reader_id INTEGER NOT NULL,
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiration_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Fulfilled', 'Cancelled', 'Expired')),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE CASCADE
);

-- Таблиця логування змін (аудиту)
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    record_id INTEGER NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100) DEFAULT CURRENT_USER
);

-- Перевірка створеної структури через системний каталог
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name IN ('reservations', 'audit_log')
ORDER BY table_name, ordinal_position;
```

**Результат виконання:**
<img width="1437" height="932" alt="Знімок екрана 2026-11-16 195822" src="https://github.com/user-attachments/assets/0d23d18c-8714-4975-8d5f-aff31ca0b229" />

---

#### Крок 2. Складні транзакції

Реалізовано комплексний бізнес-процес повернення книги читачем із одночасним оновленням залишків на складі та закриттям черги активного бронювання.

```sql
-- Підготовка тестового активного бронювання на книгу book_id = 1
INSERT INTO reservations (book_id, reader_id, expiration_date)
VALUES (1, 2, CURRENT_TIMESTAMP + INTERVAL '3 days')
RETURNING reservation_id, book_id, reader_id, status;

-- Складна транзакція повернення книги
BEGIN;

-- Крок 1: Фіксуємо дату повернення у видачі
UPDATE lendings
SET return_date = CURRENT_DATE
WHERE lending_id = 1 AND return_date IS NULL
RETURNING lending_id, book_id, reader_id, return_date;

-- Крок 2: Збільшуємо кількість доступних примірників книги
UPDATE books
SET available_copies = available_copies + 1
WHERE book_id = (SELECT book_id FROM lendings WHERE lending_id = 1)
RETURNING book_id, title, available_copies;

-- Крок 3: Перевіряємо найстаріше активне бронювання на цю книгу
SELECT reservation_id, reader_id, reservation_date
FROM reservations
WHERE book_id = 1 AND status = 'Active'
ORDER BY reservation_date
LIMIT 1;

-- Крок 4: Переводимо знайдене бронювання у статус 'Fulfilled'
UPDATE reservations
SET status = 'Fulfilled'
WHERE reservation_id = (
    SELECT reservation_id
    FROM reservations
    WHERE book_id = 1 AND status = 'Active'
    ORDER BY reservation_date
    LIMIT 1
)
RETURNING reservation_id, status;

COMMIT;

-- Зведена перевірка результату транзакції
SELECT
    l.lending_id,
    b.title,
    r1.first_name || ' ' || r1.last_name AS borrower,
    l.return_date,
    r2.first_name || ' ' || r2.last_name AS next_reader,
    res.status AS reservation_status
FROM lendings l
JOIN books b ON l.book_id = b.book_id
JOIN readers r1 ON l.reader_id = r1.reader_id
LEFT JOIN reservations res ON b.book_id = res.book_id AND res.reservation_id = 1
LEFT JOIN readers r2 ON res.reader_id = r2.reader_id
WHERE l.lending_id = 1;
```

**Результат виконання:**
<img width="1433" height="892" alt="Знімок екрана 2026-11-16 200837" src="https://github.com/user-attachments/assets/94b6e347-f779-4d25-90e2-c2c36539e212" />

---

#### Крок 3. Використання SAVEPOINT

Продемонстровано частковий відкат транзакції за допомогою точок збереження `SAVEPOINT` при виникненні помилки дублювання унікального `ISBN`.

```sql
BEGIN;

-- 1. Додаємо нового автора (author_id = 6)
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES ('Ольга', 'Кобилянська', 1863, 'Україна')
RETURNING author_id, first_name, last_name;

SAVEPOINT after_author;

-- 2. Додаємо першу книгу автора з коректним ISBN
INSERT INTO books (isbn, title, author_id, publication_year, genre, total_copies, available_copies)
VALUES ('978-966-03-4566-7', 'Земля', 6, 1902, 'Роман', 3, 3)
RETURNING book_id, title, isbn;

SAVEPOINT after_first_book;

-- 3. Спроба додати книгу з дублікатом ISBN (викличе ERROR unique constraint "books_isbn_key")
INSERT INTO books (isbn, title, author_id, publication_year, genre)
VALUES ('978-966-03-4566-7', 'Інша книга', 6, 1905, 'Роман');
```

*Після виникнення помилки відкочуємо транзакцію лише до точки `after_first_book`:*

```sql
-- 4. Частковий відкат до точки збереження після першої книги
ROLLBACK TO SAVEPOINT after_first_book;

-- 5. Додаємо другу книгу з правильним унікальним ISBN
INSERT INTO books (isbn, title, author_id, publication_year, genre, total_copies, available_copies)
VALUES ('978-966-03-4567-4', 'Царівна', 6, 1896, 'Повість', 2, 2)
RETURNING book_id, title, isbn;

COMMIT;

-- Перевірка збережених даних
SELECT a.first_name, a.last_name, b.book_id, b.title, b.isbn
FROM authors a
JOIN books b ON a.author_id = b.author_id
WHERE a.author_id = 6
ORDER BY b.book_id;
```

**Висновок:** Механізм `SAVEPOINT` дозволив ізолювати та скасувати лише помилковий `INSERT`, зберігши попередньо доданого автора та першу книгу в межах тієї самої транзакції.

**Результат виконання:**
<img width="1437" height="897" alt="Знімок екрана 2026-11-17 184129" src="https://github.com/user-attachments/assets/5be8765f-2cba-4037-b899-37075a914ef8" />

---

#### Крок 4. Каскадні операції

Продемонстровано автоматичне видалення пов'язаних бронювань при видаленні книги завдяки `ON DELETE CASCADE`.

```sql
BEGIN;

-- Створюємо тестового автора (author_id = 7)
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES ('Тестовий', 'Автор', 1900, 'Україна')
RETURNING author_id;

-- Створюємо тестову книгу (book_id = 8)
INSERT INTO books (isbn, title, author_id, publication_year, genre, total_copies, available_copies)
VALUES ('978-966-00-0000-0', 'Тестова книга', 7, 2000, 'Тест', 1, 0)
RETURNING book_id;

-- Створюємо бронювання на тестову книгу (reservation_id = 2)
INSERT INTO reservations (book_id, reader_id, expiration_date)
VALUES (8, 1, CURRENT_TIMESTAMP + INTERVAL '7 days')
RETURNING reservation_id;

COMMIT;

-- Перевірка зв'язку перед видаленням
SELECT b.book_id, b.title, b.isbn, r.reservation_id, r.status
FROM books b
LEFT JOIN reservations r ON b.book_id = r.book_id
WHERE b.isbn = '978-966-00-0000-0';

-- Видаляємо книгу (бронювання видаляється каскадно)
DELETE FROM books
WHERE isbn = '978-966-00-0000-0'
RETURNING book_id, title;

-- Перевірка, що бронювання автоматично видалилося
SELECT * FROM reservations WHERE reservation_id = 2;

-- Тепер видаляємо тестового автора (успішно, бо книг у нього більше немає)
DELETE FROM authors WHERE author_id = 7 RETURNING author_id, first_name, last_name;
```

**Результат виконання:**
<img width="1438" height="897" alt="Знімок екрана 2026-11-17 184618" src="https://github.com/user-attachments/assets/1396d6b4-0edd-48e7-9c79-1a84d10b828b" />

---

#### Крок 5. Тригери для аудиту

Створено тригерну функцію `log_books_changes()` та тригер `books_audit_trigger` для автоматичної фіксації всіх операцій `INSERT`, `UPDATE`, `DELETE` у таблиці `books`.

```sql
CREATE OR REPLACE FUNCTION log_books_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_data)
        VALUES ('books', 'INSERT', NEW.book_id, row_to_json(NEW)::jsonb);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data)
        VALUES ('books', 'UPDATE', NEW.book_id, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data)
        VALUES ('books', 'DELETE', OLD.book_id, row_to_json(OLD)::jsonb);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER books_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON books
FOR EACH ROW
EXECUTE FUNCTION log_books_changes();

-- Тестування роботи тригера (INSERT -> UPDATE -> DELETE)
INSERT INTO books (isbn, title, author_id, publication_year, genre, total_copies, available_copies)
VALUES ('978-966-03-9999-9', 'Нова книга', 2, 2024, 'Сучасна', 5, 5);

UPDATE books
SET available_copies = available_copies - 1
WHERE isbn = '978-966-03-9999-9';

DELETE FROM books WHERE isbn = '978-966-03-9999-9';

-- Перегляд журналу аудиту
SELECT
    log_id,
    operation,
    record_id,
    COALESCE(new_data->>'title', old_data->>'title') AS title,
    old_data->>'available_copies' AS old_copies,
    new_data->>'available_copies' AS new_copies,
    to_char(changed_at, 'YYYY-MM-DD HH24:MI:SS') AS changed_time,
    changed_by
FROM audit_log
WHERE table_name = 'books'
ORDER BY log_id DESC;

-- Статистика операцій в аудиті
SELECT operation, COUNT(*) AS operations_count
FROM audit_log
WHERE table_name = 'books'
GROUP BY operation;
```

**Результат виконання:**
<img width="1017" height="815" alt="Знімок екрана 2026-11-17 185213" src="https://github.com/user-attachments/assets/a8e3b59d-6d5b-4b67-b2eb-8ee8a0348283" />

---

#### Крок 6. Блокування записів

Продемонстровано песимістичне блокування рядків `SELECT ... FOR UPDATE` при одночасному доступі з двох паралельних сесій у DBeaver.

**Сесія 1 (Перше вікно SQL-редактора):**

```sql
BEGIN;

-- Блокуємо рядок книги book_id = 1 для оновлення
SELECT book_id, title, available_copies
FROM books
WHERE book_id = 1
FOR UPDATE;

-- Імітація тривалої обробки транзакції (5 секунд)
SELECT pg_sleep(5);

UPDATE books
SET available_copies = available_copies - 1
WHERE book_id = 1
RETURNING book_id, title, available_copies;

COMMIT;
```

**Сесія 2 (Друге вікно SQL-редактора, запускається паралельно під час `pg_sleep`):**

```sql
BEGIN;

-- Запит чекає звільнення блокування Сесією 1, після чого отримує вже оновлене значення (6)
SELECT book_id, title, available_copies
FROM books
WHERE book_id = 1
FOR UPDATE;

UPDATE books
SET available_copies = available_copies - 1
WHERE book_id = 1
RETURNING book_id, title, available_copies;

COMMIT;

-- Фінальна перевірка (available_copies коректно зменшилося двічі: 7 -> 6 -> 5)
SELECT book_id, title, available_copies FROM books WHERE book_id = 1;
```

**Аналіз:** Конструкція `FOR UPDATE` накладає ексклюзивне блокування на рядок, змушуючи другу транзакцію чекати завершення (`COMMIT`) першої. Це повністю усуває аномалію втраченого оновлення (*Lost Update*).

**Результат виконання:**
<img width="1427" height="770" alt="Знімок екрана 2026-11-17 191436" src="https://github.com/user-attachments/assets/deab9544-4f48-4122-8a40-4f54bd723b62" />

---

### Рівень 3. Творче розширення та адміністрування

#### Крок 1. Система версіонування

Тригерна функція `version_books_changes()` записує версії книг у `books_history`. Стан книги на вибраний момент визначає інтервал `[valid_from, valid_to)`.

**Таблиця версій**

```sql
CREATE TABLE public.books_history (
    history_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL,
    isbn VARCHAR(17) NOT NULL,
    title VARCHAR(200) NOT NULL,
    author_id INTEGER NOT NULL,
    publication_year INTEGER,
    genre VARCHAR(50),
    total_copies INTEGER,
    available_copies INTEGER,
    version_number INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    operation VARCHAR(10) NOT NULL,
    changed_by VARCHAR(100) DEFAULT CURRENT_USER
);
```

**Тригер версіонування** 

```sql
SELECT pg_get_triggerdef(t.oid) AS trigger_definition,
       pg_get_functiondef(t.tgfoid) AS function_definition
FROM pg_trigger AS t
JOIN pg_proc AS p ON p.oid = t.tgfoid
WHERE t.tgrelid = 'public.books'::regclass
  AND p.proname = 'version_books_changes'
  AND NOT t.tgisinternal;
```

**Стан книги на вибраний момент**

```sql
-- Рівень 3, крок 1. Стан «Лісової пісні» на початок дії другої версії.
WITH chosen_time AS (
    SELECT book_id, valid_from AS as_of
    FROM public.books_history
    WHERE isbn = '978-966-03-4563-6'
      AND version_number = 2
    ORDER BY history_id DESC
    LIMIT 1
)
SELECT
    version.book_id,
    version.title,
    version.version_number,
    version.genre,
    version.total_copies,
    version.available_copies,
    chosen_time.as_of,
    version.valid_to
FROM chosen_time
JOIN public.books_history AS version
  ON version.book_id = chosen_time.book_id
 AND version.valid_from <= chosen_time.as_of
 AND (version.valid_to IS NULL OR chosen_time.as_of < version.valid_to)
WHERE version.operation <> 'DELETE'
ORDER BY version.version_number DESC, version.history_id DESC
LIMIT 1;
```

**Результат.** Версія №2 «Лісової пісні» має жанр «Драма», 8 примірників загалом і 5 доступних.
<img width="1590" height="756" alt="01-version-as-of" src="https://github.com/user-attachments/assets/c91c3e7e-8763-4a3a-8349-0e1acb07861b" />

---

#### Крок 2. Відкладені операції

Завдання `pg_cron` переводить прострочене тестове бронювання зі статусу `Active` у `Expired`. Інтервал запуску становить 10 секунд. Після виконання завдання вимикається.

```sql
-- Рівень 3, крок 2. Автоматичне завершення окремого тестового бронювання.
WITH demo AS (
    INSERT INTO public.reservations
        (book_id, reader_id, reservation_date, expiration_date, status)
    VALUES (2, 3,
        (CURRENT_TIMESTAMP AT TIME ZONE 'UTC') - INTERVAL '10 minutes',
        (CURRENT_TIMESTAMP AT TIME ZONE 'UTC') - INTERVAL '1 minute',
        'Active')
    RETURNING reservation_id, status, expiration_date
)
SELECT reservation_id,
       status AS initial_status,
       expiration_date,
       cron.schedule('lab03_demo_expire_reservation', '10 seconds', format($job$
           DO $run$
           BEGIN
               UPDATE public.reservations
               SET status = 'Expired'
               WHERE reservation_id = %s
                 AND status = 'Active'
                 AND expiration_date <= (CURRENT_TIMESTAMP AT TIME ZONE 'UTC');

               PERFORM cron.alter_job(
                   (SELECT jobid FROM cron.job
                    WHERE jobname = 'lab03_demo_expire_reservation'
                      AND username = CURRENT_USER),
                   active => false
               );
           END;
           $run$;
       $job$, reservation_id)) AS job_id
FROM demo;
```

**Перевірка журналу запусків**

```sql
-- Перевірка після автоматичного запуску Supabase Cron.
-- Ідентифікатор бронювання отримано від запиту налаштування.
SELECT r.reservation_id,
       r.status AS reservation_status,
       j.jobname AS cron_job,
       d.status AS run_status,
       to_char(d.start_time AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS') AS ran_at_utc,
       j.active AS job_active
FROM public.reservations AS r
CROSS JOIN cron.job AS j
JOIN cron.job_run_details AS d ON d.jobid = j.jobid
WHERE r.reservation_id = 6
  AND j.jobname = 'lab03_demo_expire_reservation'
  AND d.end_time IS NOT NULL
ORDER BY d.runid DESC
LIMIT 1;
```

**Результат.** Бронювання №6 має статус `Expired`, запуск Cron має статус `succeeded`.
<img width="1397" height="763" alt="02-cron-expiration" src="https://github.com/user-attachments/assets/72cefd40-6eaa-464b-8df4-da716523e3b6" />

---

#### Крок 3. Складна бізнес-логіка

Процедура `issue_book()` перевіряє статус читача, ліміт видач та наявність примірників. Вона блокує рядок книги через `FOR UPDATE`, враховує найстаріше активне бронювання, списує примірник і створює запис видачі.

```sql
CREATE OR REPLACE PROCEDURE public.issue_book(
    IN p_book_id integer,
    IN p_reader_id integer,
    IN p_days_to_return integer DEFAULT 14
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_available INTEGER;
    v_reader_status VARCHAR;
    v_active_lendings INTEGER;
    v_reservation_id INTEGER;
BEGIN
    SELECT status INTO v_reader_status
    FROM readers WHERE reader_id = p_reader_id;
    IF v_reader_status != 'Active' THEN
        RAISE EXCEPTION 'Читач не активний (статус: %)', v_reader_status;
    END IF;

    SELECT COUNT(*) INTO v_active_lendings
    FROM lendings
    WHERE reader_id = p_reader_id AND return_date IS NULL;
    IF v_active_lendings >= 5 THEN
        RAISE EXCEPTION 'Читач досяг ліміту одночасно виданих книг (5)';
    END IF;

    SELECT available_copies INTO v_available
    FROM books WHERE book_id = p_book_id FOR UPDATE;
    IF v_available <= 0 THEN
        RAISE EXCEPTION 'Немає доступних примірників цієї книги';
    END IF;

    SELECT reservation_id INTO v_reservation_id
    FROM reservations
    WHERE book_id = p_book_id AND status = 'Active'
    ORDER BY reservation_date LIMIT 1;
    IF v_reservation_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM reservations
                   WHERE reservation_id = v_reservation_id AND reader_id = p_reader_id) THEN
            UPDATE reservations SET status = 'Fulfilled'
            WHERE reservation_id = v_reservation_id;
        ELSE
            RAISE EXCEPTION 'Книга заброньована іншим читачем';
        END IF;
    END IF;

    UPDATE books SET available_copies = available_copies - 1 WHERE book_id = p_book_id;
    INSERT INTO lendings (book_id, reader_id, due_date)
    VALUES (p_book_id, p_reader_id, CURRENT_DATE + p_days_to_return);
    COMMIT;
END;
$procedure$;
```

**Приклад виклику процедури**

```sql
CALL public.issue_book(4, 3, 21);
```

**Перевірка процедури й видачі**

```sql
-- Рівень 3, крок 3. Перевірка вже оформленої видачі книги.
SELECT 'issue_book(integer, integer, integer)' AS procedure_name,
       routine.prokind = 'p' AS procedure_exists,
       l.lending_id,
       b.title,
       concat_ws(' ', r.first_name, r.last_name) AS reader_name,
       l.lending_date,
       l.due_date,
       l.due_date - l.lending_date AS loan_days
FROM public.lendings AS l
JOIN public.books AS b ON b.book_id = l.book_id
JOIN public.readers AS r ON r.reader_id = l.reader_id
JOIN pg_proc AS routine
  ON routine.oid = to_regprocedure('public.issue_book(integer,integer,integer)')
WHERE l.lending_id = 2;
```

**Результат.** `issue_book` зареєстровано як процедуру. Видачу №2 книги «Тіні забутих предків» оформлено на 21 день.
<img width="1576" height="682" alt="03-issue-book" src="https://github.com/user-attachments/assets/e197fe17-7bf7-497c-8a16-3e81e0b52251" />

---

#### Крок 4. Система прав доступу

Права доступу розподілено між ролями `library_reader`, `librarian` та `library_admin`.

```sql
CREATE ROLE library_reader NOLOGIN;
CREATE ROLE librarian NOLOGIN;
CREATE ROLE library_admin NOLOGIN;

GRANT USAGE ON SCHEMA public TO library_reader;
GRANT SELECT ON authors, books TO library_reader;

GRANT library_reader TO librarian;
GRANT SELECT, INSERT, UPDATE ON readers, lendings, reservations TO librarian;
GRANT INSERT, UPDATE ON books TO librarian;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO librarian;
GRANT EXECUTE ON PROCEDURE issue_book(INTEGER, INTEGER, INTEGER) TO librarian;

GRANT librarian TO library_admin;
GRANT ALL PRIVILEGES ON authors, books, readers, lendings,
    reservations, audit_log, books_history TO library_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO library_admin;
```

**Перевірка фактичних привілеїв**

```sql
-- Рівень 3, крок 4. Перевірка чинних прав ролей бібліотеки.
SELECT rolname AS library_role,
       CASE WHEN has_table_privilege(rolname, 'public.books', 'SELECT')
            THEN 'Дозволено' ELSE 'Заборонено' END AS select_books,
       CASE WHEN has_table_privilege(rolname, 'public.books', 'UPDATE')
            THEN 'Дозволено' ELSE 'Заборонено' END AS update_books,
       CASE WHEN has_table_privilege(rolname, 'public.lendings', 'INSERT')
            THEN 'Дозволено' ELSE 'Заборонено' END AS insert_lendings,
       CASE WHEN has_table_privilege(rolname, 'public.books', 'DELETE')
            THEN 'Дозволено' ELSE 'Заборонено' END AS delete_books
FROM pg_catalog.pg_roles
WHERE rolname IN ('library_reader', 'librarian', 'library_admin')
ORDER BY array_position(ARRAY['library_reader', 'librarian', 'library_admin'], rolname::text);
```

**Результат.** Усі ролі можуть переглядати каталог. Бібліотекар і адміністратор можуть оновлювати книги та оформлювати видачі. Видалення книг дозволено адміністратору.
<img width="1122" height="720" alt="04-role-permissions" src="https://github.com/user-attachments/assets/0f50de4e-33d3-4a24-99cd-06e6e9d67073" />

---

#### Крок 5. Резервне копіювання та відновлення

Контрольні копії зберігаються у схемі `backup_library`. Завдання `library_lab3_daily_backup` виконується щодня за розкладом `0 3 * * *`.

**Перевірка автоматичного запуску і резервної копії**

```sql
SELECT j.jobname,
       j.schedule,
       d.status AS cron_status,
       d.end_time AS finished_at,
       (SELECT count(*) FROM backup_library.books_backup) AS books_in_backup
FROM cron.job AS j
LEFT JOIN cron.job_run_details AS d
       ON d.jobid = j.jobid AND d.end_time IS NOT NULL
WHERE j.jobname = 'library_lab3_daily_backup'
ORDER BY d.runid DESC NULLS LAST
LIMIT 1;
```

**Результат.** Запуск має статус `succeeded`. Резервна таблиця містить 7 книг.
<img width="1115" height="661" alt="05-automatic-backup" src="https://github.com/user-attachments/assets/b04d6722-1aac-4723-a837-5268e88f5767" />

**Демонстрація відновлення полів каталогу з контрольної копії**

Записи каталогу зіставлено з резервною копією за `book_id`. Відновлено жанр, загальну та доступну кількість примірників.

```sql
BEGIN;

UPDATE public.books AS b
SET genre = bk.genre,
    available_copies = bk.available_copies,
    total_copies = bk.total_copies
FROM backup_library.books_backup AS bk
WHERE b.book_id = bk.book_id;

COMMIT;

SELECT b.book_id, b.title,
       b.genre AS restored_genre,
       b.available_copies AS restored_copies,
       bk.available_copies AS backup_copies,
       CASE WHEN b.genre = bk.genre
                 AND b.available_copies = bk.available_copies
            THEN 'OK (Відновлено)'
            ELSE 'ERROR'
       END AS restore_status
FROM public.books AS b
JOIN backup_library.books_backup AS bk ON b.book_id = bk.book_id
ORDER BY b.book_id;
```

**Результат.** Жанр і доступний залишок збіглися з копією для всіх 7 книг.
<img width="1432" height="896" alt="Знімок екрана 2026-11-19 224158" src="https://github.com/user-attachments/assets/77d2c6d8-ea77-4373-83cc-9dab862982c2" />

---

#### Крок 6. Інтерфейс перегляду історії та відкату за період

Представлення `v_books_change_history` показує версії книги, а `v_audit_history` — записи журналу операцій. Функція `get_book_history()` повертає історію за ідентифікатором книги.

```sql
-- 1. Представлення для зручного перегляду історії версій книг (формат «було -> стало»)
CREATE OR REPLACE VIEW v_books_change_history AS
SELECT
    bh.history_id,
    bh.book_id,
    bh.version_number,
    bh.title,
    a.first_name || ' ' || a.last_name AS author_name,
    LAG(bh.genre) OVER (PARTITION BY bh.book_id ORDER BY bh.version_number) AS prev_genre,
    bh.genre AS current_genre,
    LAG(bh.available_copies) OVER (PARTITION BY bh.book_id ORDER BY bh.version_number) AS prev_copies,
    bh.available_copies AS current_copies,
    bh.operation,
    bh.changed_by,
    to_char(bh.valid_from, 'YYYY-MM-DD HH24:MI:SS') AS changed_at,
    CASE
        WHEN bh.valid_to IS NULL THEN 'Актуальна'
        ELSE 'Архівна'
    END AS version_status
FROM books_history bh
JOIN authors a ON bh.author_id = a.author_id;

-- 2. Представлення для читабельного перегляду загального журналу аудиту
CREATE OR REPLACE VIEW v_audit_history AS
SELECT
    log_id,
    table_name,
    operation,
    record_id,
    COALESCE(new_data->>'title', old_data->>'title', new_data->>'action', '—') AS object_summary,
    to_char(changed_at, 'YYYY-MM-DD HH24:MI:SS') AS changed_at,
    changed_by
FROM audit_log
ORDER BY log_id DESC;

-- 3. Функція-інтерфейс для отримання історії змін конкретної книги за її ID
CREATE OR REPLACE FUNCTION get_book_history(p_book_id INTEGER)
RETURNS TABLE (
    version_number INTEGER,
    title TEXT,
    genre_change TEXT,
    copies_change TEXT,
    operation TEXT,
    changed_by TEXT,
    changed_at TEXT,
    version_status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.version_number,
        v.title::TEXT,
        (COALESCE(v.prev_genre, '—') || ' -> ' || COALESCE(v.current_genre, '—'))::TEXT AS genre_change,
        (COALESCE(v.prev_copies::TEXT, '—') || ' -> ' || COALESCE(v.current_copies::TEXT, '—'))::TEXT AS copies_change,
        v.operation::TEXT,
        v.changed_by::TEXT,
        v.changed_at::TEXT,
        v.version_status::TEXT
    FROM v_books_change_history v
    WHERE v.book_id = p_book_id
    ORDER BY v.version_number;
END;
$$;

-- 4. Надання прав на перегляд інтерфейсу ролям бібліотекаря та адміністратора
GRANT SELECT ON v_books_change_history, v_audit_history TO librarian, library_admin;
GRANT EXECUTE ON FUNCTION get_book_history(INTEGER) TO librarian, library_admin;

-- 5. Демонстрація роботи інтерфейсу: історія змін книги «Лісова пісня» (book_id = 3)
SELECT * FROM get_book_history(3);

-- 6. Останні 10 подій у загальному журналі аудиту
SELECT * FROM v_audit_history LIMIT 10;
```

<img width="1430" height="888" alt="Знімок екрана 2026-11-23 213446" src="https://github.com/user-attachments/assets/d66ed60c-dbdc-4270-8c86-b5f7d597180b" />

**Відкат жанру книги за вибраний період**

Попереднє значення взято з `audit_log.old_data` для першої зміни жанру за 17 листопада 2026 року. Відкат виконано на тимчасовій копії книги.

```sql
CREATE TEMP TABLE lab03_genre_rollback_demo AS SELECT book_id, title, genre FROM public.books WHERE book_id = 3;

WITH first_change AS (
    SELECT record_id AS book_id, changed_at, old_data->>'genre' AS previous_genre
    FROM public.audit_log
    WHERE table_name = 'books'
      AND record_id = 3
      AND operation = 'UPDATE'
      AND changed_at >= TIMESTAMP '2026-11-17 00:00:00'
      AND changed_at < TIMESTAMP '2026-11-18 00:00:00'
      AND old_data->>'genre' IS DISTINCT FROM new_data->>'genre'
    ORDER BY changed_at, log_id
    LIMIT 1
),
before_restore AS MATERIALIZED (
    SELECT book_id, genre FROM pg_temp.lab03_genre_rollback_demo
)
UPDATE pg_temp.lab03_genre_rollback_demo AS b
SET genre = c.previous_genre
FROM first_change AS c
JOIN before_restore AS old ON old.book_id = c.book_id
WHERE b.book_id = c.book_id
RETURNING b.book_id, b.title, c.changed_at, old.genre AS genre_before, b.genre AS genre_after;
```

**Результат.** Жанр «Лісової пісні» відновлено з «Драма-феєрія» до «Драма».
<img width="990" height="661" alt="06-period-rollback" src="https://github.com/user-attachments/assets/29fddda0-e461-48a2-9c70-e3a3a0e92587" />

---

## Відповіді на контрольні запитання

1. **Різниця між `INSERT`, `UPDATE`, `DELETE` та обмеження:** `INSERT` додає нові рядки (перевіряються `PRIMARY KEY`, `UNIQUE`, `NOT NULL`, `CHECK`, `FOREIGN KEY`), `UPDATE` змінює існуючі (перевіряються всі ті самі обмеження плюс каскадні правила `ON UPDATE`), а `DELETE` видаляє рядки (перевіряється посилальна цілісність `FOREIGN KEY` у дочірніх таблицях).
2. **Важливість `WHERE` в `UPDATE` та `DELETE`:** Без секції `WHERE` СУБД застосує зміну або видалення до **всіх** рядків таблиці одночасно, що призведе до миттєвої втрати або псування даних у всій таблиці.
3. **Транзакція та властивості ACID:** Транзакція — це логічно неподільна послідовність операцій. **A (Atomicity):** при видачі книги запис у `lendings` і зменшення `available_copies` у `books` або виконуються разом, або обидва скасовуються. **C (Consistency):** транзакція не може залишити `available_copies < 0` або `available_copies > total_copies`. **I (Isolation):** дві паралельні видачі останньої книги не заважають одна одній. **D (Durability):** після `COMMIT` факт видачі книги збережеться навіть при раптовому вимкненні живлення сервера.
4. **Різниця між `COMMIT` та `ROLLBACK`:** `COMMIT` остаточно фіксує всі зміни транзакції на диску та робить їх видимими для інших сесій. `ROLLBACK` скасовує всі незафіксовані зміни поточної транзакції (використовується при помилках або порушенні бізнес-умов).
5. **Точки збереження `SAVEPOINT`:** Дозволяють встановити проміжні мітки всередині транзакції та відкотити лише останню невдалу дію (`ROLLBACK TO SAVEPOINT`), не втрачаючи попередніх успішних операцій цієї ж транзакції.
6. **Типи обмежень цілісності:** `PRIMARY KEY` (унікальний ідентифікатор запису), `FOREIGN KEY` (цілісність зв'язків між таблицями), `UNIQUE` (відсутність дублікатів, наприклад в `isbn` чи `email`), `CHECK` (логічні умови на діапазон значень), `NOT NULL` (обов'язковість заповнення поля).
7. **Каскадні операції:** Визначають реакцію дочірньої таблиці на видалення/зміну батьківського ключа: `RESTRICT` / `NO ACTION` (заборона видалення), `CASCADE` (автоматичне видалення/оновлення залежних записів), `SET NULL` (встановлення `NULL`), `SET DEFAULT` (встановлення дефолтного значення).
8. **Роль тригерів:** Автоматично виконуються при подіях `INSERT/UPDATE/DELETE` на рівні СУБД незалежно від клієнтського застосунку. Застосовуються для автоматичного аудиту (`audit_log`), версіонування (`books_history`) та складної валідації.
9. **Блокування при паралельному доступі:** Запобігають станам гонитви (*race conditions*) та втраченим оновленням (*lost updates*), коли дві сесії одночасно читають однаковий залишок книги (`7`) і обидві записують `6` замість `5`.
10. **Рівні ізоляції транзакцій:** `READ UNCOMMITTED` (у PostgreSQL працює як `READ COMMITTED`), `READ COMMITTED` (за замовчуванням у PG — захищає від «брудного читання», підходить для більшості OLTP-запитів), `REPEATABLE READ` (захищає від неповторюваного читання та фантомів у PG, підходить для фінансових звітів), `SERIALIZABLE` (повна ізоляція, підходить для критичних бізнес-транзакцій зі складними перехресними перевірками).

---

## Висновки

**Самооцінка:** 5

**Обґрунтування:**

Під час лабораторної роботи я створив базу даних бібліотеки й виконав завдання трьох рівнів. Я навчився додавати, оновлювати й видаляти записи, а також перевірив, як працюють транзакції, `ROLLBACK`, `SAVEPOINT` і блокування рядків.

На третьому рівні я налаштував історію змін книг, автоматичне завершення простроченого бронювання через `pg_cron` і права доступу для трьох ролей. Також перевірив процедуру видачі книги та роботу резервного копіювання. На тимчасовій копії запису я відновив попередній жанр книги за журналом змін за вибраний період.
