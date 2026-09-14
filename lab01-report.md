# Лабораторна робота 1. Робота з СУБД PostgreSQL та основи SQL

## Загальна інформація

**Здобувач освіти:** Дмитерчук Віталій Вадимович             
**Група:** ІПЗ-33                     
**Обраний рівень складності:** 3               
                         
## Виконання завдань

### Список таблиць

```sql
-- Запит для отримання списку таблиць
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

**Результат:** У базі даних створено 8 основних таблиць: categories, customers, employees, order_items, orders, products, regions, suppliers.

<img width="1532" height="850" alt="image" src="https://github.com/user-attachments/assets/295c1360-459f-44cd-b4c3-5b6aab622da8" />

### РІВЕНЬ 1: Основні запити
**1.1. Отримати всі записи з таблиці customers.**
```sql
SELECT * FROM customers;
```
**Результат:** Отримано 15 записів клієнтів (фізичні та юридичні особи).

<img width="1535" height="857" alt="image" src="https://github.com/user-attachments/assets/d37020c7-b977-434c-8bf1-ee7322dbbef0" />

**1.2. Вивести тільки назви товарів і їхні ціни з таблиці products.**
```sql
SELECT product_name, unit_price FROM products;
```
<img width="1533" height="852" alt="image" src="https://github.com/user-attachments/assets/491f980e-2494-4838-839f-6e8a1579faf7" />

**1.3. Показати контактні дані всіх співробітників.**
```sql
SELECT first_name, last_name, phone, email FROM employees;
```
<img width="1536" height="850" alt="image" src="https://github.com/user-attachments/assets/03d12212-13f6-4fb2-8427-6fd20c1b351b" />

**1.4. Знайти всіх клієнтів з міста Київ.**
```sql
SELECT * FROM customers WHERE city = 'Київ';
```
<img width="1534" height="848" alt="image" src="https://github.com/user-attachments/assets/1ec04b4b-b8d5-420a-9737-7d2fee746d76" />

**1.5. Вивести товари, які коштують більше 25000 грн.**
```sql
SELECT * FROM products WHERE unit_price > 25000;
```
<img width="1534" height="856" alt="image" src="https://github.com/user-attachments/assets/0ae89bc7-0d45-4029-871e-9bfee61ed4da" />

**1.6. Показати всі замовлення зі статусом 'delivered'.**
```sql
SELECT * FROM orders WHERE order_status = 'delivered';
```
<img width="1531" height="853" alt="image" src="https://github.com/user-attachments/assets/5fa4b277-f30e-4203-b133-b16e3abfd6c9" />

**1.7. Знайти співробітників відділу продажів (посада містить "продаж").**
```sql
SELECT * FROM employees WHERE title ILIKE '%продаж%';
```
<img width="1533" height="851" alt="image" src="https://github.com/user-attachments/assets/c9e63cd9-03a7-47b1-8018-3843ffd50d1a" />

**1.8. Відсортувати товари за зростанням ціни.**
```sql
SELECT * FROM products ORDER BY unit_price ASC;
```
<img width="1539" height="850" alt="image" src="https://github.com/user-attachments/assets/63a986a7-ddfe-4bff-84f9-c6a8a9170069" />

**1.9. Показати клієнтів в алфавітному порядку за іменем контактної особи.**
```sql
SELECT * FROM customers ORDER BY contact_name ASC;
```
<img width="1537" height="850" alt="image" src="https://github.com/user-attachments/assets/2a654558-d8a6-4d4f-80c3-3239a9117a0d" />

**1.10. Вивести замовлення від найновіших до найстаріших.**
```sql
SELECT * FROM orders ORDER BY order_date DESC;
```
<img width="1536" height="851" alt="image" src="https://github.com/user-attachments/assets/59559149-870f-48af-9e81-2dcc4d1f7dac" />

**1.11. Показати перші 10 найдорожчих товарів.**
```sql
SELECT * FROM products ORDER BY unit_price DESC LIMIT 10;
```
<img width="1531" height="855" alt="image" src="https://github.com/user-attachments/assets/e7d8c061-e2f3-4e67-89f4-99fd8ce41e7a" />

**1.12. Вивести 5 останніх замовлень (за датою).**
```sql
SELECT * FROM orders ORDER BY order_date DESC LIMIT 5;
```
<img width="1532" height="853" alt="image" src="https://github.com/user-attachments/assets/66a07f5c-fa83-4ee3-b533-a9270fb3a5a7" />

**1.13. Отримати перших 8 клієнтів в алфавітному порядку.**
```sql
SELECT * FROM customers ORDER BY contact_name ASC LIMIT 8;
```
<img width="1537" height="854" alt="image" src="https://github.com/user-attachments/assets/917f95aa-0616-4483-9f7d-f30fa5afab82" />

### РІВЕНЬ 2: Розширені умови та логічні оператори
**2.1. Знайти всіх клієнтів, чиї імена починаються на "Іван".**
```sql
SELECT * FROM customers WHERE contact_name ILIKE 'Іван%';
```
<img width="1535" height="850" alt="image" src="https://github.com/user-attachments/assets/2cea5497-7c21-4d1e-a67f-698cb173d43f" />

**2.2. Вивести товари, в назві яких є слово "phone" або "телефон".**
```sql
SELECT * FROM products WHERE product_name ILIKE '%phone%' OR product_name ILIKE '%телефон%';
```
<img width="1536" height="850" alt="image" src="https://github.com/user-attachments/assets/ee068ac2-2d76-44ce-904d-d6c6e01de947" />

**2.3. Самостійно: 3 власні запити з використанням LIKE (початок, кінець, містить).**
```sql
-- 1 (Початок): Знайти всі товари бренду Samsung
SELECT * FROM products WHERE product_name ILIKE 'Samsung%';

