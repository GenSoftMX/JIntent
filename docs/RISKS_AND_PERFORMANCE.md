# JIntent Risks & Performance Baseline

**Version:** 2.1.0  
**Date:** 2025-10-14  
**Purpose:** Document technical risks and establish performance baselines

---

## 1. Technical Risks

### 1.1 High Priority Risks

#### Risk 1.1: Global State in JObserver
**Severity:** 🔴 High  
**Impact:** Test isolation, concurrency bugs, memory leaks

**Description:**
`JObserver` uses static mutable callbacks, which creates issues:
- Test pollution: Callbacks persist between tests
- Isolate safety: Not thread-safe if accessed from multiple Isolates
- Memory leaks: Callbacks not automatically cleaned up

**Current Code:**
```dart
class JObserver {
  static void Function(JIntent)? onIntentDispatched;
  static void Function(JState, JState, JIntent?)? onStateChanged;
  static void Function(JEffect)? onEffectEmitted;
}
```

**Mitigation (Current):**
- Developers must manually null callbacks in `tearDown()`
- Documentation warns about test isolation

**Recommendation:**
- **3.0.0:** Refactor to instance-based observer
- **Alternative:** Provide `JObserver.reset()` helper

**Example (Proposed):**
```dart
class JObserverInstance {
  void Function(JIntent)? onIntentDispatched;
  // ... other callbacks
}

// In controller
class JController<T> {
  JController(T state, {JObserverInstance? observer});
}
```

**Timeline:** Plan for 3.0.0 (breaking change)

---

#### Risk 1.2: Sequential Dispatcher Queue Overflow
**Severity:** 🔴 High (DoS potential)  
**Impact:** Memory exhaustion, app crash

**Description:**
`JSequentialIntentDispatcher` has unbounded queue. If intents arrive faster than they're processed:
- Queue grows indefinitely
- Memory usage increases
- Potential OutOfMemoryError

**Current Code:**
```dart
final _queue = Queue<_QueuedIntent>();  // No max size
```

**Mitigation (Current):**
- None (relies on application-level rate limiting)

**Recommendation:**
- Add optional `maxQueueSize` parameter
- Drop or reject intents when full
- Emit warning/error when approaching limit

**Example (Proposed):**
```dart
class JSequentialIntentDispatcher {
  JSequentialIntentDispatcher({this.maxQueueSize = 1000});
  
  final int maxQueueSize;
  
  Future<void> dispatch(...) {
    if (_queue.length >= maxQueueSize) {
      throw QueueOverflowException('Intent queue full: $maxQueueSize');
    }
    // ... rest of dispatch logic
  }
}
```

**Timeline:** Add in 2.2.0 (non-breaking, opt-in)

---

#### Risk 1.3: SDK Constraint Too Restrictive
**Severity:** 🔴 High (adoption blocker)  
**Impact:** Limits user base to very recent Flutter/Dart versions

**Description:**
Current SDK constraint: `^3.7.2` (released Oct 2024?)
- Excludes Flutter stable channel users (typically on 3.3.x - 3.5.x)
- Limits enterprise adoption (conservative update policies)

**Current:**
```yaml
environment:
  sdk: ^3.7.2  # Very new
```

**Mitigation (Current):**
- None (barrier to adoption)

**Recommendation:**
- Relax to `^3.0.0` (still modern, wider compatibility)
- Test on older SDK versions

**Timeline:** Change in 2.1.1 (patch, non-breaking)

---

### 1.2 Medium Priority Risks

#### Risk 2.1: Effect Timeout Configuration (Global)
**Severity:** 🟡 Medium  
**Impact:** Isolate safety, unexpected behavior

**Description:**
`JEffectsConfig` is a singleton with mutable global state:
- Not thread-safe across Isolates
- Changes affect entire application
- No per-controller customization

