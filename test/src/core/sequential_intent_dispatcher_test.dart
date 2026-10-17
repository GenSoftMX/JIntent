import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

void main() {
  for (final decorated in [false, true]) {
    final label = decorated ? 'logging wrapper' : 'sequential dispatcher';

    test('$label cancels before the first queued intent starts', () async {
      final sequential = JSequentialIntentDispatcher();
      final controller = CounterController(
        dispatcher: decorated ? LoggingDispatcher(sequential) : sequential,
      );
      var invoked = false;
      final result = controller.intent(
        CallbackIntent((_) async {
          invoked = true;
        }),
      );
      final assertion = expectLater(result, throwsStateError);
      controller.dispose();
      await assertion;
      // Let the dispatcher's scheduled drain run as well.
      await Future<void>(() {});
      expect(invoked, isFalse);
    });

    test(
      '$label cancels pending work without waiting for the active intent',
      () async {
        final sequential = JSequentialIntentDispatcher();
        final controller = CounterController(
          dispatcher: decorated ? LoggingDispatcher(sequential) : sequential,
        );
        final started = Completer<void>();
        final release = Completer<void>();
        var runningFinished = false;
        var pendingInvoked = false;
        final active = controller.intent(
          CallbackIntent((_) async {
            started.complete();
            await release.future;
            runningFinished = true;
          }),
        );
        await started.future;
        final pending = controller.intent(
          CallbackIntent((_) async {
            pendingInvoked = true;
          }),
        );
        final assertion = expectLater(pending, throwsStateError);
        controller.dispose();
        try {
          await assertion;
          expect(runningFinished, isFalse);
          expect(pendingInvoked, isFalse);
        } finally {
          release.complete();
          await active;
        }
        expect(runningFinished, isTrue);
        expect(pendingInvoked, isFalse);
      },
    );
  }

  test(
    'shared queue preserves other controllers tasks and their FIFO order',
    () async {
      final dispatcher = JSequentialIntentDispatcher();
      final first = CounterController(dispatcher: dispatcher);
      final second = CounterController(dispatcher: dispatcher);
      addTearDown(() {
        if (first.mounted) first.dispose();
        second.dispose();
      });
      final started = Completer<void>();
      final release = Completer<void>();
      final events = <String>[];
      final active = first.intent(
        CallbackIntent((_) async {
          started.complete();
          await release.future;
          events.add('active finished');
        }),
      );
      await started.future;
      final secondTask = second.intent(
        CallbackIntent((_) async => events.add('second 1')),
      );
      final cancelled = first.intent(
        CallbackIntent((_) async => events.add('cancelled')),
      );
      final thirdTask = second.intent(
        CallbackIntent((_) async => events.add('second 2')),
      );
      final assertion = expectLater(cancelled, throwsStateError);
      first.dispose();
      try {
        await assertion;
        expect(events, isEmpty);
      } finally {
        release.complete();
        await Future.wait([active, secondTask, thirdTask]);
      }
      expect(events, ['active finished', 'second 1', 'second 2']);
    },
  );

  test('failed intent does not stop remaining queued work', () async {
    final controller = CounterController();
    addTearDown(controller.dispose);
    final error = ArgumentError('failed intent');
    final failed = controller.intent(CallbackIntent((_) async => throw error));
    final assertion = expectLater(failed, throwsA(same(error)));
    final next = controller.intent(
      CallbackIntent((intent) async {
        intent.controller.update((_) => const CounterState(4));
      }),
    );
    await assertion;
    await next;
    expect(controller.currentState.value, 4);
  });

  test(
    'direct dispatch to a disposed controller fails without invoking intent',
    () async {
      final controller = CounterController();
      controller.dispose();
      var invoked = false;
      await expectLater(
        JSequentialIntentDispatcher().dispatch(
          CallbackIntent((_) async {
            invoked = true;
          }),
          controller,
        ),
        throwsStateError,
      );
      expect(invoked, isFalse);
    },
  );

  test('cancelled tasks are not reported as dispatched', () async {
    final previous = JObserver.onIntentDispatched;
    addTearDown(() => JObserver.onIntentDispatched = previous);
    var dispatched = 0;
    JObserver.onIntentDispatched = (_) => dispatched++;
    final controller = CounterController();
    final result = controller.intent(CallbackIntent((_) async {}));
    final assertion = expectLater(result, throwsStateError);
    controller.dispose();
    await assertion;
    await Future<void>(() {});
    expect(dispatched, 0);
  });

  test('logging wrapper supports dispatchers without cancellation', () async {
    final controller = CounterController(
      dispatcher: LoggingDispatcher(JDefaultIntentDispatcher()),
    );
    await controller.intent(CallbackIntent((_) async {}));
    expect(controller.dispose, returnsNormally);
  });

  test(
    'drain rejects disposed tasks even when dispatched outside their controller',
    () async {
      final dispatcher = JSequentialIntentDispatcher();
      final activeController = CounterController();
      final closedController = CounterController();
      addTearDown(activeController.dispose);
      final started = Completer<void>();
      final release = Completer<void>();
      final active = dispatcher.dispatch(
        CallbackIntent((_) async {
          started.complete();
          await release.future;
        }),
        activeController,
      );
      await started.future;
      var invoked = false;
      final queued = dispatcher.dispatch(
        CallbackIntent((_) async {
          invoked = true;
        }),
        closedController,
      );
      final assertion = expectLater(queued, throwsStateError);
      closedController.dispose();
      release.complete();
      await active;
      await assertion;
      expect(invoked, isFalse);
    },
  );
}
