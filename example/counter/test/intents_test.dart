import 'package:counter/controller.dart';
import 'package:counter/decrement_intent.dart';
import 'package:counter/increment_intent.dart';
import 'package:counter/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Controler Unit Test', () {
// Set initial State
    const initialState = CounterState(counter: 0);

// Create the controller
    final controller = Controller(initialState);

    test('Intent should update the state count to 1', () async {
      final incrementIntent = IncrementIntent();

      controller.intent(incrementIntent);

      expect(controller.currentState.counter, equals(1));
    });

    test('Intent should update the state count to 0', () async {
      final decrementIntent = DecrementIntent();

      controller.intent(decrementIntent);

      expect(controller.currentState.counter, equals(0));
    });
  });
}
