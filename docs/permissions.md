# Permission matrix

**Read this in other languages:** [Español](permissions.es.md)

Legend: ✔ allowed · ✘ not allowed · 👁 view only · L = own premises only · R = also remotely (owner app)

General rules:
- The **manager** manages **1 premises**. The **owner** manages **all** their premises.
- The global administrator (`ADMIN`) **never** sees economic data (sales, income, expenses, payments, profits, economic statistics).
- Permissions are checked on the server. Effective permissions = role permissions + individual permissions.
- Remote (owner app): can manage products and prices, employees (including deleting and changing role), tables, and hours and salaries.
  Orders and payments are only viewed. It does **not** touch orders, payments or reservations.

| Action | OWNER | MANAGER | WAITER | KITCHEN | DELIVERY | Global ADMIN |
|---|---|---|---|---|---|---|
| Manage employees (create, remove, role) | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Assign individual permissions to employees | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Manage products, categories, ingredients, modifiers and prices | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Manage tables and table groups | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| View table status | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Create and modify open orders | ✔ | ✔ | ✔ (any active table) | ✘ | ✘ | ✘ |
| Cancel or delete an open order (recorded in `audit_logs`) | ✔ | ✔ L | ✘ | ✘ | ✘ | ✘ |
| View kitchen orders | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ |
| View orders and payments (read) | ✔ R | ✔ L | open orders of active tables, regardless of who started them | ✘ | ✘ | ✘ |
| Confirm payment and hand over the ticket | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Refund a payment | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| Manage customers | ✔ | ✔ | ✔ | ✘ | 👁 those of their deliveries | ✘ |
| Manage reservations | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Assign deliveries | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| View and update their own deliveries | ✘ | ✘ | ✘ | ✘ | ✔ | ✘ |
| View inventory and stock alerts | ✔ R | ✔ L | ✘ | ✔ | ✘ | ✘ |
| Modify stock | ✔ | ✔ | ✘ | ✔ | ✘ | ✘ |
| Manage suppliers | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| Record employee hours | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Record salary and overtime payments | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Record supplier payments | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| View expenses (salaries and supplier payments) and statistics | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| View their own hours and time-off bank | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ |
| Premises settings (backups, overtime multiplier) | ✔ | ✔ L | ✘ | ✘ | ✘ | ✘ |
| View the premises audit log (`audit_logs`) | ✔ | ✔ L | ✘ | ✘ | ✘ | ✘ |
| **Manage the central database** (owners, companies, premises, installations, administrators and their permissions) | ✘ | ✘ | ✘ | ✘ | ✘ | ✔ |

Team decisions:
- The manager sees all data of their premises, including salaries and supplier payments.
- The waiter sees the open orders of the tables that are active at that moment, regardless of who started serving the table. A closed order is no longer visible.
- Only the owner and the manager can cancel or delete an open order. Closed orders are never deleted. If more roles should be able to do it later, the permission is added.
- The global administrator **only takes care of the central database**. They manage nothing inside a premises (employees, products, tables, settings, audit) and see no economic data.
- The waiter can modify the open orders of any active table.
