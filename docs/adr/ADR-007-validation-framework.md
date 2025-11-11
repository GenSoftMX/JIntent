# ADR-007: Validation Framework

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 2 Security & API - Validation Strategy  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines validation framework, patterns, and guidelines for JIntent to ensure data integrity and security through consistent validation practices.

---

## 2. Context

### 2.1 Background

**Current Validation (v2.1.0):**

**Existing:**
- ✅ JUseCase validator chain
- ✅ Type safety via Dart type system
- ⚠️ No built-in validators
- ⚠️ No validation DSL
- ⚠️ Each developer implements custom validation

**Implementation:**
```dart
abstract class JUseCase<INPUT, OUTPUT> {
  final List<Either<Exception, INPUT> Function(INPUT)> _validators = [];
  
  void addValidator(Either<Exception, INPUT> Function(INPUT) validator) {
    _validators.add(validator);
  }
  
  Future<Either<Exception, OUTPUT>> call(INPUT input) async {
    // Run validators
    for (final validator in _validators) {
      final result = validator(input);
      if (result.isLeft) return Left(result.left!);
    }
    return run(input);
  }
}
```

**Gaps:**
- No common validation library
- No standardized validators
- No validation composition
- No validation error aggregation
- No cross-field validation support

### 2.2 Problem Statement

**Current Challenges:**
- Developers reinvent validation logic
- Inconsistent validation patterns
- No reusable validators
- Verbose validation code
- Hard to test validation in isolation

**Business Impact:**
- Invalid data reaches controllers
- Inconsistent UX for validation errors
- Security risk (insufficient input validation)
- Development overhead

---

## 3. Decision

### 3.1 Validation Architecture

**Decision:** Provide lightweight validation framework, not enforce usage

**Approach:**
- Optional validation utilities
- Composable validators
- Either-based results
- Fail-fast by default
- Extensible for custom validators

**Philosophy:**
- JIntent provides building blocks
- Consumers can use any validation library
- Examples show best practices
- Type system is primary validation

### 3.2 Validator Interface

**Decision:** Define standard validator interface

**Implementation:**
```dart
/// A function that validates input and returns Either.
///
/// Returns [Right] with validated input if valid.
/// Returns [Left] with [ValidationFailure] if invalid.
typedef Validator<T> = Either<ValidationFailure, T> Function(T input);

/// Validation failure with structured information.
class ValidationFailure extends Failure {
  final String field;
  final dynamic value;
  final List<String> constraints;
  
  ValidationFailure({
    required String message,
    required this.field,
    this.value,
    this.constraints = const [],
  }) : super(
    code: 'VALIDATION_FAILED',
    message: message,
    context: {
      'field': field,
      'value': value,
      'constraints': constraints,
    },
  );
  
  @override
  String toString() => 'ValidationFailure($field): $message';
}

/// Aggregates multiple validation failures.
class ValidationFailures extends Failure {
  final List<ValidationFailure> failures;
  
  ValidationFailures(this.failures)
      : super(
          code: 'MULTIPLE_VALIDATION_ERRORS',
          message: 'Multiple validation errors occurred',
          context: {
            'failures': failures.map((f) => f.toString()).toList(),
          },
        );
  
  @override
  String toString() => 'ValidationFailures(${failures.length} errors)';
}
```

### 3.3 Common Validators

**Decision:** Provide library of common validators

