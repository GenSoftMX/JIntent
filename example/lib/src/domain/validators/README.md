# Validation Examples

This directory contains example validators demonstrating JIntent's input validation patterns.

## Overview

JIntent use cases support input validation through the `UseCaseInputValidator` pattern. Validators enforce preconditions and business rules before the use case's business logic executes.

## Files

- **`common_validators.dart`** - Reusable validator functions for common patterns (range, format, null checks)

## Key Concepts

### Fail-Fast Validation Chain

Validators are executed in order and stop at the first failure:

```dart
class MyUseCase extends JUseCase<Input, Output> {
  MyUseCase() {
    addValidator(_validator1);  // Checked first
    addValidator(_validator2);  // Only checked if validator1 passes
    addValidator(_validator3);  // Only checked if validator2 passes
  }
}
```

### Validator Signature

```dart
typedef UseCaseInputValidator<I> = Either<Exception, I> Function(I input);

// Returns Left on failure:
return Left(Exception('Validation failed'));

// Returns Right on success:
return Right(input);
```

## Example Use Cases

The following use cases demonstrate validation patterns:

1. **`SetCounterValueUseCase`** - Simple range validation
2. **`ValidateCounterConfigUseCase`** - Multi-field validation with fail-fast chain
3. **`AddToCounterUseCase`** - Comprehensive validation with cross-field checks
4. **`IncrementUseCase`** - Stateful validator pattern
5. **`DecrementUseCase`** - Validation in business logic (alternative pattern)

## Usage Examples

### Using Common Validators

```dart
import 'package:counter/src/domain/validators/common_validators.dart';

class MyUseCase extends JUseCase<int, String> {
  MyUseCase() {
    // Use pre-built validators
    addValidator((input) => CommonValidators.intInRange(input, 0, 100));
    addValidator((input) => CommonValidators.nonNegative(input));
  }
  
  @override
  Future<Either<Exception, String>> run(int input) async {
    // Business logic with validated input
    return Right(input.toString());
  }
}
```

### Custom Validators

```dart
class CreateUserUseCase extends JUseCase<UserInput, User> {
  CreateUserUseCase() {
    addValidator(_validateEmail);
    addValidator(_validatePassword);
  }
  
  Either<Exception, UserInput> _validateEmail(UserInput input) {
    if (!input.email.contains('@')) {
      return Left(Exception('Invalid email format'));
    }
    return Right(input);
  }
  
  Either<Exception, UserInput> _validatePassword(UserInput input) {
    if (input.password.length < 8) {
      return Left(Exception('Password must be at least 8 characters'));
    }
    return Right(input);
  }
  
  @override
  Future<Either<Exception, User>> run(UserInput input) async {
    // Create user with validated input
    return Right(User(email: input.email));
  }
}
```

## Best Practices

1. **Order validators by cost** - Cheap checks first (null, range), expensive checks last (database, API)
2. **One concern per validator** - Each validator should check a single thing
3. **Clear error messages** - Provide actionable feedback
4. **Immutable validators** - Don't modify input, just validate it
5. **Reuse common patterns** - Use `CommonValidators` or create your own library

## Testing

Test validators individually and as part of use cases:

```dart
void main() {
  group('Range validator', () {
    test('accepts valid values', () {
      final result = CommonValidators.intInRange(5, 0, 10);
      expect(result.isRight, true);
    });
    
    test('rejects out of range values', () {
      final result = CommonValidators.intInRange(15, 0, 10);
      expect(result.isLeft, true);
    });
  });
  
  group('UseCase validation', () {
    test('fails fast on first invalid validator', () async {
      final useCase = ValidateCounterConfigUseCase();
      final input = CounterConfig(
        initialValue: 5,
        minValue: 0,
        maxValue: 10,
        step: -1, // Invalid - will fail first
      );
      
      final result = useCase(input);
      
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('Step must be positive'));
    });
  });
}
```

## Related Documentation

- [Validation Guide](/docs/VALIDATION_GUIDE.md) - Comprehensive validation patterns and best practices
- [Error Handling Guide](/docs/ERROR_HANDLING_GUIDE.md) - Using Either for error handling
- [Use Case Documentation](/lib/src/domain/use_case.dart) - Core use case implementation

## Learn More

For complete validation examples and patterns, see the [Validation Guide](/docs/VALIDATION_GUIDE.md).
