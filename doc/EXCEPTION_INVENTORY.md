# Exception & Error Handling Inventory - JIntent

**Status:** Draft  
**Date:** 2025-10-15  
**Version:** 2.1.0  
**Commit Reference:** 86700cb

---

## Table of Contents

1. [Overview](#1-overview)
2. [Error Handling Strategy](#2-error-handling-strategy)
3. [Exception Inventory](#3-exception-inventory)
4. [Error Patterns](#4-error-patterns)
5. [Governance Rules](#5-governance-rules)
6. [Change Workflow](#6-change-workflow)
7. [Testing Requirements](#7-testing-requirements)
8. [Monitoring & Observability](#8-monitoring--observability)
9. [Recommendations](#9-recommendations)

---

## 1. Overview

### 1.1 Purpose

This document provides a comprehensive inventory of error and exception handling patterns used in the JIntent library. It establishes governance rules for maintaining consistency and stability in error handling practices.

### 1.2 Scope

**Included:**
- Exception types and usage patterns
- Error handling approaches (Either monad, try-catch)
- Error propagation strategies
- Governance rules for error handling changes

**Excluded:**
- Application-specific errors (consumer responsibility)
- Flutter framework exceptions
- Third-party dependency errors

### 1.3 Key Findings

- **No Custom Error Code System:** JIntent uses Dart standard exceptions and Either monad
- **Functional Error Handling:** Either<Exception, T> for expected errors
- **Exception Types:** 3 primary exception types used
- **Governance Status:** No formal error handling governance (being established)

---

## 2. Error Handling Strategy

### 2.1 Dual Approach

JIntent employs two complementary error handling strategies:

#### Approach 1: Either Monad (Functional)

**Purpose:** Explicit, type-safe error handling for expected failures

**Usage Context:**
- Domain layer (use cases)
- Repository patterns
- Business logic validation

**Advantages:**
- Forces error handling (compile-time safety)
- Self-documenting (signature shows failure possibility)
- No runtime exceptions for expected cases

**Example:**
```dart
Future<Either<Exception, User>> getUser(String id) async {
  try {
    final user = await repository.fetch(id);
    return Right(user);
  } catch (e) {
    return Left(Exception('User not found'));
  }
}

// Caller must handle both cases
final result = await getUser('123');
if (result.isLeft) {
  // Handle error: result.left
} else {
  // Use value: result.right
}
```

#### Approach 2: Dart Exceptions (Imperative)

**Purpose:** Exceptional conditions and programmer errors

**Usage Context:**
- Timeouts
- Invalid arguments
- Unexpected states

**Advantages:**
- Standard Dart pattern
- Automatic stack traces
- Framework integration

**Example:**
```dart
if (timeout != null && effect.result.timeout(timeout)) {
  throw TimeoutException('Effect timed out');
}
```

### 2.2 Error Categories

| Category | Handling Method | Layer | Example |
|----------|----------------|-------|---------|
| Business Logic Errors | Either<Exception, T> | Domain | Validation failures, not found |
| Timeout Errors | TimeoutException | Core | Effect waiting timeout |
| Validation Errors | Either<Exception, T> | Domain | Input validation failures |
| Programmer Errors | ArgumentError | Domain | Invalid mapper inputs |
| Unexpected Errors | Exception (catch-all) | All | Unhandled edge cases |

### 2.3 Error Propagation

**Principle:** Errors propagate upward through layers

```
Domain Layer (Use Case)
    ↓ Returns Either<Exception, T>
Core Layer (Intent)
    ↓ Checks result, emits effect or updates state
Presentation Layer (UI)
    ↓ Listens to state/effects, shows error UI
```

---

## 3. Exception Inventory

### 3.1 Exception Table

| Code/Type | Category | Message Pattern | HTTP Status | Layer | Usage Count | Notes | Change Approved? |
|-----------|----------|----------------|-------------|-------|-------------|-------|------------------|
| Exception (generic) | Business Logic | "Validation failed", "Not found", etc. | 400/404/422 | Domain | Widespread | Standard Dart Exception | N/A (frozen) |
| TimeoutException | Timeout | "Effect {type} (id={id}) timed out after {duration}" | 408 | Core | Low | Used in effect timeout handling | N/A (frozen) |
| ArgumentError | Validation | "Invalid argument: {reason}" | 400 | Domain | Low | Mapper validation errors | N/A (frozen) |

**Total Exception Types:** 3  
**Custom Exceptions:** 0  
**Error Codes:** 0 (not used)

### 3.2 Exception Usage Analysis

#### Exception (Generic)

**Definition:** Dart standard `Exception` class

**Usage Contexts:**
1. Use case validation failures
   ```dart
   if (value < 0) return Left(Exception('Value must be positive'));
   ```

2. Business rule violations
   ```dart
   if (!user.isActive) return Left(Exception('User is inactive'));
   ```

3. Not found scenarios
   ```dart
   if (entity == null) return Left(Exception('Entity not found'));
   ```

**Strengths:**
- Simple, universally understood
- No custom types needed
- Works with Either monad

**Weaknesses:**
- Generic, hard to distinguish error types
- No structured data
- Message-only error context
- Not i18n-friendly

**Recommendation:** Consider custom exception types in Phase 2

#### TimeoutException

**Definition:** Dart standard `TimeoutException`

**Usage Context:** Effect timeout handling

**Implementation Location:** `lib/src/core/jcontroller.dart`

```dart
return effect.result.timeout(
  appliedTimeout,
  onTimeout: () {
    if (!effect.isCompleted) {
      effect.completeError(
        TimeoutException(
          'Effect ${effect.runtimeType} (id=${effect.id}) timed out after $appliedTimeout',
        ),
      );
    }
    return Future.value(null) as V;
  },
);
```

**Strengths:**
- Standard Dart exception
- Clear semantic meaning
- Includes timeout details in message

**Weaknesses:**
- Message-based error info
- No structured timeout context

**Change Status:** Frozen (Phase 0 rule)

#### ArgumentError

**Definition:** Dart standard `ArgumentError`

**Usage Context:** Mapper input validation

**Implementation Location:** `lib/src/domain/mapper.dart`

```dart
dynamic transformDynamic(dynamic entityOrArray) {
  if (entityOrArray is INPUT) return transform(entityOrArray);
  if (entityOrArray is List<INPUT>) return transformList(entityOrArray);
  throw ArgumentError('Expected $INPUT or List<$INPUT>, got ${entityOrArray.runtimeType}');
}
```

**Strengths:**
- Appropriate for programming errors
- Standard Dart exception
- Clear type mismatch message

**Weaknesses:**
- Unchecked (not Either)
- Runtime failure

**Change Status:** Frozen (Phase 0 rule)

### 3.3 Unused Exception Types

**None identified.** All defined exception types are actively used.

### 3.4 Duplicate or Ambiguous Exceptions

**None identified.** The three exception types have distinct purposes:
- `Exception` - Business logic errors
- `TimeoutException` - Timing failures
- `ArgumentError` - Programming errors

---

## 4. Error Patterns

### 4.1 Pattern 1: Use Case Error Handling

**Description:** Use Either monad for expected failures

**Implementation:**
```dart
// Use case definition
class IncrementUseCase extends JSyncUseCase<int, int> {
  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue + 1;
    
    if (newValue > 100) {
      return Left(Exception('Value cannot exceed 100'));
    }
    return Right(newValue);
  }
}

// Intent usage
final result = await _useCase.call(state.counter);
if (result.isLeft) {
  // Handle error
  controller.emitSideEffect(ShowErrorEffect(result.left!.toString()));
  return;
}
// Use result.right
controller.update((s) => s.copyWith(counter: result.right));
```

**Pros:**
- Type-safe
- Forces error handling
- No runtime exceptions for expected errors

**Cons:**
- More verbose than try-catch
- Requires Either understanding

### 4.2 Pattern 2: Effect Timeout Handling

**Description:** Handle effect timeouts with TimeoutException

**Implementation:**
```dart
try {
  final confirmed = await controller.emitAndWaitSideEffect(
    DeleteDialogEffect(itemName: 'File.txt'),
    timeout: Duration(seconds: 30),
  );
  if (confirmed) {
    // Proceed with deletion
  }
} on TimeoutException catch (e) {
  // Handle timeout
  controller.emitSideEffect(ShowErrorEffect('Operation timed out'));
}
```

**Pros:**
- Standard Dart exception handling
- Clear timeout semantics

**Cons:**
- Requires explicit catch
- Interrupts flow with exception

### 4.3 Pattern 3: Validation Chain

**Description:** Chain validators on use case inputs

**Implementation:**
```dart
final useCase = IncrementUseCase();

useCase.addValidator((input) {
  if (input < 0) return Left(Exception('Input must be non-negative'));
  return Right(input);
});

useCase.addValidator((input) {
  if (input > 1000) return Left(Exception('Input too large'));
  return Right(input);
});

final result = await useCase.call(value);
// First failing validator stops execution
```

**Pros:**
- Composable validation
- Fail-fast behavior
- Reusable validators

**Cons:**
- Only one error reported (first failure)
- No error aggregation

### 4.4 Pattern 4: Global Error Handling (Missing)

**Current State:** No global error handler

**Gap:** Each intent handles errors independently, leading to:
- Inconsistent error UX
- Duplicated error handling logic
- No centralized error logging

**Recommendation:** Add global error interceptor in Phase 2

---

## 5. Governance Rules

### 5.1 Phase 0 Governance (Current)

**RULE 1: No Exception Modifications During Phase 0**

During Phase 0 (Discovery), the following are **PROHIBITED**:
- Adding new exception types
- Modifying exception messages
- Changing error handling patterns
- Refactoring error structures

**Rationale:** Maintain stability during analysis

**Exception:** Documentation and inventory creation only

### 5.2 Future Governance (Post-Phase 0)

#### Rule: Exception Type Changes

**Requirement:** All new exception types require:
1. GitHub Issue documenting need
2. ADR (Architecture Decision Record) if architectural impact
3. PR with implementation
4. Tests covering new exception
5. Documentation update
6. CHANGELOG entry

**Approval:** Requires 1+ maintainer approval

#### Rule: Error Message Changes

**Requirement:** Breaking message changes require:
1. Semantic version bump (MAJOR if client code parses messages)
2. Migration guide if breaking
3. Deprecation period if possible

**Approval:** Maintainer decision

#### Rule: Error Handling Pattern Changes

**Requirement:** Pattern changes (e.g., Either → Result) require:
1. ADR documenting rationale
2. Migration guide
3. Deprecation of old pattern
4. Community discussion (RFC)

**Approval:** Community consensus + maintainer approval

### 5.3 Immutability Policy

**Principle:** Once released, exception types are immutable (add, don't modify)

**Breaking Changes:**
- Require MAJOR version bump
- Require migration guide
- Minimize frequency

**Non-Breaking Changes:**
- Adding new exception types (MINOR)
- Adding optional exception properties (MINOR)
- Improving error messages (PATCH, if non-breaking)

---

## 6. Change Workflow

### 6.1 Process for Adding New Exception Type

**Step 1: Proposal (Issue Creation)**
```markdown
Title: [Exception] Add ValidationException for input errors

Description:
- Problem: Generic Exception too broad for validation
- Proposed: ValidationException with field-level errors
- Use cases: Form validation, API input validation
- Breaking: No (additive change)
```

**Step 2: Discussion & Approval**
- Community feedback (7 days)
- Maintainer decision
- Assigned to milestone

**Step 3: Implementation (PR)**
1. Create exception type
   ```dart
   class ValidationException implements Exception {
     final Map<String, String> errors;
     ValidationException(this.errors);
   }
   ```
2. Add tests
3. Update documentation
4. Update EXCEPTION_INVENTORY.md
5. Add CHANGELOG entry

**Step 4: Review & Merge**
- Code review (≥1 approval)
- Tests pass
- Documentation complete
- Merge to main

**Step 5: Release**
- Include in next MINOR release
- Publish to pub.dev
- Announce in release notes

### 6.2 Issue Template: Exception Change Request

```markdown
## Exception Change Request

### Type of Change
- [ ] New exception type
- [ ] Modify existing exception
- [ ] Change error handling pattern
- [ ] Update error messages

### Motivation
Why is this change needed?

### Proposed Solution
What is the proposed approach?

### Breaking Change?
- [ ] Yes (requires MAJOR version)
- [ ] No (backward compatible)

### Migration Path
How will existing users migrate? (if breaking)

### Testing Plan
How will this be tested?

### Documentation Updates
What docs need updating?
```

---

## 7. Testing Requirements

### 7.1 Exception Testing Standards

**Requirement:** All exception scenarios must have tests

**Test Coverage:**
- ✅ Exception thrown correctly
- ✅ Exception message accurate
- ✅ Exception handled properly
- ✅ State updated correctly after error
- ✅ Side effects emitted on error

**Example Test:**
```dart
test('returns Left when validation fails', () async {
  useCase.addValidator((input) {
    if (input < 0) return Left(Exception('Negative input'));
    return Right(input);
  });

  final result = await useCase.call(-1);

  expect(result.isLeft, true);
  expect(result.left!.toString(), contains('Negative input'));
});
```

### 7.2 Current Test Coverage

**Exception Tests Found:**

1. **Use Case Validation Test** (`test/src/domain/use_case_test.dart`)
   - Tests validator failure → Left
   - Tests validator success → Right

2. **Effect Test** (`test/src/core/jeffect_test.dart`)
   - Tests effect completion
   - Tests effect error completion

**Gaps:**
- No timeout exception tests
- No ArgumentError tests
- No error recovery tests

**Recommendation:** Add comprehensive exception tests in Phase 1

### 7.3 Test Requirements for New Exceptions

**Mandatory Tests:**
1. Exception instantiation
2. Exception message
3. Either monad integration (if applicable)
4. Intent error handling
5. UI error display (integration test)

---

## 8. Monitoring & Observability

### 8.1 Current State

**Error Monitoring:** Not implemented

**Available Hooks:**
- `JObserver.notifyStateChanged()` - State updates (including error states)
- `JObserver.notifyEffectEmitted()` - Side effects (including error effects)

**Gap:** No dedicated error tracking

### 8.2 Recommendations

#### Phase 2: Error Logging
- Add error-specific observer callbacks
- Log error frequency and types
- Track error-to-recovery ratios

#### Phase 3: Error Monitoring Integration
- Document Sentry integration pattern
- Document Crashlytics integration
- Provide error monitoring examples

### 8.3 Error Metrics to Track

**Recommended Metrics:**
1. Error rate (errors per minute)
2. Error types distribution
3. Most common error messages
4. Error recovery success rate
5. Effect timeout frequency

### 8.4 Alerting (Future)

**Recommended Alerts:**
- Error rate spike (>10x baseline)
- New error type detected
- Critical exception frequency
- Timeout rate increase

---

## 9. Recommendations

### 9.1 Short-Term (Phase 1)

1. **Document Error Patterns**
   - Create error handling guide
   - Provide examples for common scenarios
   - Document best practices

2. **Expand Test Coverage**
   - Add timeout exception tests
   - Add error recovery tests
   - Add integration tests for error flows

3. **Establish Governance**
   - Formalize exception change process
   - Create issue templates
   - Document approval requirements

### 9.2 Medium-Term (Phase 2)

1. **Custom Exception Types**
   - Consider: `ValidationException`, `NetworkException`, `AuthException`
   - Add structured error data (not just messages)
   - Support error codes for i18n

2. **Enhanced Error Context**
   - Add stack trace preservation
   - Add error metadata (timestamps, context)
   - Support error aggregation

3. **Global Error Handler**
   - Add error interceptor middleware
   - Centralize error logging
   - Provide default error UX patterns

### 9.3 Long-Term (Phase 3-4)

1. **Advanced Error Handling**
   - Retry strategies with exponential backoff
   - Circuit breaker pattern
   - Error recovery workflows

2. **Observability Integration**
   - Error monitoring dashboards
   - Error analytics
   - Anomaly detection

3. **Developer Tools**
   - Error debugging tools
   - Error simulation utilities
   - Error testing frameworks

---

## 10. Summary

### 10.1 Current State

**Strengths:**
- ✅ Clear Either monad pattern for expected errors
- ✅ Minimal, focused exception types
- ✅ Standard Dart exceptions (no custom boilerplate)

**Gaps:**
- ❌ No custom exception hierarchy
- ❌ Generic exceptions lack structure
- ❌ No global error handling
- ❌ Limited error monitoring hooks

### 10.2 Governance Status

**Phase 0 (Current):**
- Exception inventory complete
- Governance rules established
- Change workflow documented
- **No exception changes allowed**

**Post-Phase 0:**
- Exception changes via Issue → ADR → PR process
- Requires maintainer approval
- Breaking changes require MAJOR version

### 10.3 Next Steps

1. ✅ **Complete:** Exception inventory documented
2. 📋 **Next:** Stakeholder review of governance rules
3. 📋 **Phase 1:** Expand exception tests
4. 📋 **Phase 2:** Implement custom exception types
5. 📋 **Phase 3:** Add error monitoring patterns

---

**Document Status:** Draft - Awaiting Review  
**Owner:** Project Maintainer  
**Last Updated:** 2025-10-15

---

*For overall analysis, see [Repository Analysis](./REPOSITORY_ANALYSIS.md)*  
*For architecture decisions, see [ADR-000](./adr/ADR-000-context-and-high-level-decisions.md)*
