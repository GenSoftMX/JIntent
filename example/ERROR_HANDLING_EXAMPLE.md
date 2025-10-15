# Error Handling Example - Counter App

This document demonstrates the error handling patterns implemented in the JIntent counter example app.

## Overview

The counter app showcases consistent error UX patterns using JIntent's side effect system. It demonstrates:
- Error snackbars with different severities
- Success feedback
- Validation error handling
- Effect categorization for analytics

## Error Handling Architecture

### 1. Effect Definitions

The app defines multiple effect types for different user feedback scenarios:

```dart
/// Error snackbar (red background)
class ShowRejectOperation extends JEffect<bool> with JCategorizableEffect {
  final String message;
  ShowRejectOperation({required this.message});
  
  @override
  String get category => 'error';
}

/// Success snackbar (green background)
class ShowSuccessEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;
  ShowSuccessEffect({required this.message});
  
  @override
  String get category => 'success';
}

/// Warning snackbar (orange background)
class ShowWarningEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;
  ShowWarningEffect({required this.message});
  
  @override
  String get category => 'warning';
}

/// Info snackbar (blue background)
class ShowInfoEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;
  ShowInfoEffect({required this.message});
  
  @override
  String get category => 'info';
}

/// Error dialog for critical errors
class ShowErrorDialogEffect extends JDialogEffect<bool> with JCategorizableEffect {
  final String title;
  final String message;
  final String? actionLabel;
  
  ShowErrorDialogEffect({
    required this.title,
    required this.message,
    this.actionLabel,
  });
  
  @override
  String get category => 'error_dialog';
}
```

### 2. Effect Handler Implementation

The `CounterEffectHandler` registers handlers for all effect types:

```dart
class CounterEffectHandler extends JSideEffectHandler<CounterState> {
  CounterEffectHandler(super.controller) {
    register<ShowRejectOperation>(_onShowError);
    register<ShowSuccessEffect>(_onShowSuccess);
    register<ShowWarningEffect>(_onShowWarning);
    register<ShowInfoEffect>(_onShowInfo);
    register<ShowErrorDialogEffect>(_onShowErrorDialog);
  }

  Future<void> _onShowError(
    ShowRejectOperation effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(effect.message)),
          ],
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
    effect.complete(true);
  }

  // ... other handlers
}
```

## Error Handling Patterns

### Pattern 1: Validation Error Handling

When the increment/decrement use cases fail validation:

```dart
class IncrementIntent extends JIntent<CounterState> {
  @override
  Future<void> onInvoke() async {
    final incrementResult = _incrementUseCase(state.counter);

    incrementResult.fold(
      (failure) => handleFailure(failure),
      (data) => handleSuccess(data),
    );
  }

  @protected
  void handleFailure(Exception e) async {
    // Show error snackbar
    await emitAndWaitSideEffect<bool>(
      ShowRejectOperation(message: e.toString()),
    );
  }

  @protected
  void handleSuccess(int value) {
    _saveCurrentValueUseCase.run(value);
    update((state) => state.copyWith(newStateCounter: value));
    
    // Show success feedback for milestones
    if (value % 10 == 0) {
      controller.emitSideEffect(
        ShowSuccessEffect(message: 'Milestone reached: $value!'),
      );
    }
  }
}
```

### Pattern 2: Use Case Validation

The use cases implement business rules and return errors:

```dart
class IncrementUseCase extends JSyncUseCase<int, int> {
  IncrementUseCase() {
    addValidator((input) {
      if (input == 10) {
        return Left(
          Exception('Value cannot be greater than 10 from: use case validator'),
        );
      }
      return Right(input);
    });
  }

  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue + 1;

    if (newValue > 10) {
      return Left(Exception('Value cannot be greater than 10'));
    }
    return Right(newValue);
  }
}

class DecrementUseCase extends JSyncUseCase<int, int> {
  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue - 1;

    if (newValue < -10) {
      return Left(Exception('Value cannot be less than -10'));
    }
    return Right(newValue);
  }
}
```

## User Experience Flow

### Successful Increment
1. User taps increment button
2. `IncrementIntent` is dispatched
3. `IncrementUseCase` validates and increments
4. State is updated with new value
5. If value is a milestone (divisible by 10), a green success snackbar appears

### Failed Increment (Validation Error)
1. User taps increment when counter is at 10
2. `IncrementIntent` is dispatched
3. `IncrementUseCase` validation fails
4. `IncrementIntent.handleFailure()` is called
5. Red error snackbar appears: "Value cannot be greater than 10"
6. State remains unchanged

### Failed Decrement (Validation Error)
1. User taps decrement when counter is at -10
2. `DecrementIntent` is dispatched
3. `DecrementUseCase` validation fails
4. `DecrementIntent.handleFailure()` is called
5. Red error snackbar appears: "Value cannot be less than -10"
6. State remains unchanged

## Visual Design

