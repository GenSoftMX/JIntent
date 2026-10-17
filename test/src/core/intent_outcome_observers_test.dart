import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/devtools.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

class _SearchIntent extends CallbackIntent {
  _SearchIntent(super.callback);
}

class _Outcomes extends JObserverDelegate {
  final events = <String>[];

  @override
  void onIntentDispatched(JIntent intent) => events.add('dispatched');

  @override
  void onIntentCancelled(JIntent intent) => events.add('cancelled');

  @override
  void onIntentDropped(JIntent intent) => events.add('dropped');
}

void main() {
  late _Outcomes outcomes;

  setUp(() {
    outcomes = _Outcomes();
    JObserver.addObserver(outcomes);
  });

  tearDown(() {
    JMetrics.reset();
    JObserver.reset();
  });

  test('notifyIntentCompleted routes by cancellation state', () async {
    final controller = CounterController();
    addTearDown(controller.dispose);
    final ok = CallbackIntent((_) async {});
    final cancelled = CallbackIntent((i) async => i.cancel());

    await controller.intent(ok);
    await controller.intent(cancelled);

    expect(outcomes.events, ['dispatched', 'cancelled']);
  });

  test('default dispatcher reports cancelled intents as cancelled', () async {
    final controller = CounterController(
      dispatcher: JDefaultIntentDispatcher(),
    );
    addTearDown(controller.dispose);

    await controller.intent(CallbackIntent((i) async => i.cancel()));

    expect(outcomes.events, ['cancelled']);
  });

  test('droppable reports dropped intents and dispatched ones', () async {
    final controller = CounterController(
      dispatcher: JDroppableIntentDispatcher(),
    );
    addTearDown(controller.dispose);
    final gate = Completer<void>();
    final first = controller.intent(_SearchIntent((_) => gate.future));
    await controller.intent(_SearchIntent((_) async {}));
    gate.complete();
    await first;

    expect(outcomes.events, ['dropped', 'dispatched']);
  });

  test('restartable reports the superseded intent as cancelled', () async {
    final controller = CounterController(
      dispatcher: JRestartableIntentDispatcher(),
    );
    addTearDown(controller.dispose);
    final gate = Completer<void>();
    final first = controller.intent(_SearchIntent((_) => gate.future));
    await Future<void>(() {});
    await controller.intent(_SearchIntent((_) async {}));
    gate.complete();
    await first;

    expect(outcomes.events, ['dispatched', 'cancelled']);
  });

  test('a cancelled intent that fails is reported as failed only', () async {
    final controller = CounterController(
      dispatcher: JDefaultIntentDispatcher(),
    );
    addTearDown(controller.dispose);
    final failures = <String>[];
    JObserver.onIntentFailed = (_, error, _) => failures.add('$error');

    await expectLater(
      controller.intent(
        CallbackIntent((i) async {
          i.cancel();
          throw StateError('x');
        }),
      ),
      throwsStateError,
    );

    expect(outcomes.events, isEmpty);
    expect(failures, hasLength(1));
  });

  test('metrics count cancelled and dropped intents with durations', () async {
    JMetrics.attachToObserver();
    final droppable = CounterController(
      dispatcher: JDroppableIntentDispatcher(),
    );
    addTearDown(droppable.dispose);
    final gate = Completer<void>();
    final running = droppable.intent(_SearchIntent((_) => gate.future));
    await droppable.intent(_SearchIntent((_) async {}));
    gate.complete();
    await running;

    final restartable = CounterController(
      dispatcher: JRestartableIntentDispatcher(),
    );
    addTearDown(restartable.dispose);
    final other = Completer<void>();
    final old = restartable.intent(_SearchIntent((_) => other.future));
    await Future<void>(() {});
    await restartable.intent(_SearchIntent((_) async {}));
    other.complete();
    await old;

    expect(JMetrics.getMetricsByName('intent.dropped'), hasLength(1));
    expect(JMetrics.getMetricsByName('intent.cancelled'), hasLength(1));
    expect(JMetrics.getMetricsByName('intent.dispatched'), hasLength(2));
    // The dropped intent never started, so it has no duration.
    expect(
      JMetrics.getMetricsByName('intent.execution.duration'),
      hasLength(3),
    );
  });
}
