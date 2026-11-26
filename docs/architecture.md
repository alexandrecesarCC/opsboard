# Architecture and decisions

## ADR-001: Dependency-free demonstration

The first release uses native ES modules and browser APIs to keep the static deployment reproducible without a package registry. The domain is independent of the DOM and storage implementation. A later React/TypeScript migration can retain these contracts; this release does not claim to use that stack.

## State and integrity

A versioned snapshot stores project and task arrays and the latest 100 activity entries. A task references a valid project. Projects with tasks cannot be deleted. State changes are validated before writing; the in-memory snapshot changes only after storage succeeds. User strings are escaped before HTML interpolation. Corrupt snapshots trigger a visible warning and a temporary seeded view.

## Limits

No concurrent editing or cross-tab synchronization, identity verification, server-side controls or durable backup. A future remote adapter needs authorization, row-level policies, migrations, conflict handling and integration tests before production use.