**Current Code:**
```dart
class JEffectsConfig {
  factory JEffectsConfig() => _instance ??= JEffectsConfig._();
  static JEffectsConfig? _instance;
  
  Duration? defaultTimeout;  // Mutable global
}
```

**Recommendation:**
- Allow per-controller effect config
- Freeze config after first use (immutable)
- Document Isolate safety limitations

**Timeline:** Document in 2.2.0, refactor in 3.0.0

---

#### Risk 2.2: No Structured Error Types
**Severity:** 🟡 Medium  
**Impact:** Harder debugging, inconsistent error handling

**Description:**
Library uses generic `Exception` for all errors:
- Can't differentiate error types (network vs validation)
- No standardized error messages
- Harder to handle specific errors

**Recommendation:**
- Create error hierarchy: `JIntentError` base class
- Subtypes: `ValidationError`, `NetworkError`, `TimeoutError`
- Document error types in public API

**Example (Proposed):**
```dart
abstract class JIntentError implements Exception {
  final String message;
  final StackTrace? stackTrace;
  JIntentError(this.message, [this.stackTrace]);
}

class ValidationError extends JIntentError { ... }
class NetworkError extends JIntentError { ... }
```

**Timeline:** Add in 2.2.0 (non-breaking), deprecate generic in 3.0.0

---

#### Risk 2.3: Missing Widget Disposal Guidance
**Severity:** 🟡 Medium  
**Impact:** Memory leaks, zombie widgets

**Description:**
No documented pattern for disposing controllers in widgets:
- Developers may forget to call `dispose()`
- Side effect stream listeners may leak

**Recommendation:**
- Document disposal pattern in README
- Provide helper widget (`JControllerProvider`)
- Add lint rule to enforce disposal

**Timeline:** Documentation in 2.1.1, helper in 2.2.0

---

### 1.3 Low Priority Risks

#### Risk 3.1: Utils/Navigation Outside Core Scope
**Severity:** 🟢 Low  
**Impact:** API bloat, maintenance burden

**Description:**
`PlatformInfo`, `ValidationUtils`, `JNavigator` are not core to intent pattern:
- Increases package size
- More surface area to maintain
- May duplicate functionality in other packages

**Recommendation:**
- Consider extracting to separate packages
- Mark as experimental/optional
- Don't break existing users (deprecate in 3.0.0)

**Timeline:** Evaluate in 3.0.0 planning

---

#### Risk 3.2: No DevTools Integration
**Severity:** 🟢 Low (quality of life)  
**Impact:** Harder debugging for complex apps

**Description:**
No integration with Flutter DevTools:
- Can't visualize intent timeline
- Can't inspect state history
- No performance profiling

**Recommendation:**
- Create DevTools extension (separate package)
- Integrate with timeline events
- Provide state inspector

**Timeline:** POC in 2.3.0, release in 3.0.0

---

## 2. Performance Baseline

### 2.1 Current Performance (Unmeasured)

**Status:** ❌ No benchmarks currently exist

**Need Baselines For:**
1. Intent dispatch latency (intent → controller.update())
2. State update latency (update() → listener notification)
3. Sequential dispatcher throughput (intents/sec)
4. Memory overhead (per controller, per state snapshot)
5. Rebuild efficiency (unnecessary rebuilds)

---

### 2.2 Proposed Benchmarks

#### Benchmark 2.2.1: Intent Latency
**Test:** Measure time from `controller.intent()` to state update

**Setup:**
```dart
final stopwatch = Stopwatch();
final controller = TestController(TestState());

stopwatch.start();
await controller.intent(NoOpIntent());
stopwatch.stop();

print('Latency: ${stopwatch.elapsedMicroseconds}µs');
```

**Target:**
- p50: <5ms
- p95: <20ms
- p99: <50ms

---

#### Benchmark 2.2.2: Sequential Throughput
**Test:** Process 1000 intents sequentially

