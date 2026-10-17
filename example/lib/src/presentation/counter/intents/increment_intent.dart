import 'package:counter/src/domain/use_cases/increment_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/effects/show_reject_operation.dart';
import 'package:counter/src/presentation/counter/effects/show_save_failure_effect.dart';
import 'package:counter/src/presentation/counter/effects/show_success_effect.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

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

    await incrementResult.fold<Future<void>>(
      (failure) => handleFailure(failure),
      (data) => handleSuccess(data),
    );
  }

  @protected
  Future<void> handleFailure(Exception e) async {
    await emitAndWaitSideEffect<bool>(ShowRejectOperation.fromException(e));
  }

  @protected
  Future<void> handleSuccess(int value) async {
    try {
      await _saveCurrentValueUseCase.run(value);
    } on Exception catch (error, stackTrace) {
      if (!controller.mounted) rethrow;
      debugPrint('Counter persistence failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emitSideEffect(ShowSaveFailureEffect());
      return;
    }
    if (!controller.mounted) return;

    update((state) => state.copyWith(newStateCounter: value));

    // Show success feedback for every 10th increment
    if (value % 10 == 0) {
      controller.emitSideEffect(
        ShowSuccessEffect(message: 'Milestone reached: $value!'),
      );
    }
  }
}
