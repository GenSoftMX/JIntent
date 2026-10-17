# Undo and redo

Undo/redo is a stable, optional API since 3.0.0. Import it alongside
core types:

```dart
import 'package:jintent/jintent.dart';
import 'package:jintent/undo_redo.dart';
```

Use it for local edits in notes, forms or editors. It restores immutable state
snapshots; it does not reverse a database write, HTTP request, dialog or other
side effect. Persisting an edit and compensating an external operation remain
application responsibilities. History exists only in memory for one controller.

## Controller and intents

Keep state, controller, intents and presentation in their own files. A minimal
state might be:

```dart
class EditorState extends JState {
  const EditorState({this.text = ''});
  final String text;

  @override
  EditorState copyWith({String? text}) => EditorState(text: text ?? this.text);

  @override
  List<Object?> get props => [text];
}
```

The controller enables history and selects a positive capacity:

```dart
class EditorController extends JController<EditorState>
    with UndoRedoMixin<EditorState> {
  EditorController() : super(const EditorState());

  @override
  void onInit() => enableUndoRedo(maxHistorySize: 20);

  Future<void> replaceText(String text) => intent(ReplaceTextIntent(text));
}
```

Only changes explicitly recorded with `updateWithUndo` enter history.
`UndoableIntent` provides that operation to intents:

```dart
class ReplaceTextIntent extends UndoableIntent<EditorState> {
  ReplaceTextIntent(this.text);
  final String text;

  @override
  Future<void> onInvoke() async {
    performUndoableUpdate((state) => state.copyWith(text: text));
  }
}
```

Outside an intent, `controller.updateWithUndo(reducer)` records the same kind of
change. On a controller without `UndoRedoMixin`, `UndoableIntent` falls back to
an ordinary update and provides no history.

Snapshots retain references to states, not deep copies. Use immutable values
and defensive copies or unmodifiable collections, including nested values.
Reducers must be pure and return a new state; never mutate the current state,
its collections or the controller lifecycle inside a reducer. Include all
state data relevant to equality in `props`.

## History behavior

| Operation | Contract |
| --- | --- |
| Recorded change | Pushes previous state onto undo, drops the oldest entry above capacity and clears redo. |
| Equal state or throwing reducer | Leaves history intact, including an existing redo branch. |
| `undo()` / `redo()` | Return `true` when a snapshot is consumed, `false` when unavailable. Actual state changes notify controller listeners and `JObserver.onStateChanged`. |
| Equal snapshot restoration | Can consume a snapshot without emitting a domain-state change; history metadata still updates. |
| `clearHistory()` | Clears both stacks and notifies history listeners; preserves current domain state and enabled status. |
| `disableUndoRedo()` | Clears history, disables recording and publishes metadata. Subsequent recorded updates behave like ordinary updates. |
| `enableUndoRedo(maxHistorySize: n)` | Enables recording. Requires a positive capacity; invalid input throws before changing history. Reducing capacity trims oldest entries in both stacks. |
| Ordinary `update()` | Changes domain state without recording or clearing history. Explicitly clear history when replacing a document or accepting remote state. |
| Cancellation / disposal | Cancelled intents on this controller cannot change its history. After disposal, history mutations do nothing and undo/redo return `false`. Disposal releases snapshots and the metadata notifier. |

Undo/redo availability and stack sizes remain available as controller getters.
The maximum applies to each stack; shrinking the limit can discard snapshots.
Listener or observer callbacks are not transactional application operations:
exceptions in external code cannot undo an already committed state or external
side effect.

## Observe history in the UI

Domain state and history metadata are separate observables. `history` is a
read-only `ValueListenable<JUndoHistoryState>` with `enabled`, `undoCount`,
`redoCount`, `canUndo` and `canRedo`. This avoids putting stacks in domain state
or manually synchronizing duplicate button flags.

Use `JControllerBuilder` for document content, and listen to history for buttons:

```dart
ValueListenableBuilder<JUndoHistoryState>(
  valueListenable: controller.history,
  builder: (context, history, child) => IconButton(
    onPressed: history.canUndo ? () => controller.undo() : null,
    icon: const Icon(Icons.undo),
  ),
)
```

The widget example requires `package:flutter/material.dart`. Metadata is
published after an operation updates domain state, and only when the metadata
value changes. Clearing history therefore updates the buttons even though the
document remains unchanged. The controller owns the notifier; consumers only
subscribe and unsubscribe. Keep the controller alive while its widgets use it,
and dispose it when its owner is removed.

See [Undo Notes](../example/lib/src/demos/undo_notes/): it demonstrates adding,
removing, undoing, redoing and clearing history without deleting notes.

## Ordering with asynchronous work

Direct undo/redo calls are synchronous and do not enter a dispatcher queue. They
do not cancel a pending save or other intent. To serialize undo with other edits,
invoke it inside a custom intent and use a sequential dispatcher:

```dart
class UndoEditIntent extends JIntent<EditorState> {
  @override
  Future<void> onInvoke() async {
    (controller as EditorController).undo();
  }
}

// Dispatch from the UI; do not recursively await it inside the same queue.
await controller.intent(UndoEditIntent());
```

That state change is attributed to the executing intent by the observer.
Concurrent, droppable and restartable dispatchers retain their normal contracts;
history does not add serialization. See [concurrency](concurrency.md).

## Commands as an alternative

`CommandHistory<T>` stores synchronous `UndoableCommand<T>` objects instead of
state snapshots. Use it when each operation needs its own inverse:

```dart
class AppendCommand extends UndoableCommand<EditorState> {
  AppendCommand(this.suffix);
  final String suffix;

  @override
  EditorState execute(EditorState state) =>
      state.copyWith(text: '${state.text}$suffix');

  @override
  EditorState undo(EditorState state) =>
      state.copyWith(text: state.text.substring(0, state.text.length - suffix.length));
}

final history = CommandHistory<EditorState>(maxSize: 20);
var state = history.execute(const EditorState(), AppendCommand('hello'));
state = history.undo(state) ?? state;
state = history.redo(state) ?? state;
```

This is an alternative, not a second history to attach to the same edits. Its
positive capacity is validated in the constructor. Execute commits a command
only when the returned state differs. Equal results and thrown commands preserve
the stacks; undo and redo move a command only after its method succeeds. An empty
undo or redo returns `null`. Default command redo executes the command again.

Commands must be pure and work with immutable state; mutations to the command
object or external effects cannot be rolled back on failure. `CommandHistory`
has no controller, notifier, persistence or disposal lifecycle. Its owner must
apply returned states, publish its own UI metadata and call `clear()` when
switching documents. Do not mutate the document out of band while retaining
commands whose inverses depend on its contents.

## Migration from experimental

Replace `package:jintent/experimental.dart` with
`package:jintent/undo_redo.dart`. The former remains a legacy compatibility export
of the same implementation; active examples and tests use the stable entry point.
Internal `src/experimental` exports are compatibility shims, not implementations.

Existing class and method names remain available. Capacities of zero or less now
throw, and history operations from cancelled intents or disposed controllers no
longer mutate stacks. Undo/redo now report real changes to the global observer.
Migrate UI code that reads controller availability getters to listen to `history`
when it must also react to clear, enable or disable operations.
