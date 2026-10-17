# Agent work in JIntent

JIntent is a Flutter library for intents, state and effects. This file is the
entry point; load only the resources the task needs.

## Structure
- `lib/jintent.dart`: core entry point; `lib/devtools.dart`, `experimental.dart`,
  `navigation.dart`, `utils.dart` and `testing.dart` are optional entry points.
- `lib/src/`: core, domain, devtools, navigation, utils and experimental.
- `test/`: library tests; `example/`: consumer application.
- `doc/`: user guides; `doc/adr/`: ADR-000, ADR-001 and ADR-002 (accepted). Check them against the code.

## How the agent works
1. Define the scope before implementing, proportional to risk. If asked for
   analysis, do not edit until an implementation request arrives.
2. Discover, evaluate and select context by relevance, authority and currency.
3. Read the applicable rules in `.agents/rules/`; consult Knowledge on demand.
4. Execute within scope following the [task workflow](.agents/workflows/task.md).
5. Verify before finishing and distinguish passed, failed and not run.
6. Report sources used, files changed, validation and pending items.
7. Do not widen scope without explicit authorization. Reuse authorizations
   already given.
8. Changes to architecture, security, infrastructure or critical dependencies
   need an authorized scope and plan before execution.

## Canonical sources
- [Architecture](.agents/rules/architecture.md), [style](.agents/rules/code-style.md),
  [testing](.agents/rules/testing.md), [changelog](.agents/rules/changelog.md),
  [Git and security](.agents/rules/git.md).
- [System map](.agents/knowledge/system-overview.md).
- [External documentation with Context7](.agents/rules/documentation.md): query
  APIs and versions on demand; project adapter in `.codex/config.toml`.
- [Task workflow](.agents/workflows/task.md).
- [Scope](.agents/templates/request-scope.md) and
  [handoff](.agents/templates/handoff.md) templates.
- [Adoption and future extensions](.agents/README.md).

## Basic validation
For Dart code: format, `flutter analyze` and tests per the testing rules.
For documentation: check references, scope and `git diff --check`.
Executable CI configuration lives in `.github/workflows/ci.yml`.
