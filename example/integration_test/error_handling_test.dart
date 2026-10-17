import 'package:counter/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_setup.dart';

/// Longer than the counter view's 200 ms throttle interval.
const _afterThrottle = Duration(milliseconds: 400);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Error Handling Integration Tests', () {
    setUp(() async {
      await prepareCounterApp();
    });

    testWidgets('displays error when exceeding maximum boundary', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byTooltip('Increment');

      // Increment to maximum (10)
      for (int i = 0; i < 10; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      // Try to exceed maximum - should trigger error handling
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Verify counter stays at maximum
      expect(find.text('10'), findsOneWidget);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Value cannot be greater than 10'),
        findsOneWidget,
      );
    });

    testWidgets('displays error when exceeding minimum boundary', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final decrementButton = find.byTooltip('Decrement');

      // Decrement to minimum (-10)
      for (int i = 0; i < 10; i++) {
        await tester.tap(decrementButton);
        await tester.pumpAndSettle();
      }

      // Try to go below minimum - should trigger error handling
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // Verify counter stays at minimum
      expect(find.text('-10'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Value cannot be less than -10'),
        findsOneWidget,
      );
    });

    testWidgets('handles rapid button presses gracefully', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byTooltip('Increment');

      // Rapid fire increments without waiting. The view's JThrottler runs the
      // first tap at once and, when its interval ends, only the latest one.
      for (int i = 0; i < 5; i++) {
        await tester.tap(incrementButton);
      }
      await tester.pump(_afterThrottle);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('handles alternating rapid presses', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byTooltip('Increment');
      final decrementButton = find.byTooltip('Decrement');

      // Alternate between increment and decrement rapidly
      await tester.tap(incrementButton);
      await tester.tap(decrementButton);
      await tester.tap(incrementButton);
      await tester.tap(decrementButton);
      await tester.tap(incrementButton);

      // The first tap (+1) runs at once and the latest one (+1) when the
      // throttle interval ends; the ones in between are discarded.
      await tester.pump(_afterThrottle);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('recovers from error state on valid operation', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byTooltip('Increment');
      final decrementButton = find.byTooltip('Decrement');

      // Go to maximum
      for (int i = 0; i < 10; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      // Try to exceed (error state)
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Now perform valid operation (decrement)
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // Should recover and show 9
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('maintains state consistency during error conditions', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byTooltip('Increment');
      final decrementButton = find.byTooltip('Decrement');

      // Complex scenario with multiple error conditions

      // Go to max
      for (int i = 0; i < 10; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }
      expect(find.text('10'), findsOneWidget);

      // Try to exceed multiple times
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Should still be at max
      expect(find.text('10'), findsOneWidget);

      // Go to min
      for (int i = 0; i < 20; i++) {
        await tester.tap(decrementButton);
        await tester.pumpAndSettle();
      }
      expect(find.text('-10'), findsOneWidget);

      // Try to go below multiple times
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // Should still be at min
      expect(find.text('-10'), findsOneWidget);

      // Return to middle value
      for (int i = 0; i < 5; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      // Should be at -5
      expect(find.text('-5'), findsOneWidget);
    });

    testWidgets('UI remains responsive after errors', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byTooltip('Increment');
      final decrementButton = find.byTooltip('Decrement');

      // Trigger error by exceeding max
      for (int i = 0; i < 11; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      // UI should still be responsive
      expect(incrementButton, findsOneWidget);
      expect(decrementButton, findsOneWidget);

      // Should be able to perform operations
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);
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
      title: 'Counter Error Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
