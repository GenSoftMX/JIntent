import 'package:counter/di/di.dart';
import 'package:counter/src/presentation/counter/intents/decrement_intent.dart';
import 'package:counter/src/presentation/counter/intents/get_current_counter_value_intent.dart';
import 'package:counter/src/presentation/counter/intents/increment_intent.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jintent.dart';

final couterControllerProvider =
    StateNotifierProvider<CounterController, CounterState>((ref) {
      return CounterController(CounterState.initialState());
    });

/// Counter operations read the current value, persist the next one and then
/// update the state, so they must never overlap. The default
/// [JSequentialIntentDispatcher] queues a tap behind the running operation, so
/// no tap is lost once it reaches the controller.
class CounterController extends JController<CounterState> {
  final _getCurrentCounterValueIntent = Di.sl<GetCurrentCounterValueIntent>();
  final _incrementIntent = Di.sl<IncrementIntent>();
  final _decrementIntent = Di.sl<DecrementIntent>();

  CounterController(super.initialState);

  Future<void> loadCounter() => intent(_getCurrentCounterValueIntent);

  Future<void> increment() => intent(_incrementIntent);

  Future<void> decrement() => intent(_decrementIntent);

  @override
  void onInit() {}
}
