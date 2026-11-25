# Електронна бібліотека · Лабораторна робота №4

PostgreSQL, консольний застосунок Python і вебзастосунок Flask.

## Запуск

Потрібні Docker із Docker Compose та Python 3.14. Команди виконуються в папці проєкту.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe manage.py init
.\.venv\Scripts\python.exe manage.py create-user admin@example.test admin
.\.venv\Scripts\python.exe -m web_app.app
```


Вебзастосунок відкривається на [127.0.0.1:8765](http://127.0.0.1:8765). Під час створення облікового запису команда запитує пароль. Реєстрація на сайті надає роль читача. Для створення бібліотекаря у команді `create-user` вкажіть роль `librarian`.

Підключення PostgreSQL для DBeaver за замовчуванням.

| Параметр | Значення |
|---|---|
| Host | `127.0.0.1` |
| Port | `5433` |
| Database | `library_lab04` |
| User | `lab04` |
| Пароль локальної тестової бази | `lab04-local` |

Команда `manage.py init` створює схему й тестові дані під час першого запуску. Для вже створеної схеми вона додає обмеження дат бронювання, якщо його бракує. Для іншого локального пароля задайте змінну `LAB04_DB_PASSWORD` до першого запуску контейнера. У готовому контейнері користувач зберігає поточний пароль. Сервер розробки за замовчуванням доступний лише на цьому комп’ютері.

## Консоль і резервне копіювання

```powershell
.\.venv\Scripts\python.exe -m console_app.main
.\.venv\Scripts\python.exe -m console_app.main --demo
.\.venv\Scripts\python.exe manage.py backup
```


Архів резервної копії зберігається у `backups/`. Команда перевіряє його через `pg_restore --list`. Для PDF використовується системний шрифт з українськими символами. За потреби задайте шлях до TTF-шрифту у змінній `LAB04_PDF_FONT`.

## API

- `GET /api/books` повертає каталог. Параметри `q`, `genre` і `sort` відповідають полям пошуку в інтерфейсі. Значення сортування — `title`, `newest` і `available`.
- `GET /api/books/<id>` повертає одне видання або код 404, якщо його немає.

[Звіт](docs/report.md) · [ER-діаграма](docs/conceptual_model.png) · [Логічна схема](docs/logical_schema.md) · [SQL-запити](database/queries.sql)
