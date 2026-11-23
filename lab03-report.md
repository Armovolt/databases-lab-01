# Лабораторна робота 3. Модифікація даних та транзакції

## Загальна інформація

**Здобувач освіти:** Дмитерчук Віталій Вадимович            
**Група:** ІПЗ-33                    
**Обраний рівень складності:** 3                    
**Варіант:** Система управління бібліотекою                        

**Посилання на репозиторій GitHub:**

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

Реалізовано автоматичне збереження повної історії версій кожного запису таблиці `books` із часовими інтервалами дії (`valid_from` — `valid_to`) та функцією реконструкції стану на довільний момент часу.

```sql
CREATE TABLE books_versions (
    version_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL,
    version_number INTEGER NOT NULL,
    data JSONB NOT NULL,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    created_by VARCHAR(100) DEFAULT CURRENT_USER,
    UNIQUE(book_id, version_number)
);

CREATE OR REPLACE FUNCTION create_book_version()
RETURNS TRIGGER AS $$
DECLARE
    v_version_number INTEGER;
BEGIN
    -- Закриваємо попередню активну версію
    UPDATE books_versions
    SET valid_to = CURRENT_TIMESTAMP
    WHERE book_id = NEW.book_id AND valid_to IS NULL;

    -- Обчислюємо порядковий номер нової версії
    SELECT COALESCE(MAX(version_number), 0) + 1
    INTO v_version_number
    FROM books_versions
    WHERE book_id = NEW.book_id;

    -- Додаємо нову версію
    INSERT INTO books_versions (book_id, version_number, data)
    VALUES (NEW.book_id, v_version_number, row_to_json(NEW)::jsonb);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER book_versioning_trigger
AFTER INSERT OR UPDATE ON books
FOR EACH ROW
EXECUTE FUNCTION create_book_version();

-- Функція отримання стану книги на вказаний момент часу
CREATE OR REPLACE FUNCTION get_book_version(p_book_id INTEGER, p_date TIMESTAMP)
RETURNS JSONB AS $$
BEGIN
    RETURN (
        SELECT data
        FROM books_versions
        WHERE book_id = p_book_id
          AND valid_from <= p_date
          AND (valid_to IS NULL OR valid_to > p_date)
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql;

-- Тестування системи версіонування (з невеликими паузами для різниці в часі)
INSERT INTO books (isbn, title, author_id, publication_year, genre, total_copies, available_copies)
VALUES ('978-966-03-7777-7', 'Версійована книга', 3, 2020, 'Тест', 10, 10);

SELECT pg_sleep(1);
UPDATE books SET available_copies = 8 WHERE isbn = '978-966-03-7777-7';

SELECT pg_sleep(1);
UPDATE books SET available_copies = 5, genre = 'Оновлений жанр' WHERE isbn = '978-966-03-7777-7';

-- Перегляд усіх створених версій
SELECT
    version_id,
    book_id,
    version_number,
    data->>'title' AS title,
    data->>'available_copies' AS copies,
    data->>'genre' AS genre,
    to_char(valid_from, 'YYYY-MM-DD HH24:MI:SS') AS valid_from,
    to_char(valid_to, 'YYYY-MM-DD HH24:MI:SS') AS valid_to
FROM books_versions
WHERE book_id = (SELECT book_id FROM books WHERE isbn = '978-966-03-7777-7')
ORDER BY version_number;

-- Отримання історичного стану книги на момент дії версії №2
SELECT get_book_version(
    (SELECT book_id FROM books WHERE isbn = '978-966-03-7777-7'),
    (SELECT valid_from FROM books_versions WHERE book_id = (SELECT book_id FROM books WHERE isbn = '978-966-03-7777-7') AND version_number = 2)
);
```

**Результат виконання:**
<img width="1437" height="918" alt="Знімок екрана 2026-11-17 192304" src="https://github.com/user-attachments/assets/a3ffd269-3798-413d-af8c-1cffdc5755b7" />

---

#### Крок 2. Відкладені операції

