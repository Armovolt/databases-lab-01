CREATE TABLE app_users (
    user_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL UNIQUE CHECK (email = lower(email) AND position('@' IN email) > 1),
    password_hash text NOT NULL,
    role text NOT NULL DEFAULT 'reader' CHECK (role IN ('reader', 'librarian', 'admin')),
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
