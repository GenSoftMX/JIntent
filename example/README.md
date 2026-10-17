# JIntent gallery

A Flutter application that exercises the library through small, focused demos.
It consumes JIntent through a local path dependency. After the splash screen,
the gallery lists:

| Demo | What it shows | Code |
| --- | --- | --- |
| Counter | The full architecture: use cases, mappers, repositories, Riverpod, a service locator, effect handlers and error handling | [presentation/counter](lib/src/presentation/counter/) |
| Concurrency Lab | The same five tasks under the sequential, concurrent, droppable and restartable dispatchers, with cooperative cancellation and the timeline an observer reports | [demos/concurrency_lab](lib/src/demos/concurrency_lab/) |
| Startup & Effects | `effectBufferSize` for effects emitted before the UI attaches, dialogs with results, timeouts, unhandled effects and `JValidationUtils` | [demos/startup_effects](lib/src/demos/startup_effects/) |
| Observability Lab | `JMetrics`, correlation ids, a custom `JObserverDelegate`, several observers at once and `JDevToolsOverlay` | [demos/observability_lab](lib/src/demos/observability_lab/) |
| Undo Notes | Stable `UndoRedoMixin`, `UndoableIntent` and observable history | [demos/undo_notes](lib/src/demos/undo_notes/) |

The four lab demos consume controller state with `JControllerBuilder` from
[`package:jintent/widgets.dart`](../lib/widgets.dart), without a provider package.
The counter uses Riverpod. Both styles work because a `JController` is a
`StateNotifier`. Tests live under [test/src/demos](test/src/demos/), using
`package:jintent/testing.dart`.

Startup & Effects also demonstrates an
[effect-owned dialog](lib/src/demos/shared/effect_dialog.dart): timeout or
controller disposal removes only the dialog route belonging to that effect,
without popping a newer route. This is application UI policy, not automatic
navigation performed by the library.

Undo Notes uses [`package:jintent/undo_redo.dart`](../lib/undo_redo.dart). Its
history buttons listen to metadata independently of document content; clearing
history leaves the notes intact. See the [full guide](../doc/undo-redo.md).

## File organization

Each demo keeps its state, controller and page in separate files. Each intent
has its own `*_intent.dart` file; effects and their UI handler are separate too.
Controllers import the state and intents they use instead of re-exporting them.
Views and tests import each type from its defining file.

Each feature groups these files by responsibility. For example, Undo Notes:

```text
undo_notes/
  controller/notes_controller.dart
  state/notes_state.dart
  intents/add_note_intent.dart
  intents/remove_last_note_intent.dart
  presentation/notes_page.dart
```

Effects live under `effects/`, with their UI handlers under `presentation/`.
Concurrency and Observability use `observers/` for lifecycle recording and
metrics, `models/` for log entries and outcomes, and `configuration/` for lab
scenarios and dispatcher choices. Directories are created only when needed.
Counter and Splash also use the singular `controller/` and `state/` names.

## Run

From `example/`:

```sh
flutter pub get
flutter run
```

In an IDE, open the `example/` folder (not the repository root):

- **Android Studio:** it detects `lib/main.dart` and creates the `main.dart` run
  configuration on its own. Pick a device and press Run.
- **VS Code:** with the Flutter extension, press F5 and choose one of the
  configurations in [.vscode/launch.json](.vscode/launch.json): the gallery in
  debug, profile or release mode, or the integration test open in the editor.

Run `flutter analyze` and `flutter test` in this directory to validate the
example separately from the library. Device-based integration tests live in
[integration_test](integration_test/).

## Read the implementation

- [State](lib/src/presentation/counter/state/state.dart).
- [Controller](lib/src/presentation/counter/controller/controller.dart) and
  [intents](lib/src/presentation/counter/intents/).
- [View](lib/src/presentation/counter/presentation/counter_view.dart) and
  [effect handler](lib/src/presentation/counter/presentation/counter_effect_handler.dart).
- [Use cases](lib/src/domain/use_cases/) and [validators](lib/src/domain/validators/).
- [Data helpers](lib/src/data/): DTO, entity, one-way and bidirectional mapper, and
  an in-memory repository with `Either` failures.
- [Observability setup](lib/src/@core/observability/): `ObservabilitySetup`
  initializes the logger, logging observer, optional metrics and an
  `IntentOutcomeObserver` (a `JObserverDelegate` that logs failed, cancelled and
  dropped intents) once; `main` calls it at startup. `ObservableIntentMixin` adds
  contextual logging and timers. Initialize the setup before using its logger.

These helpers are application examples, not JIntent exports or required
infrastructure. Call use cases through `call` so their fail-fast validator chain
runs; `run` bypasses it.

## Library features in the counter

- **Concurrency:** the counter controller keeps the default
  `JSequentialIntentDispatcher`, so taps that arrive during a save are queued
  and run in order. (The view's 200 ms `JThrottler` still filters bursts of
  taps before they reach the controller.) See the
  [concurrency guide](../doc/concurrency.md) and the
  [sequential tests](test/src/presentation/counter_sequential_test.dart).
- **Observers:** [`IntentOutcomeObserver`](lib/src/@core/observability/observability_setup.dart)
  and its [test](test/src/observability/intent_outcome_observer_test.dart).
- **Feedback effects:** `CounterEffectHandler` shows one snack bar at a time
  (`ScaffoldMessenger` queues them otherwise) and the rejection snack bar has no
  action, so its 3 s duration applies on every supported Flutter version. See the
  [snack bar tests](test/src/presentation/counter_snackbar_test.dart).
- **Sealed `Either`:** `GetCurrentCounterValueIntent` handles the result with an
  exhaustive `switch`; the other intents use `fold`.
- **Testing helpers:** the contract and sequential tests use `JStateRecorder`,
  `JEffectRecorder` and `resetJIntentGlobals` from `package:jintent/testing.dart`;
  see the [testing guide](../doc/testing.md).

The gallery demos cover the rest of the library surface; see the table above.

## Error handling

- [Intents](lib/src/presentation/counter/intents/) handle recoverable operation
  failures and emit dedicated effects while the controller is mounted.
- [CounterEffectHandler](lib/src/presentation/counter/presentation/counter_effect_handler.dart)
  registers each concrete feedback type and owns snackbars and dialogs.
- The [controller](lib/src/presentation/counter/controller/controller.dart)
  returns dispatch futures.
- The [view](lib/src/presentation/counter/presentation/counter_view.dart) catches
  unexpected or lifecycle errors at its UI boundary, logs them and does not emit
  another feedback effect.
- [Contract tests](test/src/presentation/core_contracts_test.dart) exercise
  these boundaries.

See the library [error handling](../doc/error-handling.md),
[effects](../doc/effects.md) and [migration](../doc/migration.md) guides for the
contracts used here. This application's layering and dependencies are consumer
choices, not library requirements.

## License


MIT License

Copyright (c) 2020 Remi Rousselet

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
