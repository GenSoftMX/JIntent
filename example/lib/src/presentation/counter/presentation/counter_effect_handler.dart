import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jcontroller.dart';
import 'package:jintent/jeffect.dart';
import 'package:jintent/jstate.dart';

class CounterEffectHandler extends JSideEffectHandler<CounterState> {
  CounterEffectHandler(
      JController<CounterState> controller, BuildContext context)
      : super(controller, context) {
    register<ShowDecrementSuccessfull>(_onDecrementSuccessfull);
    register<ConfirmIncrementffect>(_handleConfirmAge);
  }

  Future<void> _onDecrementSuccessfull(ShowDecrementSuccessfull effect,
      JController<CounterState> controller) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(effect.message),duration: const Duration(seconds: 2),),
    );
  }

  Future<void> _handleConfirmAge(ConfirmIncrementffect effect,
      JController<CounterState> controller) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(effect.title),
        content: Text(effect.content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    return effect.complete(result ?? false);
  }
}

class ShowDecrementSuccessfull extends JEffect {
  final String message;

  ShowDecrementSuccessfull({required this.message});
}

class ConfirmIncrementffect extends JEffect<bool> {
  final String title;
  final String content;
  ConfirmIncrementffect({
this.title = 'Confirm Increment',
this.content = 'Do you want to add +1?',
  });
}