**String Validators:**
```dart
class StringValidators {
  /// Validates string is not empty.
  static Validator<String> notEmpty({String? message}) {
    return (value) {
      if (value.isEmpty) {
        return Left(ValidationFailure(
          message: message ?? 'Value cannot be empty',
          field: 'value',
          value: value,
          constraints: ['notEmpty'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates minimum length.
  static Validator<String> minLength(int min, {String? message}) {
    return (value) {
      if (value.length < min) {
        return Left(ValidationFailure(
          message: message ?? 'Value must be at least $min characters',
          field: 'value',
          value: value,
          constraints: ['minLength:$min'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates maximum length.
  static Validator<String> maxLength(int max, {String? message}) {
    return (value) {
      if (value.length > max) {
        return Left(ValidationFailure(
          message: message ?? 'Value must be at most $max characters',
          field: 'value',
          value: value,
          constraints: ['maxLength:$max'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates against regular expression.
  static Validator<String> pattern(RegExp regex, {String? message}) {
    return (value) {
      if (!regex.hasMatch(value)) {
        return Left(ValidationFailure(
          message: message ?? 'Value does not match pattern',
          field: 'value',
          value: value,
          constraints: ['pattern:${regex.pattern}'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates email format.
  static Validator<String> email({String? message}) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return (value) {
      if (!emailRegex.hasMatch(value)) {
        return Left(ValidationFailure(
          message: message ?? 'Invalid email format',
          field: 'value',
          value: value,
          constraints: ['email'],
        ));
      }
      return Right(value);
    };
  }
}
```

**Number Validators:**
```dart
class NumberValidators {
  /// Validates number is positive.
  static Validator<num> positive({String? message}) {
    return (value) {
      if (value <= 0) {
        return Left(ValidationFailure(
          message: message ?? 'Value must be positive',
          field: 'value',
          value: value,
          constraints: ['positive'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates minimum value.
  static Validator<num> min(num minimum, {String? message}) {
    return (value) {
      if (value < minimum) {
        return Left(ValidationFailure(
          message: message ?? 'Value must be at least $minimum',
          field: 'value',
          value: value,
          constraints: ['min:$minimum'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates maximum value.
  static Validator<num> max(num maximum, {String? message}) {
    return (value) {
      if (value > maximum) {
        return Left(ValidationFailure(
          message: message ?? 'Value must be at most $maximum',
          field: 'value',
          value: value,
          constraints: ['max:$maximum'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates value is in range.
  static Validator<num> inRange(num min, num max, {String? message}) {
    return (value) {
      if (value < min || value > max) {
        return Left(ValidationFailure(
          message: message ?? 'Value must be between $min and $max',
          field: 'value',
          value: value,
          constraints: ['range:$min-$max'],
        ));
      }
      return Right(value);
    };
  }
}
```

**Collection Validators:**
```dart
class CollectionValidators {
  /// Validates list is not empty.
  static Validator<List<T>> notEmpty<T>({String? message}) {
    return (value) {
      if (value.isEmpty) {
        return Left(ValidationFailure(
          message: message ?? 'List cannot be empty',
          field: 'value',
          value: value,
          constraints: ['notEmpty'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates list size.
  static Validator<List<T>> size<T>(int expected, {String? message}) {
    return (value) {
      if (value.length != expected) {
        return Left(ValidationFailure(
          message: message ?? 'List must have exactly $expected items',
          field: 'value',
          value: value,
          constraints: ['size:$expected'],
        ));
      }
      return Right(value);
    };
  }
  
  /// Validates each element in list.
  static Validator<List<T>> each<T>(Validator<T> elementValidator) {
    return (value) {
      final failures = <ValidationFailure>[];
      
      for (var i = 0; i < value.length; i++) {
        final result = elementValidator(value[i]);
        if (result.isLeft) {
          final failure = result.left! as ValidationFailure;
          failures.add(ValidationFailure(
            message: failure.message,
            field: '[$i].${failure.field}',
            value: failure.value,
            constraints: failure.constraints,
          ));
        }
      }
      
      if (failures.isNotEmpty) {
        return Left(ValidationFailures(failures));
      }
      
      return Right(value);
    };
  }
}
```

### 3.4 Validator Composition

**Decision:** Support composing validators

