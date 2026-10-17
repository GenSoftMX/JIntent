# Migration: 2.x to 3.0.0

Version 3.0.0 is a major release. Public signatures are largely preserved, but
the behavior changes below are incompatible with 2.x and require consumer review.

## Immutable state and equality

`update` and deprecated `setState` skip states equal to the current value (`==`).
This replaces the behavior described in 2.0.1. Use final fields, protect nested
collections, include relevant values in `props`, and return a new state rather
than mutating existing objects. `@immutable` does not freeze objects at runtime.
For nullable `copyWith` fields, distinguish omission from assigning null; see
the example in `JState` API documentation.

## Await and handle intent failures

Return the dispatch future from controller methods:

```dart
Future<void> increment() => intent(_incrementIntent);
```

Consume it at the UI boundary:

```dart
Future<void> onIncrementPressed() async {
  try {
    await controller.increment();
  } catch (error, stackTrace) {
    // Record unexpected or lifecycle failures; do not re-emit them here.
    debugPrint('Increment failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
```

`unawaited(future)` alone does not handle an error. If a void callback starts
async work, use `unawaited` only after that async method handles its failures.
Translate recoverable operation failures to dedicated effects at the operation
boundary, and present feedback only in the effect handler. For example, the
counter intents catch persistence `Exception`s and emit `ShowSaveFailureEffect`
while their controller is mounted. Unexpected `Error`s and failures after
disposal still propagate to the UI logging boundary. An effect-handler failure
must not produce another presentation effect through that fallback path.
Also await child operations within an intent: `void async` helpers or discarded
`fold` futures can escape the intent's lifetime and error handling.

The same intent instance cannot execute concurrently. It can be reused after
completion or failure. Prefer a separate instance for independent controllers.
Invoking it on a disposed controller fails before binding or execution.

## Effects and missing handlers

The default is now `UnhandledEffectStrategy.warnAndCompleteError`: missing
handlers complete awaitable results with a descriptive `StateError`, including
nullable result types. The deprecated `warnAndAutoComplete` enum member remains
available but also completes with error. Replace references to it; do not rely
on null as a fallback result. `throwError` additionally fails `handle()`;
explicit `warnOnly` logs and deliberately leaves the result pending.
Update exhaustive switches over `UnhandledEffectStrategy` to account for the
new member.

Register each concrete effect type: registering a base class does not handle
subclasses. Effect configuration is now exported by `package:jintent/jintent.dart`.

Handler failures complete pending results with the original error. Direct
`handle()` calls must handle their returned future. `JEffectListener` reports
handler failures using `FlutterError.reportError`; an application awaiting the
result must still catch its failure. A late failure never overwrites a result
that has already completed. Timeouts now fail with `TimeoutException`.

## Listener presence is not acknowledgement

An awaited effect without any stream listener fails with `StateError`. A
fire-and-forget emission without listeners is dropped; explicitly awaiting it
through `emitAndWaitSideEffect` requires a listener as well.

`hasListener` only detects a stream subscription, not a matching handler or a
completed result. A logging-only listener, paused subscription, or handler that
forgets `complete`/`completeError` can still leave a result pending. Set an
appropriate per-call timeout or application-level `JEffectsConfig().defaultTimeout`.
There is no implicit finite timeout.

Listener replacement detaches the old stream. Unmounting cancels the subscription,
but neither action cancels already running handlers or completes their results.
Events cancelled before delivery may be dropped by the broadcast stream. A
pending result then needs handler completion, timeout, or controller disposal.
Check `context.mounted` before using a UI context after an asynchronous gap.

## Controller disposal and cancellation

- New intents after disposal return a future failed with `StateError`.
- The sequential dispatcher rejects queued tasks for the disposed controller
  immediately, preserving other controllers' task order. Catch those futures.
- Custom queueing dispatchers can implement `JPendingIntentCancellation`.
  Decorators must forward that contract; `LoggingDispatcher` does so.
- Running intents and external operations are not interrupted. Use the external
  service's cancellation API where available and check `controller.mounted`
  after awaits before reading disposed state or starting more work.
- Pending effect results fail on controller disposal. Results already completed
  retain their value or original error.
- `emitSideEffect` after disposal throws synchronously and fails the effect
  result. `emitAndWaitSideEffect` exposes the failure through its returned future.

## Entry points

`package:jintent/jintent.dart` now exports only the core, the domain helpers,
`JObserver` and the dispatcher contracts. Import the rest explicitly; contents
and behavior are unchanged:

| Symbols | New import |
| --- | --- |
| `JMetrics`, `Metric`, `MetricType`, `JStructuredLogger`, `LogLevel`, `CorrelationContext`, `JDevToolsOverlay`, `JEffectsLogger`, `enableLoggingObserver` | `package:jintent/devtools.dart` |
| `UndoRedoMixin`, `UndoableIntent`, `UndoableCommand`, `CommandHistory`, `JUndoHistoryState` | `package:jintent/undo_redo.dart` |
| `JNavigator`, `JNavigatorImpl` | `package:jintent/navigation.dart` |
| `JThrottler`, `JValidationUtils`, `JColorUtils`, `JPlatformInfo` | `package:jintent/utils.dart` |

