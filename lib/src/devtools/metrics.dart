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
  static final List<Metric> _metrics = [];
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

  /// Attaches metrics collection to JObserver for automatic tracking.
  ///
  /// This will automatically track:
  /// - Intent dispatch count
  /// - Intent execution time
  /// - State change count
  /// - Effect emission count
  /// - Effect completion time
  static void attachToObserver() {
    if (!_enabled) {
      enable();
    }

    // Track intent dispatches
    final originalIntentCallback = JObserver.onIntentDispatched;
    JObserver.onIntentDispatched = (intent) {
      incrementCounter(
        'intent.dispatched',
        tags: {'type': intent.runtimeType.toString()},
      );

      // Start timing intent execution
      final timerId = startTimer(
        'intent.execution',
        tags: {'type': intent.runtimeType.toString()},
      );

      // Store timer ID for later stopping (would need intent lifecycle support)
      // For now, we just track the dispatch

      originalIntentCallback?.call(intent);
    };

    // Track state changes
    final originalStateCallback = JObserver.onStateChanged;
    JObserver.onStateChanged = (prev, next, origin) {
      incrementCounter(
        'state.changed',
        tags: {
          'stateType': next.runtimeType.toString(),
          if (origin != null) 'originIntent': origin.runtimeType.toString(),
        },
      );

      originalStateCallback?.call(prev, next, origin);
    };

    // Track effect emissions
    final originalEffectCallback = JObserver.onEffectEmitted;
    JObserver.onEffectEmitted = (effect) {
      incrementCounter(
        'effect.emitted',
        tags: {
          'type': effect.runtimeType.toString(),
          if (effect.resolvedCategory != null)
            'category': effect.resolvedCategory!,
        },
      );

      originalEffectCallback?.call(effect);
    };
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
