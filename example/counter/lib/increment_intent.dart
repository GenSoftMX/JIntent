import 'package:counter/state.dart';
import 'package:jintent/jstate.dart';

class IncrementIntent extends JIntent<CounterState> {
  @override
  invoke(JController<CounterState> controller) {
    final state = controller.currentState;

    final newState = state.copyWith(newStateCounter: state.counter + 1);

    controller.setState(newState);
  }
}
