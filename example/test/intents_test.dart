import 'package:counter/src/modules/counter/controllers/controller.dart';
import 'package:counter/src/modules/counter/intents/decrement_intent.dart';
import 'package:counter/src/modules/counter/intents/increment_intent.dart';
import 'package:counter/src/modules/counter/states/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:jintent/jprogress_dialog_manager_controller.dart';
import 'package:mockito/annotations.dart';

import './intents_test.mocks.dart';

@GenerateNiceMocks([MockSpec<JProgressDialogManagerController>()])
void main() {
  group('Controler Unit Test', () {
    setUpAll(() => GetIt.instance
        .registerLazySingleton<JProgressDialogManagerController>(
            () => MockJProgressDialogManagerController()));

    const initialState = CounterState(counter: 0);

    final controller = Controller(initialState);

    test('Intent should update the state count to 1', () async {
      final incrementIntent = IncrementIntent();

      await controller.intent(incrementIntent);

      expect(controller.currentState.counter, equals(1));
    });

    test('Intent should update the state count to 0', () async {
      final decrementIntent = DecrementIntent();

      await controller.intent(decrementIntent);

      expect(controller.currentState.counter, equals(0));
    });
  });
}