-- 2 (Кінець): Виділити клієнтів з поштою Gmail для email-розсилки
SELECT * FROM customers WHERE email ILIKE '%@gmail.com';

-- 3 (Містить): Знайти всіх керівників/директорів серед співробітників
SELECT * FROM employees WHERE title ILIKE '%директор%';
```
<img width="1538" height="849" alt="image" src="https://github.com/user-attachments/assets/48303877-ff36-4d1d-82a4-7acdedb90e5c" />

**2.4. Знайти товари дорожчі за 15000 грн і дешевші за 50000 грн.**
```sql
SELECT * FROM products WHERE unit_price > 15000 AND unit_price < 50000;
```
<img width="1540" height="849" alt="image" src="https://github.com/user-attachments/assets/7a0a0ed0-0a37-4cf9-90b4-be8b09325feb" />

**2.5. Вивести клієнтів з Києва або Львова, які є юридичними особами.**
```sql
SELECT * FROM customers WHERE (city = 'Київ' OR city = 'Львів') AND customer_type = 'company';
```
<img width="1533" height="851" alt="image" src="https://github.com/user-attachments/assets/1995eab8-a14d-43b3-b7fa-f6c46eea73fa" />

**2.6. Самостійно: 4 запити з комбінаціями логічних операторів.**
```sql
-- 1. Товари, які закінчуються на складі (менше 10 шт), але не зняті з виробництва
SELECT * FROM products WHERE units_in_stock < 10 AND discontinued = false;

-- 2. Замовлення, які зараз знаходяться в процесі обробки
SELECT * FROM orders WHERE order_status = 'pending' OR order_status = 'processing';

-- 3. Регіональні фізичні особи (не з Києва)
SELECT * FROM customers WHERE city != 'Київ' AND customer_type = 'individual';

