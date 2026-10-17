import 'package:counter/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jintent/devtools.dart';

import 'app_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Observability Integration Tests', () {
    setUp(() async {
      await prepareCounterApp();
      // Enable metrics for testing
      JMetrics.enable();
      JMetrics.clear();
      JMetrics.attachToObserver();
    });

    tearDown(() {
      JMetrics.disable();
      JMetrics.clear();
      // Clean up observers
      JObserver.onIntentDispatched = null;
      JObserver.onStateChanged = null;
      JObserver.onEffectEmitted = null;
    });

    testWidgets('metrics track intent dispatches', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      // Clear metrics before test actions
      JMetrics.clear();

      final incrementButton = find.byTooltip('Increment');

      // Perform actions
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Check metrics were recorded
      final intentMetrics = JMetrics.getMetricsByName('intent.dispatched');
      expect(intentMetrics.isNotEmpty, true);
    });

    testWidgets('metrics track state changes', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      // Clear metrics before test actions
      JMetrics.clear();

      final incrementButton = find.byTooltip('Increment');
      final decrementButton = find.byTooltip('Decrement');

      // Perform multiple state changes
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // Check state change metrics
      final stateMetrics = JMetrics.getMetricsByName('state.changed');
      expect(stateMetrics.isNotEmpty, true);
    });

    testWidgets('correlation ID propagates through user action', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      String? observedId;
      JObserver.onStateChanged = (previous, next, intent) {
        observedId = CorrelationContext.current;
      };
      await CorrelationContext.runWithCorrelation(() async {
        await tester.tap(find.byTooltip('Increment'));
        await tester.pumpAndSettle();
      }, correlationId: 'counter-integration');

      expect(observedId, 'counter-integration');
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('metrics summary is accurate', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      JMetrics.clear();

      final incrementButton = find.byTooltip('Increment');

      // Perform 3 increments
      for (int i = 0; i < 3; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      // Check summary
      final summary = JMetrics.getSummary();
      expect(summary['enabled'], true);
      expect(summary['totalMetrics'], greaterThan(0));
    });

    testWidgets('structured logger can be used during operations', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      // Create logger
      final logger = JStructuredLogger(
        serviceName: 'counter-test',
        minLevel: LogLevel.debug,
      );

      // Use logger with correlation context
      await CorrelationContext.runWithCorrelation(() async {
        final correlatedLogger = logger.withContext(
          CorrelationContext.asContext ?? {},
        );

        correlatedLogger.info('Starting counter test');

        final incrementButton = find.byTooltip('Increment');
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();

        correlatedLogger.info('Counter incremented');
      });

      // Test passes if no exceptions thrown
    });

    testWidgets('metrics can be exported and cleared', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      JMetrics.clear();

      final incrementButton = find.byTooltip('Increment');
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Get metrics
      final metrics = JMetrics.getMetrics();
      expect(metrics.isNotEmpty, true);

      // Clear metrics
      JMetrics.clear();

      final metricsAfterClear = JMetrics.getMetrics();
      expect(metricsAfterClear.isEmpty, true);
    });

    testWidgets('counter increments work correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      JMetrics.clear();

      final incrementButton = find.byTooltip('Increment');

      // First increment
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Second increment
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Get counter metrics
      final intentMetrics = JMetrics.getMetricsByName('intent.dispatched');

      // Each tap should have dispatched an intent
      expect(intentMetrics.length, greaterThanOrEqualTo(2));
    });

    testWidgets('observability works with error scenarios', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      JMetrics.clear();

      final incrementButton = find.byTooltip('Increment');

      // Go to max
      for (int i = 0; i < 10; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      // Try to exceed max (will trigger error handling)
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Metrics should still be recorded
      final summary = JMetrics.getSummary();
      expect(summary['totalMetrics'], greaterThan(0));
    });
  });
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: appRouter.routeInformationParser,
      routeInformationProvider: appRouter.routeInformationProvider,
      routerDelegate: appRouter.routerDelegate,
      title: 'Counter Observability Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
