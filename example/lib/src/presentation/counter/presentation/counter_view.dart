import 'package:counter/src/presentation/counter/controllers/controller.dart';
import 'package:counter/src/presentation/counter/presentation/counter_effect_handler.dart';
import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jintent.dart';

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

  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(
      couterControllerProvider.select((value) => value.counter),
    );

    return JEffectListener(
      controller: _counterController,
      handler: _sideEffectHandler,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('You have pushed the button this many times:'),
              Text('$counter', style: Theme.of(context).textTheme.headlineMedium),
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
              onPressed: () => throttler.call(_counterController.increment),
              tooltip: 'Increment',
              icon: const Icon(Icons.exposure_plus_1_outlined),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              label: const Text('Decrement'),
              heroTag: 'Decrement',
              onPressed: () => throttler.call(_counterController.decrement),
              tooltip: 'Decrement',
              icon: const Icon(Icons.exposure_minus_1_sharp),
            ),
          ],
        ),
      ),
    );
  }
}