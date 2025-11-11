# ADR-006: Error Handling Patterns

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 2 Security & API - Error Handling Strategy  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines error handling patterns, exception strategies, and failure management for JIntent to ensure predictable, type-safe error handling.

---

## 2. Context

### 2.1 Background

**Current Error Handling (v2.1.0):**

**Existing Patterns:**
- ✅ Either<Exception, T> monad in domain layer
- ✅ Dart exceptions for unexpected errors
- ✅ TimeoutException for effect timeouts
- ✅ ArgumentError for validation failures
- ⚠️ Generic Exception used everywhere

**Implementation:**
```dart
// Domain layer: Either monad
abstract class JUseCase<INPUT, OUTPUT> {
  Future<Either<Exception, OUTPUT>> call(INPUT input) async {
    // Validation
    for (final validator in _validators) {
      final result = validator(input);
      if (result.isLeft) return result;
    }
    // Execution
    return run(input);
  }
}

// Core layer: Dart exceptions
Future<T> emitAndWaitSideEffect<T>(JEffect<T> effect, {Duration? timeout}) {
  if (timeout != null && /* timeout expires */) {
    throw TimeoutException('Effect timeout');
  }
}
```

**Gaps:**
- No custom exception hierarchy
- No error categorization
- No centralized error handling
- No error recovery patterns
- Inconsistent error messages

### 2.2 Problem Statement

**Current Challenges:**
- Hard to distinguish error types
- No structured error data
- Inconsistent error handling across layers
- No i18n support for error messages
- No retry/recovery guidance

**Business Impact:**
- Poor developer experience
- Hard to debug issues
- Inconsistent error UX in consumer apps
- No standardized error responses

---

## 3. Decision

### 3.1 Hybrid Error Strategy

**Decision:** Use Either monad + custom exceptions

**Strategy by Layer:**

**Domain Layer (Use Cases):** Either<Failure, T>
- Expected errors (validation, business logic)
- Explicit error handling
- Type-safe error propagation

**Core Layer (JIntent framework):** Dart Exceptions
- Unexpected errors (programming errors)
- Framework-level failures
- Fail-fast approach

**Presentation Layer (Consumer apps):** Both
- Convert Either to UI state
- Catch exceptions, emit error effects
- User-friendly error messages

### 3.2 Custom Exception Hierarchy

**Decision:** Define custom exception types

**Hierarchy:**
```
Exception (Dart base)
  │
  ├─ JIntentException (Abstract base)
  │   ├─ JValidationException
  │   ├─ JTimeoutException
  │   ├─ JStateException
  │   └─ JEffectException
  │
  └─ ArgumentError (Dart built-in)
```

**Implementation:**
```dart
/// Base exception for all JIntent errors.
///
/// Provides structured error information including code, message,
/// and optional details for debugging.
abstract class JIntentException implements Exception {
  /// Error code for categorization and i18n.
  final String code;
  
  /// Human-readable error message.
  final String message;
  
  /// Optional additional details for debugging.
  final Map<String, dynamic>? details;
  
  /// Stack trace where error occurred.
  final StackTrace? stackTrace;
  
  const JIntentException({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });
  
  @override
  String toString() => 'JIntentException($code): $message';
}

/// Exception thrown when input validation fails.
class JValidationException extends JIntentException {
  JValidationException({
    required String message,
    String? field,
    dynamic value,
    StackTrace? stackTrace,
  }) : super(
    code: 'VALIDATION_ERROR',
    message: message,
    details: {
      if (field != null) 'field': field,
      if (value != null) 'value': value,
    },
    stackTrace: stackTrace,
  );
}

/// Exception thrown when an operation times out.
class JTimeoutException extends JIntentException {
  final Duration timeout;
  
  JTimeoutException({
    required String message,
    required this.timeout,
    StackTrace? stackTrace,
  }) : super(
    code: 'TIMEOUT',
    message: message,
    details: {'timeout': timeout.toString()},
    stackTrace: stackTrace,
  );
}

/// Exception thrown when state operation fails.
class JStateException extends JIntentException {
  JStateException({
    required String message,
    StackTrace? stackTrace,
  }) : super(
    code: 'STATE_ERROR',
    message: message,
    stackTrace: stackTrace,
  );
}

/// Exception thrown when effect handling fails.
class JEffectException extends JIntentException {
  final String? effectType;
  
  JEffectException({
    required String message,
    this.effectType,
    StackTrace? stackTrace,
  }) : super(
    code: 'EFFECT_ERROR',
    message: message,
    details: {if (effectType != null) 'effectType': effectType},
    stackTrace: stackTrace,
  );
}
```

