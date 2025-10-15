# ADR-002: Testing Strategy

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 1 Foundation - Quality & Testing  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines the testing strategy, coverage targets, test types, and quality standards for JIntent to ensure reliability and maintainability.

---

## 2. Context

### 2.1 Background

**Current Testing State (v2.1.0):**
- 9 test files (485 lines)
- Basic unit tests for core components
- No integration tests
- No coverage reporting configured
- Manual testing for examples

**Test Files:**
```
test/
├── src/
│   ├── core/
│   │   ├── effects_test.dart
│   │   ├── jcontroller_test.dart
│   │   └── sequential_dispatcher_test.dart
│   ├── dev_tools/
│   │   └── logging_observer_test.dart
│   └── domain/
│       ├── either_test.dart
│       ├── mapper_test.dart
│       └── use_case_test.dart
```

**Testing Tools:**
- flutter_test (SDK)
- test ^1.21.0
- mockito ^5.4.0
- mocktail ^1.0.4

### 2.2 Problem Statement

**Current Gaps:**
- Unknown test coverage percentage
- No coverage enforcement
- Inconsistent test patterns
- Missing integration tests
- No performance/benchmark tests
- No CI/CD test automation

**Business Impact:**
- Risk of undetected regressions
- Reduced confidence in releases
- Harder to refactor safely
- Community contribution friction

---

## 3. Decision

### 3.1 Test Coverage Targets

**Decision:** Establish tiered coverage targets

**Phase 1 Target (Baseline):** 80% coverage
- Core components: 90%+
- Domain layer: 85%+
- DevTools/Utils: 70%+
- Examples: Not measured

**Phase 2 Target (Production-Ready):** 85% coverage
- Core components: 95%+
- Domain layer: 90%+
- DevTools/Utils: 80%+

**Phase 3+ Target (Excellence):** 90% coverage
- All components: 90%+

**Measurement:**
- Line coverage (primary metric)
- Branch coverage (secondary)
- Exclude generated code
- Exclude example apps

**Enforcement:**
- CI fails if coverage drops below target
- PR reviews check coverage delta
- Monthly coverage reports

### 3.2 Test Types & Pyramid

**Decision:** Follow standard testing pyramid

```
        /\
       /E2E\        10% - End-to-End (Example App)
      /------\
     /  Integ \     20% - Integration (Component)
    /----------\
   /   Unit     \   70% - Unit (Method/Class)
  /--------------\
```

**1. Unit Tests (70% of tests)**

**Purpose:** Test individual classes/methods in isolation

**Scope:**
- Single class behavior
- Method logic verification
- Edge cases and error conditions
- Mock all dependencies

**Examples:**
- `JController.setState()` updates state
- `Either.map()` transforms Right values
- `JEffect.complete()` completes future

**Tools:** flutter_test, mockito/mocktail

**2. Integration Tests (20% of tests)**

**Purpose:** Test component interactions

**Scope:**
- Multiple classes working together
- Controller + Intent + State flow
- Effect emission and handling
- Use case + mapper pipelines

**Examples:**
- Intent → Controller → State update flow
- Controller emits effect → Handler receives
- Use case validation → error handling

**Tools:** flutter_test, real instances (less mocking)

**3. End-to-End Tests (10% of tests)**

**Purpose:** Test complete user scenarios in example app

**Scope:**
- Full application flow
- UI interactions
- Real side effects
- Platform-specific behavior

**Examples:**
- User taps button → counter increments → UI updates
- Error dialog appears on failure
- Navigation flows work

**Tools:** flutter_test, integration_test package

### 3.3 Test Organization

**Decision:** Follow consistent structure

**Directory Structure:**
```
test/
├── src/                          # Mirrors lib/src/
│   ├── core/
│   │   ├── effects_test.dart
│   │   ├── jcontroller_test.dart
│   │   └── ...
│   ├── domain/
│   │   └── ...
│   └── devtools/
│       └── ...
├── integration/                  # Integration tests
│   ├── intent_flow_test.dart
│   └── effect_handling_test.dart
├── helpers/                      # Test utilities
│   ├── test_state.dart
│   └── test_intents.dart
└── fixtures/                     # Test data
    └── ...
```

