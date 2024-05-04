import 'package:counter/src/modules/counter/states/state.dart';
import 'package:jintent/jstate.dart';

class IncrementIntent extends JIntent<CounterState> {
  @override
  invoke(JController<CounterState> controller) async {
    final state = controller.currentState;

    final newState = state.copyWith(newStateCounter: state.counter + 1);

    pd.show(msg: "Increment");

    await Future.delayed(const Duration(seconds: 2))
        .then((value) => controller.setState(newState));

    pd.hide();
  }
}
