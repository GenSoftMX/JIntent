# Error handling

Use `Either<Exception, T>` for expected operation failures. `Left` holds the
failure; `Right` holds success. These are values, not an automatic exception
boundary: thrown exceptions still propagate.

```dart
Either<Exception, int> decrement(int value) {
  return value <= 0
      ? Left(Exception('Counter cannot be negative'))
      : Right(value - 1);
}
```

In an intent, translate recoverable operation failures into a dedicated effect.
Present feedback only in the effect handler. Return `controller.intent(...)`
futures from controller methods. Catch unexpected or lifecycle failures at the UI
boundary and log them without emitting another presentation effect. `unawaited`
alone does not catch errors. Await asynchronous branches, including futures
returned by `fold`, before an intent completes.

Disposal does not stop running services. Check `controller.mounted` after awaits
before accessing disposed state or starting more work. Keep cancellation in the
service that owns the operation. The
[counter example](../example/README.md#error-handling) shows this end to end.

## Failure boundaries

| Boundary | Failure behavior |
| --- | --- |
| Use-case validation | First returned `Left` stops execution; thrown exceptions propagate |
| Intent dispatch | Failures propagate through the returned future |
| Overlapping invocation of one intent instance | `StateError` |
| New or queued intent on disposed controller | Failed future with `StateError` for the default sequential dispatcher |
| Awaited effect without a listener | Result fails with `StateError` |
| Awaitable effect without a matching handler | Default strategy fails result with `StateError`; configurable |
| Effect timeout | `TimeoutException` |
| Handler exception | Pending result and direct `handle()` future fail with original error |
| Controller disposal | Pending effect results fail; running external work continues |
| Unsupported `transformDynamic` input | `ArgumentError` |

This is a boundary summary, not a catalog of application exceptions or stable
error-message strings. See [effects](effects.md) and [migration](migration.md).

## Debug logging hook

```dart
EitherConfig.configureLogger((error) {
  // Send a redacted diagnostic to the application's logger.
});
```

The hook runs only in debug mode and does not catch thrown exceptions, install
Flutter error handlers, or provide crash reporting. `EitherConfig.errorLogger`
is global; restore it after tests or temporary integrations. Keep the callback
non-throwing because it executes while constructing `Left`. Application-wide
Flutter handlers, analytics and crash reporting belong to the consuming
application. Avoid logging secrets or displaying raw exceptions to users.
