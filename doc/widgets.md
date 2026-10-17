# Consuming controller state in Flutter

Import the optional widgets entry point:

```dart
import 'package:jintent/widgets.dart';
```

These widgets work directly with `JController`; a provider package is optional.
They do not create or dispose controllers. The caller owns the controller and
must keep it alive while the widget uses it.

## Build from a state

Given a `CounterController` with a `CounterState.count` field:

```dart
JControllerBuilder<CounterState>(
  controller: controller,
  builder: (context, state) => Text('${state.count}'),
)
```

The initial state is available on the first build. Later state notifications
schedule a rebuild; multiple changes before a Flutter frame can be coalesced.
This is a view of current state, not a recorder of every transition. Use
`JStateRecorder` from [the testing entry point](testing.md) to record transitions.

## Select a value

```dart
JControllerSelector<CounterState, int>(
  controller: controller,
  selector: (state) => state.count,
  builder: (context, count) => Text('$count'),
)
```

For controller notifications, the selector rebuilds only when the selected
value differs by `==`. Updating an unrelated field does not rebuild that
builder. Parent or inherited-widget rebuilds still work normally. Select
immutable values with meaningful equality; mutating a selected list in place
is not supported.

Replacing the controller detaches the old listener and uses the new state
immediately. Replacing the selector recomputes the selection, even without a
state notification. Removing the widget detaches its listener without disposing
the controller.

## Keep effects outside builders

Use `JEffectListener` for dialogs, navigation and feedback. Builders and selectors
may run repeatedly and must not perform one-time side effects.

An awaited effect timing out does not automatically dismiss its UI. The consumer
owns that UI policy. The [example dialog helper](../example/lib/src/demos/shared/effect_dialog.dart)
binds one dialog route to its effect's result: it removes only that route when
the effect settles externally and leaves newer routes untouched. See
[effects](effects.md) for the underlying timeout and disposal contracts.
