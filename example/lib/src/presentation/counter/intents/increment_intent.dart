import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:jintent/jstate.dart';

class IncrementIntent extends JIntent<CounterState> {
  @override
  invoke(JController<CounterState> controller) async {
    final state = controller.currentState;
    final counter = state.counter;

    final confirmed =
        await controller.emitAndWaitSideEffect<bool>(ConfirmIncrementffect());
        
    if (confirmed) {
      var newState = state.copyWith(newStateCounter: counter + 1);

      controller.setState(newState);
    }
  }
}
