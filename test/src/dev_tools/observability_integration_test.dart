import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

class TestState extends JState {
  final int value;

  const TestState({this.value = 0});

  TestState copyWith({int? value}) => TestState(value: value ?? this.value);

  @override
  List<Object?> get props => [value];
}

class TestIntent extends JIntent<TestState> with JIntentHelpers {
  final JStructuredLogger logger;
  final bool shouldFail;

  TestIntent(this.logger, {this.shouldFail = false});

  @override
  Future<void> onInvoke() async {
    await CorrelationContext.runWithCorrelation(() async {
      final correlatedLogger = logger.withContext(
        CorrelationContext.asContext ?? {},
      );

      correlatedLogger.info('Intent execution started');
      final timerId = JMetrics.startTimer('test.intent.duration');

      try {
        await Future.delayed(const Duration(milliseconds: 10));

        if (shouldFail) {
          throw Exception('Intentional failure');
        }

        JMetrics.incrementCounter('test.intent.success');
        JMetrics.stopTimer(timerId, tags: {'status': 'success'});
        correlatedLogger.info('Intent execution completed');

        update((state) => state.copyWith(value: state.value + 1));
      } catch (e) {
        JMetrics.incrementCounter('test.intent.failed');
        JMetrics.stopTimer(timerId, tags: {'status': 'failed'});
        correlatedLogger.error('Intent execution failed', error: e);
        rethrow;
      }
    });
  }
}

