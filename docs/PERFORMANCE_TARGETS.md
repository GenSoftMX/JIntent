# Performance Targets and SLOs

**Status:** Draft | **Phase:** 1 - Baseline Definition  
**Last Updated:** 2025-10-15  
**Next Review:** After Phase 2 Benchmarking

---

## Overview

This document defines Service Level Objectives (SLOs) and Service Level Indicators (SLIs) for JIntent's performance. These targets ensure the library maintains acceptable performance characteristics for production applications.

**Note:** Benchmark measurements will be implemented in Phase 2. Current targets are based on architectural analysis and industry best practices.

---

## Performance Philosophy

JIntent prioritizes:
1. **Predictability** over raw speed - sequential intent processing prevents race conditions
2. **Zero-cost abstraction** - overhead should be minimal compared to hand-written state management
3. **Scalability** - performance should degrade gracefully with increased load
4. **Memory efficiency** - minimal memory footprint per controller instance

---

## Service Level Objectives (SLOs)

### 1. Intent Dispatch Latency

**Definition:** Time from `controller.dispatch(intent)` call to start of intent handler execution.

| Percentile | Target | Measurement Method |
|------------|--------|-------------------|
| p50 (median) | <5ms | Benchmark suite |
| p95 | <10ms | Benchmark suite |
| p99 | <20ms | Benchmark suite |
| p99.9 | <50ms | Benchmark suite |

**Rationale:**
- Intent dispatch should be near-instantaneous for responsive UI
- Sequential processing adds minimal overhead (queue management)
- 10ms at p95 is imperceptible to users (60fps = 16.67ms per frame)

**Failure Impact:**
- High latency causes UI lag and poor user experience
- Missed frame deadlines (>16ms) cause visible jank

**Mitigation:**
- Keep intent handlers lightweight
- Offload heavy work to use cases (async)
- Monitor queue depth in observability hooks

---

### 2. State Transition Overhead

**Definition:** Time to update state from `state = newState` to notification of listeners.

| Percentile | Target | Measurement Method |
|------------|--------|-------------------|
| p50 | <1ms | Microbenchmark |
| p95 | <2ms | Microbenchmark |
| p99 | <5ms | Microbenchmark |

**Rationale:**
- State transition is synchronous and should be extremely fast
- Based on `StateNotifier` performance characteristics
- Immutable state updates (copyWith) are O(1) for most cases

**Failure Impact:**
- High overhead causes cumulative lag in rapid state updates
- UI rebuild delays

**Mitigation:**
- Use efficient `copyWith` implementations
- Avoid deep nested object graphs in state
- Consider using immutable collections (built_value, freezed)

---

### 3. Side Effect Emission Overhead

**Definition:** Time to emit a side effect from `emitSideEffect(effect)` to listener notification.

| Percentile | Target | Measurement Method |
|------------|--------|-------------------|
| p50 | <3ms | Benchmark |
| p95 | <5ms | Benchmark |
| p99 | <10ms | Benchmark |

**Rationale:**
- Side effects use stream sink, which has minimal overhead
- Effect categorization and ID generation add small cost
- 5ms is acceptable for non-blocking operations (navigation, dialogs)

**Failure Impact:**
- Delayed navigation or dialog display
- Perceived sluggishness

**Mitigation:**
- Keep effect objects lightweight
- Avoid complex effect construction
- Use fire-and-forget pattern when possible

---

### 4. Memory Overhead per Controller

**Definition:** Memory footprint of a single `JController` instance with typical usage.

| Scenario | Target | Measurement Method |
|----------|--------|-------------------|
| Minimal (empty state) | <10KB | Memory profiler |
| Typical (10 intents, 5 effects) | <50KB | Memory profiler |
| Heavy (100 intents queued) | <200KB | Memory profiler |

**Rationale:**
- Controllers should be lightweight enough to instantiate many in a single app
- Most memory is state data (user-controlled), not framework overhead
- Queue and stream buffers should not grow unbounded

**Failure Impact:**
- Memory leaks cause app crashes
- High memory usage impacts battery life
- Slow garbage collection pauses

