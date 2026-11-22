# RacoDesk database

**Read this in other languages:** [Español](database.es.md)

> **Status:** design, not yet implemented. PostgreSQL planned. Technologies are provisional.

There are two independent databases:

- **Local:** one per restaurant, on the local server (a Windows PC). It stores all operational and economic data of that restaurant.
- **Central:** general, in Supabase (provisional). It stores owners, companies, premises, installations and administrators. **It does not store orders, payments or expenses.**

**Conventions:** `id bigint` auto-increment keys (unless stated otherwise); amounts `numeric(10,2)`; dates `timestamptz` in UTC; `created_at` and `updated_at` on all tables except join tables; `deleted_at` (soft delete) where indicated.

**General team rules:**
- A **manager** manages **one** premises. An **owner** manages **all** their premises.
- An order is considered **paid** when the waiter confirms the payment. The **ticket** is given to the customer after paying.
- **Expenses** come from two sources: salary payments and payments to product suppliers.
- Worked hours are recorded **per week** and are used to calculate the month's salary.
- There are no subscriptions.

---

# 1. Local database (33 tables)

## 1.1 Users, roles and permissions

### `restaurant`
**Purpose:** general data of the restaurant. It has a single row.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| name | text | |
| installation_id | uuid UNIQUE | Public identifier of the installation. Must match the one in the central. The secret goes in `.env` or encrypted, **not** in this table |
| delivery_enabled | boolean | Delivery is optional per restaurant |
| overtime_multiplier | numeric(4,2) | Multiplier for paid overtime. 1.00 = same as a normal hour; adjusted according to the collective agreement |
| backup_path | text NULL | Folder for the daily backups. Configurable; by default, a folder on the same computer |
| legal_name, tax_id, address, phone | text | Business data printed on the ticket |

### `roles`
**Purpose:** list of local roles.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| code | text UNIQUE | `OWNER`, `MANAGER`, `WAITER`, `KITCHEN`, `DELIVERY` |
| name | text | |

### `permissions`
**Purpose:** list of actions that can be allowed (for example manage products). The matrix per role is in `docs/permissions.md`.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| code | text UNIQUE | |
| description | text | |

### `role_permissions`
**Purpose:** which permissions each role has. Join table.

| Column | Type | Notes |
|---|---|---|
| role_id | bigint FK → roles.id | PK (role_id, permission_id) |
| permission_id | bigint FK → permissions.id |  |

### `users`
**Purpose:** employees who use the system at the premises.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| role_id | bigint FK → roles.id | |
| first_name | text | |
| last_name | text | |
| phone | text | |
| address | text | |
| email | text UNIQUE | Also used to log in |
| password_hash | text | |
| active | boolean | |
| hourly_rate | numeric(8,2) NULL | Price per hour, used to calculate the salary |
| deleted_at | timestamptz NULL | |

### `user_permissions`
**Purpose:** extra permissions assigned to a specific user. Effective permissions = role permissions + individual permissions. Join table.

| Column | Type | Notes |
|---|---|---|
| user_id | bigint FK → users.id | PK (user_id, permission_id) |
| permission_id | bigint FK → permissions.id |  |

### `linked_owners`
**Purpose:** owners authorized to query this premises from outside. The local checks authorization here and does not rely only on the central.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| central_owner_id | bigint | Id of the owner in the central |
| linked_at | timestamptz | |
| revoked_at | timestamptz NULL | |

## 1.2 Hours and salaries

### `employee_work_hours`
**Purpose:** hours worked by each employee **each week**. They are used to calculate the month's salary.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK → users.id | |
| week_start | date | Monday of the week. UNIQUE (user_id, week_start) |
| hours_worked | numeric(5,2) | |
| overtime_hours | numeric(5,2) NOT NULL default 0 | Overtime hours of the week |
| overtime_choice | enum NULL | `PAID` (get paid) or `TIME_OFF` (rest). Chosen by the employee |
| registered_by | bigint FK → users.id | Who records the hours |

Calculation: month's salary = (sum of `hours_worked` of the weeks of that month + overtime hours with `PAID`) × `users.hourly_rate`
(overtime rate: `restaurant.overtime_multiplier`).
**Month rule:** a week counts for the month in which its **Thursday** falls (`week_start` + 3 days).
Overtime hours with `TIME_OFF` go to the employee's time-off bank (see `time_off_records`).

