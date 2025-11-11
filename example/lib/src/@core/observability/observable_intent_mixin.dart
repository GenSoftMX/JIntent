import 'package:jintent/jintent.dart';
import 'observability_setup.dart';

/// Mixin that adds observability features to intents.
/// 
/// Provides easy access to logging and metrics within intents.
/// 
/// Example:
/// ```dart
/// class MyIntent extends JIntent<MyState> 
///     with JIntentHelpers, ObservableIntentMixin {
///   @override
///   Future<void> onInvoke() async {
///     logInfo('Intent started');
///     trackMetric('operation.count');
///     
///     try {
///       await performOperation();
///       logInfo('Intent completed');
///     } catch (e) {
///       logError('Intent failed', error: e);
///       rethrow;
///     }
///   }
/// }
/// ```
mixin ObservableIntentMixin<T extends JState> on JIntent<T> {
  /// Gets the logger with correlation context if available.
  JStructuredLogger get logger {
    final baseLogger = ObservabilitySetup.logger;
    final correlationContext = CorrelationContext.asContext;
    
    if (correlationContext != null) {
      return baseLogger.withContext({
        ...correlationContext,
        'intentType': runtimeType.toString(),
      });
    }
    
    return baseLogger.withContext({
      'intentType': runtimeType.toString(),
    });
  }

  /// Logs an info-level message.
  void logInfo(String message, {Map<String, dynamic>? context}) {
    logger.info(message, context: context);
  }

  /// Logs a debug-level message.
  void logDebug(String message, {Map<String, dynamic>? context}) {
    logger.debug(message, context: context);
  }

  /// Logs a warning-level message.
  void logWarn(String message, {Map<String, dynamic>? context, Object? error}) {
    logger.warn(message, context: context, error: error);
  }

  /// Logs an error-level message.
  void logError(
    String message, {
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.error(
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Increments a counter metric.
  void trackMetric(String name, {Map<String, String>? tags}) {
    JMetrics.incrementCounter(name, tags: tags);
  }

  /// Starts a timer for measuring operation duration.
  /// 
  /// Returns a timer ID that should be passed to [stopTimer].
  String startTimer(String name, {Map<String, String>? tags}) {
    return JMetrics.startTimer(name, tags: tags);
  }

  /// Stops a timer and records the duration.
  void stopTimer(String timerId, {Map<String, String>? tags}) {
    JMetrics.stopTimer(timerId, tags: tags);
  }

  /// Wraps intent execution with automatic timing and logging.
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> onInvoke() async {
  ///   await withObservability(() async {
  ///     // Your intent logic here
  ///     await performOperation();
  ///   });
  /// }
  /// ```
  Future<void> withObservability(
    Future<void> Function() operation, {
    String? operationName,
  }) async {
    final name = operationName ?? runtimeType.toString();
    final timerId = startTimer('$name.duration');
    
    logDebug('$name started');
    
    try {
      await operation();
      stopTimer(timerId, tags: {'status': 'success'});
      logDebug('$name completed successfully');
    } catch (e, stackTrace) {
      stopTimer(timerId, tags: {'status': 'error'});
      logError(
        '$name failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Wraps intent execution with correlation context, timing, and logging.
  /// 
  /// This is the recommended way to execute observable intents.
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> onInvoke() async {
  ///   await withFullObservability(() async {
  ///     // Your intent logic here
  ///     // Correlation ID is automatically propagated
  ///     await performOperation();
  ///   });
  /// }
  /// ```
  Future<void> withFullObservability(
    Future<void> Function() operation, {
    String? operationName,
    String? correlationId,
  }) async {
    await CorrelationContext.runWithCorrelation(
      () => withObservability(operation, operationName: operationName),
      correlationId: correlationId,
    );
  }
}
