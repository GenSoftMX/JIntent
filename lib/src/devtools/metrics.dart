import 'dart:collection';

import 'package:jintent/src/core/core.dart';
import 'package:jintent/src/devtools/jobserver.dart';

/// Metric types supported by JMetrics.
enum MetricType { counter, gauge, histogram, timer }

/// A single metric measurement.
class Metric {
  final String name;
  final MetricType type;
  final num value;
  final DateTime timestamp;
  final Map<String, String> tags;

  Metric({
    required this.name,
    required this.type,
    required this.value,
    DateTime? timestamp,
    Map<String, String>? tags,
  }) : timestamp = timestamp ?? DateTime.now().toUtc(),
       tags = tags ?? {};

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    if (tags.isNotEmpty) 'tags': tags,
  };
}

/// Metrics collection framework for JIntent.
///
/// Provides performance and operational metrics for:
/// - Intent execution time
/// - Effect completion time
/// - State update frequency
/// - Error rates
///
/// Example usage:
/// ```dart
/// void main() {
///   // Enable metrics collection
///   JMetrics.enable();
///
///   // Optionally attach to JObserver for automatic metrics
///   JMetrics.attachToObserver();
///
///   runApp(MyApp());
/// }
///
/// // Later, retrieve metrics
/// final metrics = JMetrics.getMetrics();
/// print('Total intents: ${metrics.where((m) => m.name == 'intent.dispatched').length}');
/// ```
class JMetrics {
  static bool _enabled = false;

  /// Maximum number of metrics retained; the oldest are dropped first.
  ///
  /// Counters and timers keep recording while old measurements are discarded,
  /// so long sessions do not grow memory without bound. Values below 1 are
  /// treated as 1.
  static int maxMetrics = defaultMaxMetrics;

  /// The value [maxMetrics] has until it is changed or [reset].
  static const int defaultMaxMetrics = 1000;

  static final _metrics = Queue<Metric>();
  static final _observer = _MetricsObserver();
  static final Map<String, DateTime> _timers = {};
  static final Map<String, int> _counters = {};

  /// Enables metrics collection.
  static void enable() {
    _enabled = true;
  }

  /// Disables metrics collection.
  static void disable() {
    _enabled = false;
  }

  /// Restores the initial state: disabled, detached from [JObserver], no
  /// metrics and the default [maxMetrics].
  static void reset() {
    disable();
    detachFromObserver();
    clear();
    maxMetrics = defaultMaxMetrics;
  }

  /// Clears all collected metrics.
  static void clear() {
    _metrics.clear();
    _timers.clear();
    _counters.clear();
  }

  /// Records a metric.
  static void record(Metric metric) {
    if (!_enabled) return;
    _metrics.add(metric);
    final limit = maxMetrics < 1 ? 1 : maxMetrics;
    while (_metrics.length > limit) {
      _metrics.removeFirst();
    }
  }

  /// Increments a counter metric.
  static void incrementCounter(String name, {Map<String, String>? tags}) {
    if (!_enabled) return;

    final key = _keyWithTags(name, tags);
    _counters[key] = (_counters[key] ?? 0) + 1;

    record(
      Metric(
        name: name,
        type: MetricType.counter,
        value: _counters[key]!,
        tags: tags,
      ),
    );
  }

  /// Records a gauge metric (a value that can go up or down).
  static void recordGauge(String name, num value, {Map<String, String>? tags}) {
    if (!_enabled) return;

    record(
      Metric(name: name, type: MetricType.gauge, value: value, tags: tags),
    );
  }

  /// Starts a timer for measuring duration.
  ///
  /// Returns a timer ID that should be passed to [stopTimer].
  static String startTimer(String name, {Map<String, String>? tags}) {
    if (!_enabled) return '';

    final timerId = _keyWithTags(name, tags);
    _timers[timerId] = DateTime.now();
    return timerId;
  }

  /// Stops a timer and records the duration.
  static void stopTimer(String timerId, {Map<String, String>? tags}) {
    if (!_enabled) return;

    final startTime = _timers.remove(timerId);
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    final name = timerId.split('|').first;

    record(
      Metric(
        name: '$name.duration',
        type: MetricType.timer,
        value: duration.inMicroseconds,
        tags: {...?tags, 'unit': 'microseconds'},
      ),
    );
  }

  /// Records a histogram value (useful for distributions).
  static void recordHistogram(
    String name,
    num value, {
    Map<String, String>? tags,
  }) {
    if (!_enabled) return;

    record(
      Metric(name: name, type: MetricType.histogram, value: value, tags: tags),
    );
  }

