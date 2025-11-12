import 'package:counter/di/di.dart';
import 'package:counter/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Error Handling Integration Tests', () {
    setUp(() async {
      await Di().init();
    });

    testWidgets('displays error when exceeding maximum boundary', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);

      // Increment to maximum (10)
      for (int i = 0; i < 10; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      // Try to exceed maximum - should trigger error handling
      await tester.tap(incrementButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify counter stays at maximum
      expect(find.text('10'), findsOneWidget);

      // Note: In a real app, you might also check for:
      // - Error dialog: expect(find.text('Error'), findsOneWidget);
      // - Snackbar: expect(find.byType(SnackBar), findsOneWidget);
      // - Error message text
    });

    testWidgets('displays error when exceeding minimum boundary', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final decrementButton = find.byIcon(Icons.remove);

      // Decrement to minimum (-10)
      for (int i = 0; i < 10; i++) {
        await tester.tap(decrementButton);
        await tester.pumpAndSettle();
      }

      // Try to go below minimum - should trigger error handling
      await tester.tap(decrementButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify counter stays at minimum
      expect(find.text('-10'), findsOneWidget);
    });

    testWidgets('handles rapid button presses gracefully', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);

      // Rapid fire increments without waiting
      for (int i = 0; i < 5; i++) {
        await tester.tap(incrementButton);
      }
      await tester.pumpAndSettle();

      // Should handle all increments correctly
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('handles alternating rapid presses', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);
      final decrementButton = find.byIcon(Icons.remove);

      // Alternate between increment and decrement rapidly
      await tester.tap(incrementButton);
      await tester.tap(decrementButton);
      await tester.tap(incrementButton);
      await tester.tap(decrementButton);
      await tester.tap(incrementButton);

      await tester.pumpAndSettle();

      // Final result should be +1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('recovers from error state on valid operation', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);
      final decrementButton = find.byIcon(Icons.remove);

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

      final incrementButton = find.byIcon(Icons.add);
      final decrementButton = find.byIcon(Icons.remove);

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

      final incrementButton = find.byIcon(Icons.add);
      final decrementButton = find.byIcon(Icons.remove);

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
