import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:jintent/jcontroller.dart';
import 'package:jintent/jintent.dart';

class DecrementIntent extends JIntent<CounterState> {
  @override
  invoke(JController<CounterState> controller) async {
    final state = controller.currentState;

    final counter = state.counter;

    final newState = state.copyWith(newStateCounter: counter - 1);

    controller.emitSideEffect(ShowDecrementSuccessfull(message: "1 was subtracted from $counter"));

    controller.setState(newState);
  }
}
