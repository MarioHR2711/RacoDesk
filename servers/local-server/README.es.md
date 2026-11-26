# local-server

**Leer en otros idiomas:** [English](README.md)

Uno por restaurante: API, lógica y base de datos local (Laravel y PostgreSQL, provisional). Se ejecuta en un TPV con Windows.

**Estado:** esqueleto de la iteración 0. Proyecto Laravel 13 vacío configurado para PostgreSQL, con Sanctum instalado y una prueba mínima.
Todavía no hay migraciones, modelos ni endpoints de negocio (iteración 1). Los archivos que Laravel trae por defecto (migraciones
`users`, `cache` y `jobs`, modelo `User`, factory y seeder) se dejan como vienen y se adaptarán a [`docs/database.es.md`](../../docs/database.es.md) en la iteración 1.
La autenticación con Sanctum aún no está implementada.

## Requisitos

- PHP 8.3 o superior con las extensiones `pdo_pgsql`, `mbstring`, `openssl`, `fileinfo` y `curl`
- Composer
- PostgreSQL 16

Consulta [`docs/dev-setup.es.md`](../../docs/dev-setup.es.md) y ejecuta `scripts/check-env.ps1` desde la raíz del repositorio para comprobarlos.

## Instalar

Desde esta carpeta (`servers/local-server`):

```powershell
composer install
copy .env.example .env
php artisan key:generate
```

Después abre `.env` y rellena `DB_USERNAME` y `DB_PASSWORD` con tu propio usuario de PostgreSQL local. **Nunca subas `.env`.**

Crea la base de datos (pide la contraseña de `postgres`):

```powershell
psql -U postgres -c "CREATE DATABASE racodesk_local;"
```

Comprueba la conexión:

```powershell
php artisan db:show
```

## Ejecutar

```powershell
php artisan serve
```

Abre <http://127.0.0.1:8000/up>: indica que la aplicación está funcionando.

## Pruebas

PHPUnit:

```powershell
php artisan test
```

La prueba actual (`tests/Feature/HealthCheckTest.php`) solo comprueba que la aplicación arranca. No necesita la base de datos.
