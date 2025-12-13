# Contributing to Scriptz

We love your input! We want to make contributing to `scriptz` as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features

## Development Process

We use a Gitflow-inspired workflow:

1.  **Develop Branch**: All new features and fixes should be merged into `develop`.
2.  **Main Branch**: `main` serves as the release branch. We do not push directly to `main`.
3.  **Releases**: Merging `develop` into `main` triggers our automated release pipeline.

### Branch Strategy

-   **`develop`**: Default branch. Submit your PRs here.
-   **`main`**: Production-ready code.

### Release Pipeline

We use **Release Please** to automate releases.

1.  Changes accumulate in `develop`.
2.  An automated action creates a PR (`develop` → `main`) for you.
3.  When that PR is merged to `main`, `release-please` analyzes the commits.
4.  `release-please` creates a **Release PR** on `main` that updates the `CHANGELOG.md` and bumps the version.
5.  Merging the **Release PR** triggers the final GitHub Release and tagging.

## Commit Messages

We enforce **Conventional Commits** to automate versioning and changelog generation.
Your commit messages must follow this format:

```
<type>(<scope>): <subject>
```

### Allowed Types

-   **feat**: A new feature (minor version bump).
-   **fix**: A bug fix (patch version bump).
-   **chore**: Maintenance (no version bump).
-   **docs**: Documentation only changes.
-   **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc).
-   **refactor**: A code change that neither fixes a bug nor adds a feature.
-   **perf**: A code change that improves performance.
-   **test**: Adding missing tests or correcting existing tests.
-   **ci**: Changes to our CI configuration files and scripts.

### Examples

-   `feat(install): add support for python scripts`
-   `fix(barrel): output file name collision`
-   `docs: update readme`
-   `ci: configure release-please`

> **Note:** PRs with non-conventional commit messages will be blocked by `commitlint`.

## Submitting a Pull Request

1.  Fork the repo and create your branch from `develop`.
2.  Run tests/lints locally if available.
3.  Ensure your commit messages follow the rules above.
4.  Submit a Pull Request to the `develop` branch.
