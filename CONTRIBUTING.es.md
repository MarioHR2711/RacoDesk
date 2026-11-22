# Cómo colaborar

**Leer en otros idiomas:** [English](CONTRIBUTING.md)

## Ramas

- `main`: versión estable, siempre presentable. Solo recibe código que ya se ha probado en `develop`.
- `develop`: rama de integración. Todo el trabajo se fusiona primero aquí y se prueba aquí.
- `feature/<nombre-corto>`: funcionalidad nueva, por ejemplo `feature/orders-api`.
- `fix/<nombre-corto>`: corrección de errores.
- `docs/<nombre-corto>`: cambios de documentación.

Forma de trabajar:

1. **Toda rama de trabajo se crea desde `develop`** (nunca desde `main`).
2. Se trabaja en la rama y se abre una pull request **hacia `develop`**. La revisa el compañero antes de fusionarla
   (coincide con el paso **Check** de nuestro tablero de Trello).
3. Antes de abrir la pull request, se trae el último `develop` a tu rama (`git pull origin develop`) y se resuelven allí los conflictos que haya.
4. Los cambios se prueban en `develop`. Cuando las pruebas pasan, al final de cada iteración se fusiona `develop` en `main`
   y se etiqueta (`it-1`, `it-2`, ...).
5. Las ramas **no se borran** después de fusionarlas, para conservar el historial del trabajo.

## Mensajes de commit

Formato: `tipo: descripción corta en inglés`

Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Ejemplos: `feat: add table status endpoint`, `docs: update architecture diagram`.

## Documentación

La documentación se mantiene en dos idiomas. El archivo por defecto está en inglés (`README.md`) y la versión en español tiene el mismo nombre con `.es` antes de la extensión (`README.es.md`). Cuando cambie un documento, hay que actualizar las dos versiones.

## Seguridad

No subas nunca contraseñas, claves de API, archivos `.env` ni datos reales de clientes. Usa `.env.example` para las plantillas de configuración.
