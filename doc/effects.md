# Effects

Effects represent transient UI work outside persistent state. Import all effect
APIs through `package:jintent/jintent.dart`.

| Type | Purpose |
| --- | --- |
| `JFireAndForgetEffect` | Feedback with no expected return value |
| `JResultEffect<T>` | Work that produces a result |
| `JDialogEffect<T>` | UI interaction that produces a result |

## Registration

```dart
class ConfirmDelete extends JDialogEffect<bool> {}

class CounterEffects extends JSideEffectHandler<CounterState> {
  CounterEffects(super.controller) {
    register<ConfirmDelete>((effect, controller, context) async {
      // Replace with the application's confirmation dialog.
      effect.complete(true);
    });
  }
}
```

`CounterState` is the application state from the [README](../README.md).
Attach a `JEffectListener` with the controller, handler and child widget before
emitting effects. Registration matches the concrete runtime type, not a base class.

Emit feedback with `controller.emitSideEffect(effect)`. Await UI work with:

```dart
final confirmed = await controller.emitAndWaitSideEffect(
  ConfirmDelete(),
  timeout: const Duration(seconds: 30),
);
```

Catch failures at the operation boundary. Handlers must complete awaited effects
with `complete(value)` or `completeError(error, stackTrace)`.

## Failures and lifecycle

- Without a stream listener, awaited effects fail with `StateError`;
  fire-and-forget emissions are dropped, unless the controller buffers effects
  (see below).
- With a listener but no registered handler, the default
  `warnAndCompleteError` strategy fails the result with `StateError`.
  `throwError` also fails `handle`; `warnOnly` leaves the result pending.
  Deprecated `warnAndAutoComplete` also completes with error.
- `JEffectsConfig().defaultTimeout` or the per-call timeout bounds waiting;
  there is no implicit finite timeout. Expiry fails with `TimeoutException`.
- Handler exceptions fail pending results. `JEffectListener` reports handler
  failures through `FlutterError.reportError`; result awaiters still catch errors.
- Removing or replacing a listener does not cancel running handlers. Pending
  results require completion, timeout or controller disposal. Check
  `context.mounted` before UI access after an asynchronous gap.
- Controller disposal fails pending results and rejects new emissions. It does
  not cancel external work or overwrite already completed results.

## Effects emitted before the UI attaches

A controller can emit during `onInit`, before any `JEffectListener` exists. By
default those effects are lost or failed. Opt in to a bounded buffer instead:

```dart
class SplashController extends JController<SplashState> {
  SplashController() : super(const SplashState(), effectBufferSize: 8);

  @override
  void onInit() => emitSideEffect(ShowWelcome());
}
```

With `effectBufferSize` above zero, effects emitted while nobody listens are
retained, in order, and delivered shortly after the next listener subscribes.

- Each effect is delivered once, to whoever listens first. A second listener
  does not replay it.
- Awaitable effects stay pending while retained, so `emitAndWaitSideEffect`
  waits instead of failing; use a timeout. Effects already completed (for
  example by a timeout) are skipped on delivery.
- When the buffer is full the oldest effect is discarded and completed with
  `StateError`.
- Disposal fails retained awaitable effects and drops the rest.
- Observers receive `onEffectEmitted` when the effect is emitted, not when it
  is delivered.

The buffer is a startup aid, not a queue for a UI that is absent for long:
retained effects can be stale by the time they are shown.

Any subscription to `controller.sideEffects` counts as a listener, so a
diagnostic `sideEffects.listen` attached before the UI receives the retained
effects and the `JEffectListener` that follows gets none. To watch effects
without consuming them, use `JObserver` (`onEffectEmitted`), which sees each
effect when it is emitted and never takes it from the buffer.

For consumer changes and cancellation details, see the
[migration guide](migration.md).
