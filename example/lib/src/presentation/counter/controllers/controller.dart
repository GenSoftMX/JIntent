import 'package:counter/di/di.dart';
import 'package:counter/src/presentation/counter/intents/decrement_intent.dart';
import 'package:counter/src/presentation/counter/intents/get_current_counter_value_intent.dart';
import 'package:counter/src/presentation/counter/intents/increment_intent.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jintent.dart';

final couterControllerProvider =
    StateNotifierProvider<CounterController, CounterState>((ref) {
      return CounterController(CounterState.initialState());
    });

class CounterController extends JController<CounterState> {
  final _getCurrentCounterValueIntent = Di.sl<GetCurrentCounterValueIntent>();
  final _incrementIntent = Di.sl<IncrementIntent>();
  final _decrementIntent = Di.sl<DecrementIntent>();

  CounterController(super.initialState);

  void loadCounter() {
    intent(_getCurrentCounterValueIntent);
  }

  void increment() => intent(_incrementIntent);

  void decrement() => intent(_decrementIntent);
  
  @override
  void onInit() { }
}