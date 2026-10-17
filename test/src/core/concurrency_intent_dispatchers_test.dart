import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

class _SearchIntent extends CallbackIntent {
  _SearchIntent(super.callback);
}

class _SaveIntent extends CallbackIntent {
  _SaveIntent(super.callback);
}

void main() {
  tearDown(JObserver.reset);

  group('JDroppableIntentDispatcher', () {
    late CounterController controller;

    setUp(() {
      controller = CounterController(dispatcher: JDroppableIntentDispatcher());
    });

    tearDown(() {
      if (controller.mounted) controller.dispose();
    });

    test('drops an intent of the same type while one is running', () async {
      final gate = Completer<void>();
      var secondRan = false;
      final first = controller.intent(_SearchIntent((_) => gate.future));
      final second = controller.intent(
        _SearchIntent((_) async => secondRan = true),
      );

      await second;
      expect(secondRan, isFalse);

      gate.complete();
      await first;

      await controller.intent(_SearchIntent((_) async => secondRan = true));
      expect(secondRan, isTrue);
    });

    test('runs intents of different types concurrently', () async {
      final gate = Completer<void>();
      var saved = false;
      final search = controller.intent(_SearchIntent((_) => gate.future));
      await controller.intent(_SaveIntent((_) async => saved = true));
      expect(saved, isTrue);
      gate.complete();
      await search;
    });

    test('a failure releases the slot and reaches the caller', () async {
      await expectLater(
        controller.intent(_SearchIntent((_) async => throw StateError('x'))),
        throwsStateError,
      );
      var ran = false;
      await controller.intent(_SearchIntent((_) async => ran = true));
      expect(ran, isTrue);
    });

    test('custom keys decide which intents compete', () async {
      final custom = CounterController(
        dispatcher: JDroppableIntentDispatcher(keyOf: (_) => 'all'),
      );
      addTearDown(custom.dispose);
      final gate = Completer<void>();
      var saved = false;
      final search = custom.intent(_SearchIntent((_) => gate.future));
      await custom.intent(_SaveIntent((_) async => saved = true));
      expect(saved, isFalse);
      gate.complete();
      await search;
    });

    test(
      'slots are tracked per controller when the dispatcher is shared',
      () async {
        final shared = JDroppableIntentDispatcher();
        final a = CounterController(dispatcher: shared);
        final b = CounterController(dispatcher: shared);
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        final gate = Completer<void>();
        var ranOnB = false;
        final onA = a.intent(_SearchIntent((_) => gate.future));
        await b.intent(_SearchIntent((_) async => ranOnB = true));
        expect(ranOnB, isTrue);
        gate.complete();
        await onA;
      },
    );

    test('notifies dispatched only for intents that ran', () async {
      final seen = <JIntent>[];
      JObserver.onIntentDispatched = seen.add;
      final gate = Completer<void>();
      final first = controller.intent(_SearchIntent((_) => gate.future));
      await controller.intent(_SearchIntent((_) async {}));
      gate.complete();
      await first;
      expect(seen, hasLength(1));
    });

    test('rejects dispatch after disposal', () async {
      controller.dispose();
      await expectLater(
        controller.intent(_SearchIntent((_) async {})),
        throwsStateError,
      );
    });

    test('rejects a controller disposed before the dispatcher is called', () {
      final dispatcher = JDroppableIntentDispatcher();
      controller.dispose();
      expect(
        dispatcher.dispatch(_SearchIntent((_) async {}), controller),
        throwsStateError,
      );
    });
  });

  group('JRestartableIntentDispatcher', () {
    late CounterController controller;

    setUp(() {
      controller = CounterController(
        dispatcher: JRestartableIntentDispatcher(),
      );
    });

    tearDown(() {
      if (controller.mounted) controller.dispose();
    });

    test('cancels the running intent and starts the new one at once', () async {
      final gate = Completer<void>();
      late _SearchIntent firstIntent;
      firstIntent = _SearchIntent((intent) async {
        await gate.future;
        intent.controller.update((s) => s.copyWith(value: 1), origin: intent);
      });
      final first = controller.intent(firstIntent);
      await Future<void>(() {});

      await controller.intent(
        _SearchIntent((intent) async {
          intent.controller.update((s) => s.copyWith(value: 2), origin: intent);
        }),
      );
      expect(firstIntent.isCancelled, isTrue);

      gate.complete();
      await first;

      // The superseded intent could not overwrite the newer result.
      expect(controller.currentState.value, 2);
    });

    test('lets the cancelled intent stop early by checking the flag', () async {
      final gate = Completer<void>();
      var continuedAfterCancel = false;
      final first = controller.intent(
        _SearchIntent((intent) async {
          await gate.future;
          if (intent.isCancelled) return;
          continuedAfterCancel = true;
        }),
      );
      await Future<void>(() {});
      await controller.intent(_SearchIntent((_) async {}));
      gate.complete();
      await first;
      expect(continuedAfterCancel, isFalse);
    });

    test('does not cancel intents with a different key', () async {
      final gate = Completer<void>();
      late _SearchIntent search;
      search = _SearchIntent((_) => gate.future);
      final running = controller.intent(search);
      await Future<void>(() {});
      await controller.intent(_SaveIntent((_) async {}));
      expect(search.isCancelled, isFalse);
      gate.complete();
      await running;
    });

    test('the cancelled intent still reports its own error', () async {
      final gate = Completer<void>();
      final first = controller.intent(
        _SearchIntent((_) async {
          await gate.future;
          throw StateError('late');
        }),
      );
      final assertion = expectLater(first, throwsStateError);
      await Future<void>(() {});
      await controller.intent(_SearchIntent((_) async {}));
      gate.complete();
      await assertion;
    });

    test('an old intent finishing does not release the newer slot', () async {
      final gateA = Completer<void>();
      final gateB = Completer<void>();
      final a = _SearchIntent((_) => gateA.future);
      final b = _SearchIntent((_) => gateB.future);
      final futureA = controller.intent(a);
      await Future<void>(() {});
      final futureB = controller.intent(b);
      await Future<void>(() {});

      gateA.complete();
      await futureA;

      final c = _SearchIntent((_) async {});
      final futureC = controller.intent(c);
      await futureC;
      expect(b.isCancelled, isTrue);

      gateB.complete();
      await futureB;
    });

    test('re-dispatching the running instance does not cancel it', () async {
      final gate = Completer<void>();
      late _SearchIntent running;
      running = _SearchIntent((intent) async {
        await gate.future;
        intent.controller.update((s) => s.copyWith(value: 1), origin: intent);
      });
      final first = controller.intent(running);
      await Future<void>(() {});

      await expectLater(controller.intent(running), throwsStateError);
      expect(running.isCancelled, isFalse);

      // The slot is intact: a newer intent still supersedes the running one.
      await controller.intent(_SearchIntent((_) async {}));
      expect(running.isCancelled, isTrue);

      gate.complete();
      await first;
    });

    test('a superseded but still running intent cannot be re-dispatched over '
        'the current one', () async {
      final gateA = Completer<void>();
      final gateB = Completer<void>();
      final a = _SearchIntent((_) => gateA.future);
      final b = _SearchIntent((_) => gateB.future);
      final futureA = controller.intent(a);
      await Future<void>(() {});
      final futureB = controller.intent(b);
      await Future<void>(() {});
      expect(a.isCancelled, isTrue);

      // A is still running although B owns the slot.
      await expectLater(controller.intent(a), throwsStateError);
      expect(b.isCancelled, isFalse);

      // The slot still belongs to B: a newer intent supersedes it.
      await controller.intent(_SearchIntent((_) async {}));
      expect(b.isCancelled, isTrue);

      gateA.complete();
      gateB.complete();
      await futureA;
      await futureB;
    });

    test(
      'the running instance keeps its update after a rejected re-dispatch',
      () async {
        final gate = Completer<void>();
        final running = _SearchIntent((intent) async {
          await gate.future;
          intent.controller.update((s) => s.copyWith(value: 1), origin: intent);
        });
        final first = controller.intent(running);
        await Future<void>(() {});
        await expectLater(controller.intent(running), throwsStateError);

        gate.complete();
        await first;

        expect(controller.currentState.value, 1);
      },
    );

    test('rejects dispatch after disposal', () async {
      controller.dispose();
      await expectLater(
        controller.intent(_SearchIntent((_) async {})),
        throwsStateError,
      );
    });

    test('rejects a controller disposed before the dispatcher is called', () {
      final dispatcher = JRestartableIntentDispatcher();
      controller.dispose();
      expect(
        dispatcher.dispatch(_SearchIntent((_) async {}), controller),
        throwsStateError,
      );
    });
  });
}
