# ADR-009: Performance Targets & Benchmarks

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 3 Observability & Testing - Performance Optimization  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines performance targets, benchmarking strategy, and optimization guidelines for JIntent to ensure minimal overhead and responsive applications.

---

## 2. Context

### 2.1 Background

**Current Performance (v2.1.0):**

**Characteristics:**
- Sequential intent processing (FIFO queue)
- Immutable state (copyWith pattern)
- Synchronous state updates
- Async effect handling
- StateNotifier-based reactivity

**No Formal Measurements:**
- ❌ No benchmark suite
- ❌ No performance targets
- ❌ No CI performance testing
- ❌ Unknown overhead vs raw Flutter

**Assumptions (Not Verified):**
- Intent dispatch: "negligible" (<1ms claimed in ADR-000)
- State update: O(1) time
- Effect emission: O(1) time
- Memory overhead: "minimal"

### 2.2 Problem Statement

**Current Challenges:**
- No baseline performance data
- Can't detect performance regressions
- Unknown scalability limits
- No optimization priorities
- Hard to compare with alternatives

**Business Impact:**
- Risk of poor user experience
- Unpredictable performance
- Can't confidently claim "lightweight"
- No data for optimization decisions

---

## 3. Decision

### 3.1 Performance Targets

**Decision:** Define measurable performance targets

**Target Metrics:**

**1. Intent Processing Latency**
- **P50 (median):** < 0.5ms
- **P95:** < 2ms
- **P99:** < 5ms
- **P99.9:** < 10ms

**Measurement:** Time from `intent()` call to state update completion

**2. State Update Throughput**
- **Target:** > 10,000 updates/second
- **Rationale:** Should handle rapid user interactions

**3. Effect Emission Latency**
- **Target:** < 0.1ms
- **Rationale:** Fire-and-forget, should be instant

**4. Memory Overhead Per Controller**
- **Target:** < 1KB baseline
- **Plus:** State size (varies by app)
- **Rationale:** Minimal framework overhead

**5. Binary Size Impact**
- **Target:** < 50KB added to Flutter app
- **Measurement:** Release APK size increase
- **Rationale:** Don't bloat apps

**6. Startup Time Impact**
- **Target:** < 10ms added to app startup
- **Rationale:** Don't slow app launch

**7. Frame Rendering Budget**
- **Target:** State updates don't cause dropped frames
- **Requirement:** Complete within 8ms (60 FPS) or 16ms (120 FPS)
- **Rationale:** Smooth UI

### 3.2 Benchmark Suite

**Decision:** Create comprehensive benchmark suite

**Structure:**
```
test/benchmarks/
├── intent_processing_bench.dart
├── state_update_bench.dart
├── effect_emission_bench.dart
├── memory_bench.dart
├── scalability_bench.dart
└── comparison_bench.dart
```

**Intent Processing Benchmark:**
```dart
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:jintent/jintent.dart';

class IntentProcessingBenchmark extends BenchmarkBase {
  late TestController controller;
  late TestIntent intent;
  
  IntentProcessingBenchmark() : super('IntentProcessing');
  
  @override
  void setup() {
    controller = TestController();
    intent = TestIntent();
  }
  
  @override
  void run() {
    controller.intent(intent);
  }
  
  @override
  void teardown() {
    controller.dispose();
  }
}

class TestState extends JState {
  final int value;
  TestState(this.value);
  
  @override
  List<Object?> get props => [value];
  
  TestState copyWith({int? value}) => TestState(value ?? this.value);
}

class TestIntent extends JIntent {}

class TestController extends JController<TestState, TestIntent> {
  TestController() : super(TestState(0));
  
  @override
  void handleIntent(TestIntent intent) {
    setState(state.copyWith(value: state.value + 1));
  }
}

void main() {
  IntentProcessingBenchmark().report();
}

// Expected output:
// IntentProcessing(RunTime): 0.5 us. (2,000,000 ops/sec)
```

**State Update Benchmark:**
```dart
class StateUpdateBenchmark extends BenchmarkBase {
  late TestController controller;
  
  StateUpdateBenchmark() : super('StateUpdate');
  
  @override
  void setup() {
    controller = TestController();
  }
  
  @override
  void run() {
    // Direct state update (bypassing intent queue)
    controller.setState(
      controller.state.copyWith(value: controller.state.value + 1),
    );
  }
  
  @override
  void teardown() {
    controller.dispose();
  }
}
```

