# CLAUDE.md — RacoDesk project context

**Read this in other languages:** [Español](CLAUDE.es.md)

This file gives context to Claude Code. It summarizes what the team has discussed and decided so far.
**Main rule:** do not invent decisions. If something is listed as undecided, ask before deciding.
The repository is **public**: never write passwords, keys, real `.env` files or real customer data.
**Claude Code writes the project's code.** The team reviews and decides.

## What it is

RacoDesk is the final project (*Proyecto Intermodular*, TFG) of the DAM higher technical degree, 2nd year, at Victoria Institute of Technology.
It is a management system for restaurants with one or several premises. Each restaurant has its own
local server and its own database, so it keeps working without Internet. The owner checks their
premises remotely.

Status: design stage. **There is no code yet.** Do not present anything as done if it is only design.

## Team

- Mario Hernández Ramos — GitHub `MarioHR2711` (repository owner)
- Alejandro Domínguez Mora — GitHub `alexdm0749-ops` (collaborator)
- There is no confirmed task split. Do not assign modules to anyone without asking.

## Architecture

- **Local server (one per restaurant):** business logic, API and its own database. It checks permissions.
  It is a **regular Windows POS (TPV)** at the restaurant. If there are several terminals, the server software is installed
  on **only one** and the employee software on **all of them**. Apps **never** access the database directly;
  they talk to the local server's API over the restaurant's local network.
- **Central server:** stores only general information (owners, companies, premises, local installations,
  global administrators and their permissions). **It keeps no copy of orders, payments, expenses or operational data.**
  **Decided:** the central **database** is in **Supabase** (PostgreSQL) and the **logic and features**
  live in a **dedicated central server application** (Laravel, provisional), not in Edge Functions.
- **Employee app:** operations of the premises according to role. One Android version and an **identical Windows version** for the POS terminals,
  built with **React Native** (React Native for Windows for the POS).
- **Owner app (Android):** shows data (see statistics below) and **can also change things remotely**
  (only the allowed actions, see "Remote access").
- **Admin web panel:** for global administrators. **It only takes care of the central database** (owners, companies, premises, installations, administrators and their permissions).
  It does not manage employees, products, tables or settings of any premises.
- **Without Internet:** the premises keep working (orders, tables, products, reservations, customers, inventory, payments, expenses).
  Only remote access fails. In that case the owner app shows a message saying it is **not possible to connect to the server** (no old data is shown).
- **No subscriptions:** there are no plans or subscription charges.

### Confirmed business rules

- A **manager** manages **1 premises**. An **owner** manages **all** their premises.
- An order is considered **paid** when the **waiter confirms** the payment. **Partial payments** are allowed: several payments per order; it closes when they add up to the total.
- The **ticket** is given to the customer when they pay the bill.
- **Expenses** come from: salary payments and payments to product suppliers.
- `employee_work_hours` stores the hours worked **per week** by each employee, to calculate the salary paid that month.
- **Overtime:** the employee chooses between **being paid** or **time off** (`overtime_choice`: `PAID` or `TIME_OFF`).
  Paid overtime is added to the month's salary; time-off overtime builds a bank of hours that is used up through `time_off_records`.
  Rate of paid overtime: depends on the collective agreement; set with `restaurant.overtime_multiplier`.
- **Week spanning two months:** the week counts for the month in which its **Thursday** falls (`week_start` + 3 days; ISO rule).
- **Backups:** automatic **every day**, stored by default **on the same computer**. **Decided:** the destination folder must be configurable (`restaurant.backup_path`).
  Warning: with the copy only on the same computer, a disk failure loses data and copy; recommend an external copy.
- Permission matrix per role: `docs/permissions.md`.

### Owner app statistics

Income, expenses, employees (hours, cost, sales), products (best sellers, income per product and category), low stock,
comparison between premises. The local server calculates them and sends totals. There is no statistics table.

### Security rules (mandatory)

1. Permissions are checked **on the server**, not just by hiding buttons.
2. The global administrator **cannot** see sales, income, expenses, payments, profits or economic statistics.
   This also applies in the APIs; the server must reject the request.
3. Passwords are stored as `password_hash`.
4. Audit: the `audit_logs` table is only for important actions.
5. GDPR (development): personal data defined by the team: **employees** = first name, last name, phone, email, address; **delivery customers** = name, phone, address. Do not store more personal data; customer and employee data live on the local server;
   the central only holds owner and administrator data; Supabase in an **EU region**; be able to delete or anonymize a customer or employee
   on request; never write personal data to logs; notify the owner in case of a breach.

