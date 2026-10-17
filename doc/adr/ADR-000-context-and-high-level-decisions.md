# ADR-000: Context and High-Level Decisions

**Status:** Accepted  
**Date:** 2025-10-15 (condensed 2026-10-16)

This record captures JIntent's baseline context and high-level decisions. It was
condensed from its original form: the phase roadmap, numeric targets, governance
process and open questions were removed because they referred to a discarded
process or to unverified figures. Check the code, tests and `pubspec.yaml` for
current behavior and versions. A change of decision needs a new record that
supersedes this one.

## Context

JIntent is a Flutter package that applies an MVI-inspired Intent pattern to
state management. It addresses mixed UI and business logic, duplicated side
effects (navigation, dialogs), hard-to-test transitions, race conditions in
state updates and state mutation bugs. It targets intermediate to advanced
Flutter developers familiar with MVI, Redux or BLoC, in apps of any size.

**Non-goals.** JIntent does not provide an HTTP client, persistence layer,
dependency injection container, navigation framework, form validation library or
business logic. This keeps the library focused and leaves choices to consumers.

## Principles

1. **Simplicity over completeness:** minimal primitives (`JState`, `JIntent`,
   `JController`), not a framework.
2. **Explicitness over implicitness:** state changes and side effects are explicit
   (`controller.intent(LoginIntent())`).
3. **Immutability first:** states are immutable and updated with `copyWith`.
4. **Type safety:** core types are generic (`JController<CounterState>`).
5. **Testability:** each component is testable in isolation.
6. **Minimal dependencies:** only essential, stable packages.
7. **Progressive disclosure:** simple cases stay simple; complex ones are possible.
8. **Backward compatibility:** follow semantic versioning and provide migration
   paths for breaking changes.

## Decisions

| # | Decision | Rationale |
| --- | --- | --- |
| D1 | MVI-inspired architecture | Unidirectional flow and clear separation; simpler than Redux or BLoC boilerplate |
| D2 | Layers: Core (state, intent, controller, effect) → Domain (use cases, `Either`, mappers) → Presentation (consumer UI) | Clear boundaries, reusable domain logic |
| D3 | Strict generic type system | Compile-time safety, at the cost of some verbosity |
| D4 | `Either<Exception, T>` for expected domain errors | Explicit error handling that forces consideration |
| D5 | Side effects travel on a separate broadcast stream, not in state | Keeps state pure; one-time events decoupled from UI |
| D6 | Intents are processed sequentially (FIFO) | Prevents races and gives predictable transitions, with some queueing delay |
| D7 | `JController` builds on `StateNotifier` | Proven reactive base, compatible with Riverpod |
| D8 | No built-in dependency injection (`get_it` removed in 2.0.0) | Less coupling; consumers pick their own DI |
| D9 | `JObserver` hooks for state and effect observation | Opt-in extensibility for logging, analytics and debugging |
| D10 | Distributed through pub.dev | Standard channel and dependency resolution |
| D11 | MIT license | Permissive and widely adopted |
| D12 | Semantic versioning | Clear communication of breaking changes |
| D13 | Requires the Flutter SDK (SDK constraints in `pubspec.yaml`) | `StateNotifier` and the target audience depend on Flutter |
| D14 | Runnable counter example in `example/` | Learning by example and integration coverage |
| D15 | Record architectural decisions as ADRs | Transparency and historical context |