### `time_off_records`
**Purpose:** time off taken by an employee in exchange for overtime. Time-off bank =
sum of `overtime_hours` with `TIME_OFF` − sum of `hours` in this table.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK → users.id | |
| taken_on | date | Day of rest |
| hours | numeric(5,2) | Hours deducted |
| registered_by | bigint FK → users.id | |

### `salary_payments`
**Purpose:** monthly salary payment to an employee. Each payment creates an expense of type `SALARY`.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| expense_id | bigint FK UNIQUE → expenses.id | |
| user_id | bigint FK → users.id | Employee who is paid |
| month | date | First day of the month. UNIQUE (user_id, month) |
| hours_total | numeric(6,2) | Hours of the month |
| hourly_rate | numeric(8,2) | Price per hour at that time |
| amount | numeric(10,2) | |

## 1.3 Tables

### `tables`
**Purpose:** the restaurant's tables and their state.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| number | integer UNIQUE | Visible number |
| status | enum | `AVAILABLE`, `OCCUPIED`, `RESERVED` |
| active | boolean | |

### `table_groups`
**Purpose:** groups of several tables. They are reused when they stop being active. There is no history.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| active | boolean |  |
| created_at | timestamptz |  |

### `table_group_members`
**Purpose:** which tables make up each group. Join table.

| Column | Type | Notes |
|---|---|---|
| group_id | bigint FK → table_groups.id | PK (group_id, table_id) |
| table_id | bigint FK → tables.id |  |

A table can only be in one active group at a time (enforced in the application).

## 1.4 Products and inventory

### `categories`
**Purpose:** product categories.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| name | text |  |
| active | boolean |  |

### `products`
**Purpose:** the restaurant's menu.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| category_id | bigint FK → categories.id | |
| name | text | |
| price | numeric(10,2) | Final price, VAT included |
| tax_rate | numeric(5,2) | |
| active | boolean | Enable or disable |
| deleted_at | timestamptz NULL | |

### `suppliers`
**Purpose:** product suppliers.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| name | text | |
| phone | text NULL | |
| email | text NULL | |
| tax_id | text NULL | |
| active | boolean | |
| deleted_at | timestamptz NULL | |

### `ingredients`
**Purpose:** ingredients and stock. Low-stock alerts come from here.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| supplier_id | bigint FK NULL → suppliers.id | Usual supplier |
| name | text | |
| unit | text | |
| stock_quantity | numeric(10,3) | Current stock |
| min_quantity | numeric(10,3) | Minimum before alerting |

There is no inventory movements table (team decision).

### `product_ingredients`
**Purpose:** which ingredients each product contains. Join table.

| Column | Type | Notes |
|---|---|---|
| product_id | bigint FK → products.id | PK (product_id, ingredient_id) |
| ingredient_id | bigint FK → ingredients.id |  |
| quantity | numeric(10,3) | Quantity of the ingredient in one unit of the product |

### `ingredient_modifiers`
**Purpose:** possible modifications of an ingredient in an order.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| ingredient_id | bigint FK → ingredients.id | |
| type | enum | `REMOVE`, `EXTRA`. There is no `OPTION` |
| extra_price | numeric(10,2) | Default 0 |

## 1.5 Customers and orders

### `customers`
**Purpose:** customers with their contact details and one address (for reservations and delivery).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| name | text |  |
| phone | text |  |
| address | text NULL | Only needed for delivery |
| deleted_at | timestamptz NULL |  |

`email` is not stored: only name, phone and address are kept.
To delete a customer who requests it, the record is anonymized (name, phone and address emptied) and their orders are kept.

### `orders`
**Purpose:** dine-in, takeaway and delivery orders.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK → users.id | Who creates the order |
| customer_id | bigint FK NULL → customers.id | |
| table_id | bigint FK NULL → tables.id | |
| group_id | bigint FK NULL → table_groups.id | |
| type | enum | `DINE_IN`, `TAKEAWAY`, `DELIVERY` |
| total | numeric(10,2) | |
| ticket_number | integer UNIQUE NULL | Sequential. Assigned when the payment is confirmed |
| closed_at | timestamptz NULL | Filled in when the payment is confirmed. A closed order is neither edited nor deleted |

