from argparse import ArgumentParser
from datetime import datetime
from getpass import getpass
import os
from pathlib import Path
from shutil import which
from subprocess import PIPE, run

from werkzeug.security import generate_password_hash

from database import connect, validate_email

ROOT = Path(__file__).resolve().parent
RESERVATION_DATES_SQL = "08_validate_reservation_dates.sql"
SQL_ORDER = (
    "01_create_tables.sql", "03_create_procedures.sql", "04_create_triggers.sql",
    "05_create_views.sql", "06_create_users.sql", "07_create_audit.sql",
    RESERVATION_DATES_SQL, "02_insert_data.sql",
)


def docker(*args, **kwargs):
    docker_bin = Path(os.environ.get("LOCALAPPDATA", "")) / "Programs/DockerDesktop/resources/bin"
    exe = which("docker") or docker_bin / "docker.exe"
    env = os.environ.copy()
    if docker_bin.is_dir():
        env["PATH"] = str(docker_bin) + os.pathsep + env["PATH"]
    return run([str(exe), "compose", *args], cwd=ROOT, env=env, check=True, **kwargs)


def run_sql_files(*paths):
    script = b"\n\n".join((ROOT / "database" / name).read_bytes() for name in paths)
    docker("exec", "-T", "postgres", "psql", "-X", "-1", "-v", "ON_ERROR_STOP=1",
           "-U", "lab04", "-d", "library_lab04", input=script)


def initialize():
    docker("up", "-d", "--wait")
    with connect() as conn:
        schema_exists = conn.execute("SELECT to_regclass('public.books') AS books").fetchone()["books"]
        date_check_exists = conn.execute(
            """SELECT 1 FROM pg_constraint
               WHERE conrelid = to_regclass('public.reservations')
                 AND conname = 'reservations_valid_dates'"""
        ).fetchone()
    if not schema_exists:
        run_sql_files(*SQL_ORDER)
    elif not date_check_exists:
        run_sql_files("03_create_procedures.sql", RESERVATION_DATES_SQL)
        print("Додано перевірку дат бронювання.")
    else:
        print("Схема бібліотеки вже створена.")


def create_user(email, role):
    email = validate_email(email)
    password = os.environ.get("LAB04_NEW_PASSWORD") or getpass("Пароль нового користувача: ")
    if len(password) < 10:
        raise SystemExit("Пароль має містити щонайменше 10 символів.")
    with connect("setup") as conn:
        conn.execute(
            "INSERT INTO app_users (email, password_hash, role) VALUES (%s, %s, %s)",
            (email, generate_password_hash(password), role),
        )
    print(f"Створено користувача {email} з роллю {role}.")


def backup():
    directory = ROOT / "backups"
    directory.mkdir(exist_ok=True)
    filename = directory / f"library_lab04-{datetime.now():%Y%m%d-%H%M%S-%f}.dump"
    temp = filename.with_suffix(".partial")
    try:
        with temp.open("wb") as stream:
            docker("exec", "-T", "postgres", "pg_dump", "-Fc", "-U", "lab04", "library_lab04",
                   stdout=stream)
        with temp.open("rb") as stream:
            listing = docker("exec", "-T", "postgres", "pg_restore", "--list",
                             stdin=stream, stdout=PIPE).stdout.decode("utf-8")
        filename = temp.rename(filename)
    finally:
        temp.unlink(missing_ok=True)
    tables = sum("TABLE DATA" in line for line in listing.splitlines())
    print(f"Резервна копія: {filename.name}")
    print(f"Таблиць із даними в архіві: {tables}")


def main():
    parser = ArgumentParser(description="Керування базою електронної бібліотеки")
    tasks = parser.add_subparsers(dest="command", required=True)
    tasks.add_parser("init")
    tasks.add_parser("backup")
    account = tasks.add_parser("create-user")
    account.add_argument("email")
    account.add_argument("role", choices=("reader", "librarian", "admin"))
    args = parser.parse_args()
    if args.command == "init":
        initialize()
    elif args.command == "backup":
        backup()
    else:
        create_user(args.email, args.role)


if __name__ == "__main__":
    main()
