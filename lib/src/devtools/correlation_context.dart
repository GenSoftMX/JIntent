import 'dart:async';

/// Manages correlation IDs for tracking operations across the application.
///
/// Correlation IDs help trace a single user action or request through
/// multiple layers of the application (intents, state changes, effects, etc.).
///
/// This is particularly useful for:
/// - Debugging complex flows
/// - Tracing user actions in logs
/// - Correlating errors with their originating actions
/// - Performance monitoring
///
/// Example usage:
/// ```dart
/// // At the start of a user action:
/// await CorrelationContext.runWithCorrelation(() async {
///   // All code here will have access to the same correlation ID
///   controller.dispatch(LoginIntent());
/// });
///
/// // In any part of the code:
/// final id = CorrelationContext.current;
/// logger.info('Processing login', context: {'correlationId': id});
/// ```
class CorrelationContext {
  static const _correlationIdKey = #correlationId;
  static int _counter = 0;

  /// Gets the current correlation ID from the zone, or null if not in a correlated context.
  static String? get current {
    return Zone.current[_correlationIdKey] as String?;
  }

  /// Runs the given function with a new correlation ID.
  ///
  /// All code executed within [fn] (including async operations) will have
  /// access to the same correlation ID via [current].
  ///
  /// If [correlationId] is provided, it will be used; otherwise, a new one
  /// will be generated.
  static Future<T> runWithCorrelation<T>(
    Future<T> Function() fn, {
    String? correlationId,
  }) async {
    final id = correlationId ?? _generateId();

    return await runZoned(fn, zoneValues: {_correlationIdKey: id});
  }

  /// Runs the given synchronous function with a new correlation ID.
  ///
  /// Similar to [runWithCorrelation], but for synchronous code.
  static T runSyncWithCorrelation<T>(T Function() fn, {String? correlationId}) {
    final id = correlationId ?? _generateId();

    return runZoned(fn, zoneValues: {_correlationIdKey: id});
  }

  /// Generates a unique correlation ID.
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final counter = _counter++;
    return '$timestamp-$counter';
  }

  /// Gets the correlation ID as a map entry for easy inclusion in context maps.
  static Map<String, String>? get asContext {
    final id = current;
    return id != null ? {'correlationId': id} : null;
  }

  /// Resets the internal counter (useful for testing).
  static void resetCounter() {
    _counter = 0;
  }
}
