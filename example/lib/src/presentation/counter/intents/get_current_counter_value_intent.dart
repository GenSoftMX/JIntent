import 'package:counter/src/domain/use_cases/get_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
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

    getCurrentValueUseCaseResult.fold(
      (failure) => handleFailure(failure),
      (data) => handleSuccess(data),
    );
  }

  @protected
  void handleFailure(Exception e) {
    emitSideEffect(ShowRejectOperation(message: e.toString()));
  }
  
  @protected
  void handleSuccess(int value) async {
    update((state) => state.copyWith(newStateCounter: value));
  }
}
