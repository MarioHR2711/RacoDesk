# Base de datos de RacoDesk

**Leer en otros idiomas:** [English](database.md)

> **Estado:** diseño aún no implementado. PostgreSQL previsto. Las tecnologías son provisionales.

Hay dos bases de datos independientes:

- **Local:** una por restaurante, en el servidor local (un PC con Windows). Guarda todos los datos operativos y económicos de ese restaurante.
- **Central:** general, en Supabase (provisional). Guarda propietarios, empresas, locales, instalaciones y administradores. **No guarda pedidos, pagos ni gastos.**

**Convenciones:** claves `id bigint` autoincremental (salvo que se indique); importes `numeric(10,2)`; fechas `timestamptz` en UTC; `created_at` y `updated_at` en todas las tablas salvo las de unión; `deleted_at` (borrado suave) donde se indica.

**Reglas generales del equipo:**
- Un **encargado** gestiona **un** local. Un **propietario** gestiona **todos** sus locales.
- Un pedido se da por **pagado** cuando el camarero confirma el pago. El **ticket** se entrega al cliente después de pagar.
- Los **gastos** salen de dos fuentes: pago de salarios y pago a proveedores de productos.
- Las horas trabajadas se anotan **por semana** y sirven para calcular el salario del mes.
- No hay suscripciones.

---

# 1. Base local (33 tablas)

## 1.1 Usuarios, roles y permisos

### `restaurant`
**Función:** datos generales del restaurante. Tiene una sola fila.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| name | text | |
| installation_id | uuid UNIQUE | Identificador público de la instalación. Debe coincidir con el del central. El secreto va en `.env` o cifrado, **no** en esta tabla |
| delivery_enabled | boolean | El reparto es opcional por restaurante |
| overtime_multiplier | numeric(4,2) | Multiplicador de las horas extra cobradas. 1.00 = igual que la hora normal; se ajusta según el convenio |
| backup_path | text NULL | Carpeta de las copias de seguridad diarias. Configurable; por defecto, una carpeta del mismo equipo |
| legal_name, tax_id, address, phone | text | Datos del negocio que se imprimen en el ticket |

### `roles`
**Función:** lista de roles locales.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| code | text UNIQUE | `OWNER`, `MANAGER`, `WAITER`, `KITCHEN`, `DELIVERY` |
| name | text | |

### `permissions`
**Función:** lista de acciones que se pueden permitir (por ejemplo gestionar productos). La matriz por rol está en `docs/permissions.es.md`.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| code | text UNIQUE | |
| description | text | |

### `role_permissions`
**Función:** qué permisos tiene cada rol. Tabla de unión.

| Columna | Tipo | Notas |
|---|---|---|
| role_id | bigint FK → roles.id | PK (role_id, permission_id) |
| permission_id | bigint FK → permissions.id |  |

### `users`
**Función:** empleados que usan el sistema en el local.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| role_id | bigint FK → roles.id | |
| first_name | text | Nombre |
| last_name | text | Apellidos |
| phone | text | |
| address | text | |
| email | text UNIQUE | También sirve para iniciar sesión |
| password_hash | text | |
| active | boolean | |
| hourly_rate | numeric(8,2) NULL | Precio por hora, para calcular el salario |
| deleted_at | timestamptz NULL | |

### `user_permissions`
**Función:** permisos extra asignados a un usuario concreto. Permisos efectivos = permisos del rol + permisos individuales. Tabla de unión.

| Columna | Tipo | Notas |
|---|---|---|
| user_id | bigint FK → users.id | PK (user_id, permission_id) |
| permission_id | bigint FK → permissions.id |  |

### `linked_owners`
**Función:** propietarios autorizados a consultar este local desde el exterior. El local comprueba aquí la autorización y no se fía solo del central.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| central_owner_id | bigint | Id del propietario en el central |
| linked_at | timestamptz | |
| revoked_at | timestamptz NULL | |

## 1.2 Horas y salarios

### `employee_work_hours`
**Función:** horas trabajadas por cada empleado **cada semana**. Con ellas se calcula el salario del mes.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK → users.id | |
| week_start | date | Lunes de la semana. UNIQUE (user_id, week_start) |
| hours_worked | numeric(5,2) | |
| overtime_hours | numeric(5,2) NOT NULL default 0 | Horas extra de la semana |
| overtime_choice | enum NULL | `PAID` (cobrar) o `TIME_OFF` (descanso). Lo elige el empleado |
| registered_by | bigint FK → users.id | Quien anota las horas |

Cálculo: salario del mes = (suma de `hours_worked` de las semanas de ese mes + horas extra con `PAID`) × `users.hourly_rate`
(tarifa de las horas extra: `restaurant.overtime_multiplier`).
**Regla de mes:** una semana cuenta para el mes en que cae su **jueves** (`week_start` + 3 días).
Las horas extra con `TIME_OFF` van a la bolsa de descanso del empleado (ver `time_off_records`).

