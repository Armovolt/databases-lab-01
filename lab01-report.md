# Лабораторна робота 1. Робота з СУБД PostgreSQL та основи SQL

## Загальна інформація

**Здобувач освіти:** Дмитерчук Віталій Вадимович             
**Група:** ІПЗ-33                     
**Обраний рівень складності:** 3               
                         
## Виконання завдань

### Список таблиць

```
sql -- Запит для отримання списку таблиць
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

**Результат:** У базі даних створено 8 основних таблиць: categories, customers, employees, order_items, orders, products, regions, suppliers.

<img width="1532" height="850" alt="image" src="https://github.com/user-attachments/assets/295c1360-459f-44cd-b4c3-5b6aab622da8" />

### РІВЕНЬ 1: Основні запити
**1.1. Отримати всі записи з таблиці customers.**
```
SELECT * FROM customers;
```
**Результат:** Отримано 15 записів клієнтів (фізичні та юридичні особи).

<img width="1535" height="857" alt="image" src="https://github.com/user-attachments/assets/d37020c7-b977-434c-8bf1-ee7322dbbef0" />

**1.2. Вивести тільки назви товарів і їхні ціни з таблиці products.**
```
SELECT product_name, unit_price FROM products;
```
<img width="1533" height="852" alt="image" src="https://github.com/user-attachments/assets/491f980e-2494-4838-839f-6e8a1579faf7" />

**1.3. Показати контактні дані всіх співробітників.**
```
SELECT first_name, last_name, phone, email FROM employees;
```
<img width="1536" height="850" alt="image" src="https://github.com/user-attachments/assets/03d12212-13f6-4fb2-8427-6fd20c1b351b" />

**1.4. Знайти всіх клієнтів з міста Київ.**
```
SELECT * FROM customers WHERE city = 'Київ';
```
<img width="1534" height="848" alt="image" src="https://github.com/user-attachments/assets/1ec04b4b-b8d5-420a-9737-7d2fee746d76" />

**1.5. Вивести товари, які коштують більше 25000 грн.**
```
SELECT * FROM products WHERE unit_price > 25000;
```
<img width="1534" height="856" alt="image" src="https://github.com/user-attachments/assets/0ae89bc7-0d45-4029-871e-9bfee61ed4da" />

**1.6. Показати всі замовлення зі статусом 'delivered'.**
```
SELECT * FROM orders WHERE order_status = 'delivered';
```
<img width="1531" height="853" alt="image" src="https://github.com/user-attachments/assets/5fa4b277-f30e-4203-b133-b16e3abfd6c9" />
