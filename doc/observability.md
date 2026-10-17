# Observability and extension points

JIntent provides logging, correlation, metrics and a debug overlay from
`package:jintent/devtools.dart`; `JObserver` itself comes from
`package:jintent/jintent.dart`. Test helpers live in `package:jintent/testing.dart`; see
[testing](testing.md). Configure them in the application; they do not install a
remote backend. Redact application data before logging.

## Logging and correlation

```dart
final logger = JStructuredLogger(
  serviceName: 'counter',
  minLevel: LogLevel.info,
);
logger.info('Counter loaded', context: {'source': 'local'});
```

`JStructuredLogger` writes JSON logs. `CorrelationContext.runWithCorrelation`
runs an asynchronous callback in a zone with an ID available through `current`
and `asContext`. Include that context in logs when needed. The example's
[observability setup](../example/lib/src/@core/observability/) shows one
integration.

## Observer and metrics

`JObserver` notifies intent start, completion and failure, state changes and
emitted effects. Register a `JObserverDelegate` with `JObserver.addObserver`;
override only the notifications you need. Any number of observers can coexist,
and the returned function removes that registration alone:

```dart
class AnalyticsObserver extends JObserverDelegate {
  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) {
    report(intent.runtimeType, error, stackTrace);
  }
}

final remove = JObserver.addObserver(AnalyticsObserver());
```

`onIntentStarted` and `onIntentFailed` are raised by `JIntent` itself, so they
cover every dispatcher and direct `run` calls. Dispatchers report how an intent
ended without failing: `onIntentDispatched` on success, `onIntentCancelled` when
cancellation was requested ([concurrency](concurrency.md)), and
`onIntentDropped` when a dispatcher discarded it without running. The last two
exist only on observers, not as static callbacks. A state change made inside an
intent reports that intent as its origin even when `update` was called without
one. Rejections before execution (disposed controller,
overlapping invocation of one instance, cancelled queue entries) are not
failures of the intent and are not reported.

The static callbacks (`onIntentDispatched`, `onIntentFailed`, `onStateChanged`,
`onEffectEmitted`) hold one slot each and assigning replaces the previous value;
they run before registered observers. Prefer observers when several consumers
share the process. An observer that throws never affects the observed code: the
error goes to `FlutterError.reportError` and the others still run. Call
`JObserver.reset()` in tests.

`JMetrics.enable()` enables collection; `attachToObserver()` registers an
observer that counts `intent.dispatched`, `intent.failed`, `intent.cancelled`,
`intent.dropped`, `state.changed` and `effect.emitted`, and records `intent.execution.duration` (microseconds) for each
intent. That duration covers `onInvoke` only; time waiting in a dispatcher queue
and effect completion are not measured. Attaching twice has no extra effect and
`detachFromObserver()` stops it. Use `incrementCounter`, `recordGauge`,
`startTimer` and `stopTimer` for explicit measurements, and `getMetrics` or
`getSummary` to inspect them. `JMetrics.maxMetrics` (default 1000) bounds
retained measurements by dropping the oldest.

## Debug overlay

`JDevToolsOverlay` displays recent intent, state and effect notifications inside
the app. Intents that failed, were cancelled or were dropped appear too, titled
`Type (failed)`, `Type (cancelled)` or `Type (dropped)`. It is a local debug overlay, not a browser DevTools integration.

```dart
MaterialApp(
  builder: (context, child) => JDevToolsOverlay(
    enabled: kDebugMode,
    maxEvents: 50,
    maxEventAge: const Duration(seconds: 30),
    child: child!,
  ),
);
```

It registers its own observer and removes only that registration on disposal,
so it can be combined with logging, metrics and static callbacks. Keep it
disabled outside debugging: event metadata can include
application data. See the
[implementation](../lib/src/devtools/devtools_overlay.dart).

## Extension points

JIntent has no plugin registry or automatic plugin discovery. It exposes:

- `JObserver`: see above.
- `JIntentDispatcher`: implement `dispatch<T>` and inject it through the
  controller constructor. The controller defaults to sequential dispatch;
  `JDefaultIntentDispatcher` invokes immediately without a queue. See
  [concurrency](concurrency.md) for the ready-made strategies. A custom
  dispatcher reports to observers through the public `JObserver.notify...`
  methods: call `notifyIntentCompleted` after `intent.run` succeeds (it reports
  `onIntentCancelled` for a cancelled intent and `onIntentDispatched` otherwise)
  and `notifyIntentDropped` for an intent it discards without running. Do not
  call the other `notify...` methods: the intent reports its own start and
  failure, and the controller reports state changes and effects.
- `JPendingIntentCancellation`: implement this for dispatchers that retain queued
  work. Reject pending futures on disposal, preserve other controllers' order,
  and forward cancellation through decorators. `LoggingDispatcher` does so.
- `JSideEffectHandler`: register handlers for concrete effect types. See
  [effects](effects.md).

Custom dispatchers must define ordering, concurrency and failure behavior. Do
not recursively await a queued child intent behind the currently running intent
on the same sequential queue. [Undo/redo](undo-redo.md) records selected local
state changes, not external service operations. Its synchronous undo/redo calls
report actual state changes to observers; dispatch a custom intent when these
operations must share the queue and carry intent attribution.

## Measuring performance

No latency, memory, binary-size or throughput budget is established. Measure on
the target device and build mode: dispatch-to-completion time (including queue
delay), rebuilds after state changes (equal states are skipped), retained state
and debug events, and logging/observer integrations separately. Record workload,
device, build mode and method with any published result.