Створено чергу запланованих завдань (`scheduled_operations`) та обробник `execute_scheduled_operations()` із перехопленням винятків (`EXCEPTION WHEN OTHERS`).

```sql
CREATE TABLE scheduled_operations (
    operation_id SERIAL PRIMARY KEY,
    operation_type VARCHAR(50) NOT NULL,
    target_table VARCHAR(50) NOT NULL,
    operation_data JSONB NOT NULL,
    scheduled_for TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Executed', 'Failed', 'Cancelled')),
    executed_at TIMESTAMP,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION execute_scheduled_operations()
RETURNS INTEGER AS $$
DECLARE
    v_operation RECORD;
    v_count INTEGER := 0;
BEGIN
    FOR v_operation IN
        SELECT * FROM scheduled_operations
        WHERE status = 'Pending' AND scheduled_for <= CURRENT_TIMESTAMP
    LOOP
        BEGIN
            CASE v_operation.operation_type
                WHEN 'UPDATE_BOOK_STATUS' THEN
                    UPDATE books
                    SET available_copies = (v_operation.operation_data->>'available_copies')::INTEGER
                    WHERE book_id = (v_operation.operation_data->>'book_id')::INTEGER;

                WHEN 'EXPIRE_RESERVATION' THEN
                    UPDATE reservations
                    SET status = 'Expired'
                    WHERE reservation_id = (v_operation.operation_data->>'reservation_id')::INTEGER;

                WHEN 'BLOCK_READER' THEN
                    UPDATE readers
                    SET status = 'Blocked'
                    WHERE reader_id = (v_operation.operation_data->>'reader_id')::INTEGER;
            END CASE;

            UPDATE scheduled_operations
            SET status = 'Executed', executed_at = CURRENT_TIMESTAMP
            WHERE operation_id = v_operation.operation_id;

            v_count := v_count + 1;
        EXCEPTION WHEN OTHERS THEN
            UPDATE scheduled_operations
            SET status = 'Failed',
                executed_at = CURRENT_TIMESTAMP,
                error_message = SQLERRM
            WHERE operation_id = v_operation.operation_id;
        END;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Тестування: створюємо бронювання та плануємо його експірацію
INSERT INTO reservations (book_id, reader_id, expiration_date, status)
VALUES (2, 3, CURRENT_TIMESTAMP + INTERVAL '1 day', 'Active')
RETURNING reservation_id, status;

-- Додаємо завдання в чергу на негайне виконання та завдання на майбутнє
INSERT INTO scheduled_operations (operation_type, target_table, operation_data, scheduled_for)
VALUES
    ('EXPIRE_RESERVATION', 'reservations', jsonb_build_object('reservation_id', 3), CURRENT_TIMESTAMP - INTERVAL '1 second'),
    ('BLOCK_READER', 'readers', jsonb_build_object('reader_id', 4), CURRENT_TIMESTAMP + INTERVAL '5 minutes')
RETURNING operation_id, operation_type, status, scheduled_for;

-- Запускаємо обробник відкладених операцій
SELECT execute_scheduled_operations();

-- Перевіряємо статус завдань та оновлене бронювання
SELECT operation_id, operation_type, status, executed_at, error_message FROM scheduled_operations;
SELECT reservation_id, status FROM reservations WHERE reservation_id = 3;
```

**Результат виконання:**
<img width="1198" height="726" alt="Знімок екрана 2026-11-17 192442" src="https://github.com/user-attachments/assets/c3ad85e6-22f9-4877-8263-4cb68cf4c783" />

---

#### Крок 3. Складна бізнес-логіка

Створено функцію `extend_lending()` для автоматичної пролонгації видачі книги з перевіркою активності видачі, статусу читача та наявності прострочених книг.

