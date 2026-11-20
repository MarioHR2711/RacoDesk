# RacoDesk

> Sistema de gestión para restaurantes con uno o varios locales. Cada restaurante funciona con su propio servidor local, de modo que sigue operando sin Internet, mientras que el propietario puede supervisar sus locales a distancia.

**Leer en otros idiomas:** [English](README.md)

## Sobre el proyecto

RacoDesk es el Proyecto Intermodular del ciclo de Técnico Superior en Desarrollo de Aplicaciones Multiplataforma (DAM, 2.º curso) de Victoria Institute of Technology.

**Estado actual:** fase de análisis y diseño. El código se irá añadiendo de forma progresiva a medida que se completen las iteraciones de desarrollo. Todo lo que se describe aquí es el diseño previsto, no funcionalidad ya implementada.

## El problema

Gestionar un restaurante implica coordinar a la vez mesas, pedidos, cocina, cobros, reservas, existencias, gastos y personal. En muchos negocios estas tareas se reparten entre herramientas separadas y, cuando el propietario tiene varios locales, no puede estar presente en todos ni conocer a tiempo lo que ocurre en cada uno. Si además el sistema depende de una conexión permanente a Internet, un corte de red puede interrumpir el servicio en plena jornada.

## Cómo funciona (diseño previsto)

- **Servidor local (uno por restaurante).** Ejecuta la lógica del negocio y ofrece una API, con su propia base de datos. Los dispositivos del personal se conectan a él por la red local del restaurante, por lo que el trabajo diario no depende de Internet ni del servidor central.
- **Servidor central.** Guarda solo información general: propietarios, empresas, locales, instalaciones locales y administradores globales con sus permisos. **No** guarda copia de los datos operativos ni económicos de los restaurantes. El acceso remoto usa una conexión WebSocket abierta por el servidor local; los detalles aún se están decidiendo.
- **App de empleados (Android).** La usa el personal del restaurante según su rol.
- **App del propietario (Android).** Permite consultar ventas, ingresos, gastos e histórico de todos sus locales.
- **Panel web de administración.** Interfaz independiente para los administradores globales. Los administradores no pueden acceder a la información económica, y esta restricción se aplica en el servidor y no solo en la interfaz.
- **Los permisos** se comprueban siempre en el servidor.

## Funcionalidades previstas

- Empleados, roles y permisos
- Mesas y agrupaciones de mesas
- Pedidos y productos
- Categorías, ingredientes y modificadores
- Clientes y reservas
- Pedidos a domicilio y repartidores
- Pagos y gastos, con ticket para el cliente
- Inventario y avisos de stock
- Notificaciones
- Estadísticas

## Roles de usuario

| Rol | Identificador |
|---|---|
| Propietario | `OWNER` |
| Encargado | `MANAGER` |
| Camarero | `WAITER` |
| Cocina | `KITCHEN` |
| Repartidor | `DELIVERY` |

El administrador global (`ADMIN`) es independiente de estos roles locales. La matriz completa de permisos está aún por definir.

## Tecnologías (provisionales)

> Todas las tecnologías son provisionales y pueden cambiar según avance el proyecto.

| Área | Tecnología |
|---|---|
| Apps Android | JavaScript, React Native |
| Panel web de administración | JavaScript, React |
| Servidores (local y central) | PHP, Laravel |
| Base de datos | PostgreSQL |
| Herramientas | Git y GitHub, Visual Studio Code, Trello |

## Estructura del repositorio

```
RacoDesk/
├── apps/
│   ├── employee-app/     # App Android para el personal (React Native)
│   ├── owner-app/        # App Android para propietarios (React Native)
│   └── admin-panel/      # Panel web para administradores globales (React)
├── servers/
│   ├── local-server/     # Uno por restaurante: API y base de datos local (Laravel)
│   └── central-server/   # Información general y acceso remoto (Laravel)
├── docs/                 # Documentación del proyecto
└── .github/              # Plantillas de issues y pull requests
```

Cada carpeta contiene un README breve que explica su finalidad y su estado actual.

## Hoja de ruta

El proyecto sigue un modelo incremental e iterativo con iteraciones de dos semanas.

| Iteración | Objetivo |
|---|---|
| 0 | Planificación, análisis y diseño base |
| 1 | Servidor local: base de datos, API, autenticación, empleados y permisos |
| 2 | Mesas, categorías, productos, ingredientes, modificadores y pedidos |
| 3 | Pagos y ticket, gastos, inventario y notificaciones |
| 4 | Clientes, reservas, pedidos a domicilio y repartidores |
| 5 | Servidor central y comunicación con los servidores locales |
| 6 | App del propietario, estadísticas y panel de administración |
| 7 | Estabilización, pruebas de aceptación y documentación |

## Equipo

| Nombre | GitHub |
|---|---|
| Mario Hernández Ramos | [@MarioHR2711](https://github.com/MarioHR2711) |
| Alejandro Domínguez Mora | [@alexdm0749-ops](https://github.com/alexdm0749-ops) |

## Contribuir

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para ver las convenciones de ramas y commits del equipo.

## Licencia

Este proyecto se publica bajo la [licencia MIT](LICENSE).