**Mitigation:**
- Properly dispose controllers when no longer needed
- Monitor intent queue depth
- Clear effect stream listeners on dispose
- Use weak references for observers if needed

---

### 5. Intent Throughput

**Definition:** Number of intents that can be processed per second (sequential processing).

| Load Type | Target | Measurement Method |
|-----------|--------|-------------------|
| Simple intents (no async) | >500/sec | Benchmark |
| Async intents (fast use case) | >100/sec | Benchmark |
| Async intents (1s use case) | ~1/sec | By design |

**Rationale:**
- Sequential processing inherently limits throughput
- Most apps have <10 intents/second (user interaction rate)
- High-frequency scenarios (animations, polling) should use specialized solutions

**Failure Impact:**
- Intent queue grows unbounded
- Memory exhaustion
- Delayed user feedback

**Mitigation:**
- Debounce/throttle high-frequency intents at UI layer
- Use custom dispatcher for high-throughput scenarios
- Monitor queue depth via `JObserver`

---

### 6. Observability Hook Overhead

**Definition:** Additional latency introduced by `JObserver` hooks (logging, analytics).

| Hook Type | Target | Measurement Method |
|-----------|--------|-------------------|
| onIntentReceived | <0.1ms | Benchmark |
| onStateChanged | <0.1ms | Benchmark |
| onEffectEmitted | <0.1ms | Benchmark |
| onError | <1ms | Benchmark |

**Rationale:**
- Observers should have near-zero cost in production
- Logging/analytics should not impact user experience
- Async operations should be offloaded

**Failure Impact:**
- Observer overhead compounds across many events
- Noticeable lag if many observers are registered

**Mitigation:**
- Disable verbose observers in production
- Use async logging (fire-and-forget)
- Limit number of registered observers

---

## Service Level Indicators (SLIs)

### How We Measure Performance

#### 1. Benchmark Suite (Phase 2)

Location: `benchmark/` directory

**Tests:**
- Intent dispatch latency (cold start, warm, hot)
- State transition overhead (small state, large state, nested state)
- Side effect emission (single effect, burst of effects)
- Memory profiling (allocation rate, retention, leaks)
- Throughput (sustained load, burst load)

**Running Benchmarks:**
```bash
flutter run benchmark/intent_dispatch_benchmark.dart
flutter run --profile benchmark/memory_benchmark.dart
```

**Output:**
- CSV files with raw data
- Summary statistics (p50, p95, p99)
- Memory flamegraphs

#### 2. Integration Tests (Phase 2)

Measure performance in realistic scenarios:
- Example app with typical usage patterns
- Stress tests with extreme loads
- Platform-specific performance (web vs. native)

#### 3. Continuous Monitoring (Phase 3)

- CI/CD performance regression tests
- Automated alerts on SLO violations
- Historical trend analysis

---

## Performance Budget

Maximum acceptable overhead for JIntent compared to hand-written state management:

| Operation | Hand-Written | JIntent Target | Overhead Budget |
|-----------|--------------|----------------|-----------------|
| State update | ~0.5ms | ~1.5ms | +200% (acceptable) |
| Event handling | ~1ms | ~5ms | +400% (worth the abstraction) |
| Memory per "controller" | ~5KB | ~15KB | +200% (acceptable) |

**Philosophy:** 
- Abstractions have a cost, but JIntent's cost should be **worth it** in terms of:
  - Code clarity
  - Testability
  - Maintainability
  - Reduced bugs

---

## Edge Cases and Limits

### Known Performance Bottlenecks

#### 1. Intent Queue Flood
**Scenario:** Malicious or buggy code dispatches thousands of intents rapidly.

**Impact:** Memory exhaustion, UI freeze.

**Detection:** Queue depth monitoring via `JObserver`.

**Mitigation:**
- Implement rate limiting in controllers (if needed)
- Use throttling/debouncing at UI layer
- Document best practices

#### 2. Large State Objects
**Scenario:** State contains megabytes of data (large lists, images).

**Impact:** Slow state transitions, high memory usage.

**Detection:** Memory profiler, state size monitoring.

