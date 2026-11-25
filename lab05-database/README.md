# Лабораторна робота №5 · Електронна бібліотека

[Звіт з лабораторної роботи](docs/report.md)

Робота використовує схему електронної бібліотеки з №4. SQL-скрипти для початкової структури й даних містяться в [sql/base](sql/base). Тестова база працює в окремому контейнері PostgreSQL 17.

## Запуск на Windows

1. Запустіть Docker Desktop.
2. Відкрийте PowerShell у папці `lab05-database`. Для першого запуску створіть локальний пароль у файлі `.env`.

   ```powershell
   if (-not (Test-Path .env)) {
       Set-Content -Encoding ASCII .env ('LAB05_DB_PASSWORD=' + [guid]::NewGuid().ToString('N'))
   }
   ```

3. Запустіть виконання на чистій базі.

   ```powershell
   .\run-lab.ps1
   ```

Скрипт запускає PostgreSQL, завантажує схему й дані, виконує перевірки та зберігає вивід у [docs/evidence](docs/evidence). Локальна резервна копія з’явиться в `backups/library_lab05.dump`, а контрольна база називається `library_lab05_restore`.

Для перегляду робочої бази через `psql` виконайте:

```powershell
docker compose exec postgres psql -U lab05 -d library_lab05
```

Підключення через DBeaver використовує хост `127.0.0.1`, порт `5434`, базу `library_lab05`, користувача `lab05` та пароль із `.env`. Для демонстрації обмеженого користувача скрипт використовує локальне підключення всередині контейнера.

## Моніторинг

Щоб оновити статистику у звіті моніторингу, запустіть запит у поточній базі:

```powershell
docker compose exec -T postgres psql -X -U lab05 -d library_lab05 -f /tmp/lab05-sql/11_monitor.sql
```

Після перестворення контейнера з тим самим томом перед цією командою виконайте `docker compose cp sql postgres:/tmp/lab05-sql`.
