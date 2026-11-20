# CLAUDE.es.md — Contexto del proyecto RacoDesk

**Leer en otros idiomas:** [English](CLAUDE.md)

> Versión en español de `CLAUDE.md`, que es la que lee Claude Code. Si cambia una, hay que actualizar la otra.

Este archivo da contexto a Claude Code. Resume lo hablado y decidido hasta ahora por el equipo.
**Regla principal:** no inventes decisiones. Si algo está marcado como pendiente, pregunta antes de decidir.
El repositorio es **público**: nunca escribas contraseñas, claves, `.env` reales ni datos reales de clientes.
**Claude Code escribe el código** del proyecto. El equipo revisa y decide.

## Qué es

RacoDesk es el Proyecto Intermodular (TFG) de DAM, 2.º curso, en Victoria Institute of Technology.
Es un sistema de gestión para restaurantes con uno o varios locales. Cada restaurante tiene su propio
servidor local y su propia base de datos, así que sigue funcionando sin Internet. El propietario consulta
sus locales a distancia.

Estado: fase de diseño. **Todavía no hay código.** No presentes como hecho nada que sea solo diseño.

## Equipo

- Mario Hernández Ramos — GitHub `MarioHR2711` (dueño del repo)
- Alejandro Domínguez Mora — GitHub `alexdm0749-ops` (colaborador)
- No hay reparto de tareas confirmado. No asignes módulos a nadie sin preguntar.

## Arquitectura

- **Servidor local (uno por restaurante):** lógica, API y base de datos propia. Comprueba permisos.
  Es un **TPV normal con Windows** en el restaurante. Si hay varios terminales, el software de servidor se instala
  **solo en uno** y el software de empleado en **todos**. Las apps **nunca** acceden directo a la base de datos;
  hablan con la API del servidor local por la red del local.
- **Servidor central:** guarda solo información general (propietarios, empresas, locales, instalaciones locales,
  administradores globales y sus permisos). **No guarda copia de pedidos, pagos, gastos ni datos operativos.**
  **Decidido:** la **base de datos** del central está en **Supabase** (PostgreSQL) y la **lógica y funcionalidades**
  están en una **aplicación de servidor central propia** (Laravel, provisional), no en Edge Functions.
- **App de empleados:** operaciones del local según rol. Una versión Android y una versión **idéntica en Windows** para los TPV,
  con **React Native** (React Native for Windows para el TPV).
- **App del propietario (Android):** consulta (ver estadísticas abajo) y **también puede modificar cosas en remoto**
  (solo las acciones permitidas, ver «Acceso remoto»).
- **Panel web de administración:** para administradores globales. **Solo se encarga de la base de datos central** (propietarios, empresas, locales, instalaciones, administradores y sus permisos).
  No gestiona empleados, productos, mesas ni configuración de ningún local.
- **Sin Internet:** el local sigue trabajando (pedidos, mesas, productos, reservas, clientes, inventario, pagos, gastos).
  Solo falla la consulta remota. En ese caso la app del propietario muestra un mensaje de que **no es posible conectar con el servidor** (no se muestran datos antiguos).
- **Sin suscripciones:** no hay planes ni cobros por suscripción.

### Reglas de negocio confirmadas

- Un **encargado** gestiona **1 local**. Un **propietario** gestiona **todos** sus locales.
- Un pedido se da por **pagado** cuando el **camarero confirma** el pago. Se permiten **pagos parciales**: varios cobros por pedido; se cierra al sumar el total.
- El **ticket** se entrega al cliente cuando paga la cuenta.
- Los **gastos** salen de: pago de salarios y pago a proveedores de productos.
- `employee_work_hours` guarda las horas trabajadas **por semana** por empleado, para calcular el salario pagado ese mes.
- **Horas extra:** el empleado elige entre **cobrarlas** o **tiempo de descanso** (`overtime_choice`: `PAID` o `TIME_OFF`).
  Las cobradas se suman al salario del mes; las de descanso forman una bolsa de horas que se descuenta con `time_off_records`.
  Tarifa de las horas extra cobradas: depende del convenio; se configura con `restaurant.overtime_multiplier`.
