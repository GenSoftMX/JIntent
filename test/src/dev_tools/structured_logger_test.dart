import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('JStructuredLogger', () {
    late List<String> capturedLogs;
    late void Function(String?, {int? wrapWidth}) originalDebugPrint;

    setUp(() {
      capturedLogs = [];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          capturedLogs.add(message);
        }
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    test('logs structured JSON messages', () {
      final logger = JStructuredLogger();
      logger.info('Test message');

      expect(capturedLogs.length, 1);
      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      
      expect(logEntry['level'], 'INFO');
      expect(logEntry['message'], 'Test message');
      expect(logEntry['timestamp'], isNotNull);
    });

    test('respects minimum log level', () {
      final logger = JStructuredLogger(minLevel: LogLevel.warn);
      
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warn('Warn message');

      expect(capturedLogs.length, 1);
      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      expect(logEntry['level'], 'WARN');
    });

    test('includes service name and version', () {
      final logger = JStructuredLogger(
        serviceName: 'test-service',
        version: '1.0.0',
      );
      logger.info('Test');

      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      expect(logEntry['service'], 'test-service');
      expect(logEntry['version'], '1.0.0');
    });

    test('includes custom context', () {
      final logger = JStructuredLogger();
      logger.info('Test', context: {
        'userId': '12345',
        'action': 'login',
      });

      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      expect(logEntry['context']['userId'], '12345');
      expect(logEntry['context']['action'], 'login');
    });

    test('includes error and stack trace', () {
      final logger = JStructuredLogger();
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      
      logger.error('Error occurred', error: error, stackTrace: stackTrace);

      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      expect(logEntry['error'], contains('Test error'));
      expect(logEntry['stackTrace'], isNotNull);
    });

    test('merges default context with provided context', () {
      final logger = JStructuredLogger(
        defaultContext: {'env': 'test', 'region': 'us-east'},
      );
      
      logger.info('Test', context: {'userId': '12345'});

      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      expect(logEntry['context']['env'], 'test');
      expect(logEntry['context']['region'], 'us-east');
      expect(logEntry['context']['userId'], '12345');
    });

    test('withContext creates child logger with additional context', () {
      final parentLogger = JStructuredLogger(
        defaultContext: {'env': 'test'},
      );
      
      final childLogger = parentLogger.withContext({'correlationId': 'abc-123'});
      childLogger.info('Test');

      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      expect(logEntry['context']['env'], 'test');
      expect(logEntry['context']['correlationId'], 'abc-123');
    });

    test('all log level methods work correctly', () {
      final logger = JStructuredLogger(minLevel: LogLevel.trace);
      
      logger.trace('Trace message');
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warn('Warn message');
      logger.error('Error message');

      expect(capturedLogs.length, 5);
      
      final levels = capturedLogs.map((log) {
        final entry = jsonDecode(log) as Map<String, dynamic>;
        return entry['level'];
      }).toList();

      expect(levels, ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR']);
    });

    test('child logger inherits parent configuration', () {
      final parent = JStructuredLogger(
        minLevel: LogLevel.info,
        serviceName: 'parent-service',
        version: '1.0.0',
      );
      
      final child = parent.withContext({'requestId': 'req-123'});
      child.debug('Should not log');
      child.info('Should log');

      expect(capturedLogs.length, 1);
      final logEntry = jsonDecode(capturedLogs[0]) as Map<String, dynamic>;
      expect(logEntry['service'], 'parent-service');
      expect(logEntry['version'], '1.0.0');
    });
  });

  group('LogLevel', () {
    test('has correct ordering', () {
      expect(LogLevel.trace.value < LogLevel.debug.value, true);
      expect(LogLevel.debug.value < LogLevel.info.value, true);
      expect(LogLevel.info.value < LogLevel.warn.value, true);
      expect(LogLevel.warn.value < LogLevel.error.value, true);
    });

    test('has correct names', () {
      expect(LogLevel.trace.name, 'TRACE');
      expect(LogLevel.debug.name, 'DEBUG');
      expect(LogLevel.info.name, 'INFO');
      expect(LogLevel.warn.name, 'WARN');
      expect(LogLevel.error.name, 'ERROR');
    });
  });
}
