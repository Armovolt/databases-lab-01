from argparse import ArgumentParser

from psycopg import Error

from database import add_book, catalog, connect, delete_book, edit_book, find_book


def fields():
    return {key: input(label + ": ") for key, label in (
        ("isbn", "ISBN"), ("title", "Назва"), ("genre", "Жанр"), ("published_year", "Рік видання")
    )}


def run_demo():
    sample = dict(isbn="9900000099001", title="Тестове видання", genre="Драма", published_year="2024")
    conn = connect("console-demo")
    try:
        print("Електронна бібліотека · перевірка CRUD")
        print("База:", conn.info.dbname)
        book_id = add_book(conn, sample)
        print(f"CREATE   #{book_id} — {sample['title']}")
        print(f"READ     #{book_id} — {find_book(conn, book_id)['title']}")
        edit_book(conn, book_id, {**sample, "title": "Оновлене тестове видання"})
        print(f"UPDATE   #{book_id} — {find_book(conn, book_id)['title']}")
        delete_book(conn, book_id)
        print(f"DELETE   #{book_id} — запис відсутній: {'так' if find_book(conn, book_id) is None else 'ні'}")
        print("Результат: усі чотири операції виконано.")
    finally:
        conn.rollback()
        conn.close()


def interact():
    while True:
        print("\nЕлектронна бібліотека")
        print("1. Каталог   2. Додати   3. Змінити   4. Видалити   0. Вихід")
        action = input("Операція: ").strip()
        if action == "0":
            return
        if action not in {"1", "2", "3", "4"}:
            print("Оберіть пункт меню.")
            continue
        try:
            with connect("console") as conn:
                if action == "1":
                    for book in catalog(conn, input("Пошук (можна пропустити): ")):
                        print(f"{book['book_id']:>3}  {book['title']} ({book['published_year']}) — {book['authors']}")
                elif action == "2":
                    print("Створено запис №", add_book(conn, fields()))
                else:
                    book_id = int(input("ID книги: "))
                    if action == "3":
                        result = edit_book(conn, book_id, fields())
                        print("Оновлено." if result else "Книгу не знайдено.")
                    elif input("Видалити запис? [так/ні] ").strip().lower() == "так":
                        print("Видалено." if delete_book(conn, book_id) else "Книгу не знайдено.")
        except ValueError as error:
            print(error)
        except Error as error:
            print(error.diag.message_primary or "Помилка роботи з базою.")


def main():
    parser = ArgumentParser(description="Консольний каталог електронної бібліотеки")
    parser.add_argument("--demo", action="store_true", help="перевірити CRUD в одній транзакції")
    if parser.parse_args().demo:
        run_demo()
    else:
        interact()


if __name__ == "__main__":
    main()
