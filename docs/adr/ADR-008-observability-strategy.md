# ADR-008: Observability Strategy

**Status:** Proposed  
**Date:** 2025-10-15  
**Deciders:** Project Maintainers, Community  
**Context:** Phase 3 Observability & Testing - Production Readiness  
**Related:** [ADR-000](./ADR-000-context-and-high-level-decisions.md)

---

## 1. Status

**Current Status:** Proposed  
**Approval Status:** Pending Stakeholder Review

This ADR defines observability strategy including logging, metrics, tracing, and debugging tools for JIntent to ensure production-ready monitoring and troubleshooting capabilities.

---

## 2. Context

### 2.1 Background

**Current Observability (v2.1.0):**

**Existing:**
- ✅ JObserver pattern for hooking into lifecycle
- ✅ enableLoggingObserver() utility for debug logging
- ✅ Effect metadata (categories, IDs)
- ⚠️ No structured logging
- ⚠️ No metrics collection
- ⚠️ No distributed tracing
- ⚠️ No performance monitoring

**Implementation:**
```dart
// lib/src/devtools/logging_observer.dart
void enableLoggingObserver() {
  if (kDebugMode) {
    JObserver.onIntentDispatched = (intent) {
      debugPrint('[Observer] Intent dispatched: ${intent.runtimeType}');
    };

    JObserver.onStateChanged = (prev, next, origin) {
      debugPrint(
        '[Observer] State changed: $prev → $next (via ${origin?.runtimeType})',
      );
    };

    JObserver.onEffectEmitted = (effect) {
      debugPrint('[Observer] Effect emitted: ${effect.runtimeType}');
    };
  }
}
```

### 2.2 Problem Statement

**Current Challenges:**
- No production logging strategy
- Can't track user flows in production
- No performance metrics
- Hard to debug production issues
- No alerting capability
- No observability in consumer apps

**Business Impact:**
- Slow incident response
- Unknown performance bottlenecks
- Can't measure adoption/usage
- Hard to improve user experience

---

## 3. Decision

### 3.1 Observability Pillars

**Decision:** Support three pillars of observability

**1. Logging** - What happened?
- State changes
- Intent dispatches
- Effect emissions
- Errors and warnings

**2. Metrics** - How much / how often?
- Intent processing time
- Effect completion rate
- State update frequency
- Error rate

**3. Tracing** - What caused what?
- Intent → State transition chains
- Effect handling flows
- Use case execution spans

### 3.2 Structured Logging

**Decision:** Provide structured logging framework

**Log Levels:**
```dart
enum LogLevel {
  debug,    // Detailed diagnostic information
  info,     // General information
  warning,  // Warning conditions
  error,    // Error conditions
  critical, // Critical conditions
}
```

**Log Entry:**
```dart
/// Structured log entry.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? category;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;
  
  LogEntry({
    DateTime? timestamp,
    required this.level,
    required this.message,
    this.category,
    this.context,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Converts to JSON for structured logging services.
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    if (category != null) 'category': category,
    if (context != null) 'context': context,
    if (stackTrace != null) 'stackTrace': stackTrace.toString(),
  };
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${level.name.toUpperCase()}]');
    buffer.write(' ${timestamp.toIso8601String()}');
    if (category != null) buffer.write(' [$category]');
    buffer.write(' - $message');
    if (context != null && context!.isNotEmpty) {
      buffer.write(' | Context: $context');
    }
    return buffer.toString();
  }
}
```

**Logger Interface:**
```dart
/// Logger abstraction for JIntent observability.
abstract class JLogger {
  void log(LogEntry entry);
  
  void debug(String message, {String? category, Map<String, dynamic>? context}) {
    log(LogEntry(
      level: LogLevel.debug,
      message: message,
      category: category,
      context: context,
    ));
  }
  
  void info(String message, {String? category, Map<String, dynamic>? context}) {
    log(LogEntry(
      level: LogLevel.info,
      message: message,
      category: category,
      context: context,
    ));
  }
  
  void warning(String message, {String? category, Map<String, dynamic>? context}) {
    log(LogEntry(
      level: LogLevel.warning,
      message: message,
      category: category,
      context: context,
    ));
  }
  
  void error(
    String message, {
    String? category,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(LogEntry(
      level: LogLevel.error,
      message: message,
      category: category,
      context: {
        ...?context,
        if (error != null) 'error': error.toString(),
      },
      stackTrace: stackTrace,
    ));
  }
}

/// Console logger for development.
class ConsoleLogger implements JLogger {
  @override
  void log(LogEntry entry) {
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }
}

/// Multi-logger that broadcasts to multiple loggers.
class MultiLogger implements JLogger {
  final List<JLogger> loggers;
  
  MultiLogger(this.loggers);
  
  @override
  void log(LogEntry entry) {
    for (final logger in loggers) {
      logger.log(entry);
    }
  }
}
```