**Naming Convention:**
- Test files: `<source_file>_test.dart`
- Test groups: `describe('<ClassName>')`
- Test cases: `it('<behavior>')`

### 3.4 Test Patterns & Standards

**Decision:** Adopt consistent testing patterns

**1. AAA Pattern (Arrange-Act-Assert)**

```dart
test('setState updates state and notifies listeners', () {
  // Arrange
  final controller = CounterController();
  var notified = false;
  controller.addListener(() => notified = true);
  
  // Act
  controller.setState(CounterState(count: 5));
  
  // Assert
  expect(controller.state.count, 5);
  expect(notified, true);
});
```

**2. Given-When-Then (BDD-style)**

```dart
test('emitAndWaitSideEffect returns result when completed', () async {
  // Given: A controller with an effect handler
  final controller = TestController();
  final handler = TestEffectHandler(controller);
  
  // When: An effect is emitted and awaited
  final future = controller.emitAndWaitSideEffect(TestEffect());
  await Future.delayed(Duration(milliseconds: 10));
  controller.sideEffects.first.then((effect) => effect.complete('result'));
  final result = await future;
  
  // Then: The result is returned
  expect(result, 'result');
});
```

**3. Test Doubles Strategy**

**Use Mocks:**
- External dependencies
- I/O operations (future support)
- Complex collaborators

**Use Real Objects:**
- Value objects (State, Intent)
- Simple utilities
- Domain logic

**Example:**
```dart
// Mock: External service
final mockService = MockDataService();
when(mockService.fetch()).thenReturn(Future.value(data));

// Real: State and intent
final state = CounterState(count: 0);
final intent = IncrementIntent();
```

### 3.5 Test Quality Standards

**Decision:** Enforce test quality requirements

**Requirements:**
1. **Fast:** Unit tests run in milliseconds
2. **Isolated:** Tests don't depend on each other
3. **Repeatable:** Same result every time
4. **Self-validating:** Clear pass/fail
5. **Timely:** Written with/before code

**Code Quality:**
- No commented-out tests
- No `skip: true` tests in main branch
- Clear test descriptions
- Minimal setup/teardown

**Coverage:**
- Test happy path
- Test error conditions
- Test edge cases (null, empty, boundary)
- Test concurrent scenarios (for controllers)

### 3.6 Testing Tools & Frameworks

**Decision:** Standardize on specific tools

**Unit Testing:**
- **flutter_test** (SDK) - Primary framework
- **test** ^1.21.0 - Additional utilities
- **mocktail** ^1.0.4 - Mocking (preferred over mockito for simplicity)

**Coverage:**
- **coverage** package
- `flutter test --coverage`
- **lcov** for reporting

**Integration Testing:**
- **integration_test** (SDK) - For example app
- Real device/emulator testing

**CI/CD:**
- GitHub Actions
- Automated test execution
- Coverage reporting (Codecov or similar)

### 3.7 Test Execution Strategy

**Decision:** Define when and how tests run

**Local Development:**
- Run affected tests frequently
- Run all tests before commit
- Use watch mode for TDD

**Commands:**
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/src/core/jcontroller_test.dart

