import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

import 'package:counter/src/domain/use_cases/increment_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/states/state.dart';

class IncrementIntent extends JIntent<CounterState> with JIntentHelpers {
  final IncrementUseCase _incrementUseCase;
  final SaveCurrentValueUseCase _saveCurrentValueUseCase;

  IncrementIntent({
    required IncrementUseCase incrementUseCase,
    required SaveCurrentValueUseCase saveCurrentValueUseCase,
  }) : _incrementUseCase = incrementUseCase,
       _saveCurrentValueUseCase = saveCurrentValueUseCase;

  @override
  Future<void> onInvoke() async {
    final state = controller.currentState;

    final incrementResult = _incrementUseCase(state.counter);

    incrementResult.fold(
      (failure) => handleFailure(failure),
      (data) => handleSuccess(data),
    );
  }

  @protected
  void handleFailure(Exception e) async {
    await emitAndWaitSideEffect<bool>(
      ShowRejectOperation(message: e.toString()),
    );
  }

  @protected
  void handleSuccess(int value) {
    _saveCurrentValueUseCase.run(value);

    update((state) => state.copyWith(newStateCounter: value));
    
    // Show success feedback for every 10th increment
    if (value % 10 == 0) {
      controller.emitSideEffect(
        ShowSuccessEffect(message: 'Milestone reached: $value!'),
      );
    }
  }
}
