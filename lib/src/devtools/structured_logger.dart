import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Log levels for structured logging.
enum LogLevel {
  trace(0, 'TRACE'),
  debug(1, 'DEBUG'),
  info(2, 'INFO'),
  warn(3, 'WARN'),
  error(4, 'ERROR');

  const LogLevel(this.value, this.name);
  final int value;
  final String name;
}

/// Structured logger that outputs JSON-formatted log messages.
///
/// This logger provides:
/// - Structured JSON output for easier parsing and analysis
/// - Log levels (trace, debug, info, warn, error)
/// - Timestamps for all log entries
/// - Context propagation through correlation IDs
/// - PII handling guidance (user must redact sensitive data)
///
/// Example usage:
/// ```dart
/// void main() {
///   final logger = JStructuredLogger(
///     minLevel: LogLevel.info,
///     serviceName: 'my-app',
///   );
///
///   logger.info('User logged in', context: {
///     'userId': '12345',
///     'correlationId': 'abc-123',
///   });
/// }
/// ```
class JStructuredLogger {
  final LogLevel minLevel;
  final String? serviceName;
  final String? version;
  final Map<String, dynamic> defaultContext;

  /// Creates a structured logger with the specified configuration.
  ///
  /// - [minLevel]: Minimum log level to output (default: debug)
  /// - [serviceName]: Name of the service/app for log identification
  /// - [version]: Version of the service/app
  /// - [defaultContext]: Default context to include in all log messages
  JStructuredLogger({
    this.minLevel = LogLevel.debug,
    this.serviceName,
    this.version,
    Map<String, dynamic>? defaultContext,
  }) : defaultContext = defaultContext ?? {};

  /// Logs a message at the specified level.
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.value < minLevel.value) {
      return;
    }

    final logEntry = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level.name,
      'message': message,
    };

    if (serviceName != null) {
      logEntry['service'] = serviceName;
    }

    if (version != null) {
      logEntry['version'] = version;
    }

    // Merge default context with provided context
    final mergedContext = <String, dynamic>{
      ...defaultContext,
      if (context != null) ...context,
    };

    if (mergedContext.isNotEmpty) {
      logEntry['context'] = mergedContext;
    }

    if (error != null) {
      logEntry['error'] = error.toString();
    }

    if (stackTrace != null) {
      logEntry['stackTrace'] = stackTrace.toString();
    }

    final jsonOutput = jsonEncode(logEntry);

    if (kDebugMode) {
      debugPrint(jsonOutput);
    }
  }

  /// Logs a trace-level message.
  void trace(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.trace, message, context: context);
  }

  /// Logs a debug-level message.
  void debug(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.debug, message, context: context);
  }

  /// Logs an info-level message.
  void info(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.info, message, context: context);
  }

  /// Logs a warning-level message.
  void warn(String message, {Map<String, dynamic>? context, Object? error}) {
    log(LogLevel.warn, message, context: context, error: error);
  }

  /// Logs an error-level message.
  void error(
    String message, {
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.error,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Creates a child logger with additional default context.
  ///
  /// Useful for creating loggers with specific context (e.g., per-request logger
  /// with correlation ID).
  JStructuredLogger withContext(Map<String, dynamic> additionalContext) {
    return JStructuredLogger(
      minLevel: minLevel,
      serviceName: serviceName,
      version: version,
      defaultContext: {...defaultContext, ...additionalContext},
    );
  }
}