**Mitigation:**
- Store large data in repositories, not state
- Use pagination for lists
- Lazy load data

#### 3. Effect Stream Listener Leak
**Scenario:** UI registers effect listeners but never disposes them.

**Impact:** Memory leak, increasing overhead over time.

**Detection:** Memory profiler, retention analysis.

**Mitigation:**
- Document disposal best practices
- Provide widget helpers for automatic cleanup
- Add debug mode warnings

---

## Platform-Specific Considerations

### Web
- **Challenge:** JavaScript runtime has different performance characteristics
- **Target:** Same SLOs, but measured separately
- **Mitigation:** Avoid synchronous heavy computations

### Mobile (iOS/Android)
- **Challenge:** Background throttling, battery constraints
- **Target:** Primary benchmarking platform
- **Mitigation:** Document best practices for background processing

### Desktop (Windows/macOS/Linux)
- **Challenge:** Different memory constraints
- **Target:** Same SLOs as mobile
- **Mitigation:** None needed currently

---

## Performance Testing Strategy

### Phase 1 (Current): Baseline Definition
- [x] Define SLOs and SLIs (this document)
- [ ] Document performance best practices
- [ ] Identify performance-critical code paths

### Phase 2: Benchmarking
- [ ] Implement benchmark suite
- [ ] Measure baseline performance
- [ ] Publish initial benchmark results
- [ ] Set up automated regression testing

### Phase 3: Optimization
- [ ] Profile and optimize hot paths
- [ ] Reduce memory allocations
- [ ] Optimize state update algorithm
- [ ] Platform-specific optimizations

### Phase 4: Continuous Improvement
- [ ] Automated performance testing in CI/CD
- [ ] Performance regression alerts
- [ ] Community performance contributions
- [ ] Real-world performance monitoring

---

## Best Practices for Performance

### For Library Users

#### 1. Keep State Small
❌ **Bad:**
```dart
class MyState extends JState {
  final List<LargeObject> items; // 10,000 items, 10MB
}
```

✅ **Good:**
```dart
class MyState extends JState {
  final List<String> itemIds; // 10,000 IDs, 100KB
  // Fetch full items from repository as needed
}
```

#### 2. Offload Heavy Work to Use Cases
❌ **Bad:**
```dart
void onIntent(LoadDataIntent intent) {
  final data = expensiveComputation(); // Blocks intent queue!
  state = state.copyWith(data: data);
}
```

✅ **Good:**
```dart
void onIntent(LoadDataIntent intent) async {
  final result = await loadDataUseCase.call(intent.params);
  result.fold(
    (error) => emitSideEffect(ErrorEffect(error)),
    (data) => state = state.copyWith(data: data),
  );
}
```

#### 3. Dispose Controllers Properly
✅ **Always dispose:**
```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

#### 4. Throttle/Debounce High-Frequency Intents
✅ **At UI layer:**
```dart
final throttler = Throttler(duration: Duration(milliseconds: 300));

onPressed: () => throttler.call(() {
  controller.dispatch(SearchIntent(query));
})
```

---

## Monitoring and Alerting

### Development/Testing
- **Log observer:** Print performance warnings in debug mode
- **Flutter DevTools:** Profile memory and CPU usage
- **Benchmarks:** Run locally before releases

### Production (User-Facing Apps)
- **Analytics:** Track app performance metrics (Firebase Performance)
- **Error monitoring:** Sentry, Crashlytics for performance exceptions
- **User feedback:** Monitor app reviews for performance complaints

---

## References

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Dart Performance Tips](https://dart.dev/guides/performance)
- [ADR-001: Intent Dispatcher Strategy](./adr/ADR-001-intent-dispatcher-strategy.md)
- [ADR-007: Observer and DevTools Hooks](./adr/ADR-007-observer-devtools-hooks.md)
- [ADR-010: Publication and CI/CD](./adr/ADR-010-publication-and-cicd.md)

---

**Document Owner:** JIntent Maintainers  
**Review Cycle:** After each major/minor release  
**Benchmark Data:** TBD (Phase 2)
