import 'dart:async';

import 'package:counter/di/di.dart';
import 'package:counter/src/domain/use_cases/decrement_use_case.dart';
import 'package:counter/src/domain/use_cases/get_current_value_use_case.dart';
import 'package:counter/src/domain/use_cases/increment_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/effects/show_save_failure_effect.dart';
import 'package:counter/src/presentation/counter/intents/decrement_intent.dart';
import 'package:counter/src/presentation/counter/intents/get_current_counter_value_intent.dart';
import 'package:counter/src/presentation/counter/intents/increment_intent.dart';
import 'package:counter/src/presentation/counter/presentation/counter_view.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:counter/src/presentation/splash/controller/splash_controller.dart';
import 'package:counter/src/presentation/splash/state/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestController extends JController<CounterState> {
  TestController() : super(const CounterState(counter: 1));

  @override
  void onInit() {}
}

class DeferredSave extends SaveCurrentValueUseCase {
  final entered = Completer<void>();
  final release = Completer<void>();

  DeferredSave(SharedPreferences preferences) : super(preferences: preferences);

  @override
  Future<void> run(int currentValue) async {
    entered.complete();
    await release.future;
  }
}

class FailingSave extends SaveCurrentValueUseCase {
  final Object error;

  FailingSave(SharedPreferences preferences, {Object? error})
    : error = error ?? Exception('Storage unavailable'),
      super(preferences: preferences);

  @override
  Future<void> run(int currentValue) async {
    throw error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    await Di.sl.reset();
  });

  tearDown(() async {
    await Di.sl.reset();
    resetJIntentGlobals();
  });

  for (final increment in [true, false]) {
    test(
      '${increment ? 'increment' : 'decrement'} waits for persistence',
      () async {
        final save = DeferredSave(preferences);
        final controller = TestController();
        addTearDown(controller.dispose);
        final JIntent<CounterState> intent =
            increment
                ? IncrementIntent(
                  incrementUseCase: IncrementUseCase(),
                  saveCurrentValueUseCase: save,
                )
                : DecrementIntent(
                  decrementUseCase: DecrementUseCase(),
                  saveCurrentValueUseCase: save,
                );
        final states = JStateRecorder(controller);
        addTearDown(states.dispose);
        var finished = false;
        final result = intent.run(controller).then((_) => finished = true);
        await save.entered.future;
        expect(finished, isFalse);
        expect(controller.currentState.counter, 1);
        expect(states.states, isEmpty, reason: 'no update before persistence');
        save.release.complete();
        await result;
        expect(controller.currentState.counter, increment ? 2 : 0);
        expect(states.states, [CounterState(counter: increment ? 2 : 0)]);
      },
    );
  }

  test(
    'unexpected storage errors propagate without a recovery effect',
    () async {
      final controller = TestController();
      addTearDown(controller.dispose);
      final intent = IncrementIntent(
        incrementUseCase: IncrementUseCase(),
        saveCurrentValueUseCase: FailingSave(
          preferences,
          error: StateError('Unexpected storage state'),
        ),
      );
      final ui = JEffectRecorder(controller);
      addTearDown(ui.dispose);
      await expectLater(intent.run(controller), throwsStateError);
      expect(controller.currentState.counter, 1);
      expect(ui.effects, isEmpty);
    },
  );

  for (final increment in [true, false]) {
    test(
      '${increment ? 'increment' : 'decrement'} emits a recovery effect on persistence Exception',
      () async {
        final controller = TestController();
        addTearDown(controller.dispose);
        final save = FailingSave(preferences);
        final JIntent<CounterState> intent =
            increment
                ? IncrementIntent(
                  incrementUseCase: IncrementUseCase(),
                  saveCurrentValueUseCase: save,
                )
                : DecrementIntent(
                  decrementUseCase: DecrementUseCase(),
                  saveCurrentValueUseCase: save,
                );
        final ui = JEffectRecorder(controller);
        addTearDown(ui.dispose);
        await intent.run(controller);
        await Future<void>(() {});
        expect(ui.effectsOfType<ShowSaveFailureEffect>(), hasLength(1));
        expect(controller.currentState.counter, 1);
      },
    );
  }

  test(
    'persistence failure after disposal propagates without emitting another effect',
    () async {
      final controller = TestController();
      final save = DeferredSave(preferences);
      final intent = IncrementIntent(
        incrementUseCase: IncrementUseCase(),
        saveCurrentValueUseCase: save,
      );
      final ui = JEffectRecorder(controller);
      addTearDown(ui.dispose);
      final running = intent.run(controller);
      await save.entered.future;
      final error = Exception('Storage failed after disposal');
      final assertion = expectLater(running, throwsA(same(error)));
      controller.dispose();
      save.release.completeError(error);
      await assertion;
      expect(ui.effects, isEmpty);
    },
  );

  for (final recoverable in [true, false]) {
    testWidgets(
      'counter UI handles ${recoverable ? 'recoverable' : 'unexpected'} failure without an uncaught error',
      (tester) async {
        final save = FailingSave(
          preferences,
          error:
              recoverable
                  ? Exception('Storage unavailable')
                  : StateError('Unexpected storage state'),
        );
        final emitted = <JEffect>[];
        JObserver.onEffectEmitted = emitted.add;
        Di.sl.registerSingleton<IncrementIntent>(
          IncrementIntent(
            incrementUseCase: IncrementUseCase(),
            saveCurrentValueUseCase: save,
          ),
        );
        Di.sl.registerSingleton<DecrementIntent>(
          DecrementIntent(
            decrementUseCase: DecrementUseCase(),
            saveCurrentValueUseCase: save,
          ),
        );
        Di.sl.registerSingleton<GetCurrentCounterValueIntent>(
          GetCurrentCounterValueIntent(
            getCurrentValueUseCase: GetCurrentValueUseCase(
              preferences: preferences,
            ),
          ),
        );
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: CounterView())),
        );
        await tester.tap(find.byIcon(Icons.exposure_plus_1_outlined));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        if (recoverable) {
          expect(
            find.text('Could not save the counter. Please try again.'),
            findsOneWidget,
          );
          expect(emitted.whereType<ShowSaveFailureEffect>(), hasLength(1));
        } else {
          expect(find.byType(SnackBar), findsNothing);
          expect(emitted, isEmpty);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('splash does not emit navigation after controller disposal', (
    tester,
  ) async {
    final controller = SplashController(SplashState.initialState());
    var effects = 0;
    final subscription = controller.sideEffects.listen((_) => effects++);
    addTearDown(subscription.cancel);
    final initialization = controller.init();
    controller.dispose();
    await tester.pump(const Duration(seconds: 2));
    await initialization;
    expect(effects, 0);
    expect(tester.takeException(), isNull);
  });
}