- **Semana que cruza dos meses:** la semana cuenta para el mes en que cae su **jueves** (`week_start` + 3 días; regla ISO).
- **Copias de seguridad:** automáticas **cada día**, guardadas por defecto **en el mismo equipo**. **Decidido:** la carpeta de destino debe poder configurarse (`restaurant.backup_path`).
  Aviso: con la copia solo en el mismo equipo, un fallo del disco pierde datos y copia; recomendar copia externa.
- Matriz de permisos por rol: `docs/permissions.es.md`.

### Estadísticas de la app del propietario

Ingresos, gastos, empleados (horas, coste, ventas), productos (más vendidos, ingresos por producto y categoría), stock bajo,
comparación entre locales. Las calcula el servidor local y envía totales. No hay tabla de estadísticas.

### Reglas de seguridad (obligatorias)

1. Los permisos se comprueban **en el servidor**, no solo ocultando botones.
2. El administrador global **no puede** ver ventas, ingresos, gastos, pagos, beneficios ni estadísticas económicas.
   Se aplica también en las APIs; el servidor debe rechazar la petición.
3. Contraseñas guardadas como `password_hash`.
4. Auditoría: tabla `audit_logs` solo para acciones importantes.
5. RGPD (desarrollo): datos personales definidos por el equipo: **empleados** = nombre, apellidos, teléfono, email, dirección; **clientes de reparto** = nombre, teléfono, dirección. No guardes más datos personales; los datos de clientes y empleados viven en el servidor local;
   el central solo tiene datos de propietarios y administradores; Supabase en **región de la UE**; poder borrar o anonimizar a un cliente o empleado
   si lo pide; nunca registrar datos personales en logs; avisar al propietario ante una brecha.

## Acceso remoto del propietario

Objetivo: que el propietario vea sus locales a distancia de forma **segura y eficiente**, sin que el central guarde datos operativos.
Se empieza **directamente con WebSocket** (sin fase de cola de peticiones).

Idea clave: el servidor local **abre** una conexión de salida al central. Nunca se abren puertos en el router del restaurante.

```
App propietario --HTTPS--> Servidor central <==WebSocket seguro== Servidor local
   (token corto)           (relay, no guarda)    (lo abre el local)
```

Flujo: la app pide un dato → el central valida el token y reenvía la petición al local → el local responde solo con
lo pedido → el central pasa la respuesta y **no la guarda**.

Seguridad:
- Todo cifrado con TLS (HTTPS / WSS).
- Clave propia por local, creada en la vinculación por QR con token de un solo uso y caducidad corta. Revocable.
- Token del propietario de vida corta, con renovación.
- El **local comprueba** (`linked_owners`) que ese propietario es dueño de ese local; no fiarse solo del central.
- Lista cerrada de operaciones permitidas (consultas y, ahora, **modificaciones** del propietario). El central **no** es un túnel libre.
- Las modificaciones remotas: las valida y **ejecuta el servidor local** con sus propias reglas y permisos; el central nunca escribe en la BD local.
  Cada una queda en `audit_logs` (con el propietario que la pidió), lleva identificador único para no repetirse (idempotencia)
  y puede requerir que el local esté conectado (si no, se rechaza con mensaje claro; no se encolan).
- **Acciones que el propietario puede hacer en remoto (decidido):** gestionar productos y precios (categorías, ingredientes, modificadores),
  empleados (incluido **borrarlos y cambiar su rol**), mesas, y horas trabajadas y salarios.
- **No puede tocar en remoto:** pedidos, pagos, reservas (ni clientes). Eso solo se hace en el local. En remoto solo los consulta (salvo reservas, que ni siquiera se tocan).
- Cualquier acción fuera de esta lista debe rechazarla el servidor local.
- Límite de peticiones por usuario y por local.
- Registro de accesos (`access_logs`) **sin guardar el contenido**.
- El admin global no puede pedir datos económicos: solo un token de propietario las acepta.
- Mejora futura opcional: cifrado de extremo a extremo entre app y local.

Eficiencia: el local envía totales resumidos; paginación y compresión; caché muy corta solo en memoria (opcional, documentarla).

### Supabase en el central (decidido)

