# ADR-001: Optional entry points and core refinements

**Status:** Accepted for unreleased 3.0.0

**Date:** 2026-10-16

**Relates to:** ADR-000 (D2, D6, D7, D9). It does not supersede it.

## Context

ADR-000 lists navigation frameworks and form validation as non-goals, yet the
main entry point exported navigation, validation, color and platform helpers,
experimental code, and every devtool. Observability used single-slot static
callbacks that tools overwrote, and failures of intents were invisible.
Effects emitted before the UI attached were lost.

## Decisions

| # | Decision | Rationale |
| --- | --- | --- |
| D16 | `jintent.dart` exports the core, domain helpers, `JObserver` and dispatcher contracts. Devtools, experimental, navigation and utilities are separate entry points; testing helpers are in `testing.dart`. | Aligns the public surface with ADR-000's non-goals without deleting features users rely on. |
| D17 | `Either` is a sealed class with `final` `Left`/`Right`, value equality and a `value` accessor. | Exhaustive pattern matching; removes the need for `fold`-only access. Breaking, accepted because 3.0.0 is a major release. |
| D18 | Observers are composable `JObserverDelegate`s registered with `JObserver.addObserver`; intents report start, failure, cancellation and drops. Static callbacks remain for the original events. Observer failures never reach observed code. | Refines D9. Tools stop overwriting each other and failures become observable. |
| D19 | Intent concurrency strategies beyond FIFO (droppable, restartable) use cooperative cancellation; cancelled intents cannot write state. Updates are attributed to their intent through a zone (`JIntent.current`), so the guarantee does not depend on callers passing `origin`. | Extends D6 without changing the default. Running code is never interrupted. |
| D20 | Effect buffering is opt-in (`effectBufferSize`, default 0). | Covers effects emitted before the UI attaches without changing the D5 default semantics. |
| D21 | `state_notifier ^1.0.0` stays the base of `JController` and `equatable` stays `^2.0.5`. | See below. |

## Evidence for D21 (consulted 2026-10-16)

- [`state_notifier` on pub.dev](https://pub.dev/packages/state_notifier): not
  discontinued; latest 1.0.0, published about three years earlier.
- [Riverpod 3.0 migration](https://riverpod.dev/docs/3.0_migration): the
  `StateNotifier` *providers* moved to `package:flutter_riverpod/legacy.dart`.
  That concerns Riverpod's providers, not the `state_notifier` package that
  `JController` extends.
- [`equatable` changelog](https://pub.dev/packages/equatable/changelog): 3.0.0
  stops comparing `runtimeType`. JIntent skips updates to equal states, so two
  distinct state classes with equal `props` (for example empty-props `Loading`
  and `Initial`) would become equal and their transition would be skipped.
  Adopting 3.x would require `JState` to keep the type check itself.

## Consequences

- Consumers update imports (see the migration guide) and any exhaustive handling
  of `Either`.
- The `state_notifier` dependency is a maintenance risk, not a defect. Revisit
  if it blocks a supported Flutter or Riverpod version, or if a pure-Dart core
  becomes a goal; that would need a new record.
- Not addressed: `JEffectsConfig` and the static `JObserver` registry remain
  process-wide. `JObserver.reset()` and `resetJIntentGlobals()` mitigate this in
  tests; scoped instances would be a further breaking change.
