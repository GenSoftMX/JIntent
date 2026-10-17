import 'dart:async';

import 'package:counter/src/domain/use_cases/decrement_use_case.dart';
import 'package:counter/src/domain/use_cases/get_current_value_use_case.dart';
import 'package:counter/src/domain/use_cases/increment_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/effects/show_reject_operation.dart';
import 'package:counter/src/presentation/counter/intents/decrement_intent.dart';
import 'package:counter/src/presentation/counter/intents/get_current_counter_value_intent.dart';
import 'package:counter/src/presentation/counter/intents/increment_intent.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uses the default dispatcher, like the app's Riverpod provider, without the
/// service locator.
class _Controller extends JController<CounterState> {
  _Controller() : super(CounterState.initialState());

  @override
  void onInit() {}
}

class _DeferredSave extends SaveCurrentValueUseCase {
  _DeferredSave(SharedPreferences preferences)
    : super(preferences: preferences);

  final saved = <int>[];
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> run(int currentValue) async {
    saved.add(currentValue);
    if (!entered.isCompleted) entered.complete();
    await release.future;
  }
}

class _Outcomes extends JObserverDelegate {
  final dropped = <String>[];

  @override
  void onIntentDropped(JIntent intent) => dropped.add('${intent.runtimeType}');
}

void main() {
  late SharedPreferences preferences;
  late _Controller controller;
  late JStateRecorder<CounterState> states;
  late _Outcomes outcomes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    controller = _Controller();
    states = JStateRecorder(controller);
    outcomes = _Outcomes();
    JObserver.addObserver(outcomes);
  });

  tearDown(() {
    states.dispose();
    controller.dispose();
    resetJIntentGlobals();
  });

  IncrementIntent increment(SaveCurrentValueUseCase save) => IncrementIntent(
    incrementUseCase: IncrementUseCase(),
    saveCurrentValueUseCase: save,
  );

  test(
    'a tap while an operation is in flight is queued, not dropped',
    () async {
      final save = _DeferredSave(preferences);
      final first = controller.intent(increment(save));
      await save.entered.future;

      final second = controller.intent(increment(save));
      await Future<void>(() {});
      expect(save.saved, [1], reason: 'the second tap waits for the first');

      save.release.complete();
      await Future.wait([first, second]);

      expect(save.saved, [1, 2]);
      expect(controller.currentState.counter, 2);
      expect(outcomes.dropped, isEmpty);
    },
  );

  test('increment and decrement run in tap order and never overlap', () async {
    final save = _DeferredSave(preferences);
    final running = controller.intent(increment(save));
    await save.entered.future;

    final queued = controller.intent(
      DecrementIntent(
        decrementUseCase: DecrementUseCase(),
        saveCurrentValueUseCase: save,
      ),
    );
    await Future<void>(() {});
    expect(save.saved, [1]);

    save.release.complete();
    await Future.wait([running, queued]);

    expect(save.saved, [1, 0]);
    expect(controller.currentState.counter, 0);
  });

  group('GetCurrentCounterValueIntent (exhaustive switch over Either)', () {
    GetCurrentCounterValueIntent load() => GetCurrentCounterValueIntent(
      getCurrentValueUseCase: GetCurrentValueUseCase(preferences: preferences),
    );

    test('a saved value updates the state', () async {
      await preferences.setInt('currentValue', 7);

      await controller.intent(load());

      expect(states.states, [const CounterState(counter: 7)]);
    });

    test('a missing value reaches the UI as a rejection effect', () async {
      final ui = JEffectRecorder(controller)
        ..respondTo<ShowRejectOperation, bool>((_) => true);
      addTearDown(ui.dispose);

      await controller.intent(load());
      await Future<void>(() {});

      expect(states.states, isEmpty);
      expect(
        ui.effectsOfType<ShowRejectOperation>().single.message,
        contains("No value saved for 'currentValue'"),
      );
    });
  });
}
