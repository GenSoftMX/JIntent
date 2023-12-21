import 'package:flutter/material.dart';
import 'package:jintent/jstate.dart';

@immutable
class State extends JState {
  final int counter;

  State({required this.counter});

  @override
  State copyWith({int? newStateCounter}) =>
      State(counter: newStateCounter ?? counter);
}
