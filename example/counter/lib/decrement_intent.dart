import 'package:counter/state.dart';
import 'package:jintent/jcontroller.dart';
import 'package:jintent/jintent.dart';

class DecrementIntent extends JIntent<State> {
  @override
  invoke(JController<State> controller) {
    final state = controller.currentState;

    final newState = state.copyWith(newStateCounter: state.counter - 1);

    controller.setState(newState);
  }
}
