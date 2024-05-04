import 'package:counter/src/modules/counter/intents/decrement_intent.dart';
import 'package:counter/src/modules/counter/intents/increment_intent.dart';
import 'package:counter/src/modules/counter/states/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jstate.dart';

final controllerProvider =
    StateNotifierProvider<Controller, CounterState>((ref) {
  return Controller(CounterState.initialState());
});

class Controller extends JController<CounterState> {
  Controller(super.initialState);

  void increment() {
    intent(IncrementIntent());
  }

  void decrement() {
    intent(DecrementIntent());
  }
}
