import 'package:counter/src/domain/use_cases/get_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/effects/show_reject_operation.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

class GetCurrentCounterValueIntent extends JIntent<CounterState>
    with JIntentHelpers {
  final GetCurrentValueUseCase _getCurrentValueUseCase;

  GetCurrentCounterValueIntent({
    required GetCurrentValueUseCase getCurrentValueUseCase,
  }) : _getCurrentValueUseCase = getCurrentValueUseCase;

  @override
  Future<void> onInvoke() async {
    final getCurrentValueUseCaseResult = await _getCurrentValueUseCase.run(
      const JNoParams(),
    );
    if (!controller.mounted) return;

    // `Either` is sealed: the compiler checks that both cases are handled.
    switch (getCurrentValueUseCaseResult) {
      case Left(:final value):
        handleFailure(value);
      case Right(:final value):
        handleSuccess(value);
    }
  }

  @protected
  void handleFailure(Exception e) {
    emitSideEffect(ShowRejectOperation.fromException(e));
  }

  @protected
  void handleSuccess(int value) {
    update((state) => state.copyWith(newStateCounter: value));
  }
}
