# Opsboard

A local-first operations workspace for tracking projects, tasks and delivery metrics. Built as a browser-based product demonstration with synthetic data.

## Run locally

Requires Node.js 22 for checks and Python 3 for the static server. No package installation is needed.

```sh
npm run check
npm test
npm start
```

Open http://localhost:8080. For deployment, serve the repository root over HTTPS; relative paths support a GitHub Pages project site.

## Features

- Project and task creation, editing and deletion; protected project deletion.
- Kanban drag-and-drop with keyboard-accessible status selectors.
- Search, status filters, calendar agenda and computed analytics.
- Activity history, local persistence, responsive layout and appearance preferences.

## Architecture

`src/domain.js` defines validation, immutable state transitions and metrics. `src/store.js` handles persistence and seed data. `src/app.js` owns presentation, event routing and dialogs. CSS contains responsive visual tokens. Tests cover domain rules and storage boundaries.

## Boundaries

This release is a single-device demonstration, not a production multi-user SaaS. It has no authentication, server, remote database or authorization model. Browser storage is not suitable for confidential data. Clearing site data removes saved work. Do not enter sensitive information.

See [architecture notes](docs/architecture.md) for trade-offs.
