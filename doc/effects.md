# Side Effects (JEffect) – Complete Guide

## Objective
Separate transient events (navigation, dialogs, toasts, confirmations) from persistent state.

## Key Concepts
- JEffect<T>: base effect. Can return a value (T) or fail (completeError).
- JFireAndForgetEffect: fire-and-forget semantics; no result expected.
- JResultEffect<T>: explicit intent to return a value.
- JDialogEffect<T>: special case for UI interaction (dialog, sheet, picker).
- Categories: optional for analytics/devtools.

## Flow
UI → controller.intent(...) → intent emits state(s) and/or side effects → UI (listener) handles effect → completes (or not) → intent (if emitAndWaitSideEffect was used) continues.

## Emission
```dart
controller.emitSideEffect(ShowSnackbarEffect(message: 'Saved'));
final answer = await controller.emitAndWaitSideEffect(
    ConfirmDialogEffect(question: 'Delete item?'),
);
```

## Timeout
`emitAndWaitSideEffect(effect, timeout: 5.seconds)`  
If expired: completeError(TimeoutException).

## Unhandled Strategy
Configurable via JEffectsConfig().unhandledStrategy:
- warnOnly
- warnAndAutoComplete (default)
- throwError

## Best Practices
- Always complete JResultEffect / JDialogEffect.
- Do not use emitAndWaitSideEffect with JFireAndForgetEffect (unnecessary).
- Avoid retaining BuildContext after long tasks (show the dialog immediately and await its Future).
- Use categories to group metrics (e.g. navigation, dialog, feedback).

## Handler Example
```dart
class MyEffectHandler extends JSideEffectHandler<AppState> {
    MyEffectHandler(super.controller) {
        register<ShowToastEffect>((e, c, ctx) async {
            ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(e.message)),
            );
            e.complete(null); // fire-and-forget -> optional
        });

        register<ConfirmDialogEffect>((e, c, ctx) async {
            final accepted = await showDialog<bool>(
                context: ctx,
                builder: (_) => AlertDialog(
                    title: Text('Confirm'),
                    content: Text(e.question),
                    actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Yes')),
                    ],
                ),
            );
            e.complete(accepted ?? false);
        });
    }
}
```

## Testing
- Mock effect and verify completion.
- Timeout test (use fakeAsync).
- Unhandled test (throwError strategy).