### `time_off_records`
**Función:** descansos tomados por un empleado a cambio de horas extra. Bolsa de descanso =
suma de `overtime_hours` con `TIME_OFF` − suma de `hours` de esta tabla.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK → users.id | |
| taken_on | date | Día de descanso |
| hours | numeric(5,2) | Horas descontadas |
| registered_by | bigint FK → users.id | |

### `salary_payments`
**Función:** pago mensual del salario a un empleado. Cada pago crea un gasto de tipo `SALARY`.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| expense_id | bigint FK UNIQUE → expenses.id | |
| user_id | bigint FK → users.id | Empleado que cobra |
| month | date | Primer día del mes. UNIQUE (user_id, month) |
| hours_total | numeric(6,2) | Horas del mes |
| hourly_rate | numeric(8,2) | Precio por hora en ese momento |
| amount | numeric(10,2) | |

## 1.3 Mesas

### `tables`
**Función:** mesas del restaurante y su estado.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| number | integer UNIQUE | Número visible |
| status | enum | `AVAILABLE`, `OCCUPIED`, `RESERVED` |
| active | boolean | |

### `table_groups`
**Función:** agrupaciones de varias mesas. Se reutilizan cuando dejan de estar activas. No hay historial.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| active | boolean |  |
| created_at | timestamptz |  |

### `table_group_members`
**Función:** qué mesas forman cada agrupación. Tabla de unión.

| Columna | Tipo | Notas |
|---|---|---|
| group_id | bigint FK → table_groups.id | PK (group_id, table_id) |
| table_id | bigint FK → tables.id |  |

Una mesa solo puede estar en una agrupación activa a la vez (se controla en la aplicación).

## 1.4 Productos e inventario

### `categories`
**Función:** categorías de productos.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| name | text |  |
| active | boolean |  |

### `products`
**Función:** carta del restaurante.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| category_id | bigint FK → categories.id | |
| name | text | |
| price | numeric(10,2) | Precio final con IVA incluido |
| tax_rate | numeric(5,2) | |
| active | boolean | Activar o desactivar |
| deleted_at | timestamptz NULL | |

### `suppliers`
**Función:** proveedores de los productos.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| name | text | |
| phone | text NULL | |
| email | text NULL | |
| tax_id | text NULL | |
| active | boolean | |
| deleted_at | timestamptz NULL | |

### `ingredients`
**Función:** ingredientes y existencias. De aquí salen los avisos de stock bajo.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| supplier_id | bigint FK NULL → suppliers.id | Proveedor habitual |
| name | text | |
| unit | text | |
| stock_quantity | numeric(10,3) | Existencias actuales |
| min_quantity | numeric(10,3) | Mínimo para avisar |

No hay tabla de movimientos de inventario (decisión del equipo).

### `product_ingredients`
**Función:** qué ingredientes lleva cada producto. Tabla de unión.

| Columna | Tipo | Notas |
|---|---|---|
| product_id | bigint FK → products.id | PK (product_id, ingredient_id) |
| ingredient_id | bigint FK → ingredients.id |  |
| quantity | numeric(10,3) | Cantidad del ingrediente en una unidad del producto |

### `ingredient_modifiers`
**Función:** modificaciones posibles de un ingrediente en un pedido.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| ingredient_id | bigint FK → ingredients.id | |
| type | enum | `REMOVE`, `EXTRA`. No existe `OPTION` |
| extra_price | numeric(10,2) | Por defecto 0 |

## 1.5 Clientes y pedidos

### `customers`
**Función:** clientes con su contacto y una dirección (para reservas y reparto).

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| name | text |  |
| phone | text |  |
| address | text NULL | Solo hace falta para reparto |
| deleted_at | timestamptz NULL |  |

No se guarda `email`: solo nombre, teléfono y dirección.
Para borrar a un cliente que lo pida se anonimiza (nombre, teléfono y dirección vacíos) y se conservan sus pedidos.

### `orders`
**Función:** pedidos de sala, para llevar y a domicilio.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK → users.id | Quien crea el pedido |
| customer_id | bigint FK NULL → customers.id | |
| table_id | bigint FK NULL → tables.id | |
| group_id | bigint FK NULL → table_groups.id | |
| type | enum | `DINE_IN`, `TAKEAWAY`, `DELIVERY` |
| total | numeric(10,2) | |
| ticket_number | integer UNIQUE NULL | Correlativo. Se asigna al confirmar el pago |
| closed_at | timestamptz NULL | Se rellena al confirmar el pago. Un pedido cerrado no se edita ni se borra |

