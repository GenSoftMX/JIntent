# Changelog

- `CHANGELOG.md` records only what changes for someone who consumes the
  published package. Compare against the last published version, not against
  individual commits.
- Do not record the example app, tests, CI, tooling, lints or internal
  refactors, unless they change a requirement for consumers (for example the
  minimum Flutter version).
- Something introduced in the unreleased version and corrected before release is
  edited in its `Added` entry. Do not add a `Fixed` entry for it.
- Order sections `Breaking changes`, `Added`, `Changed`, `Deprecated`, `Fixed`,
  `Documentation`. Each breaking change links to its section in
  `doc/migration.md`.
- One or two lines per entry. Put reasons, examples and trade-offs in `doc/` or
  an ADR and link them.
- Before a release, check that every public API difference against the last
  published version has an entry and that every link resolves.