## Owner remote access

Goal: let the owner see their premises remotely in a **secure and efficient** way, without the central storing operational data.
It starts **directly with WebSocket** (no request-queue phase).

Key idea: the local server **opens** an outbound connection to the central. No ports are ever opened on the restaurant's router.

```
Owner app --HTTPS--> Central server <==secure WebSocket== Local server
 (short token)       (relay, stores nothing)   (opened by the local)
```

Flow: the app asks for data → the central validates the token and forwards the request to the local → the local replies only with
what was asked → the central passes the answer on and **does not store it**.

Security:
- Everything encrypted with TLS (HTTPS / WSS).
- Own key per local, created during QR pairing with a single-use, short-lived token. Revocable.
- Short-lived owner token, with renewal.
- The **local checks** (`linked_owners`) that this owner owns this local; do not rely only on the central.
- Closed list of allowed operations (queries and, now, owner **changes**). The central is **not** a free tunnel.
- Remote changes: validated and **executed by the local server** with its own rules and permissions; the central never writes to the local DB.
  Each one is recorded in `audit_logs` (with the owner who requested it), carries a unique identifier so it is not repeated (idempotency)
  and may require the local to be connected (otherwise it is rejected with a clear message; they are not queued).
- **Actions the owner can do remotely (decided):** manage products and prices (categories, ingredients, modifiers),
  employees (including **deleting them and changing their role**), tables, and worked hours and salaries.
- **Cannot be changed remotely:** orders, payments, reservations (nor customers). That is only done at the premises. Remotely they are only viewed (reservations are not even touched).
- Any action outside this list must be rejected by the local server.
- Rate limit per user and per local.
- Access log (`access_logs`) **without storing the content**.
- The global admin cannot request economic data: only an owner token accepts them.
- Optional future improvement: end-to-end encryption between app and local.

Efficiency: the local sends summarized totals; pagination and compression; very short cache in memory only (optional, document it).

### Supabase in the central (decided)

- Supabase only provides the central's **PostgreSQL database**. The central server application (Laravel, provisional)
  is hosted separately and connects to that DB; it also hosts the relay WebSocket (for example Laravel Reverb).
- Supabase cannot host Laravel. **Decided:** the central Laravel application runs on a **Windows computer**.
  That computer must be reachable from the Internet by the locals and by the owner app (public IP/domain, HTTPS, ports or tunnel: to be solved).
- Detail to solve: the local server is a WebSocket **client**; Reverb is a server, so the local will use a compatible client library.
- Since economic data passes through a third party (the central), choose an EU region (GDPR) and consider end-to-end encryption.

## Technologies (PROVISIONAL, may change)

| Area | Technology |
|---|---|
| Android and Windows apps | JavaScript + React Native (React Native for Windows) |
| Web panel | JavaScript + React |
| Local server | PHP + Laravel (Sanctum), PostgreSQL |
| Central server | Laravel app (provisional) + PostgreSQL DB in Supabase. Owner and admin login: Laravel's own (Sanctum), **not** Supabase Auth |
| Database | PostgreSQL |
| Tools | VS Code, Git/GitHub, Trello |
| Testing | PHPUnit/Pest (servers), Jest (apps) |

Decided: the employee app on Windows is built with **React Native for Windows** (same code as Android, installed on the POS).
Native Windows modules may be needed (for example ticket printing).

Undecided: UI design tool (not for now), Docker, how to discover the server on the LAN (fixed IP or mDNS).

## Undecided (ask before implementing)

- How the central's Windows computer is made reachable from the Internet (IP/domain, HTTPS, tunnel).
- External backup recommended (the server POS and the central are a single point of failure).
- GDPR: privacy policy, retention, right to erasure, breach notification (see development rules in "Security rules").
- Invoicing: the customer receives a **ticket**. It still has to be analyzed whether it has tax effects and whether it affects VERI*FACTU
  (ask the tutor). Do not claim that RacoDesk complies with VERI*FACTU.

## Defined features

1. Employees and permissions
2. Tables and table groups
3. Orders and products
4. Categories, ingredients and modifiers
5. Customers and reservations
6. Delivery orders and drivers
7. Payments and expenses (with ticket for the customer)
8. Inventory and stock alerts
9. Notifications
10. Statistics

Work hours and salaries are part of expenses and statistics (`employee_work_hours`, `salary_payments`).

## Roles

Permission matrix: `docs/permissions.md`.