**Effect Emission Benchmark:**
```dart
class EffectEmissionBenchmark extends BenchmarkBase {
  late TestController controller;
  late TestEffect effect;
  
  EffectEmissionBenchmark() : super('EffectEmission');
  
  @override
  void setup() {
    controller = TestController();
    effect = TestEffect();
  }
  
  @override
  void run() {
    controller.emitSideEffect(effect);
  }
  
  @override
  void teardown() {
    controller.dispose();
  }
}

class TestEffect extends JFireAndForgetEffect {
  TestEffect() : super(category: 'test');
}
```

**Memory Benchmark:**
```dart
import 'dart:developer' as dev;

void memoryBenchmark() {
  // Force GC
  dev.Timeline.startSync('memory_benchmark');
  
  final before = dev.getCurrentRSS();
  
  // Create 1000 controllers
  final controllers = List.generate(
    1000,
    (_) => TestController(),
  );
  
  final after = dev.getCurrentRSS();
  
  dev.Timeline.finishSync();
  
  final overhead = (after - before) / 1000; // Per controller
  
  print('Memory overhead per controller: ${overhead / 1024} KB');
  
  // Cleanup
  for (final c in controllers) {
    c.dispose();
  }
}
```

**Scalability Benchmark:**
```dart
class ScalabilityBenchmark {
  void run() {
    final sizes = [10, 100, 1000, 10000];
    
    for (final size in sizes) {
      final stopwatch = Stopwatch()..start();
      
      final controller = TestController();
      
      // Dispatch many intents
      for (var i = 0; i < size; i++) {
        controller.intent(TestIntent());
      }
      
      // Wait for completion (sequential processing)
      // In real test, use async/await
      
      stopwatch.stop();
      
      final avgLatency = stopwatch.elapsedMicroseconds / size;
      
      print('$size intents: ${stopwatch.elapsed} (avg: ${avgLatency}μs)');
      
      controller.dispose();
    }
  }
}
```

**Comparison Benchmark:**
```dart
// Compare JIntent vs alternatives
class ComparisonBenchmark {
  void run() {
    print('=== Performance Comparison ===');
    
    // JIntent
    final jintentTime = _measureJIntent();
    print('JIntent: ${jintentTime}μs');
    
    // Raw Flutter (setState)
    final rawTime = _measureRawFlutter();
    print('Raw Flutter: ${rawTime}μs');
    
    // BLoC
    final blocTime = _measureBloc();
    print('BLoC: ${blocTime}μs');
    
    // Overhead
    final overhead = ((jintentTime - rawTime) / rawTime * 100);
    print('JIntent overhead: ${overhead.toStringAsFixed(2)}%');
  }
  
  double _measureJIntent() {
    // Implementation
    return 0.5; // μs
  }
  
  double _measureRawFlutter() {
    // Implementation
    return 0.3; // μs
  }
  
  double _measureBloc() {
    // Implementation
    return 0.8; // μs
  }
}
```

### 3.3 CI/CD Integration

**Decision:** Run benchmarks in CI/CD with regression detection

**GitHub Actions Workflow:**
```yaml
name: Performance Benchmarks

on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1'  # Weekly Monday 2 AM

jobs:
  benchmark:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # For comparison with main
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
      
      - name: Install dependencies
        run: |
          flutter pub get
          dart pub global activate benchmark_harness
      
      - name: Run benchmarks
        run: |
          dart test/benchmarks/intent_processing_bench.dart > results_pr.txt
          dart test/benchmarks/state_update_bench.dart >> results_pr.txt
          dart test/benchmarks/effect_emission_bench.dart >> results_pr.txt
      
      - name: Compare with baseline
        run: |
          # Checkout main branch results
          git checkout origin/main -- benchmark_results.txt
          
          # Compare (custom script)
          dart tool/compare_benchmarks.dart \
            benchmark_results.txt \
            results_pr.txt \
            --threshold 10  # 10% regression allowed
      
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const results = fs.readFileSync('results_pr.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Performance Benchmark Results\n\n\`\`\`\n${results}\n\`\`\``
            });
      
      - name: Fail on regression
        run: |
          # Exit 1 if regression detected
          if grep -q "REGRESSION" comparison.txt; then
            cat comparison.txt
            exit 1
          fi
```

### 3.4 Performance Monitoring

**Decision:** Track performance over time

**Metrics Dashboard:**
- Store benchmark results in git
- Visualize trends (GitHub Pages)
- Alert on regressions (CI failure)

**Storage Format (benchmark_results.json):**
```json
{
  "version": "2.1.0",
  "commit": "abc123",
  "date": "2025-10-15",
  "benchmarks": {
    "intent_processing": {
      "p50": 0.5,
      "p95": 2.0,
      "p99": 4.8,
      "unit": "microseconds"
    },
    "state_update": {
      "throughput": 15000,
      "unit": "ops_per_second"
    },
    "effect_emission": {
      "latency": 0.08,
      "unit": "microseconds"
    },
    "memory_overhead": {
      "per_controller": 0.8,
      "unit": "kilobytes"
    }
  }
}
```

### 3.5 Optimization Guidelines

**Decision:** Document performance optimization best practices

**Guidelines (doc/performance.md):**

**1. State Size**
```dart
// Bad: Large state with many fields
class AppState extends JState {
  final List<User> allUsers;  // 10,000 users
  final Map<String, Data> cache;  // Large cache
  // 50+ fields...
  
