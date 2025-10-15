import 'package:counter/di/di.dart';
import 'package:counter/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jintent/jintent.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Counter Flow Integration Tests', () {
    setUp(() async {
      await Di().init();
    });

    testWidgets('complete increment flow', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      // Find the counter display
      final counterText = find.text('0');
      expect(counterText, findsOneWidget);

      // Find and tap increment button
      final incrementButton = find.byIcon(Icons.add);
      expect(incrementButton, findsOneWidget);
      
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Verify counter increased
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('complete decrement flow', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      // Start at 0
      expect(find.text('0'), findsOneWidget);

      // Decrement
      final decrementButton = find.byIcon(Icons.remove);
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // Verify counter decreased
      expect(find.text('-1'), findsOneWidget);
    });

    testWidgets('multiple increments work correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);
      
      // Increment 3 times
      for (int i = 0; i < 3; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('increment and decrement combination', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);
      final decrementButton = find.byIcon(Icons.remove);

      // Increment 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }
      expect(find.text('5'), findsOneWidget);

      // Decrement 2 times
      for (int i = 0; i < 2; i++) {
        await tester.tap(decrementButton);
        await tester.pumpAndSettle();
      }
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('boundary validation at maximum', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);

      // Increment to maximum (10)
      for (int i = 0; i < 10; i++) {
        await tester.tap(incrementButton);
        await tester.pumpAndSettle();
      }
      expect(find.text('10'), findsOneWidget);

      // Try to exceed maximum
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Should show error dialog or snackbar
      // Counter should remain at 10
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('boundary validation at minimum', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final decrementButton = find.byIcon(Icons.remove);

      // Decrement to minimum (-10)
      for (int i = 0; i < 10; i++) {
        await tester.tap(decrementButton);
        await tester.pumpAndSettle();
      }
      expect(find.text('-10'), findsOneWidget);

      // Try to go below minimum
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // Counter should remain at -10
      expect(find.text('-10'), findsOneWidget);
    });

    testWidgets('UI reflects state correctly after multiple operations', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TestApp()));
      await tester.pumpAndSettle();

      final incrementButton = find.byIcon(Icons.add);
      final decrementButton = find.byIcon(Icons.remove);

      // Complex sequence
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Final value should be 4 (0 + 2 - 1 + 3)
      expect(find.text('4'), findsOneWidget);
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
      title: 'Counter Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
