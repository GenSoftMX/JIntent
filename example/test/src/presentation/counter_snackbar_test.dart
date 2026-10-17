import 'package:counter/di/di.dart';
import 'package:counter/src/domain/use_cases/decrement_use_case.dart';
import 'package:counter/src/domain/use_cases/get_current_value_use_case.dart';
import 'package:counter/src/domain/use_cases/increment_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/controller/controller.dart';
import 'package:counter/src/presentation/counter/effects/show_reject_operation.dart';
import 'package:counter/src/presentation/counter/intents/decrement_intent.dart';
import 'package:counter/src/presentation/counter/intents/get_current_counter_value_intent.dart';
import 'package:counter/src/presentation/counter/intents/increment_intent.dart';
import 'package:counter/src/presentation/counter/presentation/counter_view.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _limitMessage = 'Value cannot be less than -10';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    await Di.sl.reset();
    Di.sl.registerSingleton<IncrementIntent>(
      IncrementIntent(
        incrementUseCase: IncrementUseCase(),
        saveCurrentValueUseCase: SaveCurrentValueUseCase(
          preferences: preferences,
        ),
      ),
    );
    Di.sl.registerSingleton<DecrementIntent>(
      DecrementIntent(
        decrementUseCase: DecrementUseCase(),
        saveCurrentValueUseCase: SaveCurrentValueUseCase(
          preferences: preferences,
        ),
      ),
    );
    Di.sl.registerSingleton<GetCurrentCounterValueIntent>(
      GetCurrentCounterValueIntent(
        getCurrentValueUseCase: GetCurrentValueUseCase(
          preferences: preferences,
        ),
      ),
    );
  });

  tearDown(() async {
    await Di.sl.reset();
    resetJIntentGlobals();
  });

  /// Pumps the counter at its lower limit, where every decrement is rejected.
  Future<void> pumpAtLimit(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        couterControllerProvider.overrideWith(
          (ref) => CounterController(const CounterState(counter: -10)),
        ),
      ],
      child: const MaterialApp(home: CounterView()),
    ),
  );

  Future<void> decrement(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.exposure_minus_1_sharp));
    // Longer than the view's 200 ms throttle, so every tap reaches the intent.
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('rejection feedback', () {
    testWidgets('shows the reason without the Exception prefix', (
      tester,
    ) async {
      await pumpAtLimit(tester);

      await decrement(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_limitMessage), findsOneWidget);
      expect(find.textContaining('Exception:'), findsNothing);
      expect(
        find.text('-10'),
        findsOneWidget,
        reason: 'the state is unchanged',
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('has no action and closes by itself after its duration', (
      tester,
    ) async {
      await pumpAtLimit(tester);

      await decrement(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SnackBarAction), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);

      // Flutter versions that persist SnackBars with an action would keep it.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('repeated failures replace the message instead of queueing', (
      tester,
    ) async {
      await pumpAtLimit(tester);

      await decrement(tester);
      await decrement(tester);
      await decrement(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SnackBar), findsOneWidget);

      // One duration later nothing is left to replay: a queue of three would
      // still be showing its second message.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ShowRejectOperation.fromException', () {
    test('removes only the leading Exception prefix', () {
      final effect = ShowRejectOperation.fromException(
        Exception('Value cannot be less than -10'),
      );

      expect(effect.message, _limitMessage);
    });

    test('keeps a message that merely mentions Exception', () {
      final effect = ShowRejectOperation.fromException(
        Exception('Storage Exception: disk full'),
      );

      expect(effect.message, 'Storage Exception: disk full');
    });

    test('keeps the text of other exception types untouched', () {
      final effect = ShowRejectOperation.fromException(
        const FormatException('bad input'),
      );

      expect(effect.message, 'FormatException: bad input');
    });
  });
}