Restricción: `DINE_IN` exige `table_id` o `group_id` (no ambos). `TAKEAWAY` y `DELIVERY` no llevan mesa. No hay flujo de estados de pedido: se sabe si está pagado por `closed_at`.

### `order_items`
**Función:** productos de cada pedido, con el precio de ese momento.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| order_id | bigint FK → orders.id | |
| product_id | bigint FK → products.id | |
| quantity | integer | |
| unit_price | numeric(10,2) | Precio en el momento del pedido |
| tax_rate | numeric(5,2) | IVA en el momento del pedido |

### `order_item_modifiers`
**Función:** modificadores aplicados a cada producto del pedido.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| order_item_id | bigint FK → order_items.id |  |
| ingredient_id | bigint FK → ingredients.id |  |
| type | enum | `REMOVE`, `EXTRA` |
| price | numeric(10,2) | Precio aplicado en el momento del pedido |

## 1.6 Reservas

### `reservations`
**Función:** reservas de clientes.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| customer_id | bigint FK → customers.id | |
| status | enum | `PENDING`, `CONFIRMED`, `CANCELLED`, `COMPLETED` |
| start_time | timestamptz | |
| end_time | timestamptz | |
| party_size | integer | |

### `reservation_tables`
**Función:** mesas asignadas a cada reserva. Impide dos reservas a la misma hora en la misma mesa.

| Columna | Tipo | Notas |
|---|---|---|
| reservation_id | bigint FK | |
| table_id | bigint FK | |
| during | tstzrange | Copia del rango de la reserva |
| active | boolean | Falso si la reserva se cancela |

Restricción (requiere la extensión `btree_gist`):
`EXCLUDE USING gist (table_id WITH =, during WITH &&) WHERE (active)`

## 1.7 Reparto

### `delivery_drivers`
**Función:** repartidores.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| user_id | bigint FK UNIQUE → users.id |  |
| active | boolean |  |

### `delivery_orders`
**Función:** seguimiento del reparto de un pedido a domicilio.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| order_id | bigint FK UNIQUE → orders.id | |
| driver_id | bigint FK → delivery_drivers.id | |
| assigned_at | timestamptz | |
| picked_up_at | timestamptz NULL | |
| delivered_at | timestamptz NULL | |

## 1.8 Dinero

### `payments`
**Función:** cobros de los pedidos. El pedido se da por pagado cuando el camarero confirma el pago.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| order_id | bigint FK → orders.id | |
| user_id | bigint FK → users.id | Camarero que confirma el pago |
| method | enum | `CASH`, `CARD`, `ONLINE` |
| status | enum | `PENDING`, `PAID`, `FAILED`, `REFUNDED` |
| amount | numeric(10,2) | |
| confirmed_at | timestamptz NULL | |

Al pasar a `PAID` se rellenan `orders.closed_at` y `orders.ticket_number`. Los pagos no se borran. **Pagos parciales (permitidos):** un pedido puede tener varios cobros (por ejemplo cada comensal paga lo suyo, o parte en efectivo y parte con tarjeta). El pedido se cierra y recibe su `ticket_number` cuando la suma de los cobros `PAID` iguala el total. El ticket se entrega entonces.

### `expenses`
**Función:** tabla única de gastos. Hay dos tipos y cada gasto tiene exactamente una fila de detalle.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| type | enum | `SALARY`, `SUPPLIER` |
| user_id | bigint FK → users.id | Quien registra el gasto |
| amount | numeric(10,2) | |
| expense_date | date | |

### `supplier_payments`
**Función:** detalle de un gasto de tipo `SUPPLIER` (pago a un proveedor).

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| expense_id | bigint FK UNIQUE → expenses.id | |
| supplier_id | bigint FK → suppliers.id | |
| concept | text | |
| invoice_number | text NULL | |

(El detalle de `SALARY` es `salary_payments`, ver 1.2.)

## 1.9 Dispositivos, avisos y control

### `user_devices`
**Función:** dispositivos de cada usuario (móviles, tabletas y TPV con Windows) y su dirección para enviar avisos.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| user_id | bigint FK → users.id |  |
| device_type | enum | `ANDROID`, `WINDOWS` |
| device_token | text | Dirección para enviar avisos al dispositivo |
| last_seen | timestamptz |  |

### `notifications`
**Función:** avisos a los usuarios.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| user_id | bigint FK → users.id | Destinatario |
| type | enum | `LOW_STOCK` (al encargado y propietario), `NEW_ORDER` (a cocina) |
| ingredient_id | bigint FK NULL → ingredients.id | Para `LOW_STOCK` |
| order_id | bigint FK NULL → orders.id | Para `NEW_ORDER` |
| message | text |  |
| read_at | timestamptz NULL |  |

