import 'dart:async';

import 'package:counter/src/presentation/counter/controller/controller.dart';
import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/utils.dart';

class CounterView extends ConsumerStatefulWidget {
  const CounterView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CounterViewState();
}

class _CounterViewState extends ConsumerState<CounterView> {
  final throttler = JThrottler(const Duration(milliseconds: 200));

  late final CounterController _counterController;

  JSideEffectHandler<CounterState> get _sideEffectHandler =>
      CounterEffectHandler(_counterController);

  @override
  void initState() {
    super.initState();

    _counterController = ref.read(couterControllerProvider.notifier);
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Counter action failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    throttler.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(
      couterControllerProvider.select((value) => value.counter),
    );

    return JEffectListener(
      controller: _counterController,
      handler: _sideEffectHandler,
      child: Scaffold(
        appBar: AppBar(title: const Text('Counter')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('You have pushed the button this many times:'),
              Text(
                '$counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              label: const Text('Increment'),
              heroTag: 'Increment',
              onPressed:
                  () => throttler.call(
                    () => unawaited(_runAction(_counterController.increment)),
                  ),
              tooltip: 'Increment',
              icon: const Icon(Icons.exposure_plus_1_outlined),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              label: const Text('Decrement'),
              heroTag: 'Decrement',
              onPressed:
                  () => throttler.call(
                    () => unawaited(_runAction(_counterController.decrement)),
                  ),
              tooltip: 'Decrement',
              icon: const Icon(Icons.exposure_minus_1_sharp),
            ),
          ],
        ),
      ),
    );
  }
}