- Supabase solo aporta la **base de datos PostgreSQL** del central. La aplicación del servidor central (Laravel, provisional)
  se aloja aparte y se conecta a esa BD; aloja también el WebSocket de relay (por ejemplo Laravel Reverb).
- Supabase no puede alojar Laravel. **Decidido:** la aplicación central Laravel se ejecuta en un **ordenador con Windows**.
  Ese equipo debe ser alcanzable desde Internet por los locales y por la app del propietario (IP pública/dominio, HTTPS, puertos o túnel: por resolver).
- Detalle por resolver: el servidor local es **cliente** del WebSocket; Reverb es servidor, así que el local usará una librería cliente compatible.
- Como los datos económicos pasan por un tercero (el central), elegir región UE (RGPD) y valorar el cifrado de extremo a extremo.

## Tecnologías (PROVISIONALES, pueden cambiar)

| Área | Tecnología |
|---|---|
| Apps Android y Windows | JavaScript + React Native (React Native for Windows) |
| Panel web | JavaScript + React |
| Servidor local | PHP + Laravel (Sanctum), PostgreSQL |
| Servidor central | App Laravel (provisional) + BD PostgreSQL en Supabase. Login de propietarios y admins: propio de Laravel (Sanctum), **no** Supabase Auth |
| Base de datos | PostgreSQL |
| Herramientas | VS Code, Git/GitHub, Trello |
| Pruebas | PHPUnit/Pest (servidores), Jest (apps) |

Decidido: la app de empleados en Windows se hace con **React Native for Windows** (mismo código que Android, instalada en el TPV).
Pueden hacer falta módulos nativos de Windows (por ejemplo impresión de tickets).

Sin decidir: herramienta de diseño de interfaces (no por ahora), Docker, descubrimiento del servidor en la LAN (IP fija o mDNS).

## Pendiente de decidir (pregunta antes de implementar)

- Cómo se hace alcanzable desde Internet el ordenador Windows del central (IP/dominio, HTTPS, túnel).
- Copia de seguridad externa recomendada (el TPV servidor y el central son punto único de fallo).
- RGPD: política de privacidad, conservación, derecho a borrar datos, aviso de brechas (ver reglas de desarrollo en «Reglas de seguridad»).
- Facturación: el cliente recibe un **ticket**. Falta analizar si tiene efectos fiscales y si afecta VERI*FACTU
  (preguntar al tutor). No afirmes que RacoDesk cumple VERI*FACTU.

## Funcionalidades definidas

1. Empleados y permisos
2. Mesas y agrupaciones de mesas
3. Pedidos y productos
4. Categorías, ingredientes y modificadores
5. Clientes y reservas
6. Pedidos a domicilio y repartidores
7. Pagos y gastos (con ticket al cliente)
8. Inventario y avisos de stock
9. Notificaciones
10. Estadísticas

Las horas de trabajo y salarios forman parte de gastos y estadísticas (`employee_work_hours`, `salary_payments`).

## Roles

Matriz de permisos: `docs/permissions.es.md`.

Locales: `OWNER`, `MANAGER`, `WAITER`, `KITCHEN`, `DELIVERY`. El `ADMIN` global es independiente.
Permisos efectivos = permisos del rol + permisos individuales (`role_permissions` + `user_permissions`).
Admins globales: tablas separadas `admin_permissions` y `admin_user_permissions`.

## Modelo de datos

Esquema completo (todas las tablas, campos y función de cada tabla): **`docs/database.es.md`**. Léelo antes de crear migraciones.

**Base local (33 tablas):** restaurant, roles, permissions, role_permissions, users, user_permissions, linked_owners,
employee_work_hours, salary_payments, time_off_records, tables, table_groups, table_group_members, categories, products, suppliers,
ingredients, product_ingredients, ingredient_modifiers, customers, orders, order_items, order_item_modifiers,
reservations, reservation_tables, delivery_drivers, delivery_orders, payments, expenses, supplier_payments,
user_devices, notifications, audit_logs.

**Base central (9 tablas):** owners, companies, locations, local_installations, pairing_tokens, access_logs,
admins, admin_permissions, admin_user_permissions.