```sql
CREATE OR REPLACE FUNCTION extend_lending(
    p_lending_id INTEGER,
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    new_due_date DATE
) AS $$
DECLARE
    v_reader_status VARCHAR(20);
    v_overdue_count INTEGER;
    v_current_due_date DATE;
    v_reader_id INTEGER;
BEGIN
    SELECT r.status, l.due_date, l.reader_id
    INTO v_reader_status, v_current_due_date, v_reader_id
    FROM lendings l
    JOIN readers r ON l.reader_id = r.reader_id
    WHERE l.lending_id = p_lending_id AND l.return_date IS NULL;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Видача не знайдена або книга вже повернена'::TEXT, NULL::DATE;
        RETURN;
    END IF;

    IF v_reader_status = 'Blocked' THEN
        RETURN QUERY SELECT FALSE, 'Читач заблокований'::TEXT, NULL::DATE;
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_overdue_count
    FROM lendings
    WHERE reader_id = v_reader_id
      AND return_date IS NULL
      AND due_date < CURRENT_DATE;

    IF v_overdue_count > 0 THEN
        RETURN QUERY SELECT FALSE, 'У читача є прострочені книги'::TEXT, NULL::DATE;
        RETURN;
    END IF;

    UPDATE lendings
    SET due_date = due_date + p_days
    WHERE lending_id = p_lending_id;

    RETURN QUERY SELECT TRUE, 'Термін продовжено'::TEXT, (v_current_due_date + p_days)::DATE;
END;
$$ LANGUAGE plpgsql;

-- Сценарій 1: Успішне продовження терміну видачі
INSERT INTO lendings (book_id, reader_id, due_date)
VALUES (2, 2, CURRENT_DATE + INTERVAL '7 days')
RETURNING lending_id, due_date;

SELECT * FROM extend_lending(2, 14);

-- Сценарій 2: Відмова через блокування читача
UPDATE readers SET status = 'Blocked' WHERE reader_id = 2;
SELECT * FROM extend_lending(2, 7);

-- Сценарій 3: Відмова через наявність простроченої книги
UPDATE readers SET status = 'Active' WHERE reader_id = 2;
INSERT INTO lendings (book_id, reader_id, lending_date, due_date)
VALUES (3, 2, CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE - INTERVAL '5 days');

SELECT * FROM extend_lending(2, 7);
```

**Результат виконання:**
<img width="993" height="741" alt="Знімок екрана 2026-11-19 010923" src="https://github.com/user-attachments/assets/b818fa1a-929f-474e-b0f9-8bef112efdd3" />

---

#### Крок 4. Система прав доступу (RBAC)

Впроваджено рольову модель розмежування прав доступу (`librarian_read`, `librarian_write`, `library_admin`) та протестовано обмеження на модифікацію даних.

```sql
-- Створення групових ролей
CREATE ROLE librarian_read;
CREATE ROLE librarian_write;
CREATE ROLE library_admin;

-- Надання привілеїв для читання
GRANT SELECT ON ALL TABLES IN SCHEMA public TO librarian_read;

-- Надання привілеїв для операційної роботи бібліотекаря
GRANT SELECT, INSERT, UPDATE ON books, lendings, reservations TO librarian_write;
GRANT DELETE ON reservations TO librarian_write;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO librarian_write;
GRANT INSERT ON audit_log, books_versions TO librarian_write;

-- Повні права для адміністратора
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO library_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO library_admin;

-- Створення користувачів та призначення їм ролей
CREATE USER librarian1 WITH PASSWORD 'secure_password1';
CREATE USER librarian2 WITH PASSWORD 'secure_password2';
CREATE USER admin1 WITH PASSWORD 'admin_password';

GRANT librarian_read TO librarian1;
GRANT librarian_write TO librarian2;
GRANT library_admin TO admin1;

-- Тестування від імені librarian1 (дозволено лише SELECT)
SET ROLE librarian1;
SELECT book_id, title, available_copies FROM books LIMIT 3;
-- Спроба UPDATE викличе ERROR: permission denied for table books
UPDATE books SET available_copies = 5 WHERE book_id = 1;

-- Тестування від імені librarian2 (дозволено UPDATE books, але заборонено DELETE authors)
SET ROLE librarian2;
UPDATE books SET available_copies = 5 WHERE book_id = 1 RETURNING book_id, title, available_copies;
-- Спроба DELETE FROM authors викличе ERROR: permission denied for table authors
DELETE FROM authors WHERE author_id = 5;

-- Повернення до ролі суперкористувача
RESET ROLE;
```

