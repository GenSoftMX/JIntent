import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

class _Toast extends JFireAndForgetEffect {
  _Toast(this.label);
  final String label;
}

class _EmittingController extends CounterController {
  _EmittingController() : super(effectBufferSize: 4);

  final startup = _Toast('startup');

  @override
  void onInit() => emitSideEffect(startup);
}

void main() {
  tearDown(JObserver.reset);

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('default behavior (effectBufferSize 0)', () {
    test(
      'fire-and-forget without a listener is dropped, not retained',
      () async {
        final controller = CounterController();
        addTearDown(controller.dispose);
        controller.emitSideEffect(_Toast('lost'));

        final received = <JEffect>[];
        controller.sideEffects.listen(received.add);
        await flush();

        expect(received, isEmpty);
      },
    );

    test('awaitable without a listener still fails', () async {
      final controller = CounterController();
      addTearDown(controller.dispose);

      await expectLater(
        controller.emitAndWaitSideEffect(BoolEffect()),
        throwsStateError,
      );
    });

    test('negative sizes are rejected', () {
      expect(
        () => CounterController(effectBufferSize: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('buffered effects', () {
    late CounterController controller;

    setUp(() => controller = CounterController(effectBufferSize: 3));
    tearDown(() {
      if (controller.mounted) controller.dispose();
    });

    test(
      'are delivered in order after the first listener subscribes',
      () async {
        final a = _Toast('a');
        final b = _Toast('b');
        controller.emitSideEffect(a);
        controller.emitSideEffect(b);

        final received = <JEffect>[];
        controller.sideEffects.listen(received.add);
        expect(received, isEmpty, reason: 'delivery is asynchronous');
        await flush();

        expect(received, [same(a), same(b)]);
      },
    );

    test('are delivered once, to the first listener only', () async {
      controller.emitSideEffect(_Toast('a'));
      final first = <JEffect>[];
      final second = <JEffect>[];
      controller.sideEffects.listen(first.add);
      await flush();
      controller.sideEffects.listen(second.add);
      await flush();

      expect(first, hasLength(1));
      expect(second, isEmpty);
    });

    test('keep emission order when emitting before delivery runs', () async {
      final a = _Toast('a');
      final b = _Toast('b');
      controller.emitSideEffect(a);
      final received = <JEffect>[];
      controller.sideEffects.listen(received.add);

      controller.emitSideEffect(b);
      await flush();

      expect(received, [same(a), same(b)]);
    });

    test('are bypassed while a listener is attached', () async {
      final received = <JEffect>[];
      controller.sideEffects.listen(received.add);
      await flush();

      controller.emitSideEffect(_Toast('live'));
      await flush();

      expect(received, hasLength(1));
    });

    test('are retained again after the listener cancels', () async {
      final subscription = controller.sideEffects.listen((_) {});
      await flush();
      await subscription.cancel();

      controller.emitSideEffect(_Toast('later'));
      final received = <JEffect>[];
      controller.sideEffects.listen(received.add);
      await flush();

      expect(received, hasLength(1));
    });

    test('awaitable effects wait for a listener instead of failing', () async {
      final result = controller.emitAndWaitSideEffect(BoolEffect());
      var completed = false;
      unawaited(result.then((_) => completed = true));
      await flush();
      expect(completed, isFalse);

      controller.sideEffects.listen((effect) {
        (effect as BoolEffect).complete(true);
      });

      expect(await result, isTrue);
    });

    test(
      'a fire-and-forget effect awaited explicitly is delivered too',
      () async {
        final toast = _Toast('awaited');
        final result = controller.emitAndWaitSideEffect(toast);

        controller.sideEffects.listen((effect) {
          (effect as _Toast).complete(null);
        });

        await result;
        expect(toast.isCompleted, isTrue);
      },
    );

    test('overflow discards the oldest and fails it with StateError', () async {
      final oldest = BoolEffect();
      final oldestResult = oldest.result;
      final assertion = expectLater(oldestResult, throwsStateError);
      controller.emitSideEffect(oldest);
      controller.emitSideEffect(_Toast('b'));
      controller.emitSideEffect(_Toast('c'));
      controller.emitSideEffect(_Toast('d'));
      await assertion;

      final received = <JEffect>[];
      controller.sideEffects.listen(received.add);
      await flush();

      expect(received.map((e) => (e as _Toast).label), ['b', 'c', 'd']);
    });

    test('completed awaitable effects are skipped on delivery', () async {
      final timedOut = BoolEffect();
      final result = controller.emitAndWaitSideEffect(
        timedOut,
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(result, throwsA(isA<TimeoutException>()));
      controller.emitSideEffect(_Toast('after'));

      final received = <JEffect>[];
      controller.sideEffects.listen(received.add);
      await flush();

      expect(received.map((e) => e.runtimeType), [_Toast]);
    });

    test(
      'disposal fails buffered awaitable effects and drops the rest',
      () async {
        final result = controller.emitAndWaitSideEffect(BoolEffect());
        final assertion = expectLater(result, throwsStateError);
        controller.emitSideEffect(_Toast('x'));

        controller.dispose();

        await assertion;
      },
    );

    test('observers are notified when the effect is emitted', () async {
      final seen = <JEffect>[];
      JObserver.onEffectEmitted = seen.add;

      controller.emitSideEffect(_Toast('a'));

      expect(seen, hasLength(1));
    });

    test('a listener attached after disposal receives nothing', () async {
      controller.emitSideEffect(_Toast('a'));
      controller.dispose();

      final received = <JEffect>[];
      controller.sideEffects.listen(received.add);
      await flush();

      expect(received, isEmpty);
    });
  });

  group('observing buffered effects', () {
    test('onEffectEmitted sees them without consuming the buffer', () async {
      final seen = <JEffect>[];
      JObserver.onEffectEmitted = seen.add;
      final controller = CounterController(effectBufferSize: 2);
      addTearDown(controller.dispose);
      controller.emitSideEffect(_Toast('a'));
      expect(seen, hasLength(1));

      final ui = <JEffect>[];
      controller.sideEffects.listen(ui.add);
      await flush();

      expect(ui, hasLength(1));
    });

    test(
      'a plain sideEffects listener consumes them, observers do not',
      () async {
        final controller = CounterController(effectBufferSize: 2);
        addTearDown(controller.dispose);
        controller.emitSideEffect(_Toast('a'));

        final tap = <JEffect>[];
        controller.sideEffects.listen(tap.add);
        await flush();
        final ui = <JEffect>[];
        controller.sideEffects.listen(ui.add);
        await flush();

        expect(tap, hasLength(1));
        expect(ui, isEmpty, reason: 'documented: the first listener wins');
      },
    );
  });

  test('effects emitted from onInit reach the first listener', () async {
    final controller = _EmittingController();
    addTearDown(controller.dispose);

    final received = <JEffect>[];
    controller.sideEffects.listen(received.add);
    await flush();

    expect(received, [same(controller.startup)]);
  });
}
