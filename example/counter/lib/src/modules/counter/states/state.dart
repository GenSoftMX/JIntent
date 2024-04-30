import 'package:flutter/material.dart';
import 'package:jintent/jstate.dart';

@immutable
class CounterState extends JState {
  final int counter;

  const CounterState({required this.counter});

  @override
  CounterState copyWith({int? newStateCounter}) =>
      CounterState(counter: newStateCounter ?? counter);

  @override
  List<Object?> get props => [counter];

  factory CounterState.initialState() => const CounterState(counter: 0);
}
