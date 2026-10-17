import 'package:counter/src/domain/use_cases/decrement_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/effects/show_reject_operation.dart';
import 'package:counter/src/presentation/counter/effects/show_save_failure_effect.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
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

    await decrementResult.fold<Future<void>>(
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
  }
}