### 3.3 Failure Class (Either Monad)

**Decision:** Use structured Failure class instead of Exception in Either

**Implementation:**
```dart
/// Represents a failure in the domain layer.
///
/// Used with [Either] to represent expected errors in use cases.
abstract class Failure {
  /// Error code for categorization.
  final String code;
  
  /// Human-readable error message.
  final String message;
  
  /// Optional additional context.
  final Map<String, dynamic>? context;
  
  const Failure({
    required this.code,
    required this.message,
    this.context,
  });
  
  @override
  String toString() => 'Failure($code): $message';
}

/// Validation failure in domain logic.
class ValidationFailure extends Failure {
  ValidationFailure({
    required String message,
    String? field,
  }) : super(
    code: 'VALIDATION_FAILED',
    message: message,
    context: {if (field != null) 'field': field},
  );
}

/// Business rule violation.
class BusinessRuleFailure extends Failure {
  BusinessRuleFailure({
    required String message,
    String? rule,
  }) : super(
    code: 'BUSINESS_RULE_VIOLATION',
    message: message,
    context: {if (rule != null) 'rule': rule},
  );
}

/// External service failure (network, database, etc.)
class ServiceFailure extends Failure {
  ServiceFailure({
    required String message,
    String? service,
  }) : super(
    code: 'SERVICE_FAILURE',
    message: message,
    context: {if (service != null) 'service': service},
  );
}

/// Unexpected error in domain layer.
class UnexpectedFailure extends Failure {
  final Exception? exception;
  
  UnexpectedFailure({
    required String message,
    this.exception,
  }) : super(
    code: 'UNEXPECTED_ERROR',
    message: message,
    context: {if (exception != null) 'exception': exception.toString()},
  );
}
```

### 3.4 Error Handling in Intents

**Decision:** Standardize error handling pattern in intents

**Pattern:**
```dart
class LoginIntent extends JIntent {
  final String email;
  final String password;
  
  LoginIntent(this.email, this.password);
}

class LoginController extends JController<LoginState, JIntent> {
  final LoginUseCase _loginUseCase;
  
  LoginController(this._loginUseCase) : super(LoginState.initial());
  
  @override
  void handleIntent(JIntent intent) async {
    if (intent is LoginIntent) {
      // 1. Set loading state
      setState(state.copyWith(isLoading: true, error: null));
      
      try {
        // 2. Execute use case
        final result = await _loginUseCase.call(
          LoginParams(email: intent.email, password: intent.password),
        );
        
        // 3. Handle result
        result.fold(
          // Left: Failure
          (failure) {
            setState(state.copyWith(
              isLoading: false,
              error: _mapFailureToMessage(failure),
            ));
            emitSideEffect(ShowErrorEffect(
              message: _mapFailureToMessage(failure),
            ));
          },
          // Right: Success
          (user) {
            setState(state.copyWith(
              isLoading: false,
              user: user,
            ));
            emitSideEffect(NavigateToHomeEffect());
          },
        );
      } on JIntentException catch (e, stackTrace) {
        // 4. Handle JIntent framework errors
        setState(state.copyWith(
          isLoading: false,
          error: 'System error: ${e.message}',
        ));
        _logError(e, stackTrace);
      } catch (e, stackTrace) {
        // 5. Handle unexpected errors
        setState(state.copyWith(
          isLoading: false,
          error: 'An unexpected error occurred',
        ));
        _logError(e, stackTrace);
      }
    }
  }
  
  String _mapFailureToMessage(Failure failure) {
    // Map failure codes to user-friendly messages
    // (supports i18n)
    switch (failure.code) {
      case 'VALIDATION_FAILED':
        return 'Please check your input';
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password';
      case 'SERVICE_FAILURE':
        return 'Network error. Please try again.';
      default:
        return 'An error occurred';
    }
  }
  
  void _logError(dynamic error, StackTrace stackTrace) {
    // Use JObserver or logging framework
    debugPrint('Error: $error\n$stackTrace');
  }
}
```

### 3.5 Error Recovery Patterns

**Decision:** Provide common error recovery patterns