**Setup:**
```dart
final stopwatch = Stopwatch();
final controller = TestController(TestState());

stopwatch.start();
for (var i = 0; i < 1000; i++) {
  await controller.intent(NoOpIntent());
}
stopwatch.stop();

final throughput = 1000 / (stopwatch.elapsedMilliseconds / 1000);
print('Throughput: ${throughput.toStringAsFixed(0)} intents/sec');
```

**Target:**
- ≥1000 intents/sec on typical hardware

---

#### Benchmark 2.2.3: Memory Overhead
**Test:** Measure memory used by controllers and states

**Setup:**
```dart
final before = ProcessInfo.currentRss;  // Requires dev dependency

final controllers = List.generate(
  1000,
  (i) => TestController(TestState(value: i)),
);

final after = ProcessInfo.currentRss;
final overhead = (after - before) / 1000;

print('Overhead per controller: ${overhead}KB');
```

**Target:**
- <10KB per controller
- <10MB for 1000 state snapshots (history)

---

#### Benchmark 2.2.4: Rebuild Efficiency
**Test:** Count unnecessary rebuilds in test scenario

**Setup:**
```dart
testWidgets('Counter increments without extra rebuilds', (tester) async {
  var buildCount = 0;
  
  await tester.pumpWidget(
    Builder(builder: (context) {
      buildCount++;
      return CounterWidget(controller);
    }),
  );
  
  await controller.intent(IncrementIntent());
  await tester.pump();
  
  expect(buildCount, 2);  // Initial + 1 update (not 3+)
});
```

**Target:**
- <10% unnecessary rebuilds in test scenarios

---

### 2.3 Performance Optimization Opportunities

**Identified Hotspots (Theoretical):**

1. **State Equality Checks:** Always notifies (since 2.0.1)
   - **Impact:** May cause unnecessary rebuilds
   - **Mitigation:** Use fine-grained controllers, selector widgets

2. **Queue Iteration:** `while (_queue.isNotEmpty)` in sequential dispatcher
   - **Impact:** Likely negligible (Queue is efficient)
   - **Mitigation:** Profile first, optimize if needed

3. **StreamController Broadcasts:** Side effects use broadcast stream
   - **Impact:** Overhead for multiple listeners
   - **Mitigation:** Document best practices (use single handler)

4. **JObserver Hook Calls:** Static function calls on every event
   - **Impact:** Negligible if null, may slow debug builds
   - **Mitigation:** Already optimized (null checks)

**Recommendation:**
- Measure first before optimizing
- Profile real-world apps (not micro-benchmarks)
- Document performance best practices

---

## 3. Concurrency Risks

### 3.1 Isolate Safety

**Current Status:** ⚠️ Unsafe for multi-Isolate usage

**Why:**
- `JObserver` uses static state (not Isolate-isolated)
- `JEffectsConfig` uses singleton (shared across Isolates)
- `StateNotifier` is not thread-safe

**Recommendation:**
- Document: "JIntent is Isolate-unsafe. Use on main Isolate only."
- For compute-heavy work: Use `compute()`, send result via intent

**Example (Safe Pattern):**
```dart
class HeavyComputeIntent extends JIntent<MyState> {
  @override
  Future<void> onInvoke() async {
    // Run in separate Isolate
    final result = await compute(expensiveFunction, input);
    
    // Update state on main Isolate
    controller.update((state) => state.copyWith(result: result));
  }
}
```

---

### 3.2 Race Conditions

**Current Status:** ✅ Mitigated by sequential dispatcher (default)

**Potential Issues:**
- If using `JDefaultIntentDispatcher`: concurrent intents possible
- State updates are synchronous (no race within single intent)

**Recommendation:**
- Document: Always use `JSequentialIntentDispatcher` (default)
- If parallel needed: Ensure intents don't depend on each other

---

## 4. Dependency Risks

### 4.1 Direct Dependencies

**Risk Assessment:**

