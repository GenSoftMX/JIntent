# JIntent Testing Baseline & Strategy

**Version:** 2.1.0  
**Date:** 2025-10-14  
**Purpose:** Document current testing posture and define quality targets

---

## 1. Current Test Coverage

### 1.1 Test File Inventory

**Total Test Files:** 9

```
test/src/
├── core/                                   # Core component tests
│   ├── jcontroller_test.dart              ✅ Dispatchers tested
│   ├── jeffect_test.dart                  ✅ Effect lifecycle tested
│   ├── jintent_helpers_test.dart          ✅ Helper methods tested
│   ├── jmeta_data_test.dart               ✅ Metadata interface tested
│   └── jstate_test.dart                   ✅ State equality tested
├── dev_tools/                             # Dev tools tests
│   ├── jobserver_test.dart                ✅ Observer hooks tested
│   └── logging_observer_test.dart         ✅ Logging setup tested
└── domain/                                # Domain pattern tests
    ├── either_test.dart                   ✅ Either monad tested
    └── use_case_test.dart                 ✅ UseCase pattern tested
```

### 1.2 Coverage Analysis (Manual)

**Estimated Coverage by Component:**

| Component | Test File | Coverage (Est.) | Lines Tested | Total Lines | Notes |
|-----------|-----------|-----------------|--------------|-------------|-------|
| **Core** | | | | | |
| JController | jcontroller_test.dart | ~60% | Basic lifecycle | ~155 lines | Missing: error paths, disposal edge cases |
| JIntent | (indirect) | ~70% | Via controller tests | ~50 lines | Missing: error in onInvoke |
| JState | jstate_test.dart | ~95% | copyWith, equality | ~41 lines | Well covered |
| JEffect | jeffect_test.dart | ~80% | Lifecycle, completion | ~75 lines | Missing: timeout edge cases |
| **Dispatchers** | | | | | |
| JDefaultIntentDispatcher | jcontroller_test.dart | ~75% | Basic dispatch | ~20 lines | Basic happy path only |
| JSequentialIntentDispatcher | (untested) | ~0% | None | ~67 lines | ❌ Critical gap |
| LoggingDispatcher | jcontroller_test.dart | ~70% | Log verification | ~35 lines | Basic coverage |
| **Dev Tools** | | | | | |
| JObserver | jobserver_test.dart | ~90% | All hooks tested | ~35 lines | Well covered |
| enableLoggingObserver | logging_observer_test.dart | ~85% | Setup tested | ~15 lines | Good coverage |
| **Domain** | | | | | |
| Either | either_test.dart | ~90% | Left, Right, fold | ~50 lines | Well covered |
| UseCase | use_case_test.dart | ~85% | Call pattern | ~30 lines | Good coverage |
| **Effects** | | | | | |
| JEffectsConfig | (untested) | ~0% | None | ~30 lines | ❌ Gap |
| JSideEffectHandler | (untested) | ~0% | None | ~100 lines | ❌ Widget test gap |
| **Utils** | | | | | |
| All utils | (untested) | ~0% | None | ~200 lines | ⚠️ Optional utilities |

**Overall Estimated Coverage:** ~55-60% (core components only)

### 1.3 Critical Coverage Gaps

**High Priority (Core Functionality):**
1. ❌ `JSequentialIntentDispatcher` - No tests (67 lines, default dispatcher)
2. ❌ `JEffectsConfig` - No tests (global config, Isolate safety concerns)
3. ❌ `JSideEffectHandler` widget - No tests (UI integration)
4. ⚠️ Error paths in `JController` (disposal during intent, mount checks)
5. ⚠️ Timeout behavior in `JEffect` (completeError on timeout)

**Medium Priority (Quality Assurance):**
6. ⚠️ Intent error propagation (completer.completeError)
7. ⚠️ State update edge cases (update during unmounted controller)
8. ⚠️ Effect stream lifecycle (multiple listeners, late subscription)

**Low Priority (Nice to Have):**
9. Widget tests for example app patterns
10. Integration tests (full UI → Intent → State → Render flow)
11. Performance tests (throughput, latency)

---

## 2. Test Quality Assessment

### 2.1 Test Patterns

**Current Patterns:**
```dart
// ✅ Good: Mock-based unit tests
class MockIntent extends Mock implements JIntent {}
when(() => intent.run(controller)).thenAnswer((_) async {});

// ✅ Good: Observer validation
JObserver.onIntentDispatched = (intent) {
  expect(intent, isA<MyIntent>());
};

// ✅ Good: Cleanup in tearDown
tearDown(() {
  JObserver.onIntentDispatched = null;
  JObserver.onStateChanged = null;
});
```