-- 4. Преміум смартфони (категорія 1, ціна > 20000)
SELECT * FROM products WHERE category_id = 1 AND unit_price > 20000;
```
<img width="1537" height="852" alt="image" src="https://github.com/user-attachments/assets/9052358c-bd47-495a-b244-a5fb4c8fd785" />

**2.7. Вивести клієнтів з міст Київ, Харків, Одеса, Дніпро.**
```sql
SELECT * FROM customers WHERE city IN ('Київ', 'Харків', 'Одеса', 'Дніпро');
```
<img width="1535" height="857" alt="image" src="https://github.com/user-attachments/assets/5311bb4d-a3ae-426a-a6e0-175042e8b360" />

**2.8. Знайти товари в ціновому діапазоні від 10000 до 30000 грн.**
```sql
SELECT * FROM products WHERE unit_price BETWEEN 10000 AND 30000;
```
<img width="1533" height="855" alt="image" src="https://github.com/user-attachments/assets/9a0316b6-7daa-43aa-909d-9870e570883b" />

**2.9. Самостійно: по 2 запити для IN, BETWEEN, IS NULL/IS NOT NULL.**
```sql
-- IN (1): Співробітники ключових філій
SELECT * FROM employees WHERE city IN ('Київ', 'Львів');
-- IN (2): Електроніка (смартфони, ноути, планшети)
SELECT * FROM products WHERE category_id IN (1, 2, 7);

-- BETWEEN (1): Замовлення за 1-й квартал 2024 року
SELECT * FROM orders WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';
-- BETWEEN (2): Співробітники із середнім рівнем зарплат
SELECT * FROM employees WHERE salary BETWEEN 20000 AND 30000;

-- IS NULL: Клієнти без компанії (додаткова перевірка фіз. осіб)
SELECT * FROM customers WHERE company_name IS NULL;
-- IS NOT NULL: Відправлені замовлення (де дата відправки вже зафіксована)
SELECT * FROM orders WHERE shipped_date IS NOT NULL;
```
<img width="1533" height="852" alt="image" src="https://github.com/user-attachments/assets/6ecfc350-0055-46a8-969f-ba7b34e94caa" />

**2.10. Самостійно (Комбінування умов): 5 складних запитів.**
```sql
-- 1. Доступні ноутбуки або смартфони в певному бюджеті
SELECT * FROM products WHERE (category_id = 1 OR category_id = 2) AND unit_price BETWEEN 20000 AND 40000 AND units_in_stock > 0;

-- 2. Користувачі Gmail з великих міст
SELECT * FROM customers WHERE email ILIKE '%@gmail.com' AND city IN ('Київ', 'Одеса');

-- 3. Нові замовлення, які ще в обробці (серпень 2024 і далі)
SELECT * FROM orders WHERE order_status IN ('pending', 'processing') AND order_date >= '2024-08-01';

-- 4. Товари Apple, які дорожчі за 10к та виробляються
SELECT * FROM products WHERE product_name ILIKE '%apple%' AND unit_price > 10000 AND discontinued = false;

-- 5. Рядові співробітники (є керівник) з Києва із ЗП менше 25000
SELECT * FROM employees WHERE reports_to IS NOT NULL AND salary < 25000 AND city = 'Київ';
```
<img width="1537" height="848" alt="image" src="https://github.com/user-attachments/assets/7ecca7f2-1464-4b4b-81ee-903f37f305ce" />

**2.11. Самостійно: 3 запити з сортуванням та 2 з OFFSET.**
```sql
-- Сортування 1: Товари спочатку за категорією, а в межах неї - від найдорожчого
SELECT * FROM products ORDER BY category_id ASC, unit_price DESC;

-- Сортування 2: Співробітники за містом і за зарплатою
SELECT * FROM employees ORDER BY city ASC, salary DESC;

-- Сортування 3: Замовлення за статусом, а потім за датою спадання
SELECT * FROM orders ORDER BY order_status ASC, order_date DESC;

-- Пагінація 1: Друга "сторінка" списку товарів (по 10 на сторінку)
SELECT * FROM products ORDER BY product_id LIMIT 10 OFFSET 10;

