# System map

Static observation of the checkout on 2026-10-16; check the current files before
reusing this data. Informational context, not a future specification.

- `pubspec.yaml`: Flutter package `jintent`, version 3.0.0, Dart `^3.7.2`.
- `lib/jintent.dart`: exports core, domain, `JObserver` and the dispatcher
  contracts. Devtools, undo/redo, widgets, navigation and utils are separate
  entry points (`lib/devtools.dart`, `undo_redo.dart`, `widgets.dart`,
  `navigation.dart`, `utils.dart`); `experimental.dart` re-exports undo/redo.
- `lib/testing.dart`: test helpers (`package:jintent/testing.dart`); the main
  entry point does not export them.
- `JController<T>` extends `StateNotifier<T>`, applies reducers and emits effects
  through a broadcast stream. Its default dispatcher is sequential per instance.
- `JIntent<T>` stores the controller when invoked and runs `onInvoke()`.
- `JEffect<T>` uses a completer for results; listener and handler connect the UI.
- `domain/`: Either, use cases and mappers; `devtools/`: observers and metrics.
- `test/src/`: core, domain and devtools tests. Their presence does not prove coverage.
- `example/`: consumer Flutter app with its own organization.
- `doc/`: user guides; `doc/adr/` holds ADR-000, ADR-001 and ADR-002 (all accepted).
- `.github/workflows/ci.yml`: Flutter 3.29.2 (minimum) and 3.47.6, formatting,
  analysis, tests and coverage.

Analysis findings need reproduction and acceptance criteria before becoming
changes; this map does not declare existing risks fixed.
