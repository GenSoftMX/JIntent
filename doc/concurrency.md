# Concurrency strategies

A controller dispatches intents through a `JIntentDispatcher`. Choose the
strategy that matches the user action and inject it in the constructor:

```dart
class SearchController extends JController<SearchState> {
  SearchController()
    : super(const SearchState(), dispatcher: JRestartableIntentDispatcher());

  Future<void> search(String query) => intent(SearchIntent(query));

  @override
  void onInit() {}
}
```

| Dispatcher | Behavior | Use for |
| --- | --- | --- |
| `JSequentialIntentDispatcher` (default) | One intent at a time, FIFO. | Anything order-sensitive. |
| `JDefaultIntentDispatcher` | Runs every intent immediately, concurrently. | Independent, idempotent work. |
| `JDroppableIntentDispatcher` | Drops an intent while another with the same key is running. | Submit, refresh, double taps. |
| `JRestartableIntentDispatcher` | Cancels the running intent with the same key, then starts the new one. | Search as you type, latest wins. |

Droppable and restartable dispatchers group intents by `runtimeType`. Pass
`keyOf` (a `JIntentKey`) to group differently, for example by entity id. Different keys never
affect each other, and keys are tracked per controller, so one dispatcher
instance can be shared.

## Dropped intents

A dropped intent is not queued or executed and its future completes normally.
Observers receive `onIntentDropped` for it; `onIntentDispatched` is raised only
for intents that ran.

## Cooperative cancellation

Restarting never interrupts running code. It calls `JIntent.cancel()` on the
superseded intent, which has two effects:

- `intent.isCancelled` becomes `true`; check it after each `await` and return
  early to skip wasted work.
- `JController.update` ignores updates made by that intent. This is what stops
  a slow earlier request from overwriting a newer result. `invoke` runs
  `onInvoke` in a zone that carries the intent (`JIntent.current`), and
  `update` uses it as the origin when you do not pass one. Plain
  `controller.update(...)` calls are therefore covered, including after
  `await`s and from timers or stream callbacks created inside the intent. An
  explicit `origin` takes precedence.

Work scheduled outside that zone, such as a callback registered before the
intent started, is not attributed to it. Updates to a *different* controller
are never attributed or blocked. Effects are not filtered, and external
operations keep running unless you use their own cancellation API.

The superseded intent's future still reports its own result or error, and
observers receive `onIntentCancelled` instead of `onIntentDispatched` when it
finishes. `cancel() is a no-op on an intent that is not running, and the
flag resets when the intent is invoked again.

## Disposal

These dispatchers keep no queue, so there is nothing to reject on disposal.
Running intents are not interrupted; the controller rejects new intents with
`StateError`, as with every dispatcher. Custom dispatchers that hold queued work
must implement `JPendingIntentCancellation`.