Constraint: `DINE_IN` requires `table_id` or `group_id` (not both). `TAKEAWAY` and `DELIVERY` have no table. There is no order state flow: whether it is paid is known from `closed_at`.

### `order_items`
**Purpose:** products in each order, with the price at that time.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| order_id | bigint FK → orders.id | |
| product_id | bigint FK → products.id | |
| quantity | integer | |
| unit_price | numeric(10,2) | Price at the time of the order |
| tax_rate | numeric(5,2) | VAT at the time of the order |

### `order_item_modifiers`
**Purpose:** modifiers applied to each product in the order.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| order_item_id | bigint FK → order_items.id |  |
| ingredient_id | bigint FK → ingredients.id |  |
| type | enum | `REMOVE`, `EXTRA` |
| price | numeric(10,2) | Price applied at the time of the order |

## 1.6 Reservations

### `reservations`
**Purpose:** customer reservations.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| customer_id | bigint FK → customers.id | |
| status | enum | `PENDING`, `CONFIRMED`, `CANCELLED`, `COMPLETED` |
| start_time | timestamptz | |
| end_time | timestamptz | |
| party_size | integer | |

### `reservation_tables`
**Purpose:** tables assigned to each reservation. It prevents two reservations at the same time on the same table.

| Column | Type | Notes |
|---|---|---|
| reservation_id | bigint FK | |
| table_id | bigint FK | |
| during | tstzrange | Copy of the reservation's range |
| active | boolean | False if the reservation is cancelled |

Constraint (requires the `btree_gist` extension):
`EXCLUDE USING gist (table_id WITH =, during WITH &&) WHERE (active)`

## 1.7 Delivery

### `delivery_drivers`
**Purpose:** delivery drivers.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| user_id | bigint FK UNIQUE → users.id |  |
| active | boolean |  |

### `delivery_orders`
**Purpose:** tracking of the delivery of a home-delivery order.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| order_id | bigint FK UNIQUE → orders.id | |
| driver_id | bigint FK → delivery_drivers.id | |
| assigned_at | timestamptz | |
| picked_up_at | timestamptz NULL | |
| delivered_at | timestamptz NULL | |

## 1.8 Money

### `payments`
**Purpose:** order payments. The order is considered paid when the waiter confirms the payment.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| order_id | bigint FK → orders.id | |
| user_id | bigint FK → users.id | Waiter who confirms the payment |
| method | enum | `CASH`, `CARD`, `ONLINE` |
| status | enum | `PENDING`, `PAID`, `FAILED`, `REFUNDED` |
| amount | numeric(10,2) | |
| confirmed_at | timestamptz NULL | |

When a payment becomes `PAID`, `orders.closed_at` and `orders.ticket_number` are filled in. Payments are not deleted. **Partial payments (allowed):** an order can have several payments (for example each diner pays their share, or part in cash and part by card). The order is closed and receives its `ticket_number` when the sum of the `PAID` payments equals the total. The ticket is handed over then.

### `expenses`
**Purpose:** single expenses table. There are two types and each expense has exactly one detail row.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| type | enum | `SALARY`, `SUPPLIER` |
| user_id | bigint FK → users.id | Who records the expense |
| amount | numeric(10,2) | |
| expense_date | date | |

### `supplier_payments`
**Purpose:** detail of an expense of type `SUPPLIER` (payment to a supplier).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| expense_id | bigint FK UNIQUE → expenses.id | |
| supplier_id | bigint FK → suppliers.id | |
| concept | text | |
| invoice_number | text NULL | |

(The detail of `SALARY` is `salary_payments`, see 1.2.)

## 1.9 Devices, alerts and control

### `user_devices`
**Purpose:** devices of each user (phones, tablets and Windows POS) and their address for sending alerts.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| user_id | bigint FK → users.id |  |
| device_type | enum | `ANDROID`, `WINDOWS` |
| device_token | text | Address for sending alerts to the device |
| last_seen | timestamptz |  |

### `notifications`
**Purpose:** alerts to users.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| user_id | bigint FK → users.id | Recipient |
| type | enum | `LOW_STOCK` (to manager and owner), `NEW_ORDER` (to kitchen) |
| ingredient_id | bigint FK NULL → ingredients.id | For `LOW_STOCK` |
| order_id | bigint FK NULL → orders.id | For `NEW_ORDER` |
| message | text |  |
| read_at | timestamptz NULL |  |