**Integration with JObserver:**
```dart
/// Configures JIntent observability.
class JObservabilityConfig {
  static JLogger? _logger;
  static JMetricsCollector? _metrics;
  
  /// Sets the logger to use.
  static void setLogger(JLogger logger) {
    _logger = logger;
    _setupLogging();
  }
  
  /// Sets the metrics collector to use.
  static void setMetrics(JMetricsCollector collector) {
    _metrics = collector;
    _setupMetrics();
  }
  
  static void _setupLogging() {
    if (_logger == null) return;
    
    JObserver.onIntentDispatched = (intent) {
      _logger!.debug(
        'Intent dispatched',
        category: 'intent',
        context: {
          'intent': intent.runtimeType.toString(),
          'metadata': intent.metadata.toJson(),
        },
      );
    };
    
    JObserver.onStateChanged = (prev, next, origin) {
      _logger!.info(
        'State changed',
        category: 'state',
        context: {
          'previous': prev.runtimeType.toString(),
          'next': next.runtimeType.toString(),
          'origin': origin?.runtimeType.toString(),
        },
      );
    };
    
    JObserver.onEffectEmitted = (effect) {
      _logger!.debug(
        'Effect emitted',
        category: 'effect',
        context: {
          'effect': effect.runtimeType.toString(),
          'id': effect.id,
          'category': effect.category,
        },
      );
    };
  }
}
```

### 3.3 Metrics Collection

**Decision:** Provide metrics collection framework

**Metric Types:**
```dart
/// Metric types for observability.
enum MetricType {
  counter,    // Monotonically increasing value
  gauge,      // Point-in-time value
  histogram,  // Distribution of values
  timer,      // Duration measurements
}

/// Base metric.
abstract class Metric {
  final String name;
  final MetricType type;
  final Map<String, String> tags;
  
  Metric({
    required this.name,
    required this.type,
    this.tags = const {},
  });
}

/// Counter metric (e.g., total intents processed).
class Counter extends Metric {
  int _value = 0;
  
  Counter(String name, {Map<String, String> tags = const {}})
      : super(name: name, type: MetricType.counter, tags: tags);
  
  void increment([int delta = 1]) {
    _value += delta;
  }
  
  int get value => _value;
}

/// Gauge metric (e.g., current queue size).
class Gauge extends Metric {
  double _value = 0;
  
  Gauge(String name, {Map<String, String> tags = const {}})
      : super(name: name, type: MetricType.gauge, tags: tags);
  
  void set(double value) {
    _value = value;
  }
  
  double get value => _value;
}

/// Timer metric (e.g., intent processing time).
class Timer extends Metric {
  final List<Duration> _measurements = [];
  
  Timer(String name, {Map<String, String> tags = const {}})
      : super(name: name, type: MetricType.timer, tags: tags);
  
  void record(Duration duration) {
    _measurements.add(duration);
  }
  
  Duration? get min =>
      _measurements.isEmpty ? null : _measurements.reduce(
        (a, b) => a < b ? a : b,
      );
  
  Duration? get max =>
      _measurements.isEmpty ? null : _measurements.reduce(
        (a, b) => a > b ? a : b,
      );
  
  Duration? get avg => _measurements.isEmpty
      ? null
      : Duration(
          microseconds: _measurements
              .map((d) => d.inMicroseconds)
              .reduce((a, b) => a + b) ~/
          _measurements.length,
        );
  
  int get count => _measurements.length;
}
```