**Combinators:**
```dart
/// Validator composition utilities.
class Validators {
  /// Combines multiple validators (all must pass).
  static Validator<T> all<T>(List<Validator<T>> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result.isLeft) return result;
      }
      return Right(value);
    };
  }
  
  /// Combines validators (at least one must pass).
  static Validator<T> any<T>(List<Validator<T>> validators) {
    return (value) {
      final failures = <ValidationFailure>[];
      
      for (final validator in validators) {
        final result = validator(value);
        if (result.isRight) return result;
        if (result.left is ValidationFailure) {
          failures.add(result.left as ValidationFailure);
        }
      }
      
      return Left(ValidationFailures(failures));
    };
  }
  
  /// Negates a validator.
  static Validator<T> not<T>(Validator<T> validator, {String? message}) {
    return (value) {
      final result = validator(value);
      if (result.isRight) {
        return Left(ValidationFailure(
          message: message ?? 'Validation should have failed',
          field: 'value',
          value: value,
        ));
      }
      return Right(value);
    };
  }
  
  /// Optional validator (null is valid).
  static Validator<T?> optional<T>(Validator<T> validator) {
    return (value) {
      if (value == null) return Right(null);
      return validator(value);
    };
  }
  
  /// Validates with custom function.
  static Validator<T> custom<T>(
    bool Function(T) test, {
    required String message,
    String? field,
  }) {
    return (value) {
      if (!test(value)) {
        return Left(ValidationFailure(
          message: message,
          field: field ?? 'value',
          value: value,
        ));
      }
      return Right(value);
    };
  }
}
```

### 3.5 Object Validation

**Decision:** Support validating complex objects

**Pattern:**
```dart
/// Validates an object with multiple fields.
class ObjectValidator<T> {
  final Map<String, Validator<dynamic>> _fieldValidators = {};
  
  /// Adds a field validator.
  ObjectValidator<T> field<F>(
    String name,
    F Function(T) getter,
    Validator<F> validator,
  ) {
    _fieldValidators[name] = (value) {
      final fieldValue = getter(value as T);
      final result = validator(fieldValue);
      if (result.isLeft && result.left is ValidationFailure) {
        final failure = result.left as ValidationFailure;
        return Left(ValidationFailure(
          message: failure.message,
          field: name,
          value: fieldValue,
          constraints: failure.constraints,
        ));
      }
      return result;
    };
    return this;
  }
  
  /// Validates the object.
  Either<Failure, T> validate(T value) {
    final failures = <ValidationFailure>[];
    
    for (final entry in _fieldValidators.entries) {
      final result = entry.value(value);
      if (result.isLeft) {
        if (result.left is ValidationFailure) {
          failures.add(result.left as ValidationFailure);
        }
      }
    }
    
    if (failures.isNotEmpty) {
      return Left(ValidationFailures(failures));
    }
    
    return Right(value);
  }
}

// Usage:
class LoginParams {
  final String email;
  final String password;
  
  LoginParams({required this.email, required this.password});
}

final loginValidator = ObjectValidator<LoginParams>()
    .field('email', (p) => p.email, Validators.all([
      StringValidators.notEmpty(),
      StringValidators.email(),
    ]))
    .field('password', (p) => p.password, Validators.all([
      StringValidators.notEmpty(),
      StringValidators.minLength(8),
    ]));

// Validate:
final result = loginValidator.validate(params);
```

### 3.6 Use Case Integration

**Decision:** Integrate validation with JUseCase

**Pattern:**
```dart
class LoginUseCase extends JUseCase<LoginParams, User> {
  final AuthRepository _repository;
  
  LoginUseCase(this._repository) {
    // Add validators to use case
    addValidator((params) {
      return loginValidator.validate(params);
    });
  }
  
  @override
  Future<Either<Failure, User>> run(LoginParams input) async {
    // Validation already done by call()
    return _repository.login(input.email, input.password);
  }
}
```

### 3.7 Validation Guidelines

**Decision:** Document validation best practices

**Guidelines (doc/validation.md):**

**1. Validate Early**
- Validate at boundaries (use cases)
- Fail fast
- Don't pass invalid data to domain

**2. Use Type System**
```dart
// Bad: Primitive obsession
class User {
  final String email;  // Any string
  final int age;       // Any int
}

// Good: Value objects with validation
class Email {
  final String value;
  
  Email._(this.value);
  
  factory Email(String value) {
    final result = StringValidators.email()(value);
    if (result.isLeft) {
      throw ArgumentError('Invalid email');
    }
    return Email._(value);
  }
}

class Age {
  final int value;
  
  Age._(this.value);
  
  factory Age(int value) {
    if (value < 0 || value > 150) {
      throw ArgumentError('Invalid age');
    }
    return Age._(value);
  }
}

class User {
  final Email email;  // Always valid
  final Age age;      // Always valid
}
```