# Watch mode (requires additional tool)
flutter test --watch
```

**CI/CD:**
- Run on every PR
- Run on main branch commits
- Run nightly for full suite + integration

**Performance:**
- Unit tests: < 5 minutes total
- Integration tests: < 10 minutes
- All tests: < 15 minutes

### 3.8 Test Documentation

**Decision:** Document test requirements and patterns

**Required Documentation:**
1. **Testing Guide** (`docs/TESTING.md`)
   - How to run tests
   - How to write tests
   - Test patterns and examples
   - Coverage requirements

2. **Test Comments**
   - Complex test setup explained
   - Non-obvious assertions documented
   - Reference to related tests

**Example:**
```dart
/// Tests that sequential intent dispatcher processes intents one-at-a-time.
/// 
/// This is a critical behavior to prevent race conditions in state updates.
/// Related: ADR-000 Decision D6 (Sequential Intent Processing)
test('sequential dispatcher waits for previous intent', () async {
  // ...
});
```

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Quality Assurance**
- Catch bugs before release
- Confidence in refactoring
- Regression prevention

✅ **Documentation**
- Tests as living documentation
- Usage examples
- Expected behavior clarity

✅ **Maintainability**
- Safe to modify code
- Clear breaking changes
- Faster debugging

✅ **Community Trust**
- Professional image
- Reliable releases
- Easier contributions

### 4.2 Negative Consequences

⚠️ **Development Overhead**
- Time to write tests
- Maintenance burden
- Learning curve

⚠️ **CI/CD Time**
- Longer build times
- More infrastructure needed
- Complexity increase

⚠️ **False Confidence**
- 100% coverage ≠ 100% correctness
- Tests can have bugs too
- Over-reliance risk

### 4.3 Mitigation Strategies

**For Development Overhead:**
- Test templates and generators
- Pair programming (write tests together)
- Focus on high-value tests first

**For CI/CD Time:**
- Parallel test execution
- Incremental coverage (not full suite every time)
- Cache dependencies

**For False Confidence:**
- Code reviews catch test issues
- Manual testing for UX
- Fuzzing for edge cases (future)

---

## 5. Implementation Plan

### Phase 1: Foundation (Current - Week 1-2)
- [x] Create ADR-002
- [ ] Add coverage collection to existing tests
- [ ] Measure baseline coverage
- [ ] Configure GitHub Actions for test execution
- [ ] Add coverage reporting (Codecov)

### Phase 2: Improvement (Week 3-4)
- [ ] Write missing unit tests to reach 80% coverage
- [ ] Create test helpers and utilities
- [ ] Document testing guide (docs/TESTING.md)
- [ ] Add integration test examples

### Phase 3: Enforcement (Week 5+)
- [ ] Enable coverage gates in CI
- [ ] Add PR coverage diff reporting
- [ ] Create test templates
- [ ] Community testing guidelines

---

## 6. Examples

### Example 1: Unit Test for JController

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

class CounterState extends JState {
  final int count;
  CounterState({required this.count});
  
  @override
  List<Object?> get props => [count];
  
  CounterState copyWith({int? count}) {
    return CounterState(count: count ?? this.count);
  }
}

class IncrementIntent extends JIntent {}

class CounterController extends JController<CounterState, JIntent> {
  CounterController() : super(CounterState(count: 0));
  
  @override
  void handleIntent(JIntent intent) {
    if (intent is IncrementIntent) {
      setState(state.copyWith(count: state.count + 1));
    }
  }
}

void main() {
  group('CounterController', () {
    late CounterController controller;
    
    setUp(() {
      controller = CounterController();
    });
    
    tearDown(() {
      controller.dispose();
    });
    
    test('initial state has count 0', () {
      expect(controller.state.count, 0);
    });
    
    test('IncrementIntent increases count by 1', () {
      // Arrange
      expect(controller.state.count, 0);
      
      // Act
      controller.intent(IncrementIntent());
      
      // Assert
      expect(controller.state.count, 1);
    });
    
    test('multiple IncrementIntent calls increase count sequentially', () async {
      // Act
      controller.intent(IncrementIntent());
      controller.intent(IncrementIntent());
      controller.intent(IncrementIntent());
      
      // Wait for sequential processing
      await Future.delayed(Duration(milliseconds: 100));
      
      // Assert
      expect(controller.state.count, 3);
    });
  });
}
```

### Example 2: Integration Test for Effect Handling

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

class ShowSnackbarEffect extends JFireAndForgetEffect {
  final String message;
  ShowSnackbarEffect(this.message) : super(category: 'ui');
}

class TestController extends JController<CounterState, JIntent> {
  TestController() : super(CounterState(count: 0));
  
  @override
  void handleIntent(JIntent intent) {
    if (intent is IncrementIntent) {
      setState(state.copyWith(count: state.count + 1));
      emitSideEffect(ShowSnackbarEffect('Count: ${state.count + 1}'));
    }
  }
}

