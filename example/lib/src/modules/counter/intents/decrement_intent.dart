import 'package:counter/src/modules/counter/states/state.dart';
import 'package:jintent/jcontroller.dart';
import 'package:jintent/jintent.dart';

class DecrementIntent extends JIntent<CounterState> {
  @override
  invoke(JController<CounterState> controller) async {
    final state = controller.currentState;

    final newState = state.copyWith(newStateCounter: state.counter - 1);

    pd.show(msg: "Decrement");

    await Future.delayed(const Duration(seconds: 2))
        .then((value) => controller.setState(newState));

    pd.hide();
  }
}
