import 'package:counter/src/presentation/counter/intents/decrement_intent.dart';
import 'package:counter/src/presentation/counter/intents/increment_intent.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jstate.dart';

final couterControllerProvider =
    StateNotifierProvider<Controller, CounterState>((ref) {
  return Controller(CounterState.initialState());
});

class Controller extends JController<CounterState> {
  Controller(super.initialState);

  void increment() async {
    intent(IncrementIntent());
  }

  void decrement() {
    intent(DecrementIntent());
  }
}