Navigation, validation and the other utilities are outside the library's stated
scope (ADR-000); they remain available but are not part of the core contract.

## Either is sealed

`Either` is a `sealed` class with `final` subclasses `Left` and `Right`:

- `switch` over an `Either` is exhaustive and can destructure `value`.
- Code can no longer extend or implement `Either`.
- `Left` and `Right` expose `value`, have a `toString`, and compare by value and
  exact runtime type, so `Left<String, int>('x')` is not equal to
  `Left<String, num>('x')` in either direction.
- `Right` has a `const` constructor; `Left` does not, because it can notify
  `EitherConfig.errorLogger`. A `null` `Left` value is no longer cast to
  `Object` (it used to throw when the logger was set).

## Intent methods are not overridable

`JIntent.run` and `JIntent.invoke` are annotated `@nonVirtual`; the analyzer
reports overrides. Override `onInvoke` instead, as the documentation always
required.

A class that `implements JIntent` (a hand-written fake, not a subclass) must now
also implement `cancel()` and `isCancelled`, or it no longer compiles (unless it
forwards unknown members through `noSuchMethod`). Extend `JIntent` or use a mock
library that stubs them.

## Intent attribution and cancellation

`JIntent.invoke` runs `onInvoke` in a zone carrying the intent
(`JIntent.current`). `JController.update` called inside it without an `origin`
now reports that intent to observers (previously `null`) and is ignored once the
intent is cancelled. An explicit `origin`, calls outside intents and updates to
other controllers behave as before.

Dispatchers read `JIntent.isCancelled` after a successful run: a cancelled
intent is reported through `onIntentCancelled` instead of `onIntentDispatched`.
A mock of `JIntent` (for example with `mocktail`) used with a dispatcher must
stub `isCancelled`, as it does `run`. A custom dispatcher that called
`JObserver.notifyIntentDispatched` should call `notifyIntentCompleted` instead so
that cancelled intents are reported as cancelled; see
[extension points](observability.md#extension-points).

## Effect buffering (opt-in)

Controllers accept `effectBufferSize`. The default, 0, keeps the behavior
described above. See [effects](effects.md).

## Observers and metrics

- `JObserver` also exposes `onIntentFailed`, `JObserverDelegate` and
  `addObserver`. Existing static callbacks keep working.
- Observer and callback failures no longer propagate into the observed code (for
  example, a throwing `onIntentDispatched` used to fail an intent that had
  already succeeded). They are reported through `FlutterError.reportError`.
- `enableLoggingObserver`, `JEffectsLogger.attach` and `JDevToolsOverlay` now
  register observers instead of assigning the static callbacks. Code that checks
  `JObserver.onIntentDispatched != null` to detect them must change, and the
  overlay no longer clears callbacks owned by others when disposed.
- `JMetrics.attachToObserver` registers one observer (repeat calls are no-ops),
  records a real `intent.execution.duration` and an `intent.failed` counter, and
  `JMetrics.maxMetrics` (default 1000) drops the oldest measurements. Code that
  read an unbounded history must raise the limit.
- `JController.update` ignores updates from an intent whose
  `JIntent.isCancelled` is true; see [concurrency](concurrency.md).
- `JController.update` no longer prints `State updated.` through `debugPrint`;
  the not-mounted notice prints only in debug mode.

## Tooling

Development dependencies changed (`flutter_lints` 5, `mockito` and
`build_runner` removed); consumers of the package are unaffected. CI now analyzes
and tests the library and `example/` on Flutter 3.29.2 (the minimum) and 3.47.6.
The minimum is declared as `flutter: >=3.29.2`, the first release shipping the
Dart 3.7.2 that `sdk: ^3.7.2` already required.

## Additions

`JDroppableIntentDispatcher`, `JRestartableIntentDispatcher`, `JIntent.cancel`,
`JEffectsConfig.reset()`, the `JIntentKey` typedef and the
`package:jintent/testing.dart` helpers are new in 3.0.0 and need no migration.
`JEffectsConfig` and `UnhandledEffectStrategy` are now exported by
`package:jintent/jintent.dart`; replace any import from `package:jintent/src/`.
There is one exception: `JIntent` gained the public
members `cancel()` and `isCancelled`. An intent subclass that already declares a
member with either name must rename it.

## Versioning

The package version is declared in [pubspec.yaml](../pubspec.yaml) and released
changes in [CHANGELOG.md](../CHANGELOG.md). Preserved signatures can still be
breaking behavioral changes (ordering, error behavior, lifecycle), which is why
this release is a major version.

## Undo/redo promotion

Undo/redo is stable since 3.0.0. The experimental import remains a
compatibility export. Use the stable import for new code, observe `history` for
button availability, and use positive history capacities. See the
[undo/redo migration and contracts](undo-redo.md#migration-from-experimental).
