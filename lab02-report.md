# Лабораторна робота 2. Створення складних SQL запитів

## Загальна інформація

**Здобувач освіти:** Дмитерчук Віталій Вадимович                                 
**Група:** ІПЗ-33                                    
**Обраний рівень складності:** 3                              

**Посилання на репозиторій GitHub:** https://github.com/Armovolt/databases-lab-02

## Виконання завдань

### Рівень 1

#### 1. З'єднання таблиць

**Завдання 1.1:** INNER JOIN - список товарів з категоріями та постачальниками

```sql
SELECT p.product_name, c.category_name, s.company_name, p.unit_price
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
ORDER BY c.category_name, p.product_name;
```

**Результат виконання:**
<img width="1537" height="852" alt="image" src="https://github.com/user-attachments/assets/4ee2ffe0-8493-4a4a-89c0-929ca325b9a7" />

**Пояснення:** Цей запит здійснює строге (внутрішнє) з'єднання трьох таблиць: products, categories та suppliers за їхніми первинними та зовнішніми ключами. INNER JOIN відфільтровує записи, що не мають відповідників (наприклад, товари без вказаного постачальника не потраплять до результату). Запит корисний для побудови загального каталогу товарів з деталями.


**Завдання 1.2:** LEFT JOIN - клієнти з кількістю замовлень

```sql
SELECT c.contact_name, c.customer_type, r.region_name, COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN regions r ON c.region_id = r.region_id
GROUP BY c.customer_id, c.contact_name, c.customer_type, r.region_name
ORDER BY order_count DESC;
```

**Результат виконання:**
<img width="1536" height="855" alt="image" src="https://github.com/user-attachments/assets/ecc87e35-90c1-4304-89aa-b91cc2c23be4" />

**Пояснення:** LEFT JOIN гарантує, що у фінальну вибірку потраплять усі клієнти з таблиці customers, навіть якщо вони ще не зробили жодного замовлення (для таких клієнтів COUNT поверне 0). Якби ми тут використали INNER JOIN, клієнти без замовлень просто зникли б зі звіту.


**Завдання 1.3:** Множинне з'єднання - детальна інформація про замовлення

```sql
SELECT 
    o.order_id, 
    o.order_date, 
    c.contact_name AS customer,
    e.first_name || ' ' || e.last_name AS manager,
    p.product_name, 
    oi.quantity, 
    oi.unit_price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN employees e ON o.employee_id = e.employee_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_id DESC 
LIMIT 10;
```

**Результат виконання:**
<img width="1531" height="851" alt="image" src="https://github.com/user-attachments/assets/9a56bf12-34b7-41f9-bfa7-7561b90a158b" />

**Аналіз складності:** Запит об'єднує 5 таблиць (orders, customers, employees, order_items, products). Послідовність з'єднань логічно розходиться від центральної сутності orders до довідників клієнтів і співробітників, а потім деталізується до позицій замовлення (order_items) та самих товарів (products). Це класичний OLTP-запит для генерації деталізованого чека/накладної.


#### 2. Агрегатні функції

**Завдання 2.1:** Статистика товарів за категоріями

```sql
SELECT c.category_name,
       COUNT(p.product_id) as product_count,
       AVG(p.unit_price) as avg_price,
       MIN(p.unit_price) as min_price,
       MAX(p.unit_price) as max_price
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC;
```

**Результат виконання:**
<img width="1537" height="852" alt="image" src="https://github.com/user-attachments/assets/f7fef1c8-844a-40bb-a1dc-906647806b6a" />


**Завдання 2.2:** Продажі за регіонами з використанням HAVING

```sql
SELECT r.region_name, 
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) as total_sales, 
       COUNT(DISTINCT o.order_id) as total_orders
FROM regions r
JOIN customers c ON r.region_id = c.region_id
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY r.region_name
HAVING SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) > 50000
ORDER BY total_sales DESC;
```

**Результат виконання:**
<img width="1540" height="707" alt="image" src="https://github.com/user-attachments/assets/e9eba8e1-0ad9-4776-b6ec-b0d477522d63" />


**Завдання 2.3:** Постачальники з кількістю товарів більше 2

```sql
SELECT s.company_name, COUNT(p.product_id) as product_count
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
GROUP BY s.company_name
HAVING COUNT(p.product_id) > 2
ORDER BY product_count DESC;
```

**Результат виконання:**
<img width="1538" height="663" alt="image" src="https://github.com/user-attachments/assets/f87f3967-d9c0-4959-87d6-92ee9abe808b" />


#### 3. Базові підзапити

**Завдання 3.1:** Товари з ціною вище середньої по категорії

```sql
SELECT p.product_name, p.unit_price, c.category_name
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY c.category_name, p.unit_price DESC;
```

**Результат виконання:**
<img width="1539" height="850" alt="image" src="https://github.com/user-attachments/assets/3a5c55ca-ba9b-48eb-8d86-60334be34b4c" />


**Завдання 3.2:** Клієнти з замовленнями у 2024 році

```sql
SELECT customer_id, contact_name, city
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2024
);
```

**Результат виконання:**
<img width="1530" height="854" alt="image" src="https://github.com/user-attachments/assets/33c19faf-6217-48ac-a4cc-5c3284a55fb6" />


**Завдання 3.3:** Товари з загальною кількістю продажів

```sql
SELECT product_name, unit_price,
       (SELECT COALESCE(SUM(quantity), 0) 
        FROM order_items 
        WHERE product_id = p.product_id) as total_sold_quantity
FROM products p
ORDER BY total_sold_quantity DESC;
```

