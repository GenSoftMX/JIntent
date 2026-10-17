# JIntent

[![Pub Version](https://img.shields.io/pub/v/jintent.svg)](https://pub.dev/packages/jintent)
[![Build](https://img.shields.io/github/actions/workflow/status/GenSoftMX/JIntent/ci.yml?branch=main)](https://github.com/GenSoftMX/JIntent/actions)

JIntent is a Flutter library for explicit intents, immutable state and one-time
UI effects. Controllers manage state; intents perform operations; effect
handlers present dialogs, navigation and feedback outside persistent state.

Read the [interactive guide](https://gensoftmx.github.io/JIntent/) (English and
Spanish) for the concepts, live demos and the API reference.

## Installation

```sh
flutter pub add jintent
```

Or declare it yourself. Version 3.0.0 requires Flutter 3.29.2 or newer:

```yaml
dependencies:
  jintent: ^3.0.0
```

Import the public entry point:

```dart
import 'package:jintent/jintent.dart';
```

Optional pieces have their own entry points, so the core stays small:

| Import | Contents |
| --- | --- |
| `package:jintent/jintent.dart` | State, intents, controller, effects, dispatchers, `JObserver`, `Either`, use cases, mappers |
| `package:jintent/devtools.dart` | Structured logging, correlation, metrics, debug overlay |
| `package:jintent/testing.dart` | State and effect recorders, global reset |
| `package:jintent/widgets.dart` | Controller builder and selector without a provider package |
| `package:jintent/undo_redo.dart` | Stable undo/redo, observable history and commands |
| `package:jintent/navigation.dart` | Thin `Navigator` abstraction |
| `package:jintent/utils.dart` | Throttler, validation, color and platform helpers |

See [undo and redo](doc/undo-redo.md) for local edit history, UI integration,
ordering and migration from the legacy experimental import.

Upgrading from 2.x changes state equality, effect failures and disposal
behavior. Review the [migration guide](doc/migration.md) first.

## What's new in 3.0.0

- **Entry points:** `jintent.dart` holds only the core; devtools, undo/redo,
  widgets, navigation, utilities and test helpers moved to their own imports.
- **Predictable state:** updates equal to the current state are skipped, so
  listeners and observers only see real changes.
- **Safer effects:** an awaited effect without a listener or handler fails with
  `StateError`, and disposal fails pending results. Effect buffering is opt-in.
- **Concurrency:** droppable and restartable dispatchers, with cooperative
  cancellation through `JIntent.cancel`.
- **Observability:** composable `JObserverDelegate`s that also report failed,
  cancelled and dropped intents, plus richer metrics and overlay.
- **Also new:** stable undo/redo with observable history, `JControllerBuilder`
  and `JControllerSelector`, and test recorders in `package:jintent/testing.dart`.

Several of these change behavior compared with 2.x. See the full
[changelog](CHANGELOG.md) and the [migration guide](doc/migration.md).

## Minimal example

```dart
import 'package:jintent/jintent.dart';

class CounterState extends JState {
  final int count;
  const CounterState({this.count = 0});

  @override
  CounterState copyWith({int? count}) =>
      CounterState(count: count ?? this.count);

  @override
  List<Object?> get props => [count];
}

class IncrementIntent extends JIntent<CounterState>
    with JIntentHelpers<CounterState> {
  @override
  Future<void> onInvoke() async {
    update((state) => state.copyWith(count: state.count + 1));
  }
}

class CounterController extends JController<CounterState> {
  CounterController() : super(const CounterState());

  Future<void> increment() => intent(IncrementIntent());

  @override
  void onInit() {}
}

Future<void> main() async {
  final controller = CounterController();
  try {
    await controller.increment();
    print(controller.currentState.count); // 1
  } finally {
    controller.dispose();
  }
}
```

Connect the controller directly with `JControllerBuilder` or
`JControllerSelector` from `package:jintent/widgets.dart`, or use your
StateNotifier integration. The [widget guide](doc/widgets.md) covers ownership,
controller replacement and selecting part of a state. The
[example gallery](example/) uses the builders in its four focused labs and
Riverpod with `JEffectListener` in the counter.

## Contracts

- `JState`: include relevant values in `props`; return new immutable states.
  Updates equal to the current state are skipped.
- `JIntent`: override `onInvoke` and await its work. One instance cannot run
  concurrently; it can be reused after completion.
- `JController`: dispatches sequentially by default. Return dispatch futures
  and handle their errors at the UI boundary. `onInit` runs synchronously from
  the base constructor, before the subclass constructor body. Pass
  `effectBufferSize` to retain effects emitted before the UI attaches.
- `JEffect`: transient UI events. Register each concrete effect type in a
  `JSideEffectHandler` and complete awaited results. A subscription alone does
  not guarantee completion; configure a timeout for awaited UI work.
- `JObserver`: register `JObserverDelegate`s to observe intents (including
  failures), state and effects; see [observability](doc/observability.md).
- Disposal rejects queued intents and pending effect results; running service
  calls and handlers need their own cancellation or lifecycle checks.

See [effects](doc/effects.md) for registration, failures and timeouts, and
[error handling](doc/error-handling.md) for operation boundaries.

## Documentation

- [Interactive guide](https://gensoftmx.github.io/JIntent/) in English and
  Spanish, with live demos and diagrams.
- [Effects](doc/effects.md) and [error handling](doc/error-handling.md).
- [Concurrency strategies](doc/concurrency.md): sequential, droppable,
  restartable and cooperative cancellation.
- [Testing](doc/testing.md): state and effect recorders, global reset.
- [Domain helpers](doc/domain-helpers.md): validation and mappers.
- [Observability and extension points](doc/observability.md).
- [Migration](doc/migration.md): upgrading from 2.x to 3.0.0.
- [Security policy](SECURITY.md).
- [Changelog](CHANGELOG.md): version history.
- [Architecture records](doc/adr/README.md): ADR-000, ADR-001 and ADR-002
  (all accepted).

## Contributing

Discuss substantial changes in an issue and keep pull requests focused. Follow
[repository instructions](AGENTS.md) and the [task workflow](.agents/workflows/task.md).
For Dart changes, format affected files, run `flutter analyze` and relevant tests;
before delivering library changes, run `flutter test --coverage`. Root analysis
excludes the example, which needs separate validation when affected.

Documentation changes require checking references and `git diff --check`.
See the [CI workflow](.github/workflows/ci.yml) for executable checks and the
[code of conduct](CODE_OF_CONDUCT.md) for community guidelines.

## License

[MIT](LICENSE).
