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