void main() {
  group('Observability Integration', () {
    late List<String> capturedLogs;
    late void Function(String?, {int? wrapWidth}) originalDebugPrint;
    late JStructuredLogger logger;
    late JController<TestState> controller;

    setUp(() {
      // Capture logs
      capturedLogs = [];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          capturedLogs.add(message);
        }
      };

      // Setup logger
      logger = JStructuredLogger(
        serviceName: 'test-service',
        version: '1.0.0',
        minLevel: LogLevel.debug,
      );

      // Enable metrics
      JMetrics.enable();
      JMetrics.clear();
      JMetrics.attachToObserver();

      // Create controller
      controller = JController(const TestState());
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
      JMetrics.disable();
      JMetrics.clear();
      controller.dispose();
      JObserver.onIntentDispatched = null;
      JObserver.onStateChanged = null;
      JObserver.onEffectEmitted = null;
    });

    test('complete observability flow - success case', () async {
      await controller.dispatch(TestIntent(logger));

      // Verify logs were captured
      expect(capturedLogs.isNotEmpty, true);

      // Parse and verify log structure
      final logs = capturedLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();

      // Should have start and completion logs
      final startLogs = logs.where((l) => l['message'].contains('started'));
      final completionLogs =
          logs.where((l) => l['message'].contains('completed'));

      expect(startLogs.isNotEmpty, true);
      expect(completionLogs.isNotEmpty, true);

      // Verify correlation ID was present
      final logsWithCorrelation =
          logs.where((l) => l['context']?['correlationId'] != null);
      expect(logsWithCorrelation.isNotEmpty, true);

      // Verify metrics were recorded
      final intentMetrics = JMetrics.getMetricsByName('intent.dispatched');
      expect(intentMetrics.isNotEmpty, true);

      final successMetrics = JMetrics.getMetricsByName('test.intent.success');
      expect(successMetrics.length, 1);

      final timerMetrics = JMetrics.getMetricsByName('test.intent.duration.duration');
      expect(timerMetrics.isNotEmpty, true);

      // Verify state was updated
      expect(controller.currentState.value, 1);
    });

    test('complete observability flow - failure case', () async {
      try {
        await controller.dispatch(TestIntent(logger, shouldFail: true));
        fail('Should have thrown exception');
      } catch (e) {
        expect(e.toString(), contains('Intentional failure'));
      }

      // Verify error log was captured
      final logs = capturedLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();

      final errorLogs = logs.where((l) => l['level'] == 'ERROR');
      expect(errorLogs.isNotEmpty, true);

      // Verify error has stack trace
      final errorLog = errorLogs.first;
      expect(errorLog['error'], isNotNull);

      // Verify failure metrics were recorded
      final failedMetrics = JMetrics.getMetricsByName('test.intent.failed');
      expect(failedMetrics.length, 1);

      // Verify timer was stopped with failed status
      final timerMetrics = JMetrics.getMetricsByName('test.intent.duration.duration');
      expect(timerMetrics.isNotEmpty, true);
      
      final failedTimers = timerMetrics.where((m) => m.tags['status'] == 'failed');
      expect(failedTimers.isNotEmpty, true);
    });

    test('correlation ID propagates through async operations', () async {
      String? capturedCorrelationId;

      await CorrelationContext.runWithCorrelation(() async {
        capturedCorrelationId = CorrelationContext.current;

        await controller.dispatch(TestIntent(logger));

        final idAfterDispatch = CorrelationContext.current;
        expect(idAfterDispatch, capturedCorrelationId);
      });

      // Verify correlation ID was in logs
      final logs = capturedLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();

      final logsWithCorrelation =
          logs.where((l) => l['context']?['correlationId'] == capturedCorrelationId);
      expect(logsWithCorrelation.isNotEmpty, true);
    });

    test('metrics summary is accurate', () async {
      // Execute multiple intents
      await controller.dispatch(TestIntent(logger));
      await controller.dispatch(TestIntent(logger));
      await controller.dispatch(TestIntent(logger));

      final summary = JMetrics.getSummary();

      expect(summary['enabled'], true);
      expect(summary['totalMetrics'], greaterThan(0));
      expect(summary['counterCount'], greaterThan(0));
      expect(summary['timerCount'], greaterThan(0));
    });

    test('child logger includes parent context', () async {
      final parentLogger = JStructuredLogger(
        serviceName: 'parent',
        defaultContext: {'env': 'test'},
      );

      final childLogger = parentLogger.withContext({'requestId': 'req-123'});
      childLogger.info('Child log');

      final logs = capturedLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();

      final childLog = logs.last;
      expect(childLog['context']['env'], 'test');
      expect(childLog['context']['requestId'], 'req-123');
      expect(childLog['service'], 'parent');
    });

    test('metrics can be filtered by name and type', () async {
      await controller.dispatch(TestIntent(logger));
      await controller.dispatch(TestIntent(logger));

      final intentMetrics = JMetrics.getMetricsByName('intent.dispatched');
      expect(intentMetrics.length, greaterThanOrEqualTo(2));

      final counters = JMetrics.getMetricsByType(MetricType.counter);
      expect(counters.isNotEmpty, true);

      final timers = JMetrics.getMetricsByType(MetricType.timer);
      expect(timers.isNotEmpty, true);
    });

    test('log levels are respected', () async {
      final infoLogger = JStructuredLogger(minLevel: LogLevel.info);

      infoLogger.debug('Debug message');
      infoLogger.info('Info message');
      infoLogger.warn('Warn message');

      final logs = capturedLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();

      // Debug message should be filtered out
      final debugLogs = logs.where((l) => l['level'] == 'DEBUG');
      expect(debugLogs.isEmpty, true);

      // Info and warn should be present
      final infoLogs = logs.where((l) => l['level'] == 'INFO');
      final warnLogs = logs.where((l) => l['level'] == 'WARN');
      expect(infoLogs.isNotEmpty, true);
      expect(warnLogs.isNotEmpty, true);
    });

    test('metrics can be exported and cleared', () async {
      await controller.dispatch(TestIntent(logger));

      final metricsBefore = JMetrics.getMetrics();
      expect(metricsBefore.isNotEmpty, true);

      // Export to JSON
      final jsonMetrics = metricsBefore.map((m) => m.toJson()).toList();
      expect(jsonMetrics.isNotEmpty, true);

      // Each metric should have required fields
      for (final metric in jsonMetrics) {
        expect(metric['name'], isNotNull);
        expect(metric['type'], isNotNull);
        expect(metric['value'], isNotNull);
        expect(metric['timestamp'], isNotNull);
      }

      // Clear metrics
      JMetrics.clear();
      final metricsAfter = JMetrics.getMetrics();
      expect(metricsAfter.isEmpty, true);
    });

    test('observer integration records all events', () async {
      await controller.dispatch(TestIntent(logger));

      // Verify intent dispatch was recorded
      final intentMetrics = JMetrics.getMetricsByName('intent.dispatched');
      expect(intentMetrics.isNotEmpty, true);

      // Verify state change was recorded
      final stateMetrics = JMetrics.getMetricsByName('state.changed');
      expect(stateMetrics.isNotEmpty, true);
    });
  });
}