**Результат виконання:**
<img width="1436" height="862" alt="Знімок екрана 2026-11-19 223312" src="https://github.com/user-attachments/assets/1ee13579-1f0a-4795-bbb5-b6952a81d79b" />

---

#### Крок 5. Автоматичне відновлення даних після збоїв

Розроблено механізм створення контрольних знімків бази даних (`backup_points`) у форматі `JSONB` та повного відновлення стану всіх основних таблиць (`restore_from_backup`).

```sql
CREATE TABLE backup_points (
    backup_id SERIAL PRIMARY KEY,
    backup_name VARCHAR(100) NOT NULL,
    backup_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    data_snapshot JSONB
);

-- Функція створення контрольної точки
CREATE OR REPLACE FUNCTION create_backup_point(p_name VARCHAR, p_description TEXT DEFAULT NULL)
RETURNS INTEGER AS $$
DECLARE
    v_backup_id INTEGER;
    v_snapshot JSONB;
BEGIN
    SELECT jsonb_build_object(
        'authors', (SELECT COALESCE(jsonb_agg(row_to_json(a)), '[]'::jsonb) FROM authors a),
        'readers', (SELECT COALESCE(jsonb_agg(row_to_json(r)), '[]'::jsonb) FROM readers r),
        'books',   (SELECT COALESCE(jsonb_agg(row_to_json(b)), '[]'::jsonb) FROM books b),
        'lendings',(SELECT COALESCE(jsonb_agg(row_to_json(l)), '[]'::jsonb) FROM lendings l)
    ) INTO v_snapshot;

    INSERT INTO backup_points (backup_name, description, data_snapshot)
    VALUES (p_name, p_description, v_snapshot)
    RETURNING backup_id INTO v_backup_id;

    RETURN v_backup_id;
END;
$$ LANGUAGE plpgsql;

-- Повна функція відновлення всіх таблиць зі знімка
CREATE OR REPLACE FUNCTION restore_from_backup(p_backup_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_snapshot JSONB;
    v_record JSONB;
BEGIN
    SELECT data_snapshot INTO v_snapshot
    FROM backup_points
    WHERE backup_id = p_backup_id;

    IF v_snapshot IS NULL THEN
        RAISE EXCEPTION 'Backup point % not found', p_backup_id;
    END IF;

    -- Очищуємо таблиці з урахуванням каскадних залежностей
    TRUNCATE TABLE lendings, reservations, books, readers, authors CASCADE;

    -- 1. Відновлюємо авторів
    FOR v_record IN SELECT * FROM jsonb_array_elements(v_snapshot->'authors')
    LOOP
        INSERT INTO authors SELECT * FROM jsonb_populate_record(NULL::authors, v_record);
    END LOOP;

    -- 2. Відновлюємо читачів
    FOR v_record IN SELECT * FROM jsonb_array_elements(v_snapshot->'readers')
    LOOP
        INSERT INTO readers SELECT * FROM jsonb_populate_record(NULL::readers, v_record);
    END LOOP;

    -- 3. Відновлюємо книги
    FOR v_record IN SELECT * FROM jsonb_array_elements(v_snapshot->'books')
    LOOP
        INSERT INTO books SELECT * FROM jsonb_populate_record(NULL::books, v_record);
    END LOOP;

    -- 4. Відновлюємо видачі
    FOR v_record IN SELECT * FROM jsonb_array_elements(v_snapshot->'lendings')
    LOOP
        INSERT INTO lendings SELECT * FROM jsonb_populate_record(NULL::lendings, v_record);
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Тестування створення бекапу та відновлення після збою
SELECT create_backup_point('Before major update', 'Контрольна точка перед оновленням каталогу');

-- Імітуємо випадкове пошкодження даних (зміна назв усіх книг)
UPDATE books SET title = 'ПОШКОДЖЕНИЙ ЗАПИС';
SELECT book_id, title FROM books;

-- Відновлюємо базу даних із контрольної точки №1
SELECT restore_from_backup(1);

-- Перевіряємо, що всі дані успішно повернулися до початкового стану
SELECT book_id, title, available_copies FROM books ORDER BY book_id;
```

