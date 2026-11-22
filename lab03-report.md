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
