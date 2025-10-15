# Exception and Error Handling Inventory

**Status:** Draft | **Date:** 2025-10-14 | **Version:** 2.1.0 Analysis

## Table of Contents
- [Overview](#overview)
- [Error Handling Philosophy](#error-handling-philosophy)
- [Exception Catalog](#exception-catalog)
- [Error Patterns](#error-patterns)
- [Governance](#governance)

---

## Overview

JIntent uses a **functional error handling** approach via the `Either<L, R>` monad rather than traditional exception throwing. This inventory documents both explicit exceptions and the Either-based error model.

### Error Handling Approach

**Primary Pattern:** Either Monad
```dart
Either<Exception, Result> // Left = failure, Right = success
```

**Benefits:**
- Explicit error handling (compiler enforced)
- No hidden control flow (no try-catch surprises)
- Composable error handling
- Type-safe error propagation

**Traditional Exceptions:** Used sparingly for:
- Configuration errors (StateError, ArgumentError)
- Framework violations (TimeoutException)
- Programming errors (developer mistakes)

---

## Error Handling Philosophy

### When to Use Either<Exception, T>

✅ **USE Either for:**
- Business logic failures (validation errors, domain rule violations)
- Expected failures (network timeouts, not found, unauthorized)
- Use case execution results
- Data transformation failures

### When to Use Traditional Exceptions

✅ **USE Exceptions for:**
- Programming errors (null checks, type errors)
- Framework violations (completing an already-completed effect)
- Configuration errors (missing required setup)
- Unrecoverable errors (out of memory, should never happen)

---

## Exception Catalog

### Built-in Dart/Flutter Exceptions

| Exception Type | Layer | Usage | HTTP Mapping | Message Pattern | Governance |
|----------------|-------|-------|--------------|-----------------|------------|
| `StateError` | Core | Effect already completed or unhandled awaitable effect | 500 | "Effect already completed" or "Unhandled effect..." | ✅ Immutable |
| `TimeoutException` | Core | Side effect timeout expired | 408 | "Side effect timeout" | ✅ Immutable |
| `ArgumentError` | Domain | Invalid mapper input type | 400 | "Unsupported type" | ✅ Immutable |

### Application-Defined Exceptions

**Current State:** None defined in library.

**Expectation:** Applications using JIntent will define their own exception types:

```dart
// Example app exceptions (not in library)
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  NetworkException(this.message, [this.statusCode]);
}
```

---

## Error Patterns

### Pattern 1: Either Monad (Primary)

**Location:** `lib/src/domain/either.dart`

**Structure:**
```dart
abstract class Either<L, R> {
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn);
}

class Left<L, R> extends Either<L, R> { /* failure */ }
class Right<L, R> extends Either<L, R> { /* success */ }
```

**Usage Count:** Core pattern, used in:
- All use cases (`JUseCase`, `JSyncUseCase`)
- Use case validators
- Application business logic

**Examples:**

```dart
// Use case returning Either
class IncrementUseCase extends JSyncUseCase<int, int> {
  @override
  Either<Exception, int> run(int input) {
    if (input >= 100) {
      return Left(Exception('Counter cannot exceed 100'));
    }
    return Right(input + 1);
  }
}

// Controller handling Either result
result.fold(
  (error) => emitSideEffect(ShowErrorEffect(error.toString())),
  (value) => update((state) => state.copyWith(counter: value)),
);
```

**Error Logging:**
- Optional global logger: `EitherConfig.configureLogger(logger)`
- Logs in debug mode when `Left` is created
- No production impact (opt-in)

---

### Pattern 2: Effect Completion Errors

**Location:** `lib/src/core/effects/jeffect.dart`

**Methods:**
```dart
void complete(T value)            // Success
void completeError(Object error)  // Failure
```

**Error Types:**
- `TimeoutException` - Effect not completed within timeout
- `StateError` - Unhandled effect with throwError strategy
- Application-defined errors (anything can be passed to completeError)

**Usage:**
```dart
// Controller with timeout
final result = await emitAndWaitSideEffect(
  ConfirmDialogEffect('Delete?'),
  timeout: Duration(seconds: 5),
);
// If timeout: effect.completeError(TimeoutException('...'))

// UI handler completing with error
effect.completeError(Exception('User canceled'));
```

---

### Pattern 3: Unhandled Effect Strategy

**Location:** `lib/src/core/effects/jeffect_config.dart`

**Configuration:**
```dart
enum UnhandledEffectStrategy {
  warnOnly,                // Log warning only
  warnAndAutoComplete,     // Log + auto-complete (default)
  throwError,              // Log + throw StateError
}
```

**Behavior:**

| Strategy | Awaitable Effect | Non-Awaitable Effect | Production Safe? |
|----------|------------------|----------------------|------------------|
| `warnOnly` | ⚠️ Warning logged, caller hangs | ⚠️ Warning logged | ❌ No (hangs) |
| `warnAndAutoComplete` | ⚠️ Warning + auto-complete(null) | ⚠️ Warning logged | ✅ Yes (degraded) |
| `throwError` | ❌ StateError thrown | ❌ StateError thrown | ❌ No (crashes) |

**Recommendation:**
- Development: `throwError` (fail fast)
- Production: `warnAndAutoComplete` (graceful degradation)

---

### Pattern 4: Use Case Validators

**Location:** `lib/src/domain/use_case.dart`

**Pattern:**
```dart
typedef UseCaseInputValidator<I> = Either<Exception, I> Function(I input);

// Add validators to use case
useCase.addValidator((input) {
  if (input < 0) return Left(Exception('Must be positive'));
  return Right(input);
});
```

**Execution Flow:**
1. Validators run sequentially
2. First `Left` result stops execution
3. All validators pass → `run()` method executes
4. Any validator fails → early return with error

**Benefits:**
- Composable validation rules
- Reusable validators
- Clear separation of validation vs. execution

---

### Pattern 5: Sequential Intent Error Handling

**Location:** `lib/src/core/dispachers/sequential_intent_dispatcher.dart`

**Behavior:**
- Intents execute one at a time (queued)
- If intent throws exception:
  - Error logged to console: `❌ [JIntent][SEQ] Error in IntentType: $e`
  - Intent completer completes with error
  - Next intent in queue proceeds (error doesn't block queue)

**Example:**
```dart
try {
  await controller.intent(RiskyIntent());
} catch (e) {
  // Handle error from intent execution
}
```

---

## Error Code Conventions

### Current State

**No explicit error codes defined.** JIntent uses:
1. Exception messages (string-based)
2. Exception types (type-based discrimination)

### Recommendations for Applications

Applications using JIntent should define error codes:

```dart
// Example error code system
enum AppErrorCode {
  VALIDATION_FAILED('VAL_001', 'Validation failed'),
  NETWORK_ERROR('NET_001', 'Network error'),
  UNAUTHORIZED('AUTH_401', 'Unauthorized'),
  NOT_FOUND('DATA_404', 'Resource not found');
  
  final String code;
  final String message;
  const AppErrorCode(this.code, this.message);
}

class AppException implements Exception {
  final AppErrorCode errorCode;
  final String details;
  
  AppException(this.errorCode, [this.details = '']);
  
  @override
  String toString() => '${errorCode.code}: ${errorCode.message} - $details';
}
```

---

## Exception Statistics

### Library Exceptions (Built-in)

| Exception Type | Count | Files | Mutability Status |
|----------------|-------|-------|-------------------|
| `StateError` | 2 usages | side_effect_handler.dart | ✅ Immutable |
| `TimeoutException` | 1 usage | jcontroller.dart | ✅ Immutable |
| `ArgumentError` | 1 usage | mapper.dart | ✅ Immutable |
| **Total** | **4** | **3** | **All Immutable** |

### Either Pattern Usage

| Pattern | Files | Estimated Usage | Status |
|---------|-------|----------------|--------|
| `Either<Exception, T>` | 3+ | Core pattern | ✅ Stable |
| `Left(Exception(...))` | Multiple | High (use cases) | ✅ Stable |
| `Right(value)` | Multiple | High (use cases) | ✅ Stable |

---

## Error Handling Gaps

### Documentation Gaps

1. **No Comprehensive Error Guide** - Missing guide for app developers
2. **No Error Code Recommendations** - No guidance on error code systems
3. **Limited Examples** - Few examples of complex error scenarios
4. **No Error Recovery Patterns** - Missing retry/fallback patterns

### Testing Gaps

1. **No Error Path Tests** - Limited tests for error scenarios
2. **No Timeout Tests** - No tests for effect timeouts (fakeAsync needed)
3. **No Validation Error Tests** - Missing validator error tests
4. **No Error Logging Tests** - EitherConfig.errorLogger not tested

### Implementation Gaps

1. **No Built-in Retry** - No retry mechanism for failed intents
2. **No Error Aggregation** - No way to collect multiple validation errors
3. **No Error Context** - Stack traces not always captured
4. **No Error Telemetry** - No hooks for error tracking services

---

## Governance

### Error Handling Rules (Phase 0)

**RULE 1:** No modifications to existing exception types or messages during Phase 0.

**RULE 2:** All new exception types must be:
- Documented in this inventory
- Justified with use case
- Approved via Issue before implementation

**RULE 3:** Error messages must be:
- Clear and actionable
- Not expose internal implementation details
- Localization-friendly (no concatenation)

**RULE 4:** Either monad is the preferred pattern for:
- Use case results
- Business logic failures
- Expected errors

**RULE 5:** Traditional exceptions are for:
- Programming errors (should not happen in production)
- Framework violations
- Unrecoverable errors

### Change Workflow

**To add a new exception type:**

1. **Proposal** (GitHub Issue)
   - Exception name and type
   - Use case and justification
   - Message pattern
   - HTTP status mapping (if applicable)
   - Backward compatibility impact

2. **Review** (Tech Lead + 1 peer)
   - Verify necessity (can Either pattern be used?)
   - Check for duplicates
   - Validate naming convention
   - Assess API impact

3. **Implementation**
   - Add exception class
   - Update this inventory
   - Add tests for error path
   - Document usage examples
   - Add to CHANGELOG

4. **Testing Requirements**
   - Unit test for exception creation
   - Integration test for error flow
   - Documentation example test

### Monitoring Hooks

**Recommended for Applications:**

```dart
// Configure global error logger
EitherConfig.configureLogger((error) {
  // Send to error tracking service
  ErrorTracker.report(error);
});

// Custom observer for intent errors
class ErrorTrackingObserver extends JObserver {
  @override
  void onIntentError(Exception error, JIntent intent) {
    ErrorTracker.report(error, context: {
      'intent': intent.runtimeType.toString(),
    });
  }
}
```

---

## Error Handling Best Practices

### For Library Maintainers

1. **Prefer Either over Exceptions** - Use Either for expected failures
2. **Document All Exceptions** - Update this inventory
3. **Test Error Paths** - Every error path needs a test
4. **Clear Error Messages** - Help developers debug
5. **Backward Compatibility** - Don't change existing exception types

### For Application Developers

1. **Handle All Either Results** - Don't ignore Left values
2. **Complete All Effects** - Always call complete() or completeError()
3. **Set Timeouts** - Use timeout parameter for long-running effects
4. **Configure Strategy** - Set UnhandledEffectStrategy for production
5. **Log Errors** - Configure EitherConfig.errorLogger
6. **Test Error Scenarios** - Test Left results, timeouts, failures

---

## Recommended Improvements

### Phase 1: Foundation
- [ ] Document error handling patterns for app developers
- [ ] Add timeout tests with fakeAsync
- [ ] Test all error paths in core library
- [ ] Create error handling guide in docs

### Phase 2: Enhancement
- [ ] Error aggregation for multiple validation failures
- [ ] Retry mechanism for failed intents
- [ ] Error context (stack trace preservation)
- [ ] Structured error codes for common patterns

### Phase 3: Advanced
- [ ] Error telemetry hooks
- [ ] Error recovery patterns
- [ ] Circuit breaker for repeated failures
- [ ] Error analytics and reporting

---

## Related Documents

- [Repository Analysis](./REPOSITORY_ANALYSIS.md) - Overall architecture
- [Executive Summary](./EXECUTIVE_SUMMARY.md) - High-level overview
- [Side Effects Guide](../doc/effects.md) - Effect completion patterns

---

**Document Owner:** System Architecture & Governance Analyst  
**Last Updated:** 2025-10-14  
**Next Review:** After Phase 1 completion  
**Exception Count Last Verified:** 2025-10-14 (4 built-in exceptions)
