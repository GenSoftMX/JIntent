# Validator Examples

This directory contains example validators demonstrating best practices for input validation using JIntent's `UseCaseInputValidator`.

## Overview

These examples demonstrate:
- ✅ **Fail-fast validation chains** - Stop at the first validation error
- ✅ **Reusable validators** - Common validation patterns that can be composed
- ✅ **Domain-specific validators** - Validators tailored to specific data types
- ✅ **Clear error messages** - Helpful feedback for validation failures

## Files

### Common Validators (`common_validators.dart`)

Generic, reusable validators for common data types:

- **String validators**: `notEmpty`, `minLength`, `maxLength`, `matchesPattern`
- **Numeric validators**: `inRange`, `positive`, `nonNegative`, `doubleInRange`
- **Collection validators**: `listNotEmpty`, `listMinSize`, `listMaxSize`

**Example usage:**
```dart
class MyUseCase extends JUseCase<String, Result> {
  MyUseCase() {
    addValidator(CommonValidators.notEmpty('Username'));
    addValidator(CommonValidators.minLength(3, 'Username'));
    addValidator(CommonValidators.maxLength(20, 'Username'));
  }
}
```

### Email Validators (`email_validators.dart`)

Email-specific validation logic with chained validators:

- `notEmpty` - Ensures email is not empty
- `length` - Enforces maximum length
- `format` - Validates email format with regex
- `validDomain` - Checks for valid domain structure
- `notDisposable` - Blocks disposable email services

**Example usage:**
```dart
class RegisterUseCase extends JUseCase<RegistrationInput, User> {
  RegisterUseCase() {
    // Apply email validation chain
    for (final validator in EmailValidators.completeChain) {
      addValidator((input) => validator(input.email));
    }
  }
}
```

### Password Validators (`password_validators.dart`)

Security-focused password validation:

- `minLength` / `maxLength` - Length constraints
- `hasUppercase` / `hasLowercase` - Character requirements
- `hasNumber` / `hasSpecialChar` - Complexity requirements
- `noSpaces` - Format restrictions
- `notCommon` - Prevents weak passwords

**Pre-built chains:**
- `standardChain` - Comprehensive security (8+ chars, uppercase, lowercase, number, special char)
- `basicChain` - Lighter requirements (6+ chars, letter + number)

**Example usage:**
```dart
class ChangePasswordUseCase extends JUseCase<String, void> {
  ChangePasswordUseCase() {
    // Apply standard password validation
    for (final validator in PasswordValidators.standardChain) {
      addValidator(validator);
    }
  }
}
```

### Counter Validators (`counter_validators.dart`)

Application-specific validators for the counter example:

- `withinRange` - Ensures value is within min/max bounds
- `canIncrement` / `canDecrement` - Validates operations won't exceed limits
- `isEven` / `isOdd` - Divisibility checks
- `divisibleBy` - Custom divisibility validation

**Example usage:**
```dart
class IncrementUseCase extends JSyncUseCase<int, int> {
  IncrementUseCase() {
    addValidator(CounterValidators.withinRange(-10, 10));
    addValidator(CounterValidators.canIncrement(10));
  }
}
```

## Example Use Cases

### Validated Increment (`../use_cases/validated_increment_use_case.dart`)

Demonstrates fail-fast validation for counter increment:
1. Validates current value is within range
2. Validates increment won't exceed maximum
3. Only performs increment if all validations pass

### Validated Decrement (`../use_cases/validated_decrement_use_case.dart`)

Similar to increment, but for decrement operations:
1. Validates current value is within range
2. Validates decrement won't go below minimum
3. Only performs decrement if all validations pass

### User Registration (`../use_cases/validate_user_registration_use_case.dart`)

Complex validation example with multiple fields:
1. Email validation (empty, format, length)
2. Password validation (length, complexity)
3. Username validation (length, format)
4. Age validation (business rule)

## Fail-Fast Behavior

All validators follow a **fail-fast** approach:

```dart
class ExampleUseCase extends JUseCase<String, Result> {
  ExampleUseCase() {
    addValidator(validator1); // Executes first
    addValidator(validator2); // Only if validator1 passes
    addValidator(validator3); // Only if validator1 and validator2 pass
  }

  @override
  Future<Either<Exception, Result>> run(String input) async {
    // Only executes if ALL validators pass
    return Right(Result());
  }
}
```

**Benefits:**
- ⚡ **Performance** - Stops validation as soon as one fails
- 🎯 **Clarity** - Users see the first error, not multiple errors
- 📊 **Logic** - Validate simple checks before expensive ones

## Best Practices

### 1. Order validators by cost
```dart
// ✅ Good: Cheap checks first, expensive checks last
addValidator(notEmpty);           // O(1)
addValidator(lengthCheck);        // O(1)
addValidator(formatRegex);        // O(n)
addValidator(databaseLookup);     // Expensive
```

### 2. Provide clear error messages
```dart
// ✅ Good: Specific and actionable
return Left(Exception('Email must be between 5 and 100 characters'));

// ❌ Bad: Vague and unhelpful
return Left(Exception('Invalid input'));
```

### 3. Keep validators pure
```dart
// ✅ Good: Pure function, no side effects
UseCaseInputValidator<String> notEmpty = (input) {
  if (input.isEmpty) return Left(Exception('Cannot be empty'));
  return Right(input);
};

// ❌ Bad: Modifies input, has side effects
UseCaseInputValidator<String> trimAndValidate = (input) {
  input = input.trim(); // Don't modify input!
  return Right(input);
};
```

### 4. Use factory functions for reusability
```dart
// ✅ Good: Reusable validator factory
UseCaseInputValidator<String> minLength(int min, String field) {
  return (input) {
    if (input.length < min) {
      return Left(Exception('$field must be at least $min characters'));
    }
    return Right(input);
  };
}
```

## Testing

All validators should be tested independently:

```dart
void main() {
  group('EmailValidators', () {
    test('format accepts valid email', () {
      final result = EmailValidators.format('test@example.com');
      expect(result.isRight, true);
    });

    test('format rejects invalid email', () {
      final result = EmailValidators.format('invalid-email');
      expect(result.isLeft, true);
    });
  });
}
```

## See Also

- [Validation Guide](/docs/VALIDATION_GUIDE.md) - Comprehensive validation patterns documentation
- [Use Case Tests](/test/src/domain/use_case_test.dart) - Unit tests demonstrating validation
- [Error Handling Guide](/docs/ERROR_HANDLING_GUIDE.md) - Error handling patterns in JIntent
