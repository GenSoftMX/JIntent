# Testing Strategy

**Status:** Draft | **Phase:** 1 - Foundation  
**Last Updated:** 2025-10-15  
**Target:** Phase 1: 70% coverage | Phase 2: 80% coverage

---

## Overview

This document defines the comprehensive testing strategy for JIntent, including:
- Test types and coverage targets
- Testing best practices
- CI/CD integration
- Cross-platform testing requirements

---

## Testing Pyramid

```
        /\
       /E2E\          End-to-End (Example Apps)
      /------\        ↑ Few, high-value scenarios
     /Integration\    Integration Tests
    /------------\    ↑ More, focused on component interaction
   /  Unit Tests  \   Unit Tests
  /----------------\  ↑ Many, fast, isolated
```

### Distribution Target

| Test Type | Count (Current) | Target Phase 1 | Target Phase 2 | Execution Time |
|-----------|----------------|----------------|----------------|----------------|
| Unit Tests | 9 tests | 50+ tests | 100+ tests | <10s |
| Integration Tests | 0 | 10+ tests | 30+ tests | <30s |
| E2E Tests (Example) | 0 | 3+ tests | 10+ tests | <2min |

---

## Test Coverage Targets

### Phase 1: Foundation (Current Phase)
- **File Coverage:** ≥70%
- **Line Coverage:** ≥70%
- **Branch Coverage:** ≥60%
- **Function Coverage:** ≥75%

### Phase 2: Maturity
- **File Coverage:** ≥80%
- **Line Coverage:** ≥80%
- **Branch Coverage:** ≥70%
- **Function Coverage:** ≥85%

### Phase 3: Excellence
- **File Coverage:** ≥90%
- **Line Coverage:** ≥85%
- **Branch Coverage:** ≥80%
- **Function Coverage:** ≥90%

### Coverage Exclusions

**Excluded from coverage:**
- Generated code (`*.g.dart`)
- Example app code (`example/`)
- Test utilities (`test/utils/`)
- Platform-specific glue code

**Rationale:** Focus coverage metrics on core library code that users depend on.

---

## Unit Tests

### Scope

Test individual classes, functions, and methods in isolation:
- `JController` intent handling
- `JState` immutability and equality
- `JUseCase` validation and execution
- `Either` monad operations
- `JEffect` creation and properties
- `JObserver` hook invocations
- Mapper transformations
- Exception handling

### Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('FeatureName', () {
    late Dependency dependency;
    late SystemUnderTest sut;

    setUp(() {
      dependency = MockDependency();
      sut = SystemUnderTest(dependency: dependency);
    });

    tearDown(() {
      sut.dispose();
    });

    test('should do X when Y', () {
      // Arrange
      final input = TestInput();
      
      // Act
      final result = sut.method(input);
      
      // Assert
      expect(result, expectedOutput);
    });

    test('should handle error when Z', () {
      // Arrange
      when(() => dependency.method()).thenThrow(Exception());
      
      // Act
      final result = sut.method();
      
      // Assert
      expect(result.isLeft, true);
    });
  });
}
```

### Best Practices

✅ **Do:**
- Test one behavior per test
- Use descriptive test names (`should X when Y`)
- Mock external dependencies
- Test both success and failure paths
- Test edge cases (null, empty, boundary values)
- Clean up resources in `tearDown`

❌ **Don't:**
- Test implementation details
- Share mutable state between tests
- Use sleeps or arbitrary waits
- Test framework code (test your usage of it)
- Skip tearDown (causes memory leaks in test suite)

### Current Coverage

**Status:** 9 test files covering ~30% of library

**Priority Areas for Phase 1:**
- [ ] Complete `JController` test coverage (all intent scenarios)
- [ ] `JEffect` stream and timeout tests
- [ ] `JUseCase` validator chain tests
- [ ] Error handling (`Either` monad edge cases)
- [ ] State equality and copyWith tests
- [ ] Observer hook invocation tests

---

## Integration Tests

### Scope

Test interaction between multiple components:
- Controller + Use Case + Repository
- Intent → State → Side Effect flow
- Observer integration with controller
- Effect handler integration
- Mapper chains
- Error propagation through layers

### Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('Integration: Login Flow', () {
    late LoginController controller;
    late MockAuthRepository repository;
    late List<JEffect> capturedEffects;

    setUp(() {
      repository = MockAuthRepository();
      controller = LoginController(repository: repository);
      capturedEffects = [];
      controller.sideEffects.listen(capturedEffects.add);
    });

    tearDown(() {
      controller.dispose();
    });

    test('should update state and emit success effect on successful login', () async {
      // Arrange
      when(() => repository.login(any(), any()))
          .thenAnswer((_) async => Right(User(id: '123')));
      
      // Act
      controller.dispatch(LoginIntent(email: 'test@example.com', password: 'pass'));
      await Future.delayed(Duration(milliseconds: 100)); // Wait for async
      
      // Assert
      expect(controller.state.isLoading, false);
      expect(controller.state.user, isNotNull);
      expect(capturedEffects.length, 1);
      expect(capturedEffects.first, isA<LoginSuccessEffect>());
    });
  });
}
```

