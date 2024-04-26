import 'package:counter/decrement_intent.dart';
import 'package:counter/increment_intent.dart';
import 'package:counter/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jstate.dart';

final controllerProvider =
    StateNotifierProvider<Controller, CounterState>((ref) {
  return Controller(CounterState.initialState());
});

class Controller extends JController<CounterState> {
  Controller(super.initialState);

  increment() {
    intent(IncrementIntent());
  }

  decrement() {
    intent(DecrementIntent());
  }
}