**Результат виконання:**
<img width="1432" height="896" alt="Знімок екрана 2026-11-19 224158" src="https://github.com/user-attachments/assets/77d2c6d8-ea77-4373-83cc-9dab862982c2" />

---

#### Крок 6. Інтерфейс перегляду історії змін

Створено представлення `books_change_history` для людиночитабельного відображення аудиту та аналітичну функцію `get_changes_report()` для агрегації змін за обраний період.

```sql
-- Представлення для аналізу історії змін книг
CREATE OR REPLACE VIEW books_change_history AS
SELECT
    a.log_id,
    a.operation,
    a.record_id AS book_id,
    COALESCE(a.new_data->>'title', a.old_data->>'title') AS title,
    CASE
        WHEN a.operation = 'INSERT' THEN 'Додано нову книгу'
        WHEN a.operation = 'UPDATE' THEN
            'Оновлено: ' ||
            CASE
                WHEN a.old_data->>'available_copies' IS DISTINCT FROM a.new_data->>'available_copies'
                THEN 'Доступні примірники: ' || (a.old_data->>'available_copies') || ' → ' || (a.new_data->>'available_copies')
                ELSE 'Інші поля (' || COALESCE(a.new_data->>'title', '') || ')'
            END
        WHEN a.operation = 'DELETE' THEN 'Видалено книгу'
    END AS change_description,
    a.changed_at,
    a.changed_by
FROM audit_log a
WHERE a.table_name = 'books'
ORDER BY a.changed_at DESC;

-- Функція отримання зведеного звіту змін за період
CREATE OR REPLACE FUNCTION get_changes_report(
    p_start_date TIMESTAMP,
    p_end_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
RETURNS TABLE (
    change_date DATE,
    total_changes BIGINT,
    inserts BIGINT,
    updates BIGINT,
    deletes BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(changed_at) AS change_date,
        COUNT(*) AS total_changes,
        COUNT(*) FILTER (WHERE operation = 'INSERT') AS inserts,
        COUNT(*) FILTER (WHERE operation = 'UPDATE') AS updates,
        COUNT(*) FILTER (WHERE operation = 'DELETE') AS deletes
    FROM audit_log
    WHERE changed_at BETWEEN p_start_date AND p_end_date
    GROUP BY DATE(changed_at)
    ORDER BY change_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Тестування інтерфейсу перегляду історії та звіту за останні 30 днів
SELECT * FROM books_change_history LIMIT 10;
SELECT * FROM get_changes_report(CURRENT_TIMESTAMP - INTERVAL '30 days');
```

**Результат виконання:**
<img width="1430" height="888" alt="Знімок екрана 2026-11-23 213446" src="https://github.com/user-attachments/assets/d66ed60c-dbdc-4270-8c86-b5f7d597180b" />

---

## Відповіді на контрольні запитання