-- Пагінація 2: Пропустити 3 найновіші замовлення і показати наступні 5
SELECT * FROM orders ORDER BY order_date DESC LIMIT 5 OFFSET 3;
```
<img width="1536" height="850" alt="image" src="https://github.com/user-attachments/assets/8b56dc9e-8304-4326-8436-3332ca977948" />

### РІВЕНЬ 3: Комплексна аналітика
**3.1. Знайти товари, в назві яких є "Samsung" або "Apple", але немає слова "чохол".**
```sql
SELECT * FROM products 
WHERE (product_name ILIKE '%Samsung%' OR product_name ILIKE '%Apple%') 
AND product_name NOT ILIKE '%чохол%';
```
<img width="1533" height="846" alt="image" src="https://github.com/user-attachments/assets/dce1228a-42fa-4704-9cc1-841b76f0c2ce" />

**3.2. Самостійно: 4 складні запити з комбінаціями LIKE та логіки.**
```sql
-- 1. Флагмани Pro/Plus версій без кабелів
SELECT * FROM products WHERE (product_name ILIKE '%Pro%' OR product_name ILIKE '%Plus%') AND product_name NOT ILIKE '%кабель%';

-- 2. Клієнти на ім'я Іван із найпопулярнішими поштовиками
SELECT * FROM customers WHERE (email ILIKE '%@ukr.net' OR email ILIKE '%@gmail.com') AND contact_name ILIKE 'Іван%';

-- 3. Пошук ТОВ, які знаходяться на "вулицях" (а не на проспектах)
SELECT * FROM suppliers WHERE company_name ILIKE '%ТОВ%' AND address ILIKE '%вул.%';

-- 4. 4K OLED пристрої в описі
SELECT * FROM products WHERE description ILIKE '%oled%' AND description ILIKE '%4k%';
```
<img width="1534" height="851" alt="image" src="https://github.com/user-attachments/assets/1ef6310a-b498-49a7-bd53-4b09134596c8" />

**3.3. Знайти товари дорожчі 20000 грн (категорії 1 або 2) АБО товари дешевші 5000 грн будь-якої категорії.**
```sql
SELECT * FROM products 
WHERE (unit_price > 20000 AND category_id IN (1, 2)) OR (unit_price < 5000);
```
<img width="1537" height="852" alt="image" src="https://github.com/user-attachments/assets/b2d6107c-7fd6-4a91-b115-94c558d679d2" />

**3.4. Самостійно: 3 запити з складними вкладеними умовами.**
```sql
-- 1. Проблемні замовлення (дорога доставка або старі "завислі")
SELECT * FROM orders WHERE (order_status = 'delivered' AND freight > 200) OR (order_status = 'pending' AND order_date < '2024-08-15');

-- 2. Сегментація ключових B2B клієнтів з Києва або нових фізичних осіб
SELECT * FROM customers WHERE (customer_type = 'company' AND city = 'Київ') OR (customer_type = 'individual' AND registration_date > '2023-06-01');

-- 3. Менеджмент високого рівня або рядові співробітники з малою зарплатою
SELECT * FROM employees WHERE (salary > 30000 AND title ILIKE '%директор%') OR (salary < 25000 AND reports_to IS NOT NULL);
```
<img width="1535" height="846" alt="image" src="https://github.com/user-attachments/assets/16fb932c-89ca-4187-9eea-5fd8837b3320" />

**3.5. Самостійно: Комплексні аналітичні запити.**
```sql
-- Звіт товарів з 5+ умовами: Доступна техніка високого класу, яка не знята з виробництва та є на складі (від 5 до 20 шт)
SELECT * FROM products 
WHERE unit_price > 10000 
  AND units_in_stock >= 5 
  AND units_in_stock <= 20 
  AND category_id IN (1, 2, 3) 
  AND discontinued = false 
ORDER BY unit_price DESC;

