import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

class ListenerHandler extends JSideEffectHandler<CounterState> {
  ListenerHandler(super.controller);
}

class NotificationEffect extends JFireAndForgetEffect {}

Widget listener(CounterController controller, ListenerHandler handler) {
  return MaterialApp(
    home: JEffectListener<CounterState>(
      controller: controller,
      handler: handler,
      child: const SizedBox(),
    ),
  );
}

void main() {
  late CounterController first;
  late CounterController second;

  setUp(() {
    first = CounterController();
    second = CounterController();
  });

  tearDown(() {
    first.dispose();
    second.dispose();
  });

  testWidgets('changing controller subscribes only to the new stream', (
    tester,
  ) async {
    final handled = <JController<CounterState>>[];
    final firstHandler = ListenerHandler(first)
      ..register<BoolEffect>((effect, controller, context) async {
        handled.add(controller);
        effect.complete(true);
      });
    final secondHandler = ListenerHandler(second)
      ..register<BoolEffect>((effect, controller, context) async {
        handled.add(controller);
        effect.complete(false);
      });
    await tester.pumpWidget(listener(first, firstHandler));
    final firstEffect = BoolEffect();
    first.emitSideEffect(firstEffect);
    await tester.pump();
    expect(await firstEffect.result, isTrue);

    await tester.pumpWidget(listener(second, secondHandler));
    final ignored = BoolEffect();
    first.emitSideEffect(ignored);
    final secondEffect = BoolEffect();
    second.emitSideEffect(secondEffect);
    await tester.pump();
    expect(await secondEffect.result, isFalse);
    await expectLater(ignored.result, throwsStateError);
    expect(handled, [first, second]);
  });

  testWidgets(
    'changing handler uses the replacement without duplicate subscription',
    (tester) async {
      var oldCalls = 0;
      var newCalls = 0;
      final oldHandler = ListenerHandler(first)
        ..register<BoolEffect>((effect, controller, context) async {
          oldCalls++;
          effect.complete(true);
        });
      final newHandler = ListenerHandler(first)
        ..register<BoolEffect>((effect, controller, context) async {
          newCalls++;
          effect.complete(false);
        });
      await tester.pumpWidget(listener(first, oldHandler));
      await tester.pumpWidget(listener(first, newHandler));
      final effect = BoolEffect();
      first.emitSideEffect(effect);
      await tester.pump();
      expect(await effect.result, isFalse);
      expect(oldCalls, 0);
      expect(newCalls, 1);
    },
  );

  testWidgets('disposing listener cancels its subscription', (tester) async {
    var calls = 0;
    final handler = ListenerHandler(first)
      ..register<BoolEffect>((effect, controller, context) async {
        calls++;
        effect.complete(true);
      });
    await tester.pumpWidget(listener(first, handler));
    await tester.pumpWidget(const SizedBox());
    final effect = BoolEffect();
    first.emitSideEffect(effect);
    await tester.pump();
    expect(calls, 0);
    await expectLater(effect.result, throwsStateError);
  });

  testWidgets(
    'in-flight handler retains its original controller after replacement',
    (tester) async {
      final release = Completer<void>();
      final handler = ListenerHandler(first)
        ..register<BoolEffect>((effect, controller, context) async {
          await release.future;
          controller.update((_) => const CounterState(3));
          effect.complete(true);
        });
      await tester.pumpWidget(listener(first, handler));
      final effect = BoolEffect();
      first.emitSideEffect(effect);
      await tester.pump();
      await tester.pumpWidget(listener(second, ListenerHandler(second)));
      release.complete();
      await tester.pump();
      expect(await effect.result, isTrue);
      expect(first.currentState.value, 3);
      expect(second.currentState.value, 0);
    },
  );

  for (final asynchronous in [false, true]) {
    testWidgets(
      'handler failure ($asynchronous async) completes result and reports original error',
      (tester) async {
        final error = StateError('handler failure');
        final stack = StackTrace.current;
        final handler = ListenerHandler(first)
          ..register<BoolEffect>((effect, controller, context) {
            if (asynchronous) return Future<void>.error(error, stack);
            Error.throwWithStackTrace(error, stack);
          });
        await tester.pumpWidget(listener(first, handler));
        final effect = BoolEffect();
        final result = first.emitAndWaitSideEffect(effect);
        final assertion = expectLater(result, throwsA(same(error)));
        await tester.pump();
        await assertion;
        expect(tester.takeException(), same(error));
        expect(effect.isCompleted, isTrue);
      },
    );
  }

  testWidgets('unawaited fire-and-forget failure is reported once', (
    tester,
  ) async {
    final error = StateError('notification failure');
    final handler = ListenerHandler(first)
      ..register<NotificationEffect>((effect, controller, context) async {
        throw error;
      });
    await tester.pumpWidget(listener(first, handler));
    final effect = NotificationEffect();
    first.emitSideEffect(effect);
    await tester.pump();
    expect(tester.takeException(), same(error));
    expect(effect.isCompleted, isTrue);
    await expectLater(effect.result, throwsA(same(error)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('error after completing result does not overwrite result', (
    tester,
  ) async {
    final error = StateError('after completion');
    final handler = ListenerHandler(first)
      ..register<BoolEffect>((effect, controller, context) async {
        effect.complete(true);
        throw error;
      });
    await tester.pumpWidget(listener(first, handler));
    final effect = BoolEffect();
    first.emitSideEffect(effect);
    await tester.pump();
    expect(await effect.result, isTrue);
    expect(tester.takeException(), same(error));
  });

  testWidgets('in-flight failure after disposal still settles the result', (
    tester,
  ) async {
    final release = Completer<void>();
    final error = StateError('failure after disposal');
    final handler = ListenerHandler(first)
      ..register<BoolEffect>((effect, controller, context) async {
        await release.future;
        throw error;
      });
    await tester.pumpWidget(listener(first, handler));
    final effect = BoolEffect();
    final assertion = expectLater(effect.result, throwsA(same(error)));
    first.emitSideEffect(effect);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    release.complete();
    await tester.pump();
    await assertion;
    expect(tester.takeException(), same(error));
  });

  testWidgets('a pending handler does not block subsequent effects', (
    tester,
  ) async {
    final release = Completer<void>();
    final pending = BoolEffect();
    final immediate = BoolEffect();
    final handler = ListenerHandler(first)
      ..register<BoolEffect>((effect, controller, context) async {
        if (identical(effect, pending)) await release.future;
        effect.complete(true);
      });
    await tester.pumpWidget(listener(first, handler));
    first.emitSideEffect(pending);
    first.emitSideEffect(immediate);
    await tester.pump();
    expect(pending.isCompleted, isFalse);
    expect(await immediate.result, isTrue);
    release.complete();
    await tester.pump();
    expect(await pending.result, isTrue);
  });

  testWidgets('unmount leaves an in-flight result pending until its timeout', (
    tester,
  ) async {
    final release = Completer<void>();
    final handler = ListenerHandler(first)
      ..register<BoolEffect>((effect, controller, context) async {
        await release.future;
        effect.complete(true);
      });
    await tester.pumpWidget(listener(first, handler));
    final effect = BoolEffect();
    const timeout = Duration(seconds: 1);
    final result = first.emitAndWaitSideEffect(effect, timeout: timeout);
    final assertion = expectLater(result, throwsA(isA<TimeoutException>()));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(first.mounted, isTrue);
    expect(effect.isCompleted, isFalse);
    await tester.pump(timeout);
    await assertion;
    release.complete();
    await tester.pump();
    await expectLater(effect.result, throwsA(isA<TimeoutException>()));
  });
}
