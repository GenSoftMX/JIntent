import 'package:counter/src/domain/use_cases/decrement_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

class DecrementIntent extends JIntent<CounterState> with JIntentHelpers {
  final DecrementUseCase _decrementIntent;
  final SaveCurrentValueUseCase _saveCurrentValueUseCase;

  DecrementIntent({
    required DecrementUseCase decrementUseCase,
    required SaveCurrentValueUseCase saveCurrentValueUseCase,
  }) : _decrementIntent = decrementUseCase,
       _saveCurrentValueUseCase = saveCurrentValueUseCase;
       
  @override
  Future<void> onInvoke() async {
    final decrementResult = _decrementIntent.run(state.counter);

    decrementResult.fold(
      (failure) => handleFailure(failure),
      (data) => handleSuccess(data),
    );
  }

  @protected
  void handleFailure(Exception e) {
    controller.emitSideEffect(ShowRejectOperation(message: e.toString()));
  }

  @protected
  void handleSuccess(int value) async {
    _saveCurrentValueUseCase.run(value);

    update((state) => state.copyWith(newStateCounter: value));
  }
}