Decisiones de diseño:
- Estados de mesa: `AVAILABLE`, `OCCUPIED`, `RESERVED`. Una agrupación se reutiliza; no hay historial.
- Tipos de pedido: `DINE_IN` (mesa o agrupación), `TAKEAWAY`, `DELIVERY`. No hay flujo de estados; se sabe si está pagado por `closed_at`.
- Modificadores: `REMOVE` y `EXTRA`.
- Se guarda precio e IVA del producto en el momento del pedido. Precio con IVA incluido.
- Reservas: `PENDING`, `CONFIRMED`, `CANCELLED`, `COMPLETED`, con restricción anti-solape.
- Pagos: `CASH`, `CARD`, `ONLINE`; estados `PENDING`, `PAID`, `FAILED`, `REFUNDED`.
- Gastos: tabla `expenses` con tipo `SALARY` o `SUPPLIER` y tablas de detalle (`salary_payments`, `supplier_payments`).
- Notificaciones: `LOW_STOCK` (encargado y propietario), `NEW_ORDER` (cocina).
- Inventario: existencias y mínimos en `ingredients`. No hay `inventory_movements`.
- Reparto opcional por restaurante.
- `audit_logs.entity_id` es polimórfico.

## Plan de trabajo (lo que se va a hacer)

Incremental e iterativo, con prácticas de Scrum adaptadas a dos personas. Iteraciones de dos semanas (sin fechas oficiales).

| It. | Qué se hará |
|---|---|
| 0 | Repo, CI básica, estructura de carpetas; primer código mínimo para subir a Git |
| 1 | Servidor local: Laravel + PostgreSQL, migraciones (`docs/database.es.md`), autenticación, empleados, roles y permisos, `audit_logs` |
| 2 | Mesas y agrupaciones, categorías, productos, ingredientes, modificadores, pedidos (sala, llevar) |
| 3 | Pagos (confirmación del camarero) y ticket, gastos, proveedores, horas semanales y salarios, inventario, notificaciones |
| 4 | Clientes, reservas, pedidos a domicilio, repartidores |
| 5 | Central (app Laravel + BD en Supabase) y comunicación por WebSocket con locales: vinculación por QR, `linked_owners`, consultas y modificaciones remotas permitidas, `access_logs`, mensaje de «sin conexión» |
| 6 | App del propietario con estadísticas y modificaciones remotas, panel de administración (sin acceso económico), versión Windows de la app de empleados |
| 7 | Estabilización, pruebas de aceptación, copias de seguridad, RGPD, documentación, entrega |

Orden de trabajo para Claude Code en cada tarea: explicar qué va a hacer → esperar confirmación si es un cambio grande →
escribir código y pruebas → dejarlo listo para revisión del compañero.

Trello: **Pending → Working → Check → Done**. Al terminar se pasa a *Check*; el compañero revisa. Si falla vuelve a *Working* con una nota.
Definición de «Hecho»: código revisado, pruebas pasan, criterio cumplido, documentación al día.

## Convenciones del repositorio

- Ramas: `main` (estable), `feature/<nombre>`, `fix/<nombre>`, `docs/<nombre>`. Trabajo en rama + pull request revisada por el compañero.
- Commits en inglés: `tipo: descripción` con `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- **Documentación en dos idiomas:** el archivo por defecto está en inglés (`README.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `docs/database.es.md`, ...)
  y la versión en español tiene el mismo nombre con `.es` antes de la extensión (`README.es.md`, `CONTRIBUTING.es.md`, ...).
  Cada vez que cambie un documento, **actualiza las dos versiones**.
- Código y comentarios en inglés.
- Estructura: `apps/employee-app`, `apps/owner-app`, `apps/admin-panel`, `servers/local-server`, `servers/central-server`, `docs/`.
- Licencia MIT.
- No inventes funcionalidades fuera de la lista. Marca como provisional cualquier tecnología.

## Cómo trabajar con el equipo

- Antes de grandes cambios, explica qué vas a hacer y espera confirmación.
- Los commits los hacen los integrantes con su propio usuario de Git.
- Git: por ahora se deja como está; aún no hay nada importante subido.
- Los usuarios prefieren explicaciones en español.
