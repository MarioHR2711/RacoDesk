# Windows installer and first-run setup

**Read this in other languages:** [Español](installer.es.md)

> **Status:** planned for the future, not started. It depends on the local server existing. All technologies are provisional.

## Why

The local server runs on a Windows POS (TPV) at the restaurant. The owner should not have to install PHP, PostgreSQL and Laravel by hand. An installer leaves the local server ready, keeps working without Internet and needs no router configuration.

## Phases

1. **PowerShell install script.** Prepares everything on a computer: database, `.env`, scheduled backups and the Windows service. It is used to test and is the base of the installer.
2. **`.exe` installer.** Wraps the script (candidate tool: Inno Setup) and adds the first-run wizard.
3. **Data import from Excel/CSV.** Separate feature, see below.

Expected timing: around iteration 7, together with backups. The first-run wizard can start earlier.

## First-run wizard

| Step | What it does |
|---|---|
| Restaurant | Name and business data (the `restaurant` table: legal name, tax id, address, phone) |
| Database | Create a new local PostgreSQL database on this computer, or connect to an existing one |
| Backups | Choose the backup folder (`restaurant.backup_path`); daily automatic copies |
| Owner account | First user with role `OWNER` |
| Central link | Optional: pair with the central server through the QR code |

## Technical decisions to keep

- The server runs as a **Windows service**: it starts with the computer and does not depend on an open window.
- The database password is **generated randomly** during installation. There is never a default password, and it is never stored in the repository.
- The server software is installed on **only one** terminal of the restaurant; the employee software on all of them.
- Applying database migrations is part of installing and updating.

## Data import from Excel/CSV (not decided)

Goal: load the initial data of a restaurant without typing it by hand (menu, ingredients, suppliers, employees, tables), using Excel or CSV templates. It is **not** a full database dump.

It is a new feature that is not in the list of defined features. Before building it, the team must decide:

- Which data can be imported.
- Which roles can do it (for example owner and manager).
- Template format and how errors and duplicates are handled.
- Whether it is part of the project scope.

## Risks

- Bundling PHP, PostgreSQL and the application is a lot of work, and so are updates and database migrations.
- An unsigned installer makes Windows SmartScreen show a warning. Signing costs money; for the project it can be accepted and explained.
- It must be tested on a clean Windows installation.