**Metrics Collector:**
```dart
/// Collects and reports metrics.
class JMetricsCollector {
  final Map<String, Metric> _metrics = {};
  
  /// Gets or creates a counter.
  Counter counter(String name, {Map<String, String> tags = const {}}) {
    final key = '$name:${tags.hashCode}';
    return _metrics.putIfAbsent(
      key,
      () => Counter(name, tags: tags),
    ) as Counter;
  }
  
  /// Gets or creates a gauge.
  Gauge gauge(String name, {Map<String, String> tags = const {}}) {
    final key = '$name:${tags.hashCode}';
    return _metrics.putIfAbsent(
      key,
      () => Gauge(name, tags: tags),
    ) as Gauge;
  }
  
  /// Gets or creates a timer.
  Timer timer(String name, {Map<String, String> tags = const {}}) {
    final key = '$name:${tags.hashCode}';
    return _metrics.putIfAbsent(
      key,
      () => Timer(name, tags: tags),
    ) as Timer;
  }
  
  /// Reports all metrics.
  Map<String, dynamic> report() {
    return {
      for (final entry in _metrics.entries)
        entry.key: _metricToJson(entry.value),
    };
  }
  
  Map<String, dynamic> _metricToJson(Metric metric) {
    if (metric is Counter) {
      return {'type': 'counter', 'value': metric.value, 'tags': metric.tags};
    } else if (metric is Gauge) {
      return {'type': 'gauge', 'value': metric.value, 'tags': metric.tags};
    } else if (metric is Timer) {
      return {
        'type': 'timer',
        'count': metric.count,
        'min_ms': metric.min?.inMilliseconds,
        'max_ms': metric.max?.inMilliseconds,
        'avg_ms': metric.avg?.inMilliseconds,
        'tags': metric.tags,
      };
    }
    return {};
  }
}
```

**Built-in Metrics:**
```dart
extension JMetricsSetup on JObservabilityConfig {
  static void _setupMetrics() {
    if (_metrics == null) return;
    
    // Intent metrics
    final intentCounter = _metrics!.counter('jintent.intents.total');
    final intentTimer = _metrics!.timer('jintent.intents.duration');
    
    JObserver.onIntentDispatched = (intent) {
      intentCounter.increment();
      final stopwatch = Stopwatch()..start();
      
      // Store stopwatch to measure completion (simplified)
      _pendingIntents[intent] = stopwatch;
    };
    
    JObserver.onStateChanged = (prev, next, origin) {
      if (origin != null && _pendingIntents.containsKey(origin)) {
        final stopwatch = _pendingIntents.remove(origin)!;
        stopwatch.stop();
        intentTimer.record(stopwatch.elapsed);
      }
      
      // State change counter
      _metrics!.counter('jintent.state.changes').increment();
    };
    
    // Effect metrics
    JObserver.onEffectEmitted = (effect) {
      _metrics!.counter(
        'jintent.effects.emitted',
        tags: {'category': effect.category ?? 'unknown'},
      ).increment();
    };
  }
  
  static final Map<JIntent, Stopwatch> _pendingIntents = {};
}
```

### 3.4 Distributed Tracing

**Decision:** Support distributed tracing pattern

**Trace Context:**
```dart
/// Distributed tracing context.
class TraceContext {
  final String traceId;
  final String spanId;
  final String? parentSpanId;
  
  TraceContext({
    String? traceId,
    String? spanId,
    this.parentSpanId,
  })  : traceId = traceId ?? _generateId(),
        spanId = spanId ?? _generateId();
  
  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  }
  
  /// Creates a child span.
  TraceContext child() {
    return TraceContext(
      traceId: traceId,
      parentSpanId: spanId,
    );
  }
  
  Map<String, String> toHeaders() => {
    'X-Trace-Id': traceId,
    'X-Span-Id': spanId,
    if (parentSpanId != null) 'X-Parent-Span-Id': parentSpanId!,
  };
}

/// Span for tracing operations.
class Span {
  final String name;
  final TraceContext context;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, dynamic> tags;
  final List<LogEntry> logs = [];
  
  Span({
    required this.name,
    TraceContext? context,
    this.tags = const {},
  })  : context = context ?? TraceContext(),
        startTime = DateTime.now();
  
  void finish() {
    endTime = DateTime.now();
  }
  
  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;
  
  void log(String message, {Map<String, dynamic>? fields}) {
    logs.add(LogEntry(
      level: LogLevel.info,
      message: message,
      context: fields,
    ));
  }
  
  void setTag(String key, dynamic value) {
    (tags as Map<String, dynamic>)[key] = value;
  }
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'traceId': context.traceId,
    'spanId': context.spanId,
    'parentSpanId': context.parentSpanId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'duration_ms': duration?.inMilliseconds,
    'tags': tags,
    'logs': logs.map((l) => l.toJson()).toList(),
  };
}
```