  /// Gets all collected metrics.
  static List<Metric> getMetrics() {
    return List.unmodifiable(_metrics);
  }

  /// Gets metrics filtered by name.
  static List<Metric> getMetricsByName(String name) {
    return _metrics.where((m) => m.name == name).toList();
  }

  /// Gets metrics filtered by type.
  static List<Metric> getMetricsByType(MetricType type) {
    return _metrics.where((m) => m.type == type).toList();
  }

  /// Attaches metrics collection to [JObserver] for automatic tracking.
  ///
  /// Registers a [JObserverDelegate], so it coexists with other observers and
  /// callbacks. Calling it again is a no-op; [detachFromObserver] unregisters
  /// it. This tracks:
  /// - `intent.dispatched`, `intent.failed`, `intent.cancelled` and
  ///   `intent.dropped` counters, tagged by type
  /// - `intent.execution.duration` timers (microseconds) covering
  ///   [JIntent.onInvoke] only; time spent waiting in a dispatcher queue is
  ///   not included
  /// - `state.changed` and `effect.emitted` counters
  ///
  /// Effect completion time is not measured.
  static void attachToObserver() {
    if (!_enabled) {
      enable();
    }
    JObserver.addObserver(_observer);
  }

  /// Stops the automatic tracking installed by [attachToObserver].
  static void detachFromObserver() {
    JObserver.removeObserver(_observer);
  }

  /// Gets a summary of metrics as a map.
  static Map<String, dynamic> getSummary() {
    final summary = <String, dynamic>{
      'enabled': _enabled,
      'totalMetrics': _metrics.length,
      'activeTimers': _timers.length,
      'counters': Map<String, int>.from(_counters),
    };

    // Add metric counts by type
    for (final type in MetricType.values) {
      final count = _metrics.where((m) => m.type == type).length;
      summary['${type.name}Count'] = count;
    }

    return summary;
  }

  static String _keyWithTags(String name, Map<String, String>? tags) {
    if (tags == null || tags.isEmpty) return name;
    final tagStr = tags.entries.map((e) => '${e.key}=${e.value}').join(',');
    return '$name|$tagStr';
  }
}

class _MetricsObserver extends JObserverDelegate {
  // Weak association: an intent that never reports completion cannot leak.
  final _started = Expando<Stopwatch>('JMetrics.intentStopwatch');

  @override
  void onIntentStarted(JIntent intent) {
    _started[intent] = Stopwatch()..start();
  }

  @override
  void onIntentDispatched(JIntent intent) {
    final type = {'type': intent.runtimeType.toString()};
    JMetrics.incrementCounter('intent.dispatched', tags: type);
    _recordDuration(intent, type);
  }

  @override
  void onIntentCancelled(JIntent intent) {
    final type = {'type': intent.runtimeType.toString()};
    JMetrics.incrementCounter('intent.cancelled', tags: type);
    _recordDuration(intent, type);
  }

  @override
  void onIntentDropped(JIntent intent) {
    JMetrics.incrementCounter(
      'intent.dropped',
      tags: {'type': intent.runtimeType.toString()},
    );
  }

  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) {
    final type = {'type': intent.runtimeType.toString()};
    JMetrics.incrementCounter('intent.failed', tags: type);
    _recordDuration(intent, type);
  }

  void _recordDuration(JIntent intent, Map<String, String> type) {
    final stopwatch = _started[intent];
    if (stopwatch == null) return;
    _started[intent] = null;
    stopwatch.stop();
    JMetrics.record(
      Metric(
        name: 'intent.execution.duration',
        type: MetricType.timer,
        value: stopwatch.elapsedMicroseconds,
        tags: {...type, 'unit': 'microseconds'},
      ),
    );
  }

  @override
  void onStateChanged(JState prev, JState next, JIntent? origin) {
    JMetrics.incrementCounter(
      'state.changed',
      tags: {
        'stateType': next.runtimeType.toString(),
        if (origin != null) 'originIntent': origin.runtimeType.toString(),
      },
    );
  }

  @override
  void onEffectEmitted(JEffect effect) {
    JMetrics.incrementCounter(
      'effect.emitted',
      tags: {
        'type': effect.runtimeType.toString(),
        if (effect.resolvedCategory != null)
          'category': effect.resolvedCategory!,
      },
    );
  }
}