**Missing Patterns:**
```dart
// ❌ Missing: Widget tests
testWidgets('Controller updates widget on state change', (tester) async {
  // Test UI reactivity
});

// ❌ Missing: Integration tests
testWidgets('Full flow: Intent → State → Effect → UI', (tester) async {
  // Test end-to-end flow
});

// ❌ Missing: Performance tests
test('Sequential dispatcher handles 1000 intents in <1s', () async {
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    await controller.intent(NoOpIntent());
  }
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

### 2.2 Test Coverage Tools

**Current Setup:**
- ❌ No LCOV coverage collection
- ❌ No coverage reporting in CI
- ❌ No coverage badge in README
- ❌ No coverage threshold enforcement

**Recommended Setup:**
```yaml
# test/coverage.sh
#!/bin/bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 3. Baseline Metrics (Current State)

### 3.1 Test Execution

**Total Test Count:** ~35-40 tests (across 9 files)

**Test Speed:**
```bash
$ flutter test
# Estimated time: 3-5 seconds (all tests)
```

**Test Reliability:**
- ✅ All tests pass consistently
- ✅ No flaky tests observed
- ✅ Proper cleanup (no state leakage between tests)

### 3.2 Code Quality

**Lint Results:**
```bash
$ flutter analyze
# Expected: 0 issues (clean)
```

**Test Lint:**
- ✅ Uses `flutter_test` and `test` packages
- ✅ Modern mocking with `mocktail`
- ✅ Consistent naming conventions
- ⚠️ No test grouping by speed (fast vs slow)

---

## 4. Testing Strategy

### 4.1 Test Pyramid

**Target Distribution:**
```
      /\
     /  \      Integration (10%)  - Full flow tests
    /____\     Widget (20%)      - UI component tests
   /      \    Unit (70%)        - Logic tests
  /________\
```

**Current Distribution:**
```
      /\
     /  \      Integration (0%)   ❌
    /____\     Widget (0%)        ❌
   /      \    Unit (100%)        ✅
  /________\
```

**Gap:** Over-reliance on unit tests, no UI validation

### 4.2 Test Categories

#### 4.2.1 Unit Tests (Current: ✅ Good)

**Scope:** Test individual classes in isolation

**Examples:**
- State equality and copyWith
- Intent logic (business rules)
- Dispatcher queueing
- Effect completion

**Target Coverage:** ≥85% for core components

#### 4.2.2 Widget Tests (Current: ❌ None)

**Scope:** Test UI components with state changes

**Needed Tests:**
1. `JSideEffectHandler` routes effects correctly
2. Controller state updates trigger widget rebuilds
3. Effect listener widget lifecycle
4. Example app counter increments UI

**Target:** ≥80% of widgets tested

#### 4.2.3 Integration Tests (Current: ❌ None)

**Scope:** Test full flow from UI interaction to state update

**Needed Tests:**
1. Button press → Intent → State update → UI reflects change
2. Side effect → Dialog shown → Result returned → State updated
3. Error in intent → Error state → Error UI shown

**Target:** ≥3 critical flows tested

#### 4.2.4 Performance Tests (Current: ❌ None)

**Scope:** Validate performance requirements

**Needed Tests:**
1. Sequential dispatcher throughput (1000 intents)
2. State update latency (intent → notify)
3. Memory usage (1000 state snapshots)
4. Rebuild count (unnecessary rebuilds)

**Target:** Establish baseline, prevent regressions

---

## 5. Quality Targets (Gate A1 Agreement)

### 5.1 Coverage Targets

| Component | Current (Est.) | Target | Priority |
|-----------|----------------|--------|----------|
| **Core** | 65% | ≥85% | 🔴 High |
| JController | 60% | ≥90% | 🔴 High |
| JIntent | 70% | ≥85% | 🔴 High |
| JState | 95% | ≥95% | ✅ Met |
| JEffect | 80% | ≥85% | 🟡 Medium |
| **Dispatchers** | 40% | ≥85% | 🔴 High |
| JSequentialIntentDispatcher | 0% | ≥90% | 🔴 Critical |
| JDefaultIntentDispatcher | 75% | ≥85% | 🟡 Medium |
| **Dev Tools** | 85% | ≥80% | ✅ Met |
| **Widgets** | 0% | ≥80% | 🔴 High |
| **Integration** | 0% | ≥3 flows | 🔴 High |

### 5.2 Performance Targets

**Intent Processing:**
- Throughput: ≥1000 intents/sec (sequential)
- Latency: p50 <5ms, p95 <20ms, p99 <50ms (intent → notify)

**Memory:**
- Overhead: <10KB per controller
- State history: <10MB for 1000 snapshots

**Rebuild Efficiency:**
- Unnecessary rebuilds: <10% in test scenarios

### 5.3 Quality Targets

**Code Quality:**
- Lint warnings: 0
- Test failures: 0
- Public API documentation: 100%

**Release Quality:**
- All tests pass
- Coverage ≥85% (core)
- Performance tests pass (no regressions)
- CHANGELOG updated
- Pub.dev score: 160/160