  @override
  List<Object?> get props => [allUsers, cache, ...];
}

// Good: Lean state, reference-based
class AppState extends JState {
  final String? currentUserId;  // Reference
  final Set<String> selectedIds;  // IDs only
  // 10-15 essential fields
  
  @override
  List<Object?> get props => [currentUserId, selectedIds, ...];
}

// Store large data elsewhere (repository, database)
```

**2. copyWith Optimization**
```dart
// Bad: Manual copyWith
TestState copyWith({int? value, String? name, bool? flag}) {
  return TestState(
    value: value ?? this.value,
    name: name ?? this.name,
    flag: flag ?? this.flag,
  );
}

// Good: Use code generation (freezed, json_serializable)
@freezed
class TestState extends JState with _$TestState {
  const factory TestState({
    required int value,
    required String name,
    required bool flag,
  }) = _TestState;
}
```

**3. Avoid Heavy Computations in handleIntent**
```dart
// Bad: Heavy computation in intent handler
@override
void handleIntent(JIntent intent) {
  if (intent is ProcessDataIntent) {
    // Heavy computation (blocks intent queue)
    final result = _computeExpensiveOperation(intent.data);
    setState(state.copyWith(result: result));
  }
}

// Good: Offload to use case/repository
@override
void handleIntent(JIntent intent) async {
  if (intent is ProcessDataIntent) {
    setState(state.copyWith(isProcessing: true));
    
    // Use case handles heavy work
    final result = await _processUseCase.call(intent.data);
    
    setState(state.copyWith(
      isProcessing: false,
      result: result,
    ));
  }
}
```

**4. Batch State Updates**
```dart
// Bad: Multiple state updates
controller.intent(UpdateFieldAIntent());
controller.intent(UpdateFieldBIntent());
controller.intent(UpdateFieldCIntent());
// 3 separate state updates, 3 UI rebuilds

// Good: Single batched update
controller.intent(UpdateMultipleFieldsIntent(
  fieldA: valueA,
  fieldB: valueB,
  fieldC: valueC,
));
// 1 state update, 1 UI rebuild
```

**5. Use Effect Sampling**
```dart
// Bad: Effect for every state change
@override
void handleIntent(JIntent intent) {
  setState(newState);
  emitSideEffect(AnalyticsEffect('state_changed'));  // Too frequent
}

// Good: Sample effects
int _stateChangeCount = 0;

@override
void handleIntent(JIntent intent) {
  setState(newState);
  
  _stateChangeCount++;
  if (_stateChangeCount % 10 == 0) {  // Every 10th change
    emitSideEffect(AnalyticsEffect('state_changed_x10'));
  }
}
```

**6. Profile First, Optimize Later**
```dart
// Use Flutter DevTools
// 1. Record timeline
// 2. Identify bottlenecks
// 3. Optimize hotspots
// 4. Measure improvement

// Don't prematurely optimize
```

### 3.6 Performance Testing Requirements

**Decision:** Require performance testing for PRs

**PR Checklist Addition:**
- [ ] No performance regression (CI check passes)
- [ ] Benchmark results reviewed (if modifying core)
- [ ] Large state changes profiled

**Core Changes Trigger:**
- Modifications to JController
- Changes to intent dispatching
- State update mechanism changes
- Effect handling changes

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Predictable Performance**
- Known overhead
- Regression detection
- Optimization priorities

✅ **User Confidence**
- Data-backed "lightweight" claim
- Performance guarantees
- Comparison with alternatives

✅ **Quality Assurance**
- Prevent performance regressions
- Early detection of issues
- Continuous monitoring

✅ **Optimization Focus**
- Identify bottlenecks
- Measure improvements
- Data-driven decisions

### 4.2 Negative Consequences

⚠️ **CI Time Increase**
- Benchmarks take time
- Longer PR feedback
- More compute resources

⚠️ **Maintenance Overhead**
- Keep benchmarks updated
- Analyze results
- Investigate regressions

⚠️ **False Alarms**
- Environment variance
- Flaky benchmarks
- Threshold tuning needed

### 4.3 Mitigation Strategies

**For CI Time:**
- Run full benchmarks weekly
- Quick benchmarks on PRs
- Parallel execution

**For Maintenance:**
- Automated comparison
- Clear regression reports
- Community contributions

**For False Alarms:**
- Multiple runs (statistical significance)
- Reasonable thresholds (10-20%)
- Manual review for borderline cases

---

## 5. Implementation Plan

### Phase 1: Foundation (Week 1-2)
- [x] Create ADR-009
- [ ] Set up benchmark infrastructure
- [ ] Create basic benchmarks (intent, state)
- [ ] Establish baseline measurements

### Phase 2: CI Integration (Week 3-4)
- [ ] GitHub Actions workflow
- [ ] Regression detection
- [ ] PR comments
- [ ] Dashboard (GitHub Pages)

### Phase 3: Optimization (Week 5+)
- [ ] Profile core operations
- [ ] Optimize hotspots
- [ ] Memory profiling
- [ ] Document findings

---

## 6. Examples

See benchmark code examples in section 3.2 above.

**Expected Benchmark Output:**
```
=== JIntent Performance Benchmark Results ===

