import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

void main() {
  late CounterController first;
  late CounterController second;

  setUp(() {
    first = CounterController();
    second = CounterController();
  });

  tearDown(() {
    if (first.mounted) first.dispose();
    second.dispose();
  });

  test(
    'direct invocation rejects a disposed controller without binding it',
    () async {
      var invoked = false;
      final intent = CallbackIntent((_) async {
        invoked = true;
      });
      first.dispose();
      await expectLater(intent.run(first), throwsStateError);
      expect(invoked, isFalse);
      expect(() => intent.controller, throwsStateError);
      await intent.run(second);
      expect(invoked, isTrue);
      expect(intent.controller, same(second));
    },
  );

  test('access before invocation reports a descriptive StateError', () {
    final intent = CallbackIntent((_) async {});
    expect(() => intent.controller, throwsStateError);
    expect(() => intent.state, throwsStateError);
  });

  test('run binds state and allows reuse after completion', () async {
    final intent = CallbackIntent((intent) async {
      intent.controller.update(
        (state) => state.copyWith(value: state.value + 1),
      );
    });
    await intent.run(first);
    await intent.run(second);
    expect(first.currentState.value, 1);
    expect(second.currentState.value, 1);
    expect(intent.controller, same(second));
  });

  test('overlap is rejected before rebinding the running intent', () async {
    final release = Completer<void>();
    final started = Completer<void>();
    final intent = CallbackIntent((intent) async {
      started.complete();
      await release.future;
      intent.controller.update((_) => const CounterState(7));
    });
    final running = intent.run(first);
    await started.future;
    try {
      await expectLater(intent.invoke(second), throwsStateError);
      expect(intent.controller, same(first));
    } finally {
      release.complete();
      await running;
    }
    expect(first.currentState.value, 7);
    expect(second.currentState.value, 0);
  });

  test(
    'failure preserves error and stack and releases execution guard',
    () async {
      final error = StateError('intent failed');
      final stack = StackTrace.current;
      var attempts = 0;
      final intent = CallbackIntent((_) {
        if (attempts++ == 0) return Future<void>.error(error, stack);
        return Future<void>.value();
      });
      try {
        await intent.run(first);
        fail('Expected failure');
      } catch (caught, trace) {
        expect(caught, same(error));
        expect(trace.toString(), stack.toString());
      }
      await intent.run(second);
      expect(attempts, 2);
      expect(intent.controller, same(second));
    },
  );

  test('synchronous onInvoke failure also releases execution guard', () async {
    var attempts = 0;
    final intent = CallbackIntent((_) {
      if (attempts++ == 0) throw ArgumentError('invalid input');
      return Future<void>.value();
    });
    await expectLater(intent.invoke(first), throwsArgumentError);
    await intent.invoke(second);
    expect(attempts, 2);
  });

  test('default queue permits serial reuse of the same instance', () async {
    final intent = CallbackIntent((intent) async {
      intent.controller.update(
        (state) => state.copyWith(value: state.value + 1),
      );
    });
    await Future.wait([first.intent(intent), first.intent(intent)]);
    expect(first.currentState.value, 2);
  });

  group('observer notifications', () {
    tearDown(JObserver.reset);

    test('start and failure are reported with the original error', () async {
      final events = <String>[];
      Object? failure;
      JObserver.addObserver(_EventObserver(events, (e) => failure = e));
      final boom = StateError('boom');

      await expectLater(
        CallbackIntent((_) async => throw boom).run(first),
        throwsA(same(boom)),
      );

      expect(events, ['started', 'failed']);
      expect(failure, same(boom));
    });

    test('a successful intent reports start but not failure', () async {
      final events = <String>[];
      JObserver.addObserver(_EventObserver(events, (_) {}));

      await CallbackIntent((_) async {}).run(first);

      expect(events, ['started']);
    });

    test('rejections before execution are not reported as failures', () async {
      final events = <String>[];
      JObserver.addObserver(_EventObserver(events, (_) {}));
      first.dispose();

      await expectLater(
        CallbackIntent((_) async {}).run(first),
        throwsStateError,
      );

      expect(events, isEmpty);
    });
  });

  group('cooperative cancellation', () {
    test('cancel flags only a running intent and resets on reuse', () async {
      final gate = Completer<void>();
      final intent = CallbackIntent((_) => gate.future);
      intent.cancel();
      expect(intent.isCancelled, isFalse);

      final run = intent.run(first);
      intent.cancel();
      expect(intent.isCancelled, isTrue);
      gate.complete();
      await run;
      expect(intent.isCancelled, isTrue);

      await CallbackIntent((_) async {}).run(first);
      final reused = CallbackIntent((_) async {});
      await reused.run(first);
      expect(reused.isCancelled, isFalse);
    });

    test('a cancelled intent cannot update state, others still can', () async {
      final gate = Completer<void>();
      final cancelled = CallbackIntent((intent) async {
        await gate.future;
        intent.controller.update((s) => s.copyWith(value: 99), origin: intent);
      });
      final run = cancelled.run(first);
      cancelled.cancel();
      first.update((s) => s.copyWith(value: 1));
      gate.complete();
      await run;

      expect(first.currentState.value, 1);

      first.update(
        (s) => s.copyWith(value: 2),
        origin: CallbackIntent((_) async {}),
      );
      expect(first.currentState.value, 2);
    });
  });
}

class _EventObserver extends JObserverDelegate {
  _EventObserver(this.events, this.onFailure);
  final List<String> events;
  final void Function(Object error) onFailure;

  @override
  void onIntentStarted(JIntent intent) => events.add('started');

  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) {
    events.add('failed');
    onFailure(error);
  }
}