**3. Single Responsibility**
- One validator per rule
- Compose complex validations
- Reuse validators

**4. Meaningful Messages**
```dart
// Bad: Generic message
ValidationFailure(message: 'Invalid', field: 'email', value: email);

// Good: Specific, actionable message
ValidationFailure(
  message: 'Email must be in format: user@example.com',
  field: 'email',
  value: email,
);
```

**5. Test Validation**
```dart
test('email validator rejects invalid email', () {
  final validator = StringValidators.email();
  final result = validator('invalid-email');
  
  expect(result.isLeft, true);
  expect(result.left, isA<ValidationFailure>());
  expect((result.left as ValidationFailure).field, 'value');
});
```

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Consistency**
- Standard validation patterns
- Reusable validators
- Predictable behavior

✅ **Maintainability**
- DRY (Don't Repeat Yourself)
- Easy to test
- Clear validation logic

✅ **Security**
- Input validation at boundaries
- Type-safe validation
- Clear constraints

✅ **Developer Experience**
- Less boilerplate
- Composable validators
- Good error messages

### 4.2 Negative Consequences

⚠️ **Library Size**
- More code to maintain
- More API surface
- Documentation overhead

⚠️ **Not Comprehensive**
- Can't cover all use cases
- Some apps need custom validators
- May conflict with other validation libs

⚠️ **Learning Curve**
- New API to learn
- Functional composition
- Either monad

### 4.3 Mitigation Strategies

**For Library Size:**
- Keep validators simple
- Only common validators
- Allow custom validators

**For Comprehensiveness:**
- Document extension points
- Show custom validator examples
- Optional, not required

**For Learning Curve:**
- Comprehensive examples
- Migration from simple validation
- Video tutorials (future)

---

## 5. Implementation Plan

### Phase 1: Foundation (Week 1-2)
- [x] Create ADR-007
- [ ] Implement ValidationFailure
- [ ] Create basic validators (String, Number)
- [ ] Add to library exports

### Phase 2: Enhancement (Week 3-4)
- [ ] Collection validators
- [ ] Object validator
- [ ] Composition utilities
- [ ] Integration examples

### Phase 3: Documentation (Week 5+)
- [ ] Validation guide (doc/validation.md)
- [ ] Migration examples
- [ ] Best practices
- [ ] Video tutorial (future)

---

## 6. Examples

See code examples in sections 3.2-3.6 above.

**Complete Example:**
```dart
// 1. Define params
class RegisterParams {
  final String email;
  final String password;
  final int age;
  
  RegisterParams({
    required this.email,
    required this.password,
    required this.age,
  });
}

// 2. Create validator
final registerValidator = ObjectValidator<RegisterParams>()
    .field('email', (p) => p.email, Validators.all([
      StringValidators.notEmpty(message: 'Email is required'),
      StringValidators.email(message: 'Invalid email format'),
    ]))
    .field('password', (p) => p.password, Validators.all([
      StringValidators.notEmpty(message: 'Password is required'),
      StringValidators.minLength(8, message: 'Password must be at least 8 characters'),
      StringValidators.pattern(
        RegExp(r'[A-Z]'),
        message: 'Password must contain uppercase letter',
      ),
    ]))
    .field('age', (p) => p.age, Validators.all([
      NumberValidators.positive(message: 'Age must be positive'),
      NumberValidators.inRange(13, 120, message: 'Age must be between 13 and 120'),
    ]));

// 3. Use in use case
class RegisterUseCase extends JUseCase<RegisterParams, User> {
  final AuthRepository _repository;
  
  RegisterUseCase(this._repository) {
    addValidator((params) => registerValidator.validate(params));
  }
  
  @override
  Future<Either<Failure, User>> run(RegisterParams input) async {
    return _repository.register(input.email, input.password, input.age);
  }
}

// 4. Use in controller
class RegisterController extends JController<RegisterState, JIntent> {
  final RegisterUseCase _registerUseCase;
  
  RegisterController(this._registerUseCase) : super(RegisterState.initial());
  
  @override
  void handleIntent(JIntent intent) async {
    if (intent is RegisterIntent) {
      setState(state.copyWith(isLoading: true, errors: null));
      
      final params = RegisterParams(
        email: intent.email,
        password: intent.password,
        age: intent.age,
      );
      
      final result = await _registerUseCase.call(params);
      
      result.fold(
        (failure) {
          if (failure is ValidationFailures) {
            // Show field-specific errors
            final errors = <String, String>{};
            for (final f in failure.failures) {
              errors[f.field] = f.message;
            }
            setState(state.copyWith(
              isLoading: false,
              errors: errors,
            ));
          } else {
            setState(state.copyWith(
              isLoading: false,
              errors: {'general': failure.message},
            ));
          }
        },
        (user) {
          setState(state.copyWith(
            isLoading: false,
            user: user,
          ));
          emitSideEffect(NavigateToHomeEffect());
        },
      );
    }
  }
}
```

---

## 7. Alternatives Considered

### Alternative 1: No Validation Framework

**Approach:** Let developers handle validation themselves

**Pros:**
- No code to maintain
- Maximum flexibility
- No imposed patterns

**Cons:**
- Inconsistent validation
- Repeated code
- Security risks

**Decision:** Rejected - Guidance needed

### Alternative 2: Use Existing Library

**Approach:** Depend on `validators` or similar package

**Pros:**
- Already exists
- Maintained
- Feature-rich

**Cons:**
- External dependency
- May not match JIntent patterns
- Either integration needed

**Decision:** Rejected - Keep minimal dependencies

### Alternative 3: Annotation-Based Validation

**Approach:** Use annotations like `@NotEmpty`, `@Email`

**Pros:**
- Declarative
- Less code
- Popular pattern (Java)

**Cons:**
- Requires code generation
- Runtime overhead
- Not Dart-idiomatic

**Decision:** Rejected - Too complex

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Not comprehensive enough | Medium | High | Extensible design, custom validators |
| Conflict with other validation libs | Low | Medium | Optional, not required |
| Performance overhead | Low | Low | Simple functions, compiled |
| API changes needed | Medium | Low | Beta period, feedback |

---

## 9. Open Questions

### Q1: Code Generation Support?

**Question:** Should we provide code generator for validators?

**Answer:** Phase 3 - Consider if demand exists.

### Q2: Async Validators?

**Question:** Support validation that requires async operations?

**Answer:** Yes, but Phase 2 - use `Future<Either<Failure, T>>`.

### Q3: I18n for Validation Messages?

**Question:** Built-in internationalization support?

**Answer:** Consumers handle i18n - validators provide error codes.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [ADR-005: Security Architecture](./ADR-005-security-architecture.md) - Input validation
- [ADR-006: Error Handling Patterns](./ADR-006-error-handling-patterns.md) - ValidationFailure

### External Resources
- [Dart Validators Package](https://pub.dev/packages/validators)
- [Functional Validation](https://dev.to/gcanti/functional-design-algebraic-data-types-36kf)
- [Domain-Driven Design: Value Objects](https://martinfowler.com/bliki/ValueObject.html)

### Related ADRs
- ADR-005: Security Architecture (input validation security)
- ADR-006: Error Handling Patterns (ValidationFailure)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] Validation framework designed
- [ ] Common validators specified
- [ ] Composition patterns defined
- [ ] Integration with use cases shown
- [ ] Examples provided
- [ ] Guidelines documented

### Next Steps After Approval

1. Mark ADR-007 as **Accepted**
2. Implement ValidationFailure class
3. Create basic validators
4. Add composition utilities
5. Write validation guide
6. Update use case examples

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes validation framework for JIntent. It builds upon ADR-000 and complements ADR-005 (Security) and ADR-006 (Error Handling).*