### Color Coding
- **Red** 🔴 - Errors (validation failures, critical errors)
- **Green** 🟢 - Success (milestones, successful operations)
- **Orange** 🟠 - Warnings (potential issues)
- **Blue** 🔵 - Information (neutral messages)

### Icon Usage
- **Error**: `Icons.error_outline`
- **Success**: `Icons.check_circle_outline`
- **Warning**: `Icons.warning_amber`
- **Info**: `Icons.info_outline`

## Effect Categories

Effects are categorized for analytics and debugging:

```dart
// Track error effects
controller.sideEffects
  .where((effect) => effect.resolvedCategory == 'error')
  .listen((effect) {
    analytics.logErrorShown(
      category: effect.resolvedCategory,
      message: (effect as ShowRejectOperation).message,
    );
  });

// Track success feedback
controller.sideEffects
  .where((effect) => effect.resolvedCategory == 'success')
  .listen((effect) {
    analytics.logSuccessShown(
      category: effect.resolvedCategory,
      message: (effect as ShowSuccessEffect).message,
    );
  });
```

## Testing Error Handling

```dart
void main() {
  group('Counter Error Handling', () {
    test('shows error when incrementing beyond limit', () async {
      final controller = CounterController();
      final effects = <JEffect>[];
      
      controller.sideEffects.listen(effects.add);

      // Set counter to 10
      controller.intent(SetCounterIntent(10));
      
      // Try to increment (should fail)
      await controller.intent(IncrementIntent());

      // Verify error effect was emitted
      expect(effects.length, 1);
      expect(effects.first, isA<ShowRejectOperation>());
      expect(
        (effects.first as ShowRejectOperation).message,
        contains('cannot be greater than 10'),
      );
      
      // Verify state unchanged
      expect(controller.state.counter, 10);
    });

    test('shows success effect on milestone', () async {
      final controller = CounterController();
      final effects = <JEffect>[];
      
      controller.sideEffects.listen(effects.add);

      // Set counter to 9
      controller.intent(SetCounterIntent(9));
      
      // Increment to 10 (milestone)
      await controller.intent(IncrementIntent());

      // Verify success effect was emitted
      expect(effects.any((e) => e is ShowSuccessEffect), isTrue);
      
      final successEffect = effects.whereType<ShowSuccessEffect>().first;
      expect(successEffect.message, contains('Milestone reached: 10'));
    });
  });
}
```

## Best Practices Demonstrated

1. **Separation of Concerns**: Business logic (use cases) is separate from UI feedback (effects)
2. **Type Safety**: Using strongly-typed effect classes instead of strings
3. **Consistent UX**: All errors follow the same visual pattern
4. **User Feedback**: Clear, actionable error messages
5. **Effect Completion**: All effects properly complete to avoid hanging
6. **Categorization**: Effects are categorized for analytics
7. **Idempotency**: Effect completion is idempotent (safe to call multiple times)

## Extending the Pattern

To add new error types:

1. **Define the Effect**:
```dart
class ShowNetworkErrorEffect extends JDialogEffect<bool> with JCategorizableEffect {
  final String message;
  final VoidCallback? onRetry;
  
  ShowNetworkErrorEffect({required this.message, this.onRetry});
  
  @override
  String get category => 'error_network';
}
```

2. **Register the Handler**:
```dart
class CounterEffectHandler extends JSideEffectHandler<CounterState> {
  CounterEffectHandler(super.controller) {
    // ... existing registrations
    register<ShowNetworkErrorEffect>(_onShowNetworkError);
  }

  Future<void> _onShowNetworkError(
    ShowNetworkErrorEffect effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Error'),
        content: Text(effect.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          if (effect.onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
                effect.onRetry?.call();
              },
              child: const Text('RETRY'),
            ),
        ],
      ),
    );
    effect.complete(result ?? false);
  }
}
```

3. **Emit from Intent**:
```dart
class LoadDataIntent extends JIntent<AppState> {
  @override
  Future<void> onInvoke() async {
    final result = await _loadDataUseCase();
    
    result.fold(
      (error) {
        if (error is NetworkException) {
          controller.emitSideEffect(ShowNetworkErrorEffect(
            message: error.message,
            onRetry: () => controller.intent(this),
          ));
        } else {
          controller.emitSideEffect(ShowRejectOperation(
            message: error.toString(),
          ));
        }
      },
      (data) => handleSuccess(data),
    );
  }
}
```

## Related Documentation

- [Error Handling Guide](../docs/ERROR_HANDLING_GUIDE.md) - Comprehensive error handling patterns
- [Global Error Handler Guide](../docs/GLOBAL_ERROR_HANDLER.md) - Global error interception
- [Effects Guide](../doc/effects.md) - Complete side effects documentation
- [Error Handling Examples](../docs/examples/error_handling_examples.md) - More code examples

---

**Example Version:** 1.0  
**Last Updated:** 2025-10-15  
**Maintained By:** JIntent Core Team