Intent Processing:
  P50: 0.45μs
  P95: 1.8μs
  P99: 4.2μs
  Throughput: 2,222,222 intents/sec

State Update:
  Latency: 0.3μs
  Throughput: 3,333,333 updates/sec

Effect Emission:
  Latency: 0.08μs
  Throughput: 12,500,000 effects/sec

Memory:
  Per controller: 0.85 KB
  Per state (empty): 0.12 KB

Comparison:
  Raw Flutter setState: 0.25μs
  JIntent intent(): 0.45μs
  Overhead: 80% (0.20μs)
  
  BLoC add(): 0.75μs
  JIntent advantage: 40% faster

Binary Size:
  APK increase: 42 KB

✅ All targets met
```

---

## 7. Alternatives Considered

### Alternative 1: No Performance Testing

**Approach:** Trust that it's "fast enough"

**Pros:**
- No overhead
- Simpler CI

**Cons:**
- Unknown performance
- Risk of regressions
- No optimization data

**Decision:** Rejected - Data essential for quality

### Alternative 2: Manual Profiling Only

**Approach:** Profile when issues reported

**Pros:**
- Less CI overhead
- On-demand

**Cons:**
- Reactive, not proactive
- Regressions slip through
- No trend data

**Decision:** Rejected - Continuous monitoring better

### Alternative 3: Comprehensive Profiling

**Approach:** Profile every operation, every platform

**Pros:**
- Maximum data
- All scenarios covered

**Cons:**
- Massive overhead
- Too much data
- Diminishing returns

**Decision:** Rejected - Focus on critical paths

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Benchmarks slow CI | Medium | High | Quick subset on PR, full weekly |
| Performance targets unmet | High | Low | Optimize before 3.0 release |
| False regression alerts | Low | Medium | Statistical analysis, thresholds |
| Optimization premature | Medium | Low | Profile first guidelines |

---

## 9. Open Questions

### Q1: Which Platforms to Benchmark?

**Question:** Test on Android, iOS, Web, Desktop?

**Answer:** Phase 1: Android. Phase 2: Add iOS. Platform differences expected to be minimal (Dart VM).

### Q2: Real Device vs Emulator?

**Question:** Use real devices or CI emulators?

**Answer:** CI emulators for consistency. Real devices for verification.

### Q3: Production Performance Monitoring?

**Question:** Track app performance in production?

**Answer:** Consumers use their APM (New Relic, Firebase). JIntent provides hooks (ADR-008).

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md) - Section 5.1
- [ADR-002: Testing Strategy](./ADR-002-testing-strategy.md) - Performance testing
- [ADR-008: Observability Strategy](./ADR-008-observability-strategy.md) - Metrics

### External Resources
- [Benchmark Harness](https://pub.dev/packages/benchmark_harness)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Dart Performance](https://dart.dev/guides/language/performance)
- [Chrome DevTools Performance](https://developer.chrome.com/docs/devtools/performance/)

### Related ADRs
- ADR-002: Testing Strategy (performance tests)
- ADR-008: Observability Strategy (performance metrics)
- ADR-003: CI/CD Architecture (benchmark automation)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] Performance targets defined
- [ ] Benchmark suite designed
- [ ] CI integration planned
- [ ] Optimization guidelines documented
- [ ] Monitoring strategy outlined
- [ ] Implementation plan provided

### Next Steps After Approval

1. Mark ADR-009 as **Accepted**
2. Set up benchmark infrastructure
3. Create benchmark suite
4. Run baseline measurements
5. Configure CI automation
6. Write performance guide
7. Publish initial results

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes performance targets and benchmarking strategy for JIntent. It builds upon ADR-000 and complements ADR-002 (Testing) and ADR-008 (Observability).*