**Результат виконання:**
<img width="1541" height="849" alt="image" src="https://github.com/user-attachments/assets/7a54e9b4-ac7c-4ca1-80f2-5866093195b9" />


### Рівень 2

#### 4. Складні з'єднання

**Завдання 4.1:** RIGHT JOIN - аналіз категорій та товарів

```sql
SELECT c.category_name,
       COUNT(p.product_id) as products_count,
       COALESCE(AVG(p.unit_price), 0) as avg_price
FROM products p
RIGHT JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY products_count DESC;
```

**Результат виконання:**
<img width="1531" height="849" alt="image" src="https://github.com/user-attachments/assets/b27cc91d-9f29-4177-b087-a00e03213b04" />


**Завдання 4.2:** Self-join - співробітники та керівники

```sql
SELECT e1.first_name || ' ' || e1.last_name as employee,
       e1.title as employee_title,
       e2.first_name || ' ' || e2.last_name as manager,
       e2.title as manager_title
FROM employees e1
LEFT JOIN employees e2 ON e1.reports_to = e2.employee_id
ORDER BY e2.last_name NULLS FIRST, e1.last_name;
```

**Результат виконання:**
<img width="1534" height="781" alt="image" src="https://github.com/user-attachments/assets/085e3cfe-9c06-482f-beed-2cbca70e5984" />


#### 5. Віконні функції

**Завдання 5.1:** Ранжування товарів за ціною в категоріях

```sql
SELECT p.product_name,
       c.category_name,
       p.unit_price,
       RANK() OVER (PARTITION BY c.category_name ORDER BY p.unit_price DESC) as price_rank,
       DENSE_RANK() OVER (PARTITION BY c.category_name ORDER BY p.unit_price DESC) as price_dense_rank,
       ROW_NUMBER() OVER (PARTITION BY c.category_name ORDER BY p.unit_price DESC) as row_num
FROM products p
JOIN categories c ON p.category_id = c.category_id
ORDER BY c.category_name, p.unit_price DESC;
```

**Результат виконання:**
<img width="1536" height="849" alt="image" src="https://github.com/user-attachments/assets/9af9ddcf-bdd6-48ce-b0f2-b204a75fd29a" />


**Завдання 5.2:** Порівняння замовлень з попередніми датами

```sql
SELECT o.customer_id,
       o.order_id,
       o.order_date,
       LAG(o.order_date) OVER(PARTITION BY o.customer_id ORDER BY o.order_date) as prev_order_date,
       o.order_date - LAG(o.order_date) OVER(PARTITION BY o.customer_id ORDER BY o.order_date) as days_since_last_order
FROM orders o
ORDER BY o.customer_id, o.order_date;
```

**Результат виконання:**
<img width="1534" height="848" alt="image" src="https://github.com/user-attachments/assets/8ed51950-369b-4b07-b0ba-b8630abaa759" />


### Рівень 3

#### 6. Матеріалізовані представлення та рекурсивні запити

**Завдання 6.1:** Матеріалізоване представлення для аналізу продажів

```sql
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT
    EXTRACT(YEAR FROM o.order_date) as year,
    EXTRACT(MONTH FROM o.order_date) as month,
    c.category_name,
    r.region_name,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) as total_revenue,
    COUNT(DISTINCT o.order_id) as orders_count,
    AVG(oi.quantity * oi.unit_price * (1 - oi.discount)) as avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN customers cu ON o.customer_id = cu.customer_id
LEFT JOIN regions r ON cu.region_id = r.region_id
WHERE o.order_status = 'delivered'
GROUP BY year, month, c.category_name, r.region_name;

CREATE INDEX idx_mv_monthly_sales_date ON mv_monthly_sales(year, month);
```

**Результат виконання:**
<img width="1539" height="682" alt="image" src="https://github.com/user-attachments/assets/78559d7b-b7d1-46f6-b24d-e5a863f08df2" />

**Пояснення:** На відміну від звичайних View, матеріалізовані представлення (Materialized Views) фізично зберігають результат виконання складного запиту на диску. Перевага полягає в кардинальному прискоренні роботи аналітичних дашбордів (OLAP), оскільки базі не потрібно щоразу "на льоту" обчислювати агрегати та з'єднувати велику кількість таблиць (6 таблиць у цьому прикладі).


**Завдання 6.2:** Рекурсивний запит для ієрархії співробітників

```sql
WITH RECURSIVE employee_hierarchy AS (
    -- Базовий випадок: топ-менеджери
    SELECT employee_id, first_name, last_name, title, reports_to,
           0 as level,
           CAST(last_name || ' ' || first_name as VARCHAR(1000)) as hierarchy_path
    FROM employees
    WHERE reports_to IS NULL
    
    UNION ALL
    
    -- Рекурсивний випадок: підлеглі
    SELECT e.employee_id, e.first_name, e.last_name, e.title, e.reports_to,
           eh.level + 1,
           CAST(eh.hierarchy_path || ' -> ' || e.last_name || ' ' || e.first_name as VARCHAR(1000))
    FROM employees e
    JOIN employee_hierarchy eh ON e.reports_to = eh.employee_id
)
SELECT * FROM employee_hierarchy
ORDER BY hierarchy_path;
```

**Результат виконання:**
<img width="1531" height="847" alt="image" src="https://github.com/user-attachments/assets/9dc4ddb8-f070-4dfc-b81d-621c83071dbc" />
