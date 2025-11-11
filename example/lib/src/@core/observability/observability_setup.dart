import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

/// Sets up observability features for the application.
///
/// This includes:
/// - Structured logging
/// - Metrics collection
/// - Observer callbacks
///
/// Call this during app initialization.
class ObservabilitySetup {
  static JStructuredLogger? _logger;
  static bool _initialized = false;

  /// Gets the application logger instance.
  static JStructuredLogger get logger {
    if (_logger == null) {
      throw StateError(
        'Observability not initialized. Call ObservabilitySetup.initialize() first.',
      );
    }
    return _logger!;
  }

  /// Initializes observability features.
  ///
  /// Should be called once during app initialization.
  static void initialize({
    String serviceName = 'counter-app',
    String version = '1.0.0',
    LogLevel minLevel = LogLevel.debug,
    bool enableMetrics = true,
  }) {
    if (_initialized) {
      return;
    }

    // Setup structured logging
    _logger = JStructuredLogger(
      serviceName: serviceName,
      version: version,
      minLevel: minLevel,
      defaultContext: {
        'env': kReleaseMode ? 'production' : 'development',
        'platform': defaultTargetPlatform.name,
      },
    );

    // Enable basic logging observer
    enableLoggingObserver();

    // Enable metrics if requested
    if (enableMetrics) {
      JMetrics.enable();
      JMetrics.attachToObserver();

      _logger?.info('Metrics collection enabled');
    }

    _logger?.info(
      'Observability initialized',
      context: {
        'serviceName': serviceName,
        'version': version,
        'metricsEnabled': enableMetrics,
      },
    );

    _initialized = true;
  }

  /// Gets current metrics summary.
  static Map<String, dynamic> getMetricsSummary() {
    return JMetrics.getSummary();
  }

  /// Exports and clears current metrics.
  ///
  /// Returns the list of metrics that were cleared.
  static List<Metric> exportAndClearMetrics() {
    final metrics = JMetrics.getMetrics();
    JMetrics.clear();

    _logger?.info('Metrics exported', context: {'count': metrics.length});

    return metrics;
  }

  /// Creates a child logger with additional context.
  static JStructuredLogger createChildLogger(Map<String, dynamic> context) {
    return logger.withContext(context);
  }
}
