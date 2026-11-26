# Instalador para Windows y configuración inicial

**Leer en otros idiomas:** [English](installer.md)

> **Estado:** previsto para el futuro, sin empezar. Depende de que exista el servidor local. Todas las tecnologías son provisionales.

## Por qué

El servidor local funciona en un TPV con Windows del restaurante. El propietario no debería instalar a mano PHP, PostgreSQL y Laravel. Un instalador deja el servidor local listo, sigue funcionando sin Internet y no necesita configurar el router.

## Fases

1. **Script de instalación en PowerShell.** Prepara todo en un equipo: base de datos, `.env`, copias de seguridad programadas y servicio de Windows. Sirve para probar y es la base del instalador.
2. **Instalador `.exe`.** Envuelve el script (herramienta candidata: Inno Setup) y añade el asistente de primera configuración.
3. **Importación de datos desde Excel/CSV.** Funcionalidad aparte, ver más abajo.

Momento previsto: hacia la iteración 7, junto a las copias de seguridad. El asistente de configuración puede empezar antes.

## Asistente de primera configuración

| Paso | Qué hace |
|---|---|
| Restaurante | Nombre y datos del negocio (tabla `restaurant`: razón social, NIF, dirección, teléfono) |
| Base de datos | Crear una base PostgreSQL local nueva en este equipo, o conectar a una existente |
| Copias de seguridad | Elegir la carpeta (`restaurant.backup_path`); copias automáticas diarias |
| Cuenta del propietario | Primer usuario con rol `OWNER` |
| Vínculo con el central | Opcional: vincular con el servidor central mediante el código QR |

## Decisiones técnicas a mantener

- El servidor funciona como **servicio de Windows**: arranca con el equipo y no depende de una ventana abierta.
- La contraseña de la base de datos se **genera al azar** durante la instalación. Nunca hay una contraseña por defecto, y nunca se guarda en el repositorio.
- El software del servidor se instala en **un solo** terminal del restaurante; el de empleados, en todos.
- Aplicar las migraciones de la base de datos forma parte de instalar y de actualizar.

## Importación de datos desde Excel/CSV (sin decidir)

Objetivo: cargar los datos iniciales de un restaurante sin escribirlos a mano (carta, ingredientes, proveedores, empleados, mesas), con plantillas de Excel o CSV. **No** es un volcado completo de la base de datos.

Es una funcionalidad nueva que no está en la lista de funcionalidades definidas. Antes de hacerla, el equipo debe decidir:

- Qué datos se pueden importar.
- Qué roles pueden hacerlo (por ejemplo propietario y encargado).
- Formato de las plantillas y cómo se tratan los errores y los duplicados.
- Si entra en el alcance del proyecto.

## Riesgos

- Empaquetar PHP, PostgreSQL y la aplicación es mucho trabajo, y también las actualizaciones y las migraciones de la base de datos.
- Un instalador sin firmar hace que Windows SmartScreen muestre un aviso. Firmarlo cuesta dinero; en el proyecto se puede aceptar y explicar.
- Hay que probarlo en una instalación limpia de Windows.
