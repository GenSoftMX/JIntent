import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

class _SearchIntent extends CallbackIntent {
  _SearchIntent(super.callback);
}

class _OriginRecorder extends JObserverDelegate {
  final origins = <JIntent?>[];

  @override
  void onStateChanged(JState prev, JState next, JIntent? origin) =>
      origins.add(origin);
}

void main() {
  late CounterController controller;
  late _OriginRecorder recorder;

  setUp(() {
    controller = CounterController();
    recorder = _OriginRecorder();
    JObserver.addObserver(recorder);
  });

  tearDown(() {
    JObserver.reset();
    if (controller.mounted) controller.dispose();
  });

  test('JIntent.current is null outside an intent', () {
    expect(JIntent.current, isNull);
  });

  test('JIntent.current is the running intent, across awaits', () async {
    JIntent? before;
    JIntent? after;
    final intent = CallbackIntent((i) async {
      before = JIntent.current;
      await Future<void>.delayed(const Duration(milliseconds: 1));
      after = JIntent.current;
    });

    await controller.intent(intent);

    expect(before, same(intent));
    expect(after, same(intent));
    expect(JIntent.current, isNull);
  });

  test('a plain update inside an intent is attributed to it', () async {
    final intent = CallbackIntent((i) async {
      await Future<void>.delayed(Duration.zero);
      i.controller.update((s) => s.copyWith(value: 1));
    });

    await controller.intent(intent);

    expect(recorder.origins, [same(intent)]);
  });

  test('an update outside any intent keeps a null origin', () {
    controller.update((s) => s.copyWith(value: 1));

    expect(recorder.origins, [isNull]);
  });

  test('an explicit origin takes precedence over the zone', () async {
    final explicit = CallbackIntent((_) async {});
    final intent = CallbackIntent((i) async {
      i.controller.update((s) => s.copyWith(value: 1), origin: explicit);
    });

    await controller.intent(intent);

    expect(recorder.origins, [same(explicit)]);
  });

  test('a cancelled intent cannot write even without passing origin', () async {
    final restartable = CounterController(
      dispatcher: JRestartableIntentDispatcher(),
    );
    addTearDown(restartable.dispose);
    final gate = Completer<void>();
    final stale = _SearchIntent((i) async {
      await gate.future;
      i.controller.update((s) => s.copyWith(value: 99));
    });
    final first = restartable.intent(stale);
    await Future<void>(() {});

    await restartable.intent(
      _SearchIntent((i) async {
        i.controller.update((s) => s.copyWith(value: 2));
      }),
    );
    gate.complete();
    await first;

    expect(restartable.currentState.value, 2);
  });

  test('timers created inside the intent stay attributed to it', () async {
    final done = Completer<void>();
    late CallbackIntent intent;
    intent = CallbackIntent((i) async {
      Timer(const Duration(milliseconds: 1), () {
        i.controller.update((s) => s.copyWith(value: 5));
        done.complete();
      });
    });

    await controller.intent(intent);
    await done.future;

    expect(recorder.origins, [same(intent)]);
  });

  test('updates to another controller are not attributed or blocked', () async {
    final other = CounterController();
    addTearDown(other.dispose);
    final intent = CallbackIntent((i) async {
      i.cancel();
      other.update((s) => s.copyWith(value: 7));
    });

    await controller.intent(intent);

    expect(other.currentState.value, 7);
    expect(recorder.origins, [isNull]);
  });

  test(
    'nested intents see their own intent and restore the outer one',
    () async {
      JIntent? innerSeen;
      JIntent? outerAfter;
      final inner = CallbackIntent((_) async => innerSeen = JIntent.current);
      final nested = CounterController(dispatcher: JDefaultIntentDispatcher());
      addTearDown(nested.dispose);
      final outer = CallbackIntent((i) async {
        await nested.intent(inner);
        outerAfter = JIntent.current;
      });

      await nested.intent(outer);

      expect(innerSeen, same(inner));
      expect(outerAfter, same(outer));
    },
  );
}