void main() {
  group('Effect Handling Integration', () {
    testWidgets('controller emits effect and handler receives it', 
        (tester) async {
      // Arrange
      final controller = TestController();
      String? receivedMessage;
      
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          controller.sideEffects.listen((effect) {
            if (effect is ShowSnackbarEffect) {
              receivedMessage = effect.message;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(effect.message)),
              );
            }
          });
          return Container();
        }),
      ));
      
      // Act
      controller.intent(IncrementIntent());
      await tester.pump();
      
      // Assert
      expect(receivedMessage, 'Count: 1');
      expect(find.text('Count: 1'), findsOneWidget);
    });
  });
}
```

### Example 3: Coverage Report Goal

```
lib/src/core/jcontroller.dart        95% (57/60 lines)
lib/src/core/jintent.dart           100% (12/12 lines)
lib/src/core/jstate.dart            100% (8/8 lines)
lib/src/core/effects/jeffect.dart    90% (45/50 lines)
lib/src/domain/either.dart           95% (38/40 lines)
lib/src/domain/use_case.dart         85% (34/40 lines)
----------------------------------------
TOTAL                                90% (194/210 lines)
```

---

## 7. Alternatives Considered

### Alternative 1: No Coverage Requirements

**Approach:** Write tests but don't enforce coverage

**Pros:**
- Flexibility
- Faster development
- No coverage tool overhead

**Cons:**
- Coverage will drop over time
- Hard to catch gaps
- Inconsistent quality

**Decision:** Rejected - Professionalism requires standards

### Alternative 2: 100% Coverage Requirement

**Approach:** Mandate 100% line coverage

**Pros:**
- Complete coverage
- No gaps
- Maximum confidence

**Cons:**
- Diminishing returns (testing trivial code)
- Slows development significantly
- False sense of security

**Decision:** Rejected - 90% is more pragmatic

### Alternative 3: Only Manual Testing

**Approach:** Test example app manually before releases

**Pros:**
- Catches UX issues
- No test code to maintain
- Faster initial development

**Cons:**
- Not scalable
- No regression detection
- Hard to test edge cases
- Not repeatable

**Decision:** Rejected - Unacceptable for quality library

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Tests slow down development | Medium | High | Focus on fast unit tests, parallel CI |
| Coverage gaming (meaningless tests) | Medium | Medium | Code review enforcement, test quality checks |
| Flaky tests | High | Low | Strict test isolation, no time dependencies |
| Test maintenance burden | Medium | Medium | Keep tests simple, refactor regularly |
| Coverage tool overhead | Low | Low | Use lightweight tools, cache results |

---

## 9. Open Questions

### Q1: Integration Test Frequency?

**Question:** How often should we run integration tests?

**Options:**
- Every commit (slow)
- On PR only (balanced)
- Nightly (fast but delayed feedback)

**Answer:** On PR + nightly for full suite

### Q2: Test on All Platforms?

**Question:** Should CI test on Android, iOS, Web, Desktop?

**Answer:** Phase 1: Linux/Android only. Phase 2: Add iOS. Phase 3: Add Web/Desktop.

### Q3: Performance Benchmarks?

**Question:** Should we track performance metrics in tests?

**Answer:** Yes, see ADR-009 for performance benchmark strategy.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md) - Section 5.2 Reliability
- [Repository Analysis](../REPOSITORY_ANALYSIS.md) - Section 9 Testing Baseline
- [Executive Summary](../EXECUTIVE_SUMMARY.md) - Section 3 Critical Gaps

### External Resources
- [Effective Testing](https://dart.dev/guides/testing)
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)
- [FIRST Principles](https://pragprog.com/magazines/2012-01/unit-tests-are-first)

### Related ADRs
- ADR-003: CI/CD Architecture (test automation)
- ADR-009: Performance Targets & Benchmarks (performance testing)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] Coverage targets defined
- [ ] Test types clearly specified
- [ ] Test pyramid established
- [ ] Quality standards documented
- [ ] Implementation plan provided
- [ ] Examples included

### Next Steps After Approval

1. Mark ADR-002 as **Accepted**
2. Measure current coverage baseline
3. Configure CI/CD test execution (see ADR-003)
4. Create testing guide (docs/TESTING.md)
5. Begin writing missing tests
6. Enable coverage gates

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes testing strategy and quality standards for JIntent. It builds upon the foundation set in ADR-000.*
