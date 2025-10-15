# Input Validation Guide

**Version:** 1.0  
**Status:** Active  
**Last Updated:** 2025-10-15  
**Applies To:** JIntent 2.1.0+

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [UseCaseInputValidator Overview](#2-usecaseinputvalidator-overview)
3. [Basic Validation Patterns](#3-basic-validation-patterns)
4. [Fail-Fast Validation Chains](#4-fail-fast-validation-chains)
5. [Common Validation Scenarios](#5-common-validation-scenarios)
6. [Composable Validators](#6-composable-validators)
7. [Best Practices](#7-best-practices)
8. [Testing Validators](#8-testing-validators)
9. [Examples](#9-examples)

---

## 1. Introduction

### 1.1 Purpose

This guide provides comprehensive guidance on input validation patterns using JIntent's `UseCaseInputValidator`. Input validation is crucial for ensuring data integrity, enforcing business rules, and providing clear error messages before use case execution.

### 1.2 Goals

- **Early Failure:** Catch invalid inputs before executing business logic
- **Type Safety:** Leverage Dart's type system with Either monad
- **Composability:** Build complex validators from simple ones
- **Testability:** Easy to test validation logic in isolation
- **Clear Errors:** Provide meaningful error messages to users

### 1.3 When to Use Input Validation

Use `UseCaseInputValidator` when you need to:
- Validate preconditions before executing use case logic
- Enforce business constraints on input data
- Sanitize or normalize input data
- Provide fail-fast behavior for invalid inputs
- Chain multiple validation rules

---

## 2. UseCaseInputValidator Overview

### 2.1 Type Definition

```dart
typedef UseCaseInputValidator<I> = Either<Exception, I> Function(I input);
```

A `UseCaseInputValidator` is a function that:
- Takes an input of type `I`
- Returns `Either<Exception, I>`:
  - `Left(Exception)` if validation fails
  - `Right(I)` if validation succeeds

### 2.2 How It Works

Validators are added to use cases and executed in order before the `run` method:

```dart
class MyUseCase extends JUseCase<String, Result> {
  MyUseCase() {
    // Validators are executed in the order they are added
    addValidator(notEmptyValidator);
    addValidator(lengthValidator);
    addValidator(formatValidator);
  }

  @override
  Future<Either<Exception, Result>> run(String input) async {
    // This only executes if all validators pass
    return Right(Result(input));
  }
}
```

### 2.3 Fail-Fast Behavior

Validation follows a **fail-fast** approach:
1. Validators are executed sequentially in the order they were added
2. If any validator returns `Left(Exception)`, validation stops immediately
3. The exception is returned to the caller without executing subsequent validators
4. The use case's `run` method is never called

---

## 3. Basic Validation Patterns

### 3.1 Simple Null Check

```dart
UseCaseInputValidator<String?> notNullValidator = (input) {
  if (input == null) {
    return Left(Exception('Input cannot be null'));
  }
  return Right(input);
};
```

### 3.2 Range Validation

```dart
UseCaseInputValidator<int> positiveNumberValidator = (input) {
  if (input <= 0) {
    return Left(Exception('Input must be positive'));
  }
  return Right(input);
};

UseCaseInputValidator<int> rangeValidator(int min, int max) {
  return (input) {
    if (input < min || input > max) {
      return Left(Exception('Input must be between $min and $max'));
    }
    return Right(input);
  };
}
```

### 3.3 String Validation

```dart
UseCaseInputValidator<String> notEmptyValidator = (input) {
  if (input.isEmpty) {
    return Left(Exception('Input cannot be empty'));
  }
  return Right(input);
};

UseCaseInputValidator<String> minLengthValidator(int minLength) {
  return (input) {
    if (input.length < minLength) {
      return Left(Exception('Input must be at least $minLength characters'));
    }
    return Right(input);
  };
}

UseCaseInputValidator<String> maxLengthValidator(int maxLength) {
  return (input) {
    if (input.length > maxLength) {
      return Left(Exception('Input must be at most $maxLength characters'));
    }
    return Right(input);
  };
}
```

### 3.4 Format Validation

```dart
UseCaseInputValidator<String> emailValidator = (input) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(input)) {
    return Left(Exception('Invalid email format'));
  }
  return Right(input);
};

UseCaseInputValidator<String> phoneValidator = (input) {
  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
  if (!phoneRegex.hasMatch(input)) {
    return Left(Exception('Invalid phone number format'));
  }
  return Right(input);
};
```

---

## 4. Fail-Fast Validation Chains

### 4.1 Sequential Validation

Validators are executed in order, and validation stops at the first failure:

```dart
class CreateUserUseCase extends JUseCase<UserInput, User> {
  CreateUserUseCase() {
    // First, check if input is not null
    addValidator(_notNullValidator);
    
    // Then, validate email format (only if not null)
    addValidator(_emailFormatValidator);
    
    // Finally, check email length (only if format is valid)
    addValidator(_emailLengthValidator);
  }

  UseCaseInputValidator<UserInput> _notNullValidator = (input) {
    if (input.email == null) {
      return Left(Exception('Email is required'));
    }
    return Right(input);
  };

  UseCaseInputValidator<UserInput> _emailFormatValidator = (input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(input.email!)) {
      return Left(Exception('Invalid email format'));
    }
    return Right(input);
  };

  UseCaseInputValidator<UserInput> _emailLengthValidator = (input) {
    if (input.email!.length > 100) {
      return Left(Exception('Email too long (max 100 characters)'));
    }
    return Right(input);
  };

  @override
  Future<Either<Exception, User>> run(UserInput input) async {
    // All validators passed, create the user
    return Right(User(email: input.email!));
  }
}
```

### 4.2 Benefits of Fail-Fast

- **Performance:** Stop validation as soon as one rule fails
- **Clear Errors:** Users get the first validation error, not multiple
- **Logical Flow:** Validate basic requirements before complex ones
- **Resource Efficiency:** Avoid expensive validations if basic checks fail

---

## 5. Common Validation Scenarios

### 5.1 Business Rule Validation

```dart
class TransferMoneyUseCase extends JUseCase<TransferInput, Transaction> {
  TransferMoneyUseCase() {
    addValidator(_validateAmount);
    addValidator(_validateAccounts);
    addValidator(_validateBalance);
  }

  UseCaseInputValidator<TransferInput> _validateAmount = (input) {
    if (input.amount <= 0) {
      return Left(Exception('Transfer amount must be positive'));
    }
    if (input.amount > 10000) {
      return Left(Exception('Transfer amount exceeds daily limit'));
    }
    return Right(input);
  };

  UseCaseInputValidator<TransferInput> _validateAccounts = (input) {
    if (input.fromAccount == input.toAccount) {
      return Left(Exception('Cannot transfer to the same account'));
    }
    return Right(input);
  };

  UseCaseInputValidator<TransferInput> _validateBalance = (input) {
    // This is a simplified example - in reality, you'd check actual balance
    if (input.fromAccountBalance < input.amount) {
      return Left(Exception('Insufficient balance'));
    }
    return Right(input);
  };

  @override
  Future<Either<Exception, Transaction>> run(TransferInput input) async {
    // Execute transfer
    return Right(Transaction(/* ... */));
  }
}
```

### 5.2 Authorization Checks

```dart
class DeletePostUseCase extends JUseCase<DeletePostInput, void> {
  DeletePostUseCase() {
    addValidator(_validateOwnership);
    addValidator(_validateNotDeleted);
  }

  UseCaseInputValidator<DeletePostInput> _validateOwnership = (input) {
    if (input.post.authorId != input.currentUserId) {
      return Left(Exception('You can only delete your own posts'));
    }
    return Right(input);
  };

  UseCaseInputValidator<DeletePostInput> _validateNotDeleted = (input) {
    if (input.post.isDeleted) {
      return Left(Exception('Post is already deleted'));
    }
    return Right(input);
  };

  @override
  Future<Either<Exception, void>> run(DeletePostInput input) async {
    // Delete the post
    return Right(null);
  }
}
```

### 5.3 Complex Object Validation

```dart
class RegisterUserInput {
  final String email;
  final String password;
  final String username;
  final DateTime? birthDate;

  RegisterUserInput({
    required this.email,
    required this.password,
    required this.username,
    this.birthDate,
  });
}

class RegisterUserUseCase extends JUseCase<RegisterUserInput, User> {
  RegisterUserUseCase() {
    addValidator(_validateEmail);
    addValidator(_validatePassword);
    addValidator(_validateUsername);
    addValidator(_validateAge);
  }

  UseCaseInputValidator<RegisterUserInput> _validateEmail = (input) {
    if (input.email.isEmpty) {
      return Left(Exception('Email is required'));
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(input.email)) {
      return Left(Exception('Invalid email format'));
    }
    return Right(input);
  };

  UseCaseInputValidator<RegisterUserInput> _validatePassword = (input) {
    if (input.password.length < 8) {
      return Left(Exception('Password must be at least 8 characters'));
    }
    if (!RegExp(r'[A-Z]').hasMatch(input.password)) {
      return Left(Exception('Password must contain at least one uppercase letter'));
    }
    if (!RegExp(r'[0-9]').hasMatch(input.password)) {
      return Left(Exception('Password must contain at least one number'));
    }
    return Right(input);
  };

  UseCaseInputValidator<RegisterUserInput> _validateUsername = (input) {
    if (input.username.length < 3) {
      return Left(Exception('Username must be at least 3 characters'));
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(input.username)) {
      return Left(Exception('Username can only contain letters, numbers, and underscores'));
    }
    return Right(input);
  };

  UseCaseInputValidator<RegisterUserInput> _validateAge = (input) {
    if (input.birthDate == null) {
      return Right(input); // Optional field
    }
    final age = DateTime.now().difference(input.birthDate!).inDays ~/ 365;
    if (age < 13) {
      return Left(Exception('You must be at least 13 years old to register'));
    }
    return Right(input);
  };

  @override
  Future<Either<Exception, User>> run(RegisterUserInput input) async {
    // Register the user
    return Right(User(/* ... */));
  }
}
```

---

## 6. Composable Validators

### 6.1 Validator Factory Functions

Create reusable validators with factory functions:

```dart
// Generic validators that can be reused
class Validators {
  static UseCaseInputValidator<String> notEmpty(String fieldName) {
    return (input) {
      if (input.isEmpty) {
        return Left(Exception('$fieldName cannot be empty'));
      }
      return Right(input);
    };
  }

  static UseCaseInputValidator<String> minLength(int min, String fieldName) {
    return (input) {
      if (input.length < min) {
        return Left(Exception('$fieldName must be at least $min characters'));
      }
      return Right(input);
    };
  }

  static UseCaseInputValidator<String> maxLength(int max, String fieldName) {
    return (input) {
      if (input.length > max) {
        return Left(Exception('$fieldName must be at most $max characters'));
      }
      return Right(input);
    };
  }

  static UseCaseInputValidator<int> inRange(int min, int max, String fieldName) {
    return (input) {
      if (input < min || input > max) {
        return Left(Exception('$fieldName must be between $min and $max'));
      }
      return Right(input);
    };
  }

  static UseCaseInputValidator<T> required<T>(T? input, String fieldName) {
    return (_) {
      if (input == null) {
        return Left(Exception('$fieldName is required'));
      }
      return Right(input as T);
    };
  }
}
```

### 6.2 Field-Specific Validators

Extract validation logic into separate validator classes:

```dart
class EmailValidators {
  static UseCaseInputValidator<String> format = (input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(input)) {
      return Left(Exception('Invalid email format'));
    }
    return Right(input);
  };

  static UseCaseInputValidator<String> length = (input) {
    if (input.length > 100) {
      return Left(Exception('Email is too long (max 100 characters)'));
    }
    return Right(input);
  };

  static UseCaseInputValidator<String> notDisposable = (input) {
    final disposableDomains = ['tempmail.com', 'throwaway.email'];
    final domain = input.split('@').last;
    if (disposableDomains.contains(domain)) {
      return Left(Exception('Disposable email addresses are not allowed'));
    }
    return Right(input);
  };
}

class PasswordValidators {
  static UseCaseInputValidator<String> minLength(int min) {
    return (input) {
      if (input.length < min) {
        return Left(Exception('Password must be at least $min characters'));
      }
      return Right(input);
    };
  }

  static UseCaseInputValidator<String> hasUppercase = (input) {
    if (!RegExp(r'[A-Z]').hasMatch(input)) {
      return Left(Exception('Password must contain at least one uppercase letter'));
    }
    return Right(input);
  };

  static UseCaseInputValidator<String> hasLowercase = (input) {
    if (!RegExp(r'[a-z]').hasMatch(input)) {
      return Left(Exception('Password must contain at least one lowercase letter'));
    }
    return Right(input);
  };

  static UseCaseInputValidator<String> hasNumber = (input) {
    if (!RegExp(r'[0-9]').hasMatch(input)) {
      return Left(Exception('Password must contain at least one number'));
    }
    return Right(input);
  };

  static UseCaseInputValidator<String> hasSpecialChar = (input) {
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(input)) {
      return Left(Exception('Password must contain at least one special character'));
    }
    return Right(input);
  };
}
```

### 6.3 Using Composable Validators

```dart
class LoginUseCase extends JUseCase<LoginInput, Session> {
  LoginUseCase() {
    // Use pre-built validators
    addValidator((input) => EmailValidators.format(input.email));
    addValidator((input) => PasswordValidators.minLength(8)(input.password));
  }

  @override
  Future<Either<Exception, Session>> run(LoginInput input) async {
    // Login logic
    return Right(Session(/* ... */));
  }
}
```

---

## 7. Best Practices

### 7.1 Validator Design

**DO:**
- ✅ Keep validators simple and focused on one concern
- ✅ Order validators from simple to complex (fail-fast optimization)
- ✅ Provide clear, actionable error messages
- ✅ Use factory functions for reusable validators
- ✅ Test validators independently

**DON'T:**
- ❌ Don't perform business logic in validators (use the `run` method)
- ❌ Don't make external API calls in validators
- ❌ Don't modify the input in validators (validators should be pure)
- ❌ Don't catch exceptions in validators (let them propagate)
- ❌ Don't create overly complex validators

### 7.2 Error Messages

**Good Error Messages:**
```dart
// ✅ Specific and actionable
'Email must be between 5 and 100 characters'
'Password must contain at least one uppercase letter'
'Transfer amount exceeds daily limit of $10,000'

// ❌ Vague or unhelpful
'Invalid input'
'Validation failed'
'Error'
```

### 7.3 Performance Considerations

- Order validators by execution cost (cheap checks first)
- Avoid expensive operations (database queries, API calls)
- Cache compiled regex patterns when possible
- Use early returns to avoid unnecessary checks

```dart
class OptimizedUseCase extends JUseCase<Input, Output> {
  // ✅ Cache regex patterns
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  OptimizedUseCase() {
    // ✅ Order by cost: cheap checks first
    addValidator(_checkNotEmpty);      // Cheap: O(1)
    addValidator(_checkLength);        // Cheap: O(1)
    addValidator(_checkFormat);        // Medium: O(n)
  }

  UseCaseInputValidator<Input> _checkNotEmpty = (input) {
    if (input.value.isEmpty) {
      return Left(Exception('Value cannot be empty'));
    }
    return Right(input);
  };

  UseCaseInputValidator<Input> _checkLength = (input) {
    if (input.value.length > 100) {
      return Left(Exception('Value is too long'));
    }
    return Right(input);
  };

  UseCaseInputValidator<Input> _checkFormat = (input) {
    if (!_emailRegex.hasMatch(input.value)) {
      return Left(Exception('Invalid format'));
    }
    return Right(input);
  };

  @override
  Future<Either<Exception, Output>> run(Input input) async {
    return Right(Output());
  }
}
```

### 7.4 Synchronous vs Asynchronous Use Cases

Validators work the same way for both `JUseCase` (async) and `JSyncUseCase` (sync):

```dart
// Async use case
class AsyncUseCase extends JUseCase<String, Result> {
  AsyncUseCase() {
    addValidator(notEmptyValidator); // Validator is synchronous
  }

  @override
  Future<Either<Exception, Result>> run(String input) async {
    // Async business logic
    return Right(Result());
  }
}

// Sync use case
class SyncUseCase extends JSyncUseCase<String, Result> {
  SyncUseCase() {
    addValidator(notEmptyValidator); // Same validator
  }

  @override
  Either<Exception, Result> run(String input) {
    // Sync business logic
    return Right(Result());
  }
}
```

---

## 8. Testing Validators

### 8.1 Unit Testing Individual Validators

```dart
void main() {
  group('Email Validators', () {
    test('format validator accepts valid email', () {
      final result = EmailValidators.format('test@example.com');
      expect(result.isRight, true);
      expect(result.right, 'test@example.com');
    });

    test('format validator rejects invalid email', () {
      final result = EmailValidators.format('invalid-email');
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('Invalid email format'));
    });

    test('length validator rejects long email', () {
      final longEmail = 'a' * 101 + '@example.com';
      final result = EmailValidators.length(longEmail);
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('too long'));
    });
  });

  group('Password Validators', () {
    test('minLength validator accepts valid password', () {
      final result = PasswordValidators.minLength(8)('password123');
      expect(result.isRight, true);
    });

    test('minLength validator rejects short password', () {
      final result = PasswordValidators.minLength(8)('pass');
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('at least 8 characters'));
    });

    test('hasUppercase validator checks for uppercase', () {
      expect(PasswordValidators.hasUppercase('Password').isRight, true);
      expect(PasswordValidators.hasUppercase('password').isLeft, true);
    });
  });
}
```

### 8.2 Integration Testing Use Case Validation

```dart
void main() {
  group('RegisterUserUseCase', () {
    late RegisterUserUseCase useCase;

    setUp(() {
      useCase = RegisterUserUseCase();
    });

    test('rejects empty email', () async {
      final input = RegisterUserInput(
        email: '',
        password: 'Password123',
        username: 'user123',
      );

      final result = await useCase.call(input);

      expect(result.isLeft, true);
      expect(result.left.toString(), contains('Email is required'));
    });

    test('rejects invalid email format', () async {
      final input = RegisterUserInput(
        email: 'invalid-email',
        password: 'Password123',
        username: 'user123',
      );

      final result = await useCase.call(input);

      expect(result.isLeft, true);
      expect(result.left.toString(), contains('Invalid email format'));
    });

    test('rejects short password', () async {
      final input = RegisterUserInput(
        email: 'test@example.com',
        password: 'Pass1',
        username: 'user123',
      );

      final result = await useCase.call(input);

      expect(result.isLeft, true);
      expect(result.left.toString(), contains('at least 8 characters'));
    });

    test('accepts valid input', () async {
      final input = RegisterUserInput(
        email: 'test@example.com',
        password: 'Password123',
        username: 'user123',
      );

      final result = await useCase.call(input);

      expect(result.isRight, true);
    });

    test('stops at first validation error', () async {
      // Multiple validation errors, but only the first should be returned
      final input = RegisterUserInput(
        email: '', // First error: empty
        password: 'pass', // Would also fail
        username: 'a', // Would also fail
      );

      final result = await useCase.call(input);

      expect(result.isLeft, true);
      expect(result.left.toString(), contains('Email is required'));
      // Password and username errors are not checked
    });
  });
}
```

### 8.3 Testing Fail-Fast Behavior

```dart
void main() {
  group('Fail-Fast Validation', () {
    test('stops at first failure', () async {
      var validator1Called = false;
      var validator2Called = false;
      var validator3Called = false;

      final useCase = TestUseCase()
        ..addValidator((input) {
          validator1Called = true;
          return Right(input); // Pass
        })
        ..addValidator((input) {
          validator2Called = true;
          return Left(Exception('Second validator failed')); // Fail
        })
        ..addValidator((input) {
          validator3Called = true;
          return Right(input); // Should not be called
        });

      final result = await useCase.call('test');

      expect(result.isLeft, true);
      expect(validator1Called, true);
      expect(validator2Called, true);
      expect(validator3Called, false); // Not called due to fail-fast
    });
  });
}
```

---

## 9. Examples

### 9.1 Complete Example: E-commerce Order

See the example app in `example/lib/src/domain/validators/` for complete, runnable examples including:

- **Form validators:** Email, password, phone number validation
- **Business rule validators:** Inventory checks, pricing rules, discount validation
- **Authorization validators:** User permissions, ownership checks
- **Data integrity validators:** Foreign key checks, duplicate detection

### 9.2 Example: Counter with Validation

The example counter app demonstrates a simple validation chain:

```dart
class IncrementUseCase extends JSyncUseCase<int, int> {
  IncrementUseCase() {
    addValidator((input) {
      if (input >= 10) {
        return Left(Exception('Cannot increment: value already at maximum'));
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

### 9.3 See Also

- [Error Handling Guide](ERROR_HANDLING_GUIDE.md) - Comprehensive error handling patterns
- [Data Layer Guide](DATA_LAYER_GUIDE.md) - Data validation and transformation patterns
- [Example App](/example/lib/src/domain/validators/) - Runnable validation examples

---

## Summary

Input validation with `UseCaseInputValidator` provides:
- ✅ **Early error detection** before business logic execution
- ✅ **Fail-fast behavior** for efficient validation
- ✅ **Type-safe error handling** with Either monad
- ✅ **Composable validators** for code reuse
- ✅ **Testable validation logic** independent of use cases

Use validators to enforce preconditions, business rules, and data integrity constraints at the entry point of your use cases, keeping your core business logic clean and focused.