**Tracing Integration:**
```dart
/// Extension to add tracing to intents.
extension JIntentTracing on JIntent {
  TraceContext? get traceContext {
    // Store in metadata (requires extending JMetadata)
    return metadata.get<TraceContext>('traceContext');
  }
  
  set traceContext(TraceContext? context) {
    metadata.set('traceContext', context);
  }
}

// In controller:
@override
void handleIntent(JIntent intent) async {
  // Start span for intent processing
  final span = Span(
    name: 'handleIntent.${intent.runtimeType}',
    context: intent.traceContext,
  );
  
  try {
    // ... process intent
    
    span.setTag('state.before', state.runtimeType.toString());
    // ... update state
    span.setTag('state.after', state.runtimeType.toString());
    
    span.finish();
    _tracer.report(span);
  } catch (e, stackTrace) {
    span.setTag('error', true);
    span.log('Error occurred', fields: {'error': e.toString()});
    span.finish();
    _tracer.report(span);
    rethrow;
  }
}
```

### 3.5 DevTools Integration (Future)

**Decision:** Plan for Flutter DevTools integration

**Planned Features:**
- Timeline view of intents and state changes
- State inspector (current state)
- Effect tracker (pending, completed)
- Performance profiler
- Time-travel debugging

**Implementation Approach:**
- Use `dart:developer` extension APIs
- Custom DevTools extension (Phase 4)
- Real-time updates via service protocol

### 3.6 Production Logging Guidance

**Decision:** Document production logging best practices

**Guidelines (doc/observability.md):**

**1. Sanitize Sensitive Data**
```dart
// Bad: Log sensitive data
logger.info('User logged in', context: {
  'email': user.email,
  'password': password,  // NEVER!
});

// Good: Log sanitized data
logger.info('User logged in', context: {
  'userId': user.id,
  'timestamp': DateTime.now().toIso8601String(),
});
```

**2. Use Structured Logging**
```dart
// Bad: String concatenation
debugPrint('Intent ${intent.runtimeType} processed in ${duration}ms');

// Good: Structured context
logger.info('Intent processed', context: {
  'intent': intent.runtimeType.toString(),
  'duration_ms': duration.inMilliseconds,
});
```

**3. Log Levels**
- DEBUG: Detailed diagnostic (development only)
- INFO: Normal operations (state changes, intents)
- WARNING: Unusual but handled (timeouts, retries)
- ERROR: Errors that need attention
- CRITICAL: System failures

**4. Avoid Excessive Logging**
```dart
// Bad: Log every state change in production
setState(newState); // Logs automatically if observer enabled

// Good: Sample or aggregate
if (Random().nextDouble() < 0.01) { // 1% sampling
  logger.debug('State changed', context: {...});
}
```

**5. Integration with Services**
- Sentry: Error tracking
- Firebase Crashlytics: Crash reporting
- Datadog: Metrics and logging
- New Relic: APM
- Custom: HTTP log shipping

---

## 4. Consequences

### 4.1 Positive Consequences

✅ **Production Readiness**
- Monitor app health
- Debug production issues
- Performance tracking

✅ **Developer Experience**
- Understand app behavior
- Debug effectively
- Optimize performance

✅ **Business Intelligence**
- Usage metrics
- Feature adoption
- Error rates

✅ **Extensibility**
- Pluggable loggers
- Custom metrics
- Integration with services

### 4.2 Negative Consequences

⚠️ **Performance Overhead**
- Logging/metrics collection
- Memory for buffering
- CPU for serialization

⚠️ **Privacy Concerns**
- Must sanitize logs
- GDPR compliance
- Data retention policies

⚠️ **Complexity**
- More code to maintain
- Configuration needed
- Learning curve

### 4.3 Mitigation Strategies

**For Performance:**
- Async logging
- Sampling (not all events)
- Disabled by default

**For Privacy:**
- Clear sanitization guidelines
- Audit logging code
- Configurable scrubbing