### Best Practices

✅ **Do:**
- Test complete user journeys
- Verify state changes across multiple steps
- Capture and assert side effects
- Test error propagation
- Use realistic data
- Test async timing issues

❌ **Don't:**
- Mock everything (defeats integration test purpose)
- Test single components (that's unit testing)
- Rely on external services (use test doubles)

---

## End-to-End Tests (Example App)

### Scope

Test complete application flows using the example app:
- User interactions (tap, input, scroll)
- Navigation flows
- State persistence across screens
- Platform-specific behaviors

### Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jintent_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Counter App', () {
    testWidgets('should increment and decrement counter', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('0'), findsOneWidget);

      // Increment
      await tester.tap(find.byTooltip('Increment'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Decrement
      await tester.tap(find.byTooltip('Decrement'));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should show error dialog when reaching limit', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap decrement multiple times to trigger error
      for (int i = 0; i < 11; i++) {
        await tester.tap(find.byTooltip('Decrement'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Verify error dialog appears
      expect(find.text('Error'), findsOneWidget);
    });
  });
}
```

### Best Practices

✅ **Do:**
- Test critical user paths
- Test error scenarios
- Test on multiple platforms
- Use realistic delays (`pumpAndSettle`)
- Test accessibility

❌ **Don't:**
- Test every possible interaction (too slow)
- Rely on pixel-perfect UI matching
- Skip platform-specific testing

---

## Cross-Platform Testing

### Required Platform Coverage

| Platform | Unit Tests | Integration | E2E | CI/CD |
|----------|-----------|-------------|-----|-------|
| Linux | ✅ All | ✅ All | ✅ Headless | ✅ Primary |
| Web | ✅ All | ✅ All | ✅ Chrome | ✅ Secondary |
| Android | ✅ All | ✅ All | 🔄 Manual | 🔄 Phase 2 |
| iOS | ✅ All | ✅ All | 🔄 Manual | 🔄 Phase 2 |
| Windows | ✅ All | ⏭️ Phase 2 | ⏭️ Phase 2 | ⏭️ Phase 3 |
| macOS | ✅ All | ⏭️ Phase 2 | ⏭️ Phase 2 | ⏭️ Phase 3 |

**Rationale:**
- Unit tests run on all platforms (pure Dart, no platform-specific code)
- Integration tests primarily on Linux/Web (CI/CD constraints)
- E2E tests require device/emulator (expensive in CI)
- Manual testing for Android/iOS initially

### Platform-Specific Test Cases

**None currently** - JIntent is pure Dart with no platform-specific code.

If platform-specific behavior is added in future:
- Create `test/platform_specific/` directory
- Use conditional imports or platform checks
- Document platform differences in tests

---

## Performance Tests

### Benchmark Suite (Phase 2)

Location: `benchmark/`

**Tests:**
- Intent dispatch latency
- State transition overhead
- Side effect emission performance
- Memory allocation rate
- Throughput under load

**Execution:**
```bash
flutter run --profile benchmark/intent_benchmark.dart
```

**Regression Detection:**
- Run benchmarks on every release
- Compare against baseline
- Alert if performance degrades >10%

See [PERFORMANCE_TARGETS.md](./PERFORMANCE_TARGETS.md) for detailed SLOs.

---

## Security Tests (Phase 2)

### Input Validation Tests

Test use case validators reject malicious input:
- SQL injection patterns (if using DB)
- XSS patterns (if rendering user content)
- Path traversal patterns
- Oversized inputs (DoS protection)
- Null/empty/boundary values

### Memory Leak Tests

Verify proper resource cleanup:
- Controller disposal
- Effect stream subscription cleanup
- Observer registration/deregistration
- Large state object cleanup

### Dependency Vulnerability Tests

Automated in CI/CD:
- `dart pub audit` (when available)
- Dependabot security alerts
- OWASP dependency check

---

## Test Utilities and Helpers

### Mock Factories

```dart
// test/utils/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:jintent/jintent.dart';

@GenerateMocks([
  JUseCase,
  // Add more as needed
])
void main() {}
```

### Test Fixtures

```dart
// test/fixtures/states.dart
class TestStateFixtures {
  static CounterState counterInitial() => CounterState(counter: 0);
  static CounterState counterWithValue(int value) => CounterState(counter: value);
}
```

### Custom Matchers

```dart
// test/matchers/effect_matchers.dart
Matcher isNavigationEffect(String route) {
  return predicate<JEffect>(
    (e) => e is NavigateEffect && e.route == route,
    'is NavigateEffect to $route',
  );
}
```

---

## CI/CD Integration

### PR Pipeline

**Required checks before merge:**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Code coverage ≥70% (Phase 1 target)
- [ ] No new lint warnings
- [ ] `dart pub publish --dry-run` succeeds

**Configuration:** `.github/workflows/ci.yml`

### Coverage Reporting

**Tools:**
- **Codecov** (preferred) or **Coveralls**
- Coverage badge in README.md
- PR comments with coverage delta

**Commands:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # View locally
```

### Automated Regression Testing

**Phase 2:**
- Performance benchmarks in CI
- Memory leak detection
- Dependency vulnerability scanning

---

## Testing Best Practices

### General Principles

1. **Test Behavior, Not Implementation**
   - Focus on public API contracts
   - Don't test private methods directly
   - Refactor-safe tests

2. **Fast Tests**
   - Unit tests should run in milliseconds
   - Avoid network calls, file I/O
   - Use fakes/mocks for external dependencies

3. **Reliable Tests**
   - No flaky tests (retry on failure is a smell)
   - Deterministic (same input → same output)
   - Independent (can run in any order)

4. **Readable Tests**
   - Arrange-Act-Assert structure
   - Descriptive names
   - Minimal setup/teardown
   - Comments for complex scenarios only

### Testing Anti-Patterns

❌ **Avoid:**
- Testing framework internals (`StateNotifier` implementation details)
- Brittle UI tests (pixel-perfect matching)
- Copy-paste tests (use parameterized tests)
- Sleeping/arbitrary waits (use pumps/async properly)
- Skipping tearDown (memory leaks)
- Ignoring failing tests (fix or remove)

---

## Testing Roadmap

### Phase 1 (Current): Foundation
- [x] Define testing strategy (this document)
- [ ] Achieve 70% code coverage
- [ ] Add 50+ unit tests
- [ ] Add 10+ integration tests
- [ ] Set up CI/CD with coverage reporting
- [ ] Document testing best practices

### Phase 2: Maturity
- [ ] Achieve 80% code coverage
- [ ] Add performance benchmark suite
- [ ] Add security-focused tests
- [ ] Platform-specific E2E tests
- [ ] Automated regression testing
- [ ] Memory leak detection tests

### Phase 3: Excellence
- [ ] Achieve 90% code coverage
- [ ] Mutation testing
- [ ] Property-based testing (fuzzing)
- [ ] Chaos testing (fault injection)
- [ ] Community test contributions

---

## Contributing Tests

### Guidelines

When contributing code:
1. **Add tests for all new features**
2. **Update tests for bug fixes** (test should fail before fix, pass after)
3. **Maintain coverage** (don't decrease coverage %)
4. **Follow test structure** (Arrange-Act-Assert)
5. **Run tests locally** before pushing

### Test PR Checklist

- [ ] Tests added for new code
- [ ] All tests pass locally
- [ ] Coverage target met (≥70%)
- [ ] Test names are descriptive
- [ ] No flaky tests
- [ ] Tests are fast (<10s for unit tests)

---

## References

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito for Dart](https://pub.dev/packages/mockito)
- [ADR-010: Publication and CI/CD](./adr/ADR-010-publication-and-cicd.md)

---

**Document Owner:** JIntent Maintainers  
**Review Cycle:** After each phase completion  
**Next Review:** After Phase 1 (70% coverage achieved)