**1. Retry Pattern**
```dart
/// Executes [action] with retry logic.
///
/// Retries up to [maxAttempts] times with exponential backoff.
Future<Either<Failure, T>> withRetry<T>(
  Future<Either<Failure, T>> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  var attempt = 0;
  var delay = initialDelay;
  
  while (attempt < maxAttempts) {
    final result = await action();
    
    if (result.isRight) {
      return result;
    }
    
    // Check if error is retryable
    final failure = result.left!;
    if (!_isRetryable(failure)) {
      return result;
    }
    
    attempt++;
    if (attempt < maxAttempts) {
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }
  
  return Left(ServiceFailure(
    message: 'Operation failed after $maxAttempts attempts',
  ));
}

bool _isRetryable(Failure failure) {
  return failure is ServiceFailure && 
         failure.code != 'AUTHENTICATION_ERROR';
}
```

**2. Circuit Breaker Pattern (Future)**
```dart
/// Prevents cascading failures by breaking the circuit after threshold.
class CircuitBreaker {
  int _failureCount = 0;
  final int threshold;
  final Duration timeout;
  DateTime? _openedAt;
  
  CircuitBreaker({
    this.threshold = 5,
    this.timeout = const Duration(minutes: 1),
  });
  
  Future<Either<Failure, T>> execute<T>(
    Future<Either<Failure, T>> Function() action,
  ) async {
    // Check if circuit is open
    if (_isOpen()) {
      return Left(ServiceFailure(
        message: 'Service temporarily unavailable (circuit open)',
      ));
    }
    
    // Execute action
    final result = await action();
    
    // Update circuit state
    if (result.isLeft) {
      _failureCount++;
      if (_failureCount >= threshold) {
        _openedAt = DateTime.now();
      }
    } else {
      _failureCount = 0;
      _openedAt = null;
    }
    
    return result;
  }
  
  bool _isOpen() {
    if (_openedAt == null) return false;
    return DateTime.now().difference(_openedAt!) < timeout;
  }
}
```

**3. Fallback Pattern**
```dart
/// Provides fallback value on failure.
extension EitherExtensions<L, R> on Either<L, R> {
  R getOrElse(R Function() fallback) {
    return fold((_) => fallback(), (r) => r);
  }
  
  R getOrDefault(R defaultValue) {
    return fold((_) => defaultValue, (r) => r);
  }
}

// Usage:
final user = await useCase.call(params)
    .then((result) => result.getOrDefault(User.guest()));
```

### 3.6 Error Effect Pattern

**Decision:** Use side effects for error notifications

**Implementation:**
```dart
/// Side effect for displaying error messages.
class ErrorEffect extends JFireAndForgetEffect {
  final String message;
  final ErrorSeverity severity;
  
  ErrorEffect({
    required this.message,
    this.severity = ErrorSeverity.error,
  }) : super(category: 'error');
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

// In handler:
class MyEffectHandler extends JSideEffectHandler<AppState> {
  MyEffectHandler(super.controller) {
    register<ErrorEffect>((effect, controller, context) async {
      final color = _colorForSeverity(effect.severity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(effect.message),
          backgroundColor: color,
        ),
      );
    });
  }
}
```

### 3.7 Error Logging & Observability

**Decision:** Integrate error handling with observability (ADR-008)

**Pattern:**
```dart
// Extend JObserver with error tracking
extension ErrorObserver on JObserver {
  static void onError(
    dynamic error,
    StackTrace stackTrace, {
    JController? controller,
    JIntent? intent,
  }) {
    // Log error with context
    debugPrint('''
Error occurred:
  Error: $error
  Controller: ${controller?.runtimeType}
  Intent: ${intent?.runtimeType}
  Stack: $stackTrace
''');
    
    // Send to error tracking service (Sentry, Crashlytics)
    // _errorService.report(error, stackTrace);
  }
}

// Usage in controller:
void handleIntent(JIntent intent) async {
  try {
    // ... intent logic
  } catch (e, stackTrace) {
    ErrorObserver.onError(e, stackTrace,
      controller: this,
      intent: intent,
    );
    rethrow;
  }
}
```

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Type Safety**
- Compile-time error handling
- Either monad forces error consideration
- Custom exceptions provide structure

✅ **Developer Experience**
- Clear error categories
- Predictable error handling
- Standard patterns to follow

✅ **Debuggability**
- Structured error information
- Stack traces captured
- Error context available

✅ **Maintainability**
- Centralized error types
- Easy to extend
- Consistent patterns

### 4.2 Negative Consequences

