# Contributing

**Read this in other languages:** [Español](CONTRIBUTING.es.md)

## Branches

- `main`: stable version, always presentable. It only receives code that has already been tested in `develop`.
- `develop`: integration branch. All work is merged here first and tested here.
- `feature/<short-name>`: new functionality, e.g. `feature/orders-api`.
- `fix/<short-name>`: bug fixes.
- `docs/<short-name>`: documentation changes.

Workflow:

1. **Every working branch is created from `develop`** (never from `main`).
2. Work on the branch and open a pull request **into `develop`**. The other team member reviews it before merging
   (this matches the **Check** step of our Trello board).
3. Before opening the pull request, bring the latest `develop` into your branch (`git pull origin develop`) and resolve any conflicts there.
4. Changes are tested in `develop`. When the tests pass, at the end of each iteration `develop` is merged into `main`
   and tagged (`it-1`, `it-2`, ...).
5. Branches are **not deleted** after being merged, so the history of the work is kept.

## Commit messages

Format: `type: short description in English`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Examples: `feat: add table status endpoint`, `docs: update architecture diagram`.

## Documentation

Documentation is kept in two languages. The default file is in English (`README.md`) and the Spanish version has the same name with `.es` before the extension (`README.es.md`). When a document changes, update both versions.

## Security

Never commit passwords, API keys, `.env` files or real customer data. Use `.env.example` for configuration templates.