| Dependency | Version | Last Update | Maintenance | Risk |
|------------|---------|-------------|-------------|------|
| equatable | ^2.0.5 | 2021 | Active (maintained by Remi) | 🟢 Low |
| state_notifier | ^1.0.0 | 2022 | Active (Riverpod foundation) | 🟢 Low |
| flutter | SDK | N/A | Google-maintained | 🟢 Low |

**Conclusion:** Dependencies are stable, low risk

---

### 4.2 Transitive Dependencies

**Analysis:**
```
jintent
├── equatable (no dependencies)
└── state_notifier
    └── (minimal dependencies)
```

**Conclusion:** Flat dependency tree, no conflict risk

---

## 5. Adoption Risks

### 5.1 Learning Curve

**Barrier:** MVI pattern unfamiliar to many Flutter developers

**Mitigation:**
- ✅ README has Quick Start
- ⚠️ No video tutorials
- ⚠️ Limited real-world examples beyond counter

**Recommendation:**
- Create intermediate examples (API calls, forms, navigation)
- Video tutorial or blog post
- Community engagement (Discord, Reddit)

---

### 5.2 Migration from Other Libraries

**Barrier:** No migration guides from Bloc/Riverpod/GetX

**Mitigation:**
- ⚠️ CHANGELOG has generic migration notes

**Recommendation:**
- Create migration guide: Bloc → JIntent
- Create migration guide: Riverpod → JIntent
- Highlight benefits (less boilerplate, clearer flow)

---

## 6. Risk Mitigation Roadmap

### Immediate (2.1.1 - Patch)
1. ✅ Relax SDK constraint to ^3.0.0
2. ✅ Document Isolate safety limitations
3. ✅ Add disposal guidance to README

### Short-Term (2.2.0 - Minor)
1. ✅ Add `maxQueueSize` to sequential dispatcher
2. ✅ Create structured error types
3. ✅ Add performance benchmarks
4. ✅ Document performance best practices

### Medium-Term (2.3.0 - Minor)
1. ✅ DevTools extension POC
2. ✅ Migration guides (Bloc, Riverpod)
3. ✅ Video tutorial

### Long-Term (3.0.0 - Major)
1. ✅ Refactor JObserver to instance-based
2. ✅ Remove deprecated APIs (setState)
3. ✅ Extract utils/navigation to separate packages
4. ✅ Freeze JEffectsConfig after init

---

## 7. Monitoring & Metrics

### 7.1 Quality Metrics (Proposed)

**Track Per Release:**
- Test coverage %
- Lint warnings count
- Documentation completeness %
- Example app count

**Track in Production (User Apps):**
- Crash rate (if reporting enabled)
- Performance (if profiling enabled)
- Adoption (pub.dev downloads)

---

### 7.2 Community Health

**Track:**
- GitHub issues (open vs closed)
- PR response time
- Community questions (Stack Overflow, Discord)
- Contributor count

**Current Status:**
- ⚠️ No public issue tracker visible
- ⚠️ No community forum/Discord
- ⚠️ Single maintainer (bus factor risk)

**Recommendation:**
- Enable GitHub Issues
- Create contribution guidelines
- Encourage community contributions

---

## 8. Summary

### Critical Risks (Require Immediate Action)
1. 🔴 SDK constraint too restrictive → Change in 2.1.1
2. 🔴 No sequential dispatcher tests → Add immediately
3. 🔴 Global JObserver state → Plan refactor for 3.0.0

### Medium Risks (Address in 2.2.0)
1. 🟡 Queue overflow potential → Add max size
2. 🟡 No structured errors → Create hierarchy
3. 🟡 Missing benchmarks → Establish baselines

### Low Risks (Monitor, Address in 3.0.0)
1. 🟢 Utils outside scope → Consider extraction
2. 🟢 No DevTools → Create extension
3. 🟢 Learning curve → More examples

---

**Document Status:** ✅ Complete  
**Next Review:** After Phase 1 mitigations  
**Owner:** Development Team