### `audit_logs`
**Función:** registro de acciones importantes (no todas).

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK NULL | |
| action | text | |
| entity_type | text | Tabla a la que apunta `entity_id` |
| entity_id | bigint | Polimórfico, sin clave foránea |
| ip | inet | |
| central_owner_id | bigint NULL | Propietario que hizo la acción en remoto; `user_id` queda vacío en ese caso |
| request_id | uuid NULL UNIQUE | Identificador de la orden remota, evita repetirla |
| created_at | timestamptz | |

---

# 2. Base central (9 tablas)

Cadena: propietario → empresa → local → instalación local. La base de datos está en Supabase (decidido); la lógica está en la aplicación del servidor central, que se conecta a ella.

### `owners`
**Función:** propietarios que consultan sus locales.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| name | text | |
| email | text UNIQUE | |
| password_hash | text | Login propio de Laravel (no Supabase Auth) |
| active | boolean | |

### `companies`
**Función:** empresas de cada propietario.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| owner_id | bigint FK → owners.id |  |
| name | text |  |

### `locations`
**Función:** locales de cada empresa.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| company_id | bigint FK → companies.id |  |
| name | text |  |
| address | text |  |
| active | boolean |  |

### `local_installations`
**Función:** instalación del software de servidor en un local y su estado de conexión.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK | |
| location_id | bigint FK UNIQUE → locations.id | |
| installation_id | uuid UNIQUE | Coincide con `restaurant.installation_id` del local |
| key_hash | text | Hash de la clave del local. **Nunca en claro** |
| last_connection | timestamptz | |
| software_version | text | |
| active | boolean | |
| revoked_at | timestamptz NULL | |

No hay `api_url`: el servidor local abre la conexión hacia el central.

### `pairing_tokens`
**Función:** tokens de un solo uso para vincular un local por código QR.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| location_id | bigint FK → locations.id |  |
| token_hash | text UNIQUE | Hash del token. Nunca en claro |
| expires_at | timestamptz | De vida corta |
| used_at | timestamptz NULL | Se rellena al usarse; no se puede usar de nuevo |

### `access_logs`
**Función:** quién consultó qué local y cuándo. **No guarda el contenido de los datos.**

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| owner_id | bigint FK → owners.id |  |
| location_id | bigint FK → locations.id |  |
| query_code | text | Tipo de consulta o cambio (por ejemplo `INCOME`, `EXPENSES`) |
| result_status | text | Resultado de la petición |
| created_at | timestamptz |  |

### `admins`
**Función:** administradores globales.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| name | text |  |
| email | text UNIQUE |  |
| password_hash | text |  |
| active | boolean |  |

### `admin_permissions`
**Función:** permisos disponibles para administradores.

| Columna | Tipo | Notas |
|---|---|---|
| id | bigint PK |  |
| code | text UNIQUE |  |
| description | text |  |

### `admin_user_permissions`
**Función:** permisos de cada administrador. Tabla de unión.

| Columna | Tipo | Notas |
|---|---|---|
| admin_id | bigint FK → admins.id | PK (admin_id, permission_id) |
| permission_id | bigint FK → admin_permissions.id |  |

---

# 3. Estadísticas del propietario (calculadas, sin tabla)

Las calcula el servidor local y envía solo totales. No hay tabla de estadísticas.

| Estadística | Se calcula con |
|---|---|
| Ingresos por día, mes, método de pago | `payments` (estado `PAID`) y `orders` |
| Gastos por periodo y tipo (salarios, proveedores) | `expenses` y sus tablas de detalle |
| Empleados: horas, coste de salarios, ventas por camarero | `employee_work_hours`, `salary_payments`, `orders` |
| Productos: unidades vendidas, ingresos por producto y categoría | `order_items`, `products`, `categories` |
| Stock bajo | `ingredients` |
| Comparación entre locales | Una consulta por local; no se guarda nada en el central |

**Índices recomendados:** `orders(created_at)`, `orders(type)`, `payments(created_at)`, `payments(order_id)`, `expenses(expense_date)`, `order_items(product_id)`, `employee_work_hours(week_start)`, `notifications(user_id, read_at)`.

# 4. Seguridad en la base de datos

- Contraseñas siempre como hash.
- Clave del local solo como hash en el central. En el local, el secreto va fuera de la tabla.
- El usuario de base de datos que use el panel de administración **no debe tener permiso** sobre `payments`, `expenses`, `salary_payments` ni `supplier_payments`. Es una segunda barrera además del servidor.
- En el central, cada propietario solo ve sus propias empresas y locales (políticas de seguridad por fila).
- Pedidos cerrados y pagos no se editan ni se borran.
- Los permisos se comprueban en el servidor, no solo en la interfaz.

# 5. Aspectos por definir

- Ticket y VERI*FACTU: se guardan en la base de datos todos los datos del ticket; falta definir si el ticket tiene efectos fiscales.
