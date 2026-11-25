INSERT INTO authors (full_name) VALUES
('Леся Українка'), ('Тарас Шевченко'), ('Іван Франко'), ('Ольга Кобилянська'),
('Михайло Коцюбинський'), ('Іван Нечуй-Левицький'), ('Панас Мирний'),
('Іван Білик'), ('Валер’ян Підмогильний'), ('Микола Хвильовий');

-- Умовні ISBN для навчальних даних.
INSERT INTO books (isbn, title, genre, published_year) VALUES
('9900000000001', 'Лісова пісня', 'Драма', 1911),
('9900000000002', 'Кобзар', 'Поезія', 1840),
('9900000000003', 'Захар Беркут', 'Проза', 1883),
('9900000000004', 'Земля', 'Проза', 1902),
('9900000000005', 'Тіні забутих предків', 'Проза', 1911),
('9900000000006', 'Кайдашева сім’я', 'Проза', 1879),
('9900000000007', 'Хіба ревуть воли, як ясла повні?', 'Проза', 1880),
('9900000000008', 'Місто', 'Проза', 1928),
('9900000000009', 'Я (Романтика)', 'Новела', 1924),
('9900000000010', 'Камінний господар', 'Драма', 1912),
('9900000000011', 'Мойсей', 'Поезія', 1905),
('9900000000012', 'Intermezzo', 'Новела', 1908);

INSERT INTO book_authors (book_id, author_id)
VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(7,8),(8,9),(9,10),(10,1),(11,3),(12,5);

INSERT INTO copies (book_id, inventory_code)
SELECT b.book_id, 'LIB-' || lpad(b.book_id::text, 2, '0') || '-' || n
FROM books AS b CROSS JOIN generate_series(1, 2) AS n
ORDER BY b.book_id, n;

INSERT INTO readers (full_name, email, active) VALUES
('Марія Ткачук','reader01@example.test',true),('Олег Бондар','reader02@example.test',true),
('Ірина Коваль','reader03@example.test',true),('Андрій Лісовий','reader04@example.test',true),
('Софія Мельник','reader05@example.test',true),('Іван Олійник','reader06@example.test',true),
('Наталія Романюк','reader07@example.test',true),('Віктор Кравчук','reader08@example.test',true),
('Олена Петренко','reader09@example.test',true),('Данило Савчук','reader10@example.test',false);

INSERT INTO loans (copy_id, reader_id, issued_on, due_on, returned_on) VALUES
(1,1,CURRENT_DATE-27,CURRENT_DATE-13,CURRENT_DATE-15),
(3,2,CURRENT_DATE-25,CURRENT_DATE-11,CURRENT_DATE-10),
(5,3,CURRENT_DATE-23,CURRENT_DATE-9,CURRENT_DATE-12),
(7,4,CURRENT_DATE-21,CURRENT_DATE-7,CURRENT_DATE-8),
(9,5,CURRENT_DATE-20,CURRENT_DATE-6,CURRENT_DATE-5),
(11,6,CURRENT_DATE-18,CURRENT_DATE-4,CURRENT_DATE-4),
(1,7,CURRENT_DATE-16,CURRENT_DATE-2,NULL),
(3,8,CURRENT_DATE-12,CURRENT_DATE+2,NULL),
(5,9,CURRENT_DATE-10,CURRENT_DATE+4,NULL),
(7,1,CURRENT_DATE-7,CURRENT_DATE+7,NULL),
(9,2,CURRENT_DATE-6,CURRENT_DATE+8,NULL),
(11,3,CURRENT_DATE-5,CURRENT_DATE+9,NULL);

INSERT INTO reservations (book_id, reader_id, requested_at, expires_on, status) VALUES
(1,1,CURRENT_TIMESTAMP-INTERVAL '18 days',CURRENT_DATE-11,'fulfilled'),
(2,2,CURRENT_TIMESTAMP-INTERVAL '17 days',CURRENT_DATE-10,'fulfilled'),
(3,3,CURRENT_TIMESTAMP-INTERVAL '16 days',CURRENT_DATE-9,'fulfilled'),
(4,4,CURRENT_TIMESTAMP-INTERVAL '15 days',CURRENT_DATE-8,'cancelled'),
(5,5,CURRENT_TIMESTAMP-INTERVAL '14 days',CURRENT_DATE-7,'expired'),
(6,6,CURRENT_TIMESTAMP-INTERVAL '13 days',CURRENT_DATE-6,'expired'),
(7,7,CURRENT_TIMESTAMP-INTERVAL '12 days',CURRENT_DATE-5,'fulfilled'),
(8,8,CURRENT_TIMESTAMP-INTERVAL '11 days',CURRENT_DATE-4,'cancelled'),
(9,9,CURRENT_TIMESTAMP-INTERVAL '2 days',CURRENT_DATE+5,'pending'),
(10,1,CURRENT_TIMESTAMP-INTERVAL '1 day',CURRENT_DATE+6,'pending');

