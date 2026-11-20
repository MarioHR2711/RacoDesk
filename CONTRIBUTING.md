# Contributing

**Read this in other languages:** [Español](CONTRIBUTING.es.md)

## Branches

- `main`: stable version, always presentable.
- `feature/<short-name>`: new functionality, e.g. `feature/orders-api`.
- `fix/<short-name>`: bug fixes.
- `docs/<short-name>`: documentation changes.

Work on a branch and open a pull request. The other team member reviews it before merging into `main`
(this matches the **Check** step of our Trello board).

## Commit messages

Format: `type: short description in English`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Examples: `feat: add table status endpoint`, `docs: update architecture diagram`.

## Documentation

Documentation is kept in two languages. The default file is in English (`README.md`) and the Spanish version has the same name with `.es` before the extension (`README.es.md`). When a document changes, update both versions.

## Security

Never commit passwords, API keys, `.env` files or real customer data. Use `.env.example` for configuration templates.
