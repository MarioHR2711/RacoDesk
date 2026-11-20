# Cómo colaborar

**Leer en otros idiomas:** [English](CONTRIBUTING.md)

## Ramas

- `main`: versión estable, siempre presentable.
- `feature/<nombre-corto>`: funcionalidad nueva, por ejemplo `feature/orders-api`.
- `fix/<nombre-corto>`: corrección de errores.
- `docs/<nombre-corto>`: cambios de documentación.

Se trabaja en una rama y se abre una pull request que revisa el compañero antes de fusionarla en `main`
(coincide con el paso **Check** de nuestro tablero de Trello).

## Mensajes de commit

Formato: `tipo: descripción corta en inglés`

Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Ejemplos: `feat: add table status endpoint`, `docs: update architecture diagram`.

## Documentación

La documentación se mantiene en dos idiomas. El archivo por defecto está en inglés (`README.md`) y la versión en español tiene el mismo nombre con `.es` antes de la extensión (`README.es.md`). Cuando cambie un documento, hay que actualizar las dos versiones.

## Seguridad

No subas nunca contraseñas, claves de API, archivos `.env` ni datos reales de clientes. Usa `.env.example` para las plantillas de configuración.
