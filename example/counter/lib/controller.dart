import 'package:counter/decrement_intent.dart';
import 'package:counter/increment_intent.dart';
import 'package:counter/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jstate.dart';

final controllerProvider = StateNotifierProvider<Controller, State>((ref) {
  return Controller(State(counter: 0));
});

class Controller extends JController<State> {
  Controller(super.initialState);

  increment() {
    intent(IncrementIntent());
  }

  decrement() {
    intent(DecrementIntent());
  }
}
