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
