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

![Створення таблиць](screenshots/01-create-tables.png)

---