### `audit_logs`
**Purpose:** record of important actions (not all of them).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK NULL | |
| action | text | |
| entity_type | text | Table that `entity_id` points to |
| entity_id | bigint | Polymorphic, no foreign key |
| ip | inet | |
| central_owner_id | bigint NULL | Owner who performed the action remotely; `user_id` is empty in that case |
| request_id | uuid NULL UNIQUE | Identifier of the remote command, prevents repeating it |
| created_at | timestamptz | |

---

# 2. Central database (9 tables)

Chain: owner → company → premises → local installation. The database is in Supabase (decided); the logic is in the central server application, which connects to it.

### `owners`
**Purpose:** owners who check their premises.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| name | text | |
| email | text UNIQUE | |
| password_hash | text | Laravel's own login (not Supabase Auth) |
| active | boolean | |

### `companies`
**Purpose:** each owner's companies.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| owner_id | bigint FK → owners.id |  |
| name | text |  |

### `locations`
**Purpose:** premises of each company.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| company_id | bigint FK → companies.id |  |
| name | text |  |
| address | text |  |
| active | boolean |  |

### `local_installations`
**Purpose:** installation of the server software at a premises and its connection state.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| location_id | bigint FK UNIQUE → locations.id | |
| installation_id | uuid UNIQUE | Matches the premises' `restaurant.installation_id` |
| key_hash | text | Hash of the local's key. **Never in plain text** |
| last_connection | timestamptz | |
| software_version | text | |
| active | boolean | |
| revoked_at | timestamptz NULL | |

There is no `api_url`: the local server opens the connection to the central.

### `pairing_tokens`
**Purpose:** single-use tokens to pair a premises through a QR code.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| location_id | bigint FK → locations.id |  |
| token_hash | text UNIQUE | Hash of the token. Never in plain text |
| expires_at | timestamptz | Short-lived |
| used_at | timestamptz NULL | Filled in when used; it cannot be used again |

### `access_logs`
**Purpose:** who queried which premises and when. **It does not store the content of the data.**

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| owner_id | bigint FK → owners.id |  |
| location_id | bigint FK → locations.id |  |
| query_code | text | Type of query or change (for example `INCOME`, `EXPENSES`) |
| result_status | text | Outcome of the request |
| created_at | timestamptz |  |

### `admins`
**Purpose:** global administrators.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| name | text |  |
| email | text UNIQUE |  |
| password_hash | text |  |
| active | boolean |  |

### `admin_permissions`
**Purpose:** permissions available to administrators.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK |  |
| code | text UNIQUE |  |
| description | text |  |

### `admin_user_permissions`
**Purpose:** permissions of each administrator. Join table.

| Column | Type | Notes |
|---|---|---|
| admin_id | bigint FK → admins.id | PK (admin_id, permission_id) |
| permission_id | bigint FK → admin_permissions.id |  |

---

# 3. Owner statistics (calculated, no table)

They are calculated by the local server, which sends only totals. There is no statistics table.

| Statistic | Calculated from |
|---|---|
| Income per day, month, payment method | `payments` (state `PAID`) and `orders` |
| Expenses per period and type (salaries, suppliers) | `expenses` and their detail tables |
| Employees: hours, salary cost, sales per waiter | `employee_work_hours`, `salary_payments`, `orders` |
| Products: units sold, income per product and category | `order_items`, `products`, `categories` |
| Low stock | `ingredients` |
| Comparison between premises | One query per premises; nothing is stored in the central |

**Recommended indexes:** `orders(created_at)`, `orders(type)`, `payments(created_at)`, `payments(order_id)`, `expenses(expense_date)`, `order_items(product_id)`, `employee_work_hours(week_start)`, `notifications(user_id, read_at)`.

# 4. Database security

- Passwords always as a hash.
- The local's key only as a hash in the central. In the local, the secret is kept outside the table.
- The database user used by the admin panel **must have no permission** on `payments`, `expenses`, `salary_payments` or `supplier_payments`. It is a second barrier in addition to the server.
- In the central, each owner only sees their own companies and premises (row-level security policies).
- Closed orders and payments are neither edited nor deleted.
- Permissions are checked on the server, not only in the interface.

# 5. Aspects to define

- Ticket and VERI*FACTU: all ticket data is stored in the database; it remains to define whether the ticket has tax effects.
