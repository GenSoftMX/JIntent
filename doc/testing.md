# Testing with JIntent

Import the helpers from tests only:

```dart
import 'package:jintent/testing.dart';
```

## Record states

```dart
final controller = CounterController();
final states = JStateRecorder(controller);

await controller.intent(IncrementIntent());

expect(states.states, [const CounterState(count: 1)]);
states.dispose();
controller.dispose();
```

The recorder captures changes made after it is attached, in order. Equal
updates never appear because controllers skip them.

## Play the UI for effects

`JEffectRecorder` listens to a controller's effects, records them and completes
awaitable ones with scripted answers, so intents that wait for a dialog can run
without widgets:

```dart
final ui = JEffectRecorder(controller)
  ..respondTo<ConfirmDelete, bool>((effect) => true);

await controller.intent(DeleteIntent());

expect(ui.effectsOfType<ConfirmDelete>(), hasLength(1));
await ui.dispose();
```

Register responses per concrete effect type. An unanswered awaitable effect
stays pending, which lets you test timeouts; pass `failUnhandled: true` to fail
it with `StateError` instead. A responder that throws fails the effect with that
error.

## Reset global state

`JObserver`, `JEffectsConfig`, `JMetrics` and `EitherConfig` are process-wide.
Call `resetJIntentGlobals()` in `setUp` or `tearDown` so one test cannot affect
another.

```dart
setUp(resetJIntentGlobals);
```