-- Аналіз ключових B2B клієнтів: компанії з великих міст, що мають email та зареєстровані до 2024 року
SELECT * FROM customers 
WHERE customer_type = 'company' 
  AND city IN ('Київ', 'Дніпро', 'Харків') 
  AND email IS NOT NULL 
  AND registration_date < '2024-01-01' 
ORDER BY registration_date;
```
<img width="1535" height="856" alt="image" src="https://github.com/user-attachments/assets/82232f9c-fcb5-4133-8753-754fd06a1362" />

**3.6. Самостійно: Дослідження даних (сегменти, географія, час).**
```sql
-- Цінові сегменти:
SELECT * FROM products WHERE unit_price < 10000; -- Бюджетні
SELECT * FROM products WHERE unit_price BETWEEN 10000 AND 30000; -- Середній клас
SELECT * FROM products WHERE unit_price > 30000; -- Преміум сегмент

-- Географія клієнтів:
SELECT * FROM customers WHERE city IN ('Київ', 'Житомир'); -- Центр
SELECT * FROM customers WHERE city IN ('Львів', 'Івано-Франківськ'); -- Захід
SELECT * FROM customers WHERE city IN ('Одеса', 'Миколаїв', 'Херсон'); -- Південь
SELECT * FROM customers WHERE city IN ('Харків', 'Дніпро', 'Запоріжжя'); -- Схід

-- Часові патерни замовлень:
SELECT * FROM orders WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31'; -- Січень
SELECT * FROM orders WHERE order_date BETWEEN '2024-06-01' AND '2024-08-31'; -- Літо
SELECT * FROM orders WHERE order_date >= '2024-08-01'; -- Серпень (поточні активні)
```
<img width="1537" height="850" alt="image" src="https://github.com/user-attachments/assets/f38b5f0b-1c4a-43e4-98c9-dd1045d065bc" />

**3.7. Самостійно: 5 креативних запитів.**
```sql
-- 1. Оцінка капіталізації складу (вартість залишків конкретних товарів)
SELECT product_name, units_in_stock * unit_price AS total_inventory_value 
FROM products ORDER BY total_inventory_value DESC LIMIT 5;

-- 2. Товари, які терміново потребують дозамовлення (залишки менші або дорівнюють критичному рівню)
SELECT product_name, units_in_stock, reorder_level 
FROM products WHERE units_in_stock <= reorder_level AND discontinued = false;

-- 3. Розподіл товарів за ціновими "тирами" (за допомогою CASE)
SELECT product_name, unit_price, 
  CASE 
    WHEN unit_price < 10000 THEN 'Budget' 
    WHEN unit_price < 30000 THEN 'Mid-range' 
    ELSE 'Premium' 
  END as price_tier 
FROM products;

-- 4. Оцінка ефективної дати (якщо не доставлено, то беремо дату замовлення)
SELECT order_id, order_status, COALESCE(shipped_date, order_date) as effective_action_date 
FROM orders;

-- 5. Пошук контактів співробітників, які не мають визначеного середнього імені (middle_name)
SELECT first_name, last_name, COALESCE(middle_name, 'Не вказано') as middle_name 
FROM employees WHERE middle_name IS NULL;
```
<img width="1533" height="853" alt="image" src="https://github.com/user-attachments/assets/8be846a4-eed4-4333-a00e-377c750b2cfd" />

## Висновки
**Самооцінка:** 5             
**Обгрунтування:** В ході виконання лабораторної роботи було створено хмарну базу даних PostgreSQL на платформі Supabase, проведено успішний імпорт структури та даних technomart.sql. Було виконано абсолютно всі завдання 1, 2 та 3 рівнів складності. Самостійно спроєктовано бізнес-логіку для розширених, аналітичних та креативних запитів, які демонструють глибоке розуміння різних операторів SQL (LIKE/ILIKE, BETWEEN, IN, IS NULL, CASE, COALESCE) та умов логіки (AND/OR з пріоритетами і дужками). Робота повністю відповідає критеріям на високий рівень ("відмінно").
