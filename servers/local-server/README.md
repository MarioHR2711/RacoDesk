# local-server

**Read this in other languages:** [Español](README.es.md)

One per restaurant: API, business logic and local database (Laravel and PostgreSQL, provisional). Runs on a Windows POS.

**Status:** iteration 0 skeleton. Empty Laravel 13 project configured for PostgreSQL, with Sanctum installed and one minimal test.
There are no business migrations, models or endpoints yet (iteration 1). The default Laravel files (`users`, `cache` and `jobs`
migrations, `User` model, factory and seeder) are left as they come and will be adapted to [`docs/database.md`](../../docs/database.md) in iteration 1.
Authentication with Sanctum is not implemented yet.

## Requirements

- PHP 8.3 or higher with the `pdo_pgsql`, `mbstring`, `openssl`, `fileinfo` and `curl` extensions
- Composer
- PostgreSQL 16

See [`docs/dev-setup.md`](../../docs/dev-setup.md) and run `scripts/check-env.ps1` from the repository root to check them.

## Install

From this folder (`servers/local-server`):

```powershell
composer install
copy .env.example .env
php artisan key:generate
```

Then open `.env` and fill in `DB_USERNAME` and `DB_PASSWORD` with your own local PostgreSQL user. **Never commit `.env`.**

Create the database (it asks for the `postgres` password):

```powershell
psql -U postgres -c "CREATE DATABASE racodesk_local;"
```

Check the connection:

```powershell
php artisan db:show
```

## Run

```powershell
php artisan serve
```

Open <http://127.0.0.1:8000/up>: it shows that the application is running.

## Tests

PHPUnit:

```powershell
php artisan test
```

The current test (`tests/Feature/HealthCheckTest.php`) only checks that the application boots. It does not need the database.