**For Complexity:**
- Simple default setup
- Progressive disclosure
- Comprehensive docs

---

## 5. Implementation Plan

### Phase 1: Foundation (Week 1-2)
- [x] Create ADR-008
- [ ] Implement LogEntry and JLogger
- [ ] Create ConsoleLogger
- [ ] Add to JObservabilityConfig

### Phase 2: Metrics (Week 3-4)
- [ ] Implement Metric types
- [ ] Create JMetricsCollector
- [ ] Built-in metrics
- [ ] Integration with JObserver

### Phase 3: Tracing (Week 5-6)
- [ ] Implement TraceContext
- [ ] Create Span
- [ ] Intent tracing integration
- [ ] Documentation

### Phase 4: Advanced (Future)
- [ ] DevTools extension
- [ ] Time-travel debugging
- [ ] Performance profiler
- [ ] Service integrations

---

## 6. Examples

See code examples in sections 3.2-3.4 above.

---

## 7. Alternatives Considered

### Alternative 1: Use Existing Logging Package

**Approach:** Depend on `logging` package

**Pros:**
- Already exists
- Maintained
- Standard

**Cons:**
- External dependency
- May not match needs
- Less control

**Decision:** Rejected - Keep minimal dependencies

### Alternative 2: No Observability

**Approach:** Let consumers add their own

**Pros:**
- No code to maintain
- Maximum flexibility

**Cons:**
- Inconsistent implementations
- No guidance
- Poor experience

**Decision:** Rejected - Guidance and tools needed

### Alternative 3: Full APM Solution

**Approach:** Build complete APM like New Relic

**Pros:**
- Comprehensive
- All-in-one

**Cons:**
- Massive scope
- Not library's job
- Maintenance nightmare

**Decision:** Rejected - Provide hooks for integration

---

## 8. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Performance overhead in production | Medium | Medium | Sampling, async logging, benchmarks |
| Privacy violations | High | Low | Sanitization guidelines, audits |
| Integration complexity | Medium | Medium | Simple defaults, examples |
| DevTools maintenance | High | Low | Phase 4, community help |

---

## 9. Open Questions

### Q1: OpenTelemetry Support?

**Question:** Should we support OpenTelemetry standard?

**Answer:** Phase 4 - Valuable for enterprise users.

### Q2: Real-Time Streaming?

**Question:** Stream logs/metrics in real-time?

**Answer:** Phase 3 - WebSocket support for DevTools.

### Q3: Historical Storage?

**Question:** Store metrics/logs locally?

**Answer:** No - consumers choose storage backend.

---

## 10. References

### Internal Documents
- [ADR-000: Context and High-Level Decisions](./ADR-000-context-and-high-level-decisions.md)
- [ADR-005: Security Architecture](./ADR-005-security-architecture.md) - Secure logging
- [ADR-006: Error Handling Patterns](./ADR-006-error-handling-patterns.md) - Error logging

### External Resources
- [OpenTelemetry](https://opentelemetry.io/)
- [Structured Logging](https://www.elastic.co/guide/en/ecs/current/ecs-reference.html)
- [The Three Pillars of Observability](https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/ch04.html)
- [Flutter DevTools](https://docs.flutter.dev/development/tools/devtools/overview)

### Related ADRs
- ADR-005: Security (secure logging)
- ADR-006: Error Handling (error logging)
- ADR-009: Performance (performance metrics)

---

## 11. Approval & Sign-Off

### Reviewers

| Role | Name | Status | Date |
|------|------|--------|------|
| Project Lead | TodoFlutter.com | Pending | - |
| Technical Lead | TBD | Pending | - |
| Community | Open | Pending | - |

### Approval Criteria

- [ ] Observability pillars defined
- [ ] Logging framework specified
- [ ] Metrics collection designed
- [ ] Tracing support outlined
- [ ] Production guidance documented
- [ ] Implementation plan provided

### Next Steps After Approval

1. Mark ADR-008 as **Accepted**
2. Implement structured logging
3. Create metrics collector
4. Add tracing support
5. Write observability guide
6. Create integration examples

---

**Document Status:** Proposed  
**Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** After stakeholder approval

---

*This ADR establishes observability strategy for JIntent. It builds upon ADR-000 and complements ADR-005 (Security) and ADR-009 (Performance).*
