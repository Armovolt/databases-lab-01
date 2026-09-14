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

Результат: У базі даних створено 8 основних таблиць: categories, customers, employees, order_items, orders, products, regions, suppliers.

<img width="1532" height="850" alt="image" src="https://github.com/user-attachments/assets/295c1360-459f-44cd-b4c3-5b6aab622da8" />
