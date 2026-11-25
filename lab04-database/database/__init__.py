import os
import re

from psycopg import connect as pg_connect
from psycopg.rows import dict_row

SORTS = {
    "title": "title, book_id",
    "newest": "published_year DESC, title, book_id",
    "available": "available_copies DESC, title, book_id",
}


def connect(actor=None):
    conn = pg_connect(
        host=os.getenv("LAB04_DB_HOST", "127.0.0.1"),
        port=os.getenv("LAB04_DB_PORT", "5433"),
        dbname=os.getenv("LAB04_DB_NAME", "library_lab04"),
        user=os.getenv("LAB04_DB_USER", "lab04"),
        password=os.getenv("LAB04_DB_PASSWORD", "lab04-local"),
        row_factory=dict_row,
        connect_timeout=5,
    )
    if actor:
        try:
            conn.execute("SELECT set_config('library.actor', %s, true)", (actor,))
        except Exception:
            conn.close()
            raise
    return conn


def validate_email(value):
    email = value.strip().lower()
    if len(email) > 254 or not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email):
        raise ValueError("Вкажіть коректну електронну адресу.")
    return email


def book_fields(values):
    isbn = values.get("isbn", "").strip()
    title = values.get("title", "").strip()
    genre = values.get("genre", "").strip()
    if not re.fullmatch(r"[0-9]{13}", isbn):
        raise ValueError("ISBN має складатися з 13 цифр.")
    if not 1 <= len(title) <= 160 or not 1 <= len(genre) <= 80:
        raise ValueError("Вкажіть назву до 160 символів і жанр до 80 символів.")
    try:
        year = int(values.get("published_year", ""))
    except (ValueError, TypeError):
        raise ValueError("Вкажіть рік видання цілим числом.") from None
    if not 1450 <= year <= 2100:
        raise ValueError("Рік видання має бути від 1450 до 2100.")
    return isbn, title, genre, year


def catalog(conn, query="", genre="", sort="title"):
    order = SORTS.get(sort, SORTS["title"])
    query = query.strip()[:160]
    genre = genre.strip()[:80]
    conditions, parameters = [], []
    if query:
        conditions.append("(strpos(lower(title), lower(%s)) > 0 OR strpos(lower(authors), lower(%s)) > 0 OR isbn = %s)")
        parameters.extend((query, query, query))
    if genre:
        conditions.append("genre = %s")
        parameters.append(genre)
    where = " WHERE " + " AND ".join(conditions) if conditions else ""
    # ORDER BY формується лише зі сталих фрагментів SORTS.
    return conn.execute("SELECT * FROM v_catalog" + where + " ORDER BY " + order, parameters).fetchall()


def find_book(conn, book_id):
    return conn.execute("SELECT * FROM v_catalog WHERE book_id = %s", (book_id,)).fetchone()


def add_book(conn, values):
    return conn.execute(
        """INSERT INTO books (isbn, title, genre, published_year) VALUES (%s, %s, %s, %s)
           RETURNING book_id""",
        book_fields(values),
    ).fetchone()["book_id"]


def edit_book(conn, book_id, values):
    return conn.execute(
        """UPDATE books SET isbn = %s, title = %s, genre = %s, published_year = %s
           WHERE book_id = %s""",
        (*book_fields(values), book_id),
    ).rowcount == 1


def delete_book(conn, book_id):
    return conn.execute("DELETE FROM books WHERE book_id = %s", (book_id,)).rowcount == 1


def loan_statistics(conn):
    return conn.execute(
        """SELECT b.genre, count(*) AS total,
                  count(*) FILTER (WHERE l.returned_on IS NULL AND l.due_on < CURRENT_DATE) AS overdue
           FROM loans l JOIN copies c USING (copy_id) JOIN books b USING (book_id)
           GROUP BY b.genre ORDER BY total DESC, b.genre"""
    ).fetchall()
