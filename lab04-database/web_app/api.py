from flask import Blueprint, jsonify, request

from database import catalog, connect, find_book

api = Blueprint("api", __name__, url_prefix="/api")


@api.get("/books")
def books():
    with connect() as conn:
        rows = catalog(conn, request.args.get("q", ""), request.args.get("genre", ""),
                       request.args.get("sort", "title"))
    return jsonify(books=rows, count=len(rows))


@api.get("/books/<int:book_id>")
def detail(book_id):
    with connect() as conn:
        book = find_book(conn, book_id)
    return jsonify(book) if book else (jsonify(error="Книгу не знайдено"), 404)
