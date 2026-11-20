# Contributing / Cómo colaborar

## Branches / Ramas

- `main`: stable version, always presentable. / Versión estable.
- `feature/<short-name>`: new functionality, e.g. `feature/orders-api`.
- `fix/<short-name>`: bug fixes.
- `docs/<short-name>`: documentation changes.

Work on a branch and open a pull request. The other team member reviews it before merging into `main`
(this matches the **Check** step of our Trello board).
Se trabaja en una rama y se abre una pull request que revisa el compañero antes de fusionarla en `main`.

## Commit messages / Mensajes de commit

Format: `type: short description in English`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Examples: `feat: add table status endpoint`, `docs: update architecture diagram`.

## Security / Seguridad

Never commit passwords, API keys, `.env` files or real customer data. Use `.env.example` for configuration templates.