1. **Різниця між `INSERT`, `UPDATE`, `DELETE` та обмеження:** `INSERT` додає нові рядки (перевіряються `PRIMARY KEY`, `UNIQUE`, `NOT NULL`, `CHECK`, `FOREIGN KEY`), `UPDATE` змінює існуючі (перевіряються всі ті самі обмеження плюс каскадні правила `ON UPDATE`), а `DELETE` видаляє рядки (перевіряється посилальна цілісність `FOREIGN KEY` у дочірніх таблицях).
2. **Важливість `WHERE` в `UPDATE` та `DELETE`:** Без секції `WHERE` СУБД застосує зміну або видалення до **всіх** рядків таблиці одночасно, що призведе до миттєвої втрати або псування даних у всій таблиці.
3. **Транзакція та властивості ACID:** Транзакція — це логічно неподільна послідовність операцій. **A (Atomicity):** при видачі книги запис у `lendings` і зменшення `available_copies` у `books` або виконуються разом, або обидва скасовуються. **C (Consistency):** транзакція не може залишити `available_copies < 0` або `available_copies > total_copies`. **I (Isolation):** дві паралельні видачі останньої книги не заважають одна одній. **D (Durability):** після `COMMIT` факт видачі книги збережеться навіть при раптовому вимкненні живлення сервера.
4. **Різниця між `COMMIT` та `ROLLBACK`:** `COMMIT` остаточно фіксує всі зміни транзакції на диску та робить їх видимими для інших сесій. `ROLLBACK` скасовує всі незафіксовані зміни поточної транзакції (використовується при помилках або порушенні бізнес-умов).
5. **Точки збереження `SAVEPOINT`:** Дозволяють встановити проміжні мітки всередині транзакції та відкотити лише останню невдалу дію (`ROLLBACK TO SAVEPOINT`), не втрачаючи попередніх успішних операцій цієї ж транзакції.
6. **Типи обмежень цілісності:** `PRIMARY KEY` (унікальний ідентифікатор запису), `FOREIGN KEY` (цілісність зв'язків між таблицями), `UNIQUE` (відсутність дублікатів, наприклад в `isbn` чи `email`), `CHECK` (логічні умови на діапазон значень), `NOT NULL` (обов'язковість заповнення поля).
7. **Каскадні операції:** Визначають реакцію дочірньої таблиці на видалення/зміну батьківського ключа: `RESTRICT` / `NO ACTION` (заборона видалення), `CASCADE` (автоматичне видалення/оновлення залежних записів), `SET NULL` (встановлення `NULL`), `SET DEFAULT` (встановлення дефолтного значення).
8. **Роль тригерів:** Автоматично виконуються при подіях `INSERT/UPDATE/DELETE` на рівні СУБД незалежно від клієнтського застосунку. Застосовуються для незмінного аудиту (`audit_log`), версіонування (`books_versions`) та складної валідації.
9. **Блокування при паралельному доступі:** Запобігають станам гонитви (*race conditions*) та втраченим оновленням (*lost updates*), коли дві сесії одночасно читають однаковий залишок книги (`7`) і обидві записують `6` замість `5`.
10. **Рівні ізоляції транзакцій:** `READ UNCOMMITTED` (у PostgreSQL працює як `READ COMMITTED`), `READ COMMITTED` (за замовчуванням у PG — захищає від «брудного читання», підходить для більшості OLTP-запитів), `REPEATABLE READ` (захищає від неповторюваного читання та фантомів у PG, підходить для фінансових звітів), `SERIALIZABLE` (повна ізоляція, підходить для критичних бізнес-транзакцій зі складними перехресними перевірками).

---

## Висновки

**Самооцінка:** 5

**Обґрунтування:** У ході виконання лабораторної роботи було спроєктовано та реалізовано повнофункціональну базу даних системи управління бібліотекою (`library_lab3`) на найвищому, 3-му рівні складності. Опановано безпечні патерни модифікації даних (`INSERT`, `UPDATE`, `DELETE` з `WHERE` та `RETURNING`), керування транзакціями (`BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`), каскадні обмеження (`ON DELETE RESTRICT` та `ON DELETE CASCADE`) і песимістичні блокування рядків (`SELECT ... FOR UPDATE`) у багатосесійному режимі. Крім того, розроблено повноцінну підсистему аудиту на основі тригерів та `JSONB`, систему темпорального версіонування записів, планувальник відкладених операцій, збережені функції зі складною бізнес-логікою, рольову модель безпеки (RBAC) та механізм резервного копіювання і відновлення даних (Point-in-Time Snapshot Recovery). Робота повністю відповідає всім критеріям оцінки «відмінно».
