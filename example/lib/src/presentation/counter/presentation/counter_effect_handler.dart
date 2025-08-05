import 'dart:async';

import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

class CounterEffectHandler extends JSideEffectHandler<CounterState> {
  CounterEffectHandler(super.controller) {
    register<ShowRejectOperation>(_onDecrementSuccessfull);
  }

  Future<void> _onDecrementSuccessfull(
    ShowRejectOperation effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          effect.message,
          style: const TextStyle(color: Colors.white),
        ),

        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class ShowRejectOperation extends JEffect<bool> {
  final String message;

  ShowRejectOperation({required this.message});
}
