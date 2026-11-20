# Matriz de permisos

**Leer en otros idiomas:** [English](permissions.md)

Leyenda: ✔ puede · ✘ no puede · 👁 solo ver · L = solo su propio local · R = también en remoto (app del propietario)

Reglas generales:
- El **encargado** gestiona **1 local**. El **propietario** gestiona **todos** sus locales.
- El administrador global (`ADMIN`) **nunca** ve datos económicos (ventas, ingresos, gastos, pagos, beneficios, estadísticas económicas).
- Los permisos se comprueban en el servidor. Permisos efectivos = permisos del rol + permisos individuales.
- Remoto (app del propietario): puede gestionar productos y precios, empleados (incluido borrar y cambiar rol), mesas, y horas y salarios.
  Solo consulta pedidos y pagos. **No** toca pedidos, pagos ni reservas.

| Acción | OWNER | MANAGER | WAITER | KITCHEN | DELIVERY | ADMIN global |
|---|---|---|---|---|---|---|
| Gestionar empleados (alta, baja, rol) | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Asignar permisos individuales a empleados | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Gestionar productos, categorías, ingredientes, modificadores y precios | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Gestionar mesas y agrupaciones | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Ver estado de las mesas | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Crear y modificar pedidos abiertos | ✔ | ✔ | ✔ (de cualquier mesa activa) | ✘ | ✘ | ✘ |
| Anular o borrar un pedido abierto (queda en `audit_logs`) | ✔ | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Ver pedidos de cocina | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ |
| Ver pedidos y pagos (consulta) | ✔ R | ✔ L | pedidos abiertos de las mesas activas, sin importar quién los empezó | ✘ | ✘ | ✘ |
| Confirmar pago y entregar ticket | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Reembolsar un pago | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| Gestionar clientes | ✔ | ✔ | ✔ | ✘ | 👁 los de sus repartos | ✘ |
| Gestionar reservas | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Asignar repartos | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Ver y actualizar sus repartos | ✘ | ✘ | ✘ | ✘ | ✔ | ✘ |
| Ver inventario y avisos de stock | ✔ R | ✔ L | ✘ | ✔ | ✘ | ✘ |
| Modificar existencias | ✔ | ✔ | ✘ | ✔ | ✘ | ✘ |
| Gestionar proveedores | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| Registrar horas de empleados | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Registrar pago de salarios y horas extra | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Registrar pago a proveedores | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| Ver gastos (salarios y pagos a proveedores) y estadísticas | ✔ R | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Ver sus propias horas y bolsa de descanso | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ |
| Configuración del local (copias, multiplicador de horas extra) | ✔ | ✔ L | ✘ | ✘ | ✘ | ✘ |
| Ver registro de auditoría (`audit_logs`) del local | ✔ | ✔ L | ✘ | ✘ | ✘ | ✘ |
| **Gestionar la base de datos central** (propietarios, empresas, locales, instalaciones, administradores y sus permisos) | ✘ | ✘ | ✘ | ✘ | ✘ | ✔ |

Decisiones del equipo:
- El encargado ve todos los datos de su local, incluidos salarios y pagos a proveedores.
- El camarero ve los pedidos abiertos de las mesas activas en ese momento, sin importar quién empezó a atender la mesa. Un pedido cerrado deja de verse.
- Solo el propietario y el encargado pueden anular o borrar un pedido abierto. Los cerrados no se borran. Si más adelante deben poder hacerlo más roles, se añade el permiso.
- El administrador global **solo se encarga de la base de datos central**. No gestiona nada dentro de un local (empleados, productos, mesas, configuración, auditoría) ni ve datos económicos.
- El camarero puede modificar los pedidos abiertos de cualquier mesa activa.