⚠️ **Verbosity**
- More error handling code
- Either monad adds boilerplate
- Try-catch blocks

⚠️ **Learning Curve**
- Developers must learn Either
- Multiple error handling strategies
- When to use which pattern

⚠️ **Migration**
- Existing code uses generic Exception
- Need to migrate gradually
- Breaking change (major version)

### 4.3 Mitigation Strategies

**For Verbosity:**
- Provide helper functions
- Extension methods
- Code generation (future)

**For Learning Curve:**
- Comprehensive documentation
- Examples for common scenarios
- Migration guide

**For Migration:**
- Deprecation period
- Backward compatibility layer
- Automated migration tool (future)

---

## 5. Implementation Plan

### Phase 1: Foundation (Week 1-2)
- [x] Create ADR-006
- [ ] Define custom exception hierarchy
- [ ] Create Failure classes
- [ ] Add to library exports

### Phase 2: Adoption (Week 3-4)
- [ ] Migrate core layer to custom exceptions
- [ ] Update domain layer to use Failure
- [ ] Update examples
- [ ] Write error handling guide

### Phase 3: Enhancement (Week 5+)
- [ ] Add retry utilities
- [ ] Add circuit breaker
- [ ] Error effect patterns
- [ ] Integration with observability (ADR-008)

---

## 6. Examples

See code examples in sections 3.2-3.6 above.

---

## 7. Alternatives Considered

### Alternative 1: Exceptions Only

**Approach:** Use only Dart exceptions for all errors

**Pros:**
- Simple, familiar
- Less boilerplate
- Standard Dart approach

**Cons:**
- No compile-time error handling
- Easy to forget error handling
- Less type-safe

**Decision:** Rejected - Either provides better safety

### Alternative 2: Result Type (Rust-style)

**Approach:** Result<T, E> instead of Either<L, R>

**Pros:**
- More semantic
- Rust convention
- Clear intent

**Cons:**
- Not standard in Dart
- Either already used
- Migration complexity

**Decision:** Rejected - Either sufficient and existing

### Alternative 3: Checked Exceptions (Java-style)

**Approach:** Compile-time checked exceptions

**Pros:**
- Forces error handling
- Compile-time safety

**Cons:**
- Not supported in Dart
- Would require custom analyzer
- Very intrusive

**Decision:** Rejected - Not feasible in Dart

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking change resistance | Medium | High | Deprecation period, migration guide |
| Inconsistent adoption | Medium | Medium | Examples, documentation, reviews |
| Performance overhead | Low | Low | Either is lightweight |
| Complexity increase | Medium | Medium | Training, documentation |

---

## 9. Open Questions

### Q1: Generic vs Specific Failures?

**Question:** Should Failure be generic or have specific subclasses?

**Answer:** Both - base Failure + common subclasses, allow custom.

### Q2: Error Codes vs Enums?

**Question:** Use string codes or enum for error categorization?

**Answer:** String codes - more flexible, easier i18n.

### Q3: Automatic Error Reporting?

**Question:** Should JIntent automatically report errors to services?

**Answer:** No - opt-in via JObserver, consumers choose service.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md) - D4
- [Repository Analysis](../REPOSITORY_ANALYSIS.md) - Section 4 Error Handling
- [Exception Inventory](../EXCEPTION_INVENTORY.md)

### External Resources
- [Either Monad in Dart](https://pub.dev/packages/dartz)
- [Error Handling in Dart](https://dart.dev/guides/language/language-tour#exceptions)
- [Effective Dart: Error Handling](https://dart.dev/guides/language/effective-dart/usage#prefer-making-fields-and-top-level-variables-final)
- [Railway Oriented Programming](https://fsharpforfunandprofit.com/posts/recipe-part2/)

### Related ADRs
- ADR-005: Security Architecture (error information disclosure)
- ADR-008: Observability Strategy (error logging)
- ADR-007: Validation Framework (validation failures)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] Error strategy defined
- [ ] Custom exceptions specified
- [ ] Failure classes designed
- [ ] Patterns documented
- [ ] Examples provided
- [ ] Migration plan outlined

### Next Steps After Approval

1. Mark ADR-006 as **Accepted**
2. Implement custom exception hierarchy
3. Create Failure classes
4. Update existing error handling
5. Write error handling guide
6. Create migration examples

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes error handling patterns for JIntent. It builds upon ADR-000 and complements ADR-005 (Security) and ADR-008 (Observability).*
