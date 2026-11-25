from functools import wraps
from hmac import compare_digest
import os
import secrets

from flask import Flask, abort, flash, g, redirect, render_template, request, send_file, session, url_for
from psycopg import Error
from psycopg.errors import ForeignKeyViolation, UniqueViolation
from werkzeug.security import check_password_hash, generate_password_hash

from database import add_book, catalog, connect, delete_book, edit_book, find_book, loan_statistics, validate_email
from web_app.api import api
from web_app.reports import catalog_pdf

STAFF = ("librarian", "admin")
OPERATIONS = {
    "issue": ("CALL issue_copy(%s, %s, %s)", ("copy_id", "reader_id", "days"), "Примірник видано."),
    "return": ("CALL return_loan(%s)", ("loan_id",), "Повернення оформлено."),
    "reserve": ("CALL reserve_book(%s, %s, %s)", ("book_id", "reader_id", "days"), "Бронювання створено."),
}


def role_required(*roles):
    def decorate(view):
        @wraps(view)
        def guarded(*args, **kwargs):
            if g.user is None:
                return redirect(url_for("login"))
            if g.user["role"] not in roles:
                abort(403)
            return view(*args, **kwargs)
        return guarded
    return decorate


def create_app():
    app = Flask(__name__)
    app.config.update(SECRET_KEY=os.getenv("LAB04_SECRET_KEY") or secrets.token_hex(32),
                      SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Lax",
                      MAX_CONTENT_LENGTH=64 * 1024)
    app.json.ensure_ascii = False
    app.register_blueprint(api)

    @app.before_request
    def prepare_request():
        if request.endpoint == "static":
            return
        g.user = None
        if user_id := session.get("user_id"):
            with connect() as conn:
                g.user = conn.execute(
                    "SELECT user_id, email, role FROM app_users WHERE user_id = %s AND active", (user_id,)
                ).fetchone()
        if "csrf" not in session:
            session["csrf"] = secrets.token_urlsafe(24)
        if request.method == "POST":
            token = request.form.get("csrf", "")
            if not token.isascii() or not compare_digest(session["csrf"], token):
                abort(400)

    @app.context_processor
    def template_context():
        return {"staff": STAFF, "csrf_token": session.get("csrf", "")}

    @app.get("/")
    def index():
        query = request.args.get("q", "")
        genre = request.args.get("genre", "")
        sort = request.args.get("sort", "title")
        with connect() as conn:
            rows = catalog(conn, query, genre, sort)
            genres = conn.execute("SELECT DISTINCT genre FROM books ORDER BY genre").fetchall()
        return render_template("catalog.html", books=rows, genres=genres, query=query, genre=genre, sort=sort)

    @app.route("/register", methods=("GET", "POST"))
    def register():
        if request.method == "POST":
            try:
                email = validate_email(request.form.get("email", ""))
                password = request.form.get("password", "")
                if not 10 <= len(password) <= 128:
                    raise ValueError("Пароль має містити від 10 до 128 символів.")
                with connect(email) as conn:
                    conn.execute("INSERT INTO app_users (email, password_hash) VALUES (%s, %s)",
                                 (email, generate_password_hash(password)))
                flash("Обліковий запис створено. Увійдіть у систему.", "success")
                return redirect(url_for("login"))
            except UniqueViolation:
                flash("Для цієї адреси вже є обліковий запис.", "error")
            except ValueError as error:
                flash(str(error), "error")
            return render_template("auth.html", register=True), 422
        return render_template("auth.html", register=True)

    @app.route("/login", methods=("GET", "POST"))
    def login():
        if request.method == "POST":
            email = request.form.get("email", "").strip().lower()
            password = request.form.get("password", "")
            with connect() as conn:
                user = conn.execute(
                    "SELECT user_id, password_hash FROM app_users WHERE email = %s AND active", (email,)
                ).fetchone()
            if user and len(password) <= 128 and check_password_hash(user["password_hash"], password):
                session.clear()
                session["user_id"] = user["user_id"]
                return redirect(url_for("index"))
            flash("Невірна адреса або пароль.", "error")
            return render_template("auth.html", register=False), 422
        return render_template("auth.html", register=False)

    @app.post("/logout")
    def logout():
        session.clear()
        return redirect(url_for("index"))

    @app.get("/books/<int:book_id>")
    def book_detail(book_id):
        with connect() as conn:
            book = find_book(conn, book_id)
            if book is None:
                abort(404)
            copies = conn.execute(
                """SELECT copy_id, inventory_code, retired, EXISTS (
                   SELECT 1 FROM loans l WHERE l.copy_id = c.copy_id AND l.returned_on IS NULL
                ) AS on_loan FROM copies c WHERE book_id = %s ORDER BY copy_id""", (book_id,)
            ).fetchall()
        return render_template("book.html", book=book, copies=copies)

    @app.route("/books/new", methods=("GET", "POST"), defaults={"book_id": None})
    @app.route("/books/<int:book_id>/edit", methods=("GET", "POST"))
    @role_required(*STAFF)
    def book_form(book_id):
        with connect() as conn:
            book = find_book(conn, book_id) if book_id is not None else {}
        if book is None:
            abort(404)
        if request.method == "POST":
            try:
                with connect(g.user["email"]) as conn:
                    if book_id is None:
                        book_id = add_book(conn, request.form)
                    elif not edit_book(conn, book_id, request.form):
                        abort(404)
                flash("Запис збережено.", "success")
                return redirect(url_for("book_detail", book_id=book_id))
            except UniqueViolation:
                flash("Такий ISBN уже є в каталозі.", "error")
            except ValueError as error:
                flash(str(error), "error")
            return render_template("book_form.html", book=request.form, editing=bool(book_id)), 422
        return render_template("book_form.html", book=book, editing=bool(book_id))

    @app.post("/books/<int:book_id>/delete")
    @role_required(*STAFF)
    def book_delete(book_id):
        try:
            with connect(g.user["email"]) as conn:
                if not delete_book(conn, book_id):
                    abort(404)
        except ForeignKeyViolation:
            flash("Книгу неможливо видалити, бо вона має примірники або бронювання.", "error")
            return redirect(url_for("book_detail", book_id=book_id))
        flash("Видання видалено.", "success")
        return redirect(url_for("index"))

    @app.route("/circulation", methods=("GET", "POST"))
    @role_required(*STAFF)
    def circulation():
        if request.method == "POST":
            operation = OPERATIONS.get(request.form.get("operation"))
            if operation is None:
                abort(400)
            sql, fields, message = operation
            try:
                values = tuple(int(request.form.get(field, "")) for field in fields)
                if any(value <= 0 or value > 2_147_483_647 for value in values):
                    raise ValueError
                with connect(g.user["email"]) as conn:
                    conn.execute(sql, values)
                flash(message, "success")
            except ValueError:
                flash("Введіть додатні цілі числа.", "error")
            except Error as error:
                flash(error.diag.message_primary or "Операцію не виконано.", "error")
            return redirect(url_for("circulation"))
        with connect() as conn:
            loans = conn.execute("SELECT * FROM v_active_loans ORDER BY due_on, loan_id").fetchall()
        return render_template("circulation.html", loans=loans)

    @app.get("/statistics")
    def statistics():
        with connect() as conn:
            rows = loan_statistics(conn)
        return render_template("statistics.html", rows=rows, maximum=max(
            (row["total"] for row in rows), default=1))

    @app.get("/reports/catalog.pdf")
    @role_required(*STAFF)
    def export_catalog():
        with connect() as conn:
            books = catalog(conn)
        return send_file(catalog_pdf(books), mimetype="application/pdf", download_name="catalog.pdf",
                         as_attachment=True)

    @app.get("/audit")
    @role_required("admin")
    def audit():
        with connect() as conn:
            rows = conn.execute(
                """SELECT audit_id, table_name, operation, actor, changed_at
                   FROM audit_log ORDER BY audit_id DESC LIMIT 30"""
            ).fetchall()
        return render_template("audit.html", rows=rows)

    @app.errorhandler(403)
    def forbidden(_error):
        return render_template("forbidden.html"), 403

    return app


if __name__ == "__main__":
    create_app().run(host="127.0.0.1", port=int(os.getenv("LAB04_WEB_PORT", "8765")))
