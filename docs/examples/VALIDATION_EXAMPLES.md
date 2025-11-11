# Validation Examples Summary

This document provides a quick reference to all validation examples in the example app.

## Overview

The example app demonstrates JIntent's input validation patterns through:
- Reusable validator library (`CommonValidators`)
- Multiple use cases showing different validation patterns
- Comprehensive tests demonstrating fail-fast behavior

## Files Created

### Documentation
- [`docs/VALIDATION_GUIDE.md`](../VALIDATION_GUIDE.md) - Complete guide to input validation patterns

### Example Code
- [`example/lib/src/domain/validators/common_validators.dart`](../../example/lib/src/domain/validators/common_validators.dart) - Reusable validators
- [`example/lib/src/domain/validators/README.md`](../../example/lib/src/domain/validators/README.md) - Validators documentation
- [`example/lib/src/domain/models/counter_config.dart`](../../example/lib/src/domain/models/counter_config.dart) - Complex input model
- [`example/lib/src/domain/use_cases/set_counter_value_use_case.dart`](../../example/lib/src/domain/use_cases/set_counter_value_use_case.dart) - Simple validation example
- [`example/lib/src/domain/use_cases/validate_counter_config_use_case.dart`](../../example/lib/src/domain/use_cases/validate_counter_config_use_case.dart) - Multi-field validation
- [`example/lib/src/domain/use_cases/add_to_counter_use_case.dart`](../../example/lib/src/domain/use_cases/add_to_counter_use_case.dart) - Comprehensive validation chain

### Tests
- [`example/test/src/domain/validators/common_validators_test.dart`](../../example/test/src/domain/validators/common_validators_test.dart) - Tests for all validator functions
- [`example/test/src/domain/use_cases/set_counter_value_use_case_test.dart`](../../example/test/src/domain/use_cases/set_counter_value_use_case_test.dart) - Simple validation tests
- [`example/test/src/domain/use_cases/validate_counter_config_use_case_test.dart`](../../example/test/src/domain/use_cases/validate_counter_config_use_case_test.dart) - Fail-fast chain tests
- [`example/test/src/domain/use_cases/add_to_counter_use_case_test.dart`](../../example/test/src/domain/use_cases/add_to_counter_use_case_test.dart) - Comprehensive fail-fast tests

## Key Concepts Demonstrated

### 1. Simple Range Validation
**File:** `SetCounterValueUseCase`

```dart
class SetCounterValueUseCase extends JSyncUseCase<int, int> {
  SetCounterValueUseCase() {
    addValidator((input) => CommonValidators.intInRange(input, -10, 10));
  }
  
  @override
  Either<Exception, int> run(int newValue) {
    return Right(newValue);
  }
}
```

### 2. Multi-Field Validation with Fail-Fast
**File:** `ValidateCounterConfigUseCase`

Demonstrates three validators in a chain:
1. Step must be positive
2. Min must be less than max
3. Initial value must be in range

Execution stops at the FIRST failure.

### 3. Cross-Field Validation
**File:** `AddToCounterUseCase`

Shows validators that check:
1. Basic constraint (non-negative)
2. Business rule (reasonable amount)
3. Cross-field constraint (no overflow)

### 4. Reusable Validators
**File:** `CommonValidators`

Provides 12 reusable validator functions:
- `intInRange` - Range validation
- `notEmpty` - Non-null/empty check
- `lengthInRange` - String length validation
- `listNotEmpty` - List validation
- `notNull` - Null check
- `positive` - Positive number check
- `nonNegative` - Non-negative check
- `isEmail` - Email format validation
- `alphanumeric` - Character validation
- `minLength` - Minimum length
- `maxLength` - Maximum length

## Running the Tests

```bash
# Run all example tests
cd example
flutter test

# Run specific test
flutter test test/src/domain/validators/common_validators_test.dart

# Run with coverage
flutter test --coverage
```

## Fail-Fast Behavior

All validators demonstrate fail-fast behavior where validation stops at the first failure:

```dart
// Example: Multiple validators
MyUseCase() {
  addValidator(_validator1);  // Checked first
  addValidator(_validator2);  // Only if validator1 passes
  addValidator(_validator3);  // Only if validator2 passes
}
```

### Test Example
The tests explicitly verify fail-fast behavior:

```dart
test('stops at first failure', () {
  final config = CounterConfig(
    step: -1,         // Invalid - fails here
    minValue: 10,     // Also invalid
    maxValue: 5,      // Also invalid
    initialValue: 15, // Also invalid
  );
  
  final result = useCase(config);
  
  // Should only fail on step validation
  expect(result.left.toString(), contains('Step must be positive'));
  // Should NOT contain errors from other validators
  expect(result.left.toString(), isNot(contains('min')));
});
```

## Best Practices Shown

1. **Order matters** - Cheap checks first (null, range), expensive last
2. **Single responsibility** - Each validator checks one thing
3. **Clear error messages** - Include context and actual values
4. **Reusability** - Create validator libraries
5. **Immutability** - Validators don't modify input

## Integration with Use Cases

Updated existing use cases to demonstrate validation:

- **`IncrementUseCase`** - Shows stateful validator pattern
- **`DecrementUseCase`** - Shows validation in business logic (alternative pattern)

## Additional Resources

- [Validation Guide](../VALIDATION_GUIDE.md) - Complete validation documentation
- [Error Handling Guide](../ERROR_HANDLING_GUIDE.md) - Using Either for errors
- [Use Case Source](../../lib/src/domain/use_case.dart) - Core implementation
