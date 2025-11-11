# JIntent Input Validation Guide

**Version:** 1.0  
**Status:** Active  
**Last Updated:** 2025-10-15  
**Applies To:** JIntent 2.1.0+

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Core Concepts](#2-core-concepts)
3. [UseCaseInputValidator Pattern](#3-usecaseinputvalidator-pattern)
4. [Validation Patterns](#4-validation-patterns)
5. [Fail-Fast Validation Chain](#5-fail-fast-validation-chain)
6. [Common Validators](#6-common-validators)
7. [Best Practices](#7-best-practices)
8. [Testing Validators](#8-testing-validators)
9. [Examples](#9-examples)

---

## 1. Introduction

### 1.1 Purpose

This guide provides comprehensive guidance on input validation patterns for JIntent use cases. Input validation ensures that business logic receives valid data and fails fast when preconditions are not met.

### 1.2 Goals

- **Early Failure Detection:** Catch invalid inputs before executing business logic
- **Type Safety:** Leverage Dart's type system with Either monad
- **Composability:** Chain multiple validators together
- **Reusability:** Create reusable validation functions
- **Clear Error Messages:** Provide helpful feedback when validation fails

### 1.3 When to Use Validators

Use `UseCaseInputValidator` when you need to:

- Enforce preconditions on use case inputs
- Validate business rules before execution
- Check data constraints (ranges, formats, nullability)
- Prevent invalid state transitions
- Provide early feedback to users

---

## 2. Core Concepts

### 2.1 UseCaseInputValidator Type

```dart
typedef UseCaseInputValidator<I> = Either<Exception, I> Function(I input);
```

A validator is a function that:
- Takes an input of type `I`
- Returns `Left(Exception)` if validation fails
- Returns `Right(I)` if validation passes

### 2.2 Either Monad

JIntent uses the `Either` type for functional error handling:

```dart
// Success case
return Right(input);

// Failure case
return Left(Exception('Validation failed: input is invalid'));
```

### 2.3 Validator Execution Order

Validators are executed in the order they are added:

1. First validator is checked
2. If it fails (returns `Left`), execution stops and error is returned
3. If it passes (returns `Right`), next validator is checked
4. This continues until all validators pass or one fails

This is called **fail-fast** behavior.

---

## 3. UseCaseInputValidator Pattern

### 3.1 Basic Structure

```dart
class MyUseCase extends JUseCase<MyInput, MyOutput> {
  MyUseCase() {
    // Add validators in constructor
    addValidator(_validateNotNull);
    addValidator(_validateRange);
  }

  @override
  Future<Either<Exception, MyOutput>> run(MyInput input) async {
    // Business logic here - input is guaranteed to be valid
    return Right(result);
  }
}
```

### 3.2 Adding Validators

There are two ways to add validators:

**Inline Lambda:**
```dart
addValidator((input) {
  if (input.value < 0) {
    return Left(Exception('Value must be non-negative'));
  }
  return Right(input);
});
```

**Named Function:**
```dart
Either<Exception, MyInput> _validatePositive(MyInput input) {
  if (input.value < 0) {
    return Left(Exception('Value must be positive'));
  }
  return Right(input);
}

// In constructor:
addValidator(_validatePositive);
```

### 3.3 Validator Chaining

Multiple validators create a validation chain:

```dart
MyUseCase() {
  addValidator(_validateNotNull);      // 1st: Check null
  addValidator(_validateRange);        // 2nd: Check range
  addValidator(_validateBusinessRule); // 3rd: Check business rule
}
```

Each validator only executes if the previous one passed.

---

## 4. Validation Patterns

### 4.1 Null/Empty Checks

**Single Value:**
```dart
Either<Exception, String> _validateNotEmpty(String input) {
  if (input.trim().isEmpty) {
    return Left(Exception('Input cannot be empty'));
  }
  return Right(input);
}
```

**Object Field:**
```dart
Either<Exception, UserInput> _validateUsername(UserInput input) {
  if (input.username == null || input.username!.isEmpty) {
    return Left(Exception('Username is required'));
  }
  return Right(input);
}
```

### 4.2 Range Validation

**Numeric Range:**
```dart
Either<Exception, int> _validateRange(int input) {
  if (input < 0 || input > 100) {
    return Left(Exception('Value must be between 0 and 100'));
  }
  return Right(input);
}
```

**Length Range:**
```dart
Either<Exception, String> _validateLength(String input) {
  if (input.length < 3 || input.length > 50) {
    return Left(Exception('Length must be between 3 and 50 characters'));
  }
  return Right(input);
}
```

### 4.3 Format Validation

**Email Format:**
```dart
Either<Exception, String> _validateEmail(String input) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(input)) {
    return Left(Exception('Invalid email format'));
  }
  return Right(input);
}
```

**Phone Format:**
```dart
Either<Exception, String> _validatePhone(String input) {
  final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  if (!phoneRegex.hasMatch(input)) {
    return Left(Exception('Invalid phone format'));
  }
  return Right(input);
}
```

### 4.4 Business Rule Validation

**State Transition:**
```dart
Either<Exception, OrderInput> _validateStateTransition(OrderInput input) {
  if (input.currentState == OrderState.cancelled && 
      input.newState == OrderState.shipped) {
    return Left(Exception('Cannot ship a cancelled order'));
  }
  return Right(input);
}
```

**Access Control:**
```dart
Either<Exception, DeleteInput> _validatePermissions(DeleteInput input) {
  if (!input.user.isAdmin && input.item.ownerId != input.user.id) {
    return Left(Exception('Insufficient permissions to delete item'));
  }
  return Right(input);
}
```

### 4.5 Cross-Field Validation

```dart
Either<Exception, DateRangeInput> _validateDateRange(DateRangeInput input) {
  if (input.endDate.isBefore(input.startDate)) {
    return Left(Exception('End date must be after start date'));
  }
  return Right(input);
}
```

---

## 5. Fail-Fast Validation Chain

### 5.1 How It Works

The fail-fast pattern stops validation at the first failure:

```dart
class CreateUserUseCase extends JUseCase<UserInput, User> {
  CreateUserUseCase() {
    addValidator(_validateNotNull);        // Fails here if null -> stops
    addValidator(_validateEmailFormat);    // Never runs if previous failed
    addValidator(_validatePasswordStrength); // Never runs if previous failed
  }

  @override
  Future<Either<Exception, User>> run(UserInput input) async {
    // Only reached if ALL validators passed
    return Right(User(/* ... */));
  }
}
```

### 5.2 Benefits

1. **Performance:** Stops at first error, no unnecessary checks
2. **Clear Feedback:** Returns first validation error encountered
3. **Order Matters:** Check cheap validations first (null checks), expensive ones last (database lookups)

### 5.3 Ordering Strategy

```dart
MyUseCase() {
  // 1. Cheap, essential checks first
  addValidator(_validateNotNull);
  addValidator(_validateType);
  
  // 2. Format/structure checks
  addValidator(_validateFormat);
  addValidator(_validateLength);
  
  // 3. Business rule checks
  addValidator(_validateBusinessConstraints);
  
  // 4. Expensive checks last (DB queries, external API)
  addValidator(_validateUniqueness);
}
```

---

## 6. Common Validators

### 6.1 Reusable Validators

Create a validators library for common patterns:

```dart
class Validators {
  static Either<Exception, String> notEmpty(String input) {
    if (input.trim().isEmpty) {
      return Left(Exception('Value cannot be empty'));
    }
    return Right(input);
  }

  static Either<Exception, int> inRange(int input, int min, int max) {
    if (input < min || input > max) {
      return Left(Exception('Value must be between $min and $max'));
    }
    return Right(input);
  }

  static Either<Exception, T> notNull<T>(T? input) {
    if (input == null) {
      return Left(Exception('Value cannot be null'));
    }
    return Right(input);
  }
}
```

### 6.2 Using JValidationUtils

JIntent provides `JValidationUtils` for type conversions with defaults:

```dart
// Safe parsing with defaults
final count = JValidationUtils.intOrDefault(userInput, defaultValue: 0);
final amount = JValidationUtils.doubleOrDefault(price, defaultValue: 0.0);
final name = JValidationUtils.stringOrDefault(userName, defaultValue: '');

// Range validation
final age = JValidationUtils.parseIntInRange(
  ageInput,
  min: 0,
  max: 120,
  defaultValue: 0,
);

// Length validation
final isValid = JValidationUtils.isTextLengthInRange(
  input,
  min: 1,
  max: 255,
);
```

**Note:** `JValidationUtils` provides fallback values rather than failing. For strict validation, use `UseCaseInputValidator` with `Either` returns.

### 6.3 Higher-Order Validators

Create validators that return validators:

```dart
UseCaseInputValidator<int> rangeValidator(int min, int max) {
  return (input) {
    if (input < min || input > max) {
      return Left(Exception('Value must be between $min and $max'));
    }
    return Right(input);
  };
}

// Usage:
addValidator(rangeValidator(0, 100));
addValidator(rangeValidator(18, 65));
```

---

## 7. Best Practices

### 7.1 Validation Principles

1. **Single Responsibility:** Each validator checks one thing
2. **Order Matters:** Cheap checks first, expensive checks last
3. **Clear Messages:** Provide actionable error messages
4. **Immutability:** Don't modify input in validators
5. **Deterministic:** Same input should always produce same result

### 7.2 Error Messages

**Good Error Messages:**
```dart
// ✅ Specific and actionable
return Left(Exception('Email format is invalid. Expected: user@domain.com'));

// ✅ Includes context
return Left(Exception('Age must be between 18 and 65, got: $input'));

// ✅ Suggests solution
return Left(Exception('Password must contain at least one uppercase letter'));
```

**Poor Error Messages:**
```dart
// ❌ Too generic
return Left(Exception('Invalid input'));

// ❌ No context
return Left(Exception('Error'));

// ❌ Technical jargon for user-facing errors
return Left(Exception('RegEx pattern match failed on field username'));
```

### 7.3 When NOT to Use Validators

Don't use validators for:

- **Data transformations:** Use mappers instead
- **Side effects:** Use the use case `run` method
- **Asynchronous checks:** Use validators for sync checks only; async checks go in `run`
- **Optional validations:** Validators are always enforced

### 7.4 Combining with Business Logic

```dart
class TransferMoneyUseCase extends JUseCase<TransferInput, TransferResult> {
  TransferMoneyUseCase() {
    // Validators check preconditions
    addValidator(_validateAmount);
    addValidator(_validateAccounts);
  }

  @override
  Future<Either<Exception, TransferResult>> run(TransferInput input) async {
    // Business logic with validated input
    // Can still fail for other reasons (insufficient funds, etc.)
    final balance = await _repository.getBalance(input.fromAccount);
    
    if (balance < input.amount) {
      return Left(Exception('Insufficient funds'));
    }
    
    // Perform transfer...
    return Right(result);
  }
}
```

---

## 8. Testing Validators

### 8.1 Testing Individual Validators

```dart
void main() {
  group('Range Validator', () {
    test('accepts valid range', () {
      final validator = rangeValidator(0, 100);
      final result = validator(50);
      
      expect(result.isRight, true);
      expect(result.right, 50);
    });

    test('rejects value below range', () {
      final validator = rangeValidator(0, 100);
      final result = validator(-1);
      
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('between 0 and 100'));
    });
  });
}
```

### 8.2 Testing Use Case Validators

```dart
void main() {
  group('CreateUserUseCase validation', () {
    late CreateUserUseCase useCase;

    setUp(() {
      useCase = CreateUserUseCase();
    });

    test('rejects empty email', () async {
      final input = UserInput(email: '', password: 'valid123');
      final result = await useCase.call(input);
      
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('email'));
    });

    test('rejects invalid email format', () async {
      final input = UserInput(email: 'notanemail', password: 'valid123');
      final result = await useCase.call(input);
      
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('email format'));
    });

    test('accepts valid input', () async {
      final input = UserInput(email: 'user@example.com', password: 'valid123');
      final result = await useCase.call(input);
      
      expect(result.isRight, true);
    });
  });
}
```

### 8.3 Testing Fail-Fast Behavior

```dart
test('stops at first validation error', () async {
  final useCase = CreateUserUseCase();
  
  // Email is invalid, so password validator should not be checked
  final input = UserInput(email: '', password: 'short');
  final result = await useCase.call(input);
  
  expect(result.isLeft, true);
  // Should fail on email, not password
  expect(result.left.toString(), contains('email'));
  expect(result.left.toString(), isNot(contains('password')));
});
```

---

## 9. Examples

### 9.1 Simple Counter Validator

```dart
class IncrementUseCase extends JSyncUseCase<int, int> {
  IncrementUseCase() {
    addValidator((input) {
      if (input >= 10) {
        return Left(Exception('Counter cannot exceed 10'));
      }
      return Right(input);
    });
  }

  @override
  Either<Exception, int> run(int currentValue) {
    return Right(currentValue + 1);
  }
}
```

### 9.2 Complex Multi-Field Validator

```dart
class CreateOrderInput {
  final String customerId;
  final List<OrderItem> items;
  final double totalAmount;

  CreateOrderInput({
    required this.customerId,
    required this.items,
    required this.totalAmount,
  });
}

class CreateOrderUseCase extends JUseCase<CreateOrderInput, Order> {
  CreateOrderUseCase() {
    addValidator(_validateCustomerId);
    addValidator(_validateItems);
    addValidator(_validateAmount);
    addValidator(_validateTotalMatchesItems);
  }

  Either<Exception, CreateOrderInput> _validateCustomerId(CreateOrderInput input) {
    if (input.customerId.isEmpty) {
      return Left(Exception('Customer ID is required'));
    }
    return Right(input);
  }

  Either<Exception, CreateOrderInput> _validateItems(CreateOrderInput input) {
    if (input.items.isEmpty) {
      return Left(Exception('Order must contain at least one item'));
    }
    if (input.items.length > 100) {
      return Left(Exception('Order cannot contain more than 100 items'));
    }
    return Right(input);
  }

  Either<Exception, CreateOrderInput> _validateAmount(CreateOrderInput input) {
    if (input.totalAmount <= 0) {
      return Left(Exception('Total amount must be positive'));
    }
    return Right(input);
  }

  Either<Exception, CreateOrderInput> _validateTotalMatchesItems(CreateOrderInput input) {
    final calculatedTotal = input.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    
    if ((calculatedTotal - input.totalAmount).abs() > 0.01) {
      return Left(Exception('Total amount does not match sum of items'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, Order>> run(CreateOrderInput input) async {
    // Business logic with validated input
    return Right(Order(/* ... */));
  }
}
```

### 9.3 Reusable Validator Library

```dart
// lib/src/validators/common_validators.dart

import 'package:jintent/jintent.dart';

class CommonValidators {
  /// Validates that a string is not empty
  static Either<Exception, String> notEmpty(String input) {
    if (input.trim().isEmpty) {
      return Left(Exception('Value cannot be empty'));
    }
    return Right(input);
  }

  /// Validates that a value is within a range
  static Either<Exception, int> inRange(int input, int min, int max) {
    if (input < min || input > max) {
      return Left(Exception('Value must be between $min and $max'));
    }
    return Right(input);
  }

  /// Validates email format
  static Either<Exception, String> isEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(input)) {
      return Left(Exception('Invalid email format'));
    }
    return Right(input);
  }

  /// Validates that a list is not empty
  static Either<Exception, List<T>> listNotEmpty<T>(List<T> input) {
    if (input.isEmpty) {
      return Left(Exception('List cannot be empty'));
    }
    return Right(input);
  }

  /// Validates minimum string length
  static Either<Exception, String> minLength(String input, int min) {
    if (input.length < min) {
      return Left(Exception('Minimum length is $min characters'));
    }
    return Right(input);
  }

  /// Validates maximum string length
  static Either<Exception, String> maxLength(String input, int max) {
    if (input.length > max) {
      return Left(Exception('Maximum length is $max characters'));
    }
    return Right(input);
  }
}

// Usage in use case:
class RegisterUserUseCase extends JUseCase<UserInput, User> {
  RegisterUserUseCase() {
    addValidator((input) => CommonValidators.notEmpty(input.email));
    addValidator((input) => CommonValidators.isEmail(input.email));
    addValidator((input) => CommonValidators.minLength(input.password, 8));
  }

  @override
  Future<Either<Exception, User>> run(UserInput input) async {
    // Create user with validated input
    return Right(User(/* ... */));
  }
}
```

---

## Summary

Input validation with `UseCaseInputValidator` provides:

- **Type-safe validation** using the Either monad
- **Fail-fast behavior** that stops at the first error
- **Composable validators** that can be chained together
- **Reusable validation logic** across multiple use cases
- **Clear separation** between validation and business logic

Use validators to enforce preconditions and business rules, ensuring your use cases only execute with valid, well-formed input.

For more information, see:
- [Use Case Documentation](../lib/src/domain/use_case.dart)
- [Either Pattern Guide](ERROR_HANDLING_GUIDE.md#3-either-pattern)
- [JValidationUtils](../lib/src/utils/validation_utils.dart)