---

## 6. Test Plan (Priority Matrix)

### Phase 1: Critical Gaps (Week 1)
**Priority:** 🔴 Blocker

1. ✅ Add unit tests for `JSequentialIntentDispatcher`
   - Queue behavior (FIFO)
   - Error isolation
   - Concurrent dispatch handling

2. ✅ Add unit tests for `JEffectsConfig`
   - Timeout configuration
   - ID generation
   - Category resolution

3. ✅ Add error path tests for `JController`
   - Disposal during intent
   - Update during unmounted
   - Exception in onInit

### Phase 2: Widget Tests (Week 2)
**Priority:** 🔴 High

1. ✅ Add widget tests for `JSideEffectHandler`
   - Effect routing
   - Handler execution
   - BuildContext safety

2. ✅ Add widget tests for example app
   - Counter increments UI
   - Effect shows dialog
   - State persists

### Phase 3: Integration Tests (Week 3)
**Priority:** 🟡 Medium

1. ✅ Add integration test: Counter flow
   - Button → Intent → State → UI update

2. ✅ Add integration test: Side effect flow
   - Intent → Effect → Dialog → Result → State

3. ✅ Add integration test: Error flow
   - Invalid action → Error → Error UI

### Phase 4: Performance Tests (Week 4)
**Priority:** 🟡 Medium

1. ✅ Add performance test: Throughput
2. ✅ Add performance test: Latency
3. ✅ Add performance test: Memory
4. ✅ Document baselines

### Phase 5: Infrastructure (Week 5)
**Priority:** 🟢 Low (but important)

1. ✅ Configure LCOV coverage collection
2. ✅ Add GitHub Actions CI
3. ✅ Add coverage badge to README
4. ✅ Enforce coverage thresholds

---

## 7. Test Case Matrix

### 7.1 Happy Paths (Should Pass)

| Test Case | Current Status | Priority |
|-----------|---------------|----------|
| Intent dispatched → state updated | ✅ Tested | - |
| State equality via Equatable | ✅ Tested | - |
| Effect completed with value | ✅ Tested | - |
| Observer hooks fire correctly | ✅ Tested | - |
| Logging dispatcher logs | ✅ Tested | - |
| Sequential dispatcher queues intents | ❌ Missing | 🔴 High |
| Side effect handler routes effects | ❌ Missing | 🔴 High |

### 7.2 Edge Cases (Should Handle)

| Test Case | Current Status | Priority |
|-----------|---------------|----------|
| Intent throws exception | ⚠️ Partial | 🔴 High |
| Effect times out | ❌ Missing | 🔴 High |
| Controller disposed during intent | ❌ Missing | 🔴 High |
| Update on unmounted controller | ⚠️ Partial | 🟡 Medium |
| Multiple simultaneous intents | ❌ Missing | 🟡 Medium |
| Effect with no listeners | ❌ Missing | 🟡 Medium |
| Observer hook throws exception | ❌ Missing | 🟢 Low |

### 7.3 Error Paths (Should Fail Gracefully)

| Test Case | Current Status | Priority |
|-----------|---------------|----------|
| Invalid state in copyWith | ⚠️ Manual | 🟡 Medium |
| Null effect result | ❌ Missing | 🟡 Medium |
| Sequential queue overflow (DoS) | ❌ Missing | 🟢 Low |
| Effect completeError twice | ⚠️ Idempotent | 🟢 Low |

---

## 8. Test Automation

### 8.1 CI/CD Pipeline (Proposed)

**GitHub Actions Workflow:**
```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: dart pub global activate coverage
      - run: genhtml coverage/lcov.info -o coverage/html
      - uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

### 8.2 Pre-commit Checks

**Recommended:**
```bash
# .git/hooks/pre-commit
#!/bin/bash
flutter analyze || exit 1
flutter test || exit 1
echo "✅ All checks passed"
```

---

## 9. Success Criteria (Gate A1)

**For Gate A1 Approval:**
- [x] Baseline documented (this document)
- [x] Critical gaps identified
- [x] Test plan prioritized
- [x] Coverage targets defined
- [ ] Agreement from maintainers on targets

**For Gate A3 (Implementation Complete):**
- [ ] Core coverage ≥85%
- [ ] All critical tests pass
- [ ] Sequential dispatcher tested
- [ ] Widget tests added
- [ ] Integration tests (≥3) added
- [ ] CI/CD configured
- [ ] Coverage reporting enabled

---

## 10. Maintenance

**Review Frequency:**
- **Weekly:** During active development
- **Per Release:** Update baseline metrics
- **Quarterly:** Review and adjust targets

**Document Owner:** QA / Development Team  
**Next Review:** Upon completion of Phase 1 tests

---

**Document Status:** ✅ Complete  
**Approval Required:** Maintainer review for Gate A1