Local roles: `OWNER`, `MANAGER`, `WAITER`, `KITCHEN`, `DELIVERY`. The global `ADMIN` is independent.
Effective permissions = role permissions + individual permissions (`role_permissions` + `user_permissions`).
Global admins: separate tables `admin_permissions` and `admin_user_permissions`.

## Data model

Full schema (all tables, fields and the purpose of each table): **`docs/database.md`**. Read it before creating migrations.

**Local database (33 tables):** restaurant, roles, permissions, role_permissions, users, user_permissions, linked_owners,
employee_work_hours, salary_payments, time_off_records, tables, table_groups, table_group_members, categories, products, suppliers,
ingredients, product_ingredients, ingredient_modifiers, customers, orders, order_items, order_item_modifiers,
reservations, reservation_tables, delivery_drivers, delivery_orders, payments, expenses, supplier_payments,
user_devices, notifications, audit_logs.

**Central database (9 tables):** owners, companies, locations, local_installations, pairing_tokens, access_logs,
admins, admin_permissions, admin_user_permissions.

Design decisions:
- Table states: `AVAILABLE`, `OCCUPIED`, `RESERVED`. A table group is reused; there is no history.
- Order types: `DINE_IN` (table or group), `TAKEAWAY`, `DELIVERY`. There is no state flow; whether it is paid is known from `closed_at`.
- Modifiers: `REMOVE` and `EXTRA`.
- The product price and VAT at the time of the order are stored. Price includes VAT.
- Reservations: `PENDING`, `CONFIRMED`, `CANCELLED`, `COMPLETED`, with an anti-overlap constraint.
- Payments: `CASH`, `CARD`, `ONLINE`; states `PENDING`, `PAID`, `FAILED`, `REFUNDED`.
- Expenses: `expenses` table with type `SALARY` or `SUPPLIER` and detail tables (`salary_payments`, `supplier_payments`).
- Notifications: `LOW_STOCK` (manager and owner), `NEW_ORDER` (kitchen).
- Inventory: stock and minimums in `ingredients`. There is no `inventory_movements` table.
- Delivery is optional per restaurant.
- `audit_logs.entity_id` is polymorphic.

## Work plan (what will be done)

Incremental and iterative, with Scrum practices adapted to two people. Two-week iterations (no official dates).

| It. | What will be done |
|---|---|
| 0 | Repo, basic CI, folder structure; first minimal code to push to Git |
| 1 | Local server: Laravel + PostgreSQL, migrations (`docs/database.md`), authentication, employees, roles and permissions, `audit_logs` |
| 2 | Tables and groups, categories, products, ingredients, modifiers, orders (dine-in, takeaway) |
| 3 | Payments (waiter confirmation) and ticket, expenses, suppliers, weekly hours and salaries, inventory, notifications |
| 4 | Customers, reservations, delivery orders, drivers |
| 5 | Central (Laravel app + DB in Supabase) and WebSocket communication with locals: QR pairing, `linked_owners`, allowed remote queries and changes, `access_logs`, "no connection" message |
| 6 | Owner app with statistics and remote changes, admin panel (no economic access), Windows version of the employee app |
| 7 | Stabilization, acceptance tests, backups, GDPR, documentation, delivery |

Working order for Claude Code on each task: explain what it will do → wait for confirmation if it is a big change →
write code and tests → leave it ready for the teammate's review.

Trello: **Pending → Working → Check → Done**. When finished it goes to *Check*; the teammate reviews. If it fails it goes back to *Working* with a note.
Definition of "Done": code reviewed, tests pass, criteria met, documentation up to date.

## Repository conventions

- Branches: `main` (stable), `feature/<name>`, `fix/<name>`, `docs/<name>`. Work on a branch + pull request reviewed by the teammate.
- Commits in English: `type: description` with `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- **Documentation in two languages:** the default file is in English (`README.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `docs/database.md`, ...)
  and the Spanish version has the same name with `.es` before the extension (`README.es.md`, `CONTRIBUTING.es.md`, ...).
  Every time a document changes, **update both versions**.
- Code and comments in English.
- Structure: `apps/employee-app`, `apps/owner-app`, `apps/admin-panel`, `servers/local-server`, `servers/central-server`, `docs/`.
- MIT license.
- Do not invent features outside the list. Mark any technology as provisional.

## How to work with the team

- Before big changes, explain what you are going to do and wait for confirmation.
- Commits are made by the team members with their own Git user.
- Git: for now it is left as it is; nothing important has been pushed yet.
- The team prefers explanations in Spanish.
