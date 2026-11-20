# RacoDesk

> Restaurant management system for businesses with one or several premises. Each restaurant runs on its own local server, so it keeps working without Internet, while owners can supervise their premises remotely.

**Read this in other languages:** [Español](README.es.md)

## About the project

RacoDesk is the final project (*Proyecto Intermodular*) of the Higher Technical Degree in Multiplatform Application Development (DAM, 2nd year) at Victoria Institute of Technology.

**Current status:** analysis and design stage. Source code will be added progressively as development iterations are completed. Everything described below is the planned design, not implemented functionality.

## The problem

Managing a restaurant means coordinating tables, orders, kitchen, payments, reservations, stock, expenses and staff at the same time. In many businesses these tasks are spread across separate tools, and when an owner has several premises it is impossible to be present in all of them or to know in time what is happening in each one. If the system also depends on a permanent Internet connection, a network failure can stop the service in the middle of the day.

## How it works (planned design)

- **Local server (one per restaurant).** Runs the business logic and exposes an API, with its own database. Staff devices connect to it through the restaurant's local network, so daily work does not depend on Internet or on the central server.
- **Central server.** Stores only general information: owners, companies, premises, local installations and global administrators with their permissions. It does **not** keep a copy of the operational or financial data of the restaurants. The mechanism for remote access from the central server to the local servers has not been decided yet.
- **Employee app (Android).** Used by restaurant staff according to their role.
- **Owner app (Android).** Lets owners check sales, income, expenses and history of all their premises.
- **Admin web panel.** Separate interface for global administrators. Administrators cannot access financial information, and this restriction is enforced on the server, not only in the interface.
- **Permissions** are always checked on the server.

## Planned features

- Employees, roles and permissions
- Tables and table groups
- Orders and products
- Categories, ingredients and modifiers
- Customers and reservations
- Delivery orders and drivers
- Payments and expenses, with a ticket for the customer
- Inventory and low-stock alerts
- Notifications
- Statistics

## User roles

| Role | Identifier |
|---|---|
| Owner | `OWNER` |
| Manager | `MANAGER` |
| Waiter | `WAITER` |
| Kitchen | `KITCHEN` |
| Delivery driver | `DELIVERY` |

The global administrator (`ADMIN`) is independent from these local roles. The complete permission matrix is still to be defined.

## Technology stack (provisional)

> All technologies are provisional and may change as the project progresses.

| Area | Technology |
|---|---|
| Android apps | JavaScript, React Native |
| Admin web panel | JavaScript, React |
| Servers (local and central) | PHP, Laravel |
| Database | PostgreSQL |
| Tools | Git and GitHub, Visual Studio Code, Trello |

## Repository structure

```
RacoDesk/
├── apps/
│   ├── employee-app/     # Android app for restaurant staff (React Native)
│   ├── owner-app/        # Android app for owners (React Native)
│   └── admin-panel/      # Web panel for global administrators (React)
├── servers/
│   ├── local-server/     # One per restaurant: API and local database (Laravel)
│   └── central-server/   # General information and remote access (Laravel)
├── docs/                 # Project documentation
└── .github/              # Issue and pull request templates
```

Each folder contains a short README that explains its purpose and current status.

## Development roadmap

The project follows an incremental and iterative model with two-week iterations.

| Iteration | Goal |
|---|---|
| 0 | Planning, analysis and base design |
| 1 | Local server: database, API, authentication, employees and permissions |
| 2 | Tables, categories, products, ingredients, modifiers and orders |
| 3 | Payments and ticket, expenses, inventory and notifications |
| 4 | Customers, reservations, delivery orders and drivers |
| 5 | Central server and communication with local servers |
| 6 | Owner app, statistics and admin panel |
| 7 | Stabilization, acceptance tests and documentation |

## Team

| Name | GitHub |
|---|---|
| Mario Hernández Ramos | [@MarioHR2711](https://github.com/MarioHR2711) |
| Alejandro Domínguez Mora | [@alexdm0749-ops](https://github.com/alexdm0749-ops) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the branching and commit conventions used by the team.

## License

This project is released under the [MIT License](LICENSE).
