CREATE TABLE authors (
    author_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL CHECK (btrim(full_name) <> '')
);

CREATE TABLE books (
    book_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn varchar(13) NOT NULL UNIQUE CHECK (isbn ~ '^[0-9]{13}$'),
    title text NOT NULL CHECK (btrim(title) <> ''),
    genre text NOT NULL CHECK (btrim(genre) <> ''),
    published_year smallint NOT NULL CHECK (published_year BETWEEN 1450 AND 2100)
);

CREATE TABLE book_authors (
    book_id integer REFERENCES books ON DELETE CASCADE,
    author_id integer REFERENCES authors ON DELETE RESTRICT,
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE copies (
    copy_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id integer NOT NULL REFERENCES books ON DELETE RESTRICT,
    inventory_code text NOT NULL UNIQUE CHECK (btrim(inventory_code) <> ''),
    retired boolean NOT NULL DEFAULT false
);

CREATE TABLE readers (
    reader_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL CHECK (btrim(full_name) <> ''),
    email text NOT NULL UNIQUE CHECK (email = lower(email) AND position('@' IN email) > 1),
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE loans (
    loan_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    copy_id integer NOT NULL REFERENCES copies ON DELETE RESTRICT,
    reader_id integer NOT NULL REFERENCES readers ON DELETE RESTRICT,
    issued_on date NOT NULL DEFAULT CURRENT_DATE,
    due_on date NOT NULL,
    returned_on date,
    CHECK (due_on > issued_on),
    CHECK (returned_on IS NULL OR returned_on >= issued_on)
);

CREATE TABLE reservations (
    reservation_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id integer NOT NULL REFERENCES books ON DELETE RESTRICT,
    reader_id integer NOT NULL REFERENCES readers ON DELETE RESTRICT,
    requested_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_on date NOT NULL,
    status text NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'fulfilled', 'cancelled', 'expired'))
);

CREATE UNIQUE INDEX loans_one_active_per_copy
    ON loans (copy_id) WHERE returned_on IS NULL;

CREATE UNIQUE INDEX reservations_one_pending_per_reader
    ON reservations (book_id, reader_id) WHERE status = 'pending';

CREATE INDEX books_genre_year_idx ON books (genre, published_year, book_id);
CREATE INDEX book_authors_author_idx ON book_authors (author_id, book_id);
CREATE INDEX copies_book_idx ON copies (book_id, copy_id);
CREATE INDEX loans_active_reader_due_idx
    ON loans (reader_id, due_on) WHERE returned_on IS NULL;
CREATE INDEX reservations_queue_idx
    ON reservations (book_id, requested_at, reservation_id) WHERE status = 'pending';

