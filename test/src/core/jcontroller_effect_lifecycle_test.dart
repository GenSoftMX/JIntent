import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

class NotificationEffect extends JFireAndForgetEffect {}

void main() {
  late CounterController controller;

  setUp(() {
    controller = CounterController();
  });

  tearDown(() {
    if (controller.mounted) controller.dispose();
  });

  test(
    'awaitable effect without listener fails immediately with descriptive error',
    () async {
      final effect = BoolEffect();
      final result = controller.emitAndWaitSideEffect(effect);
      final matcher = isA<StateError>().having(
        (error) => error.message,
        'message',
        allOf(contains('No listener'), contains(effect.id)),
      );
      await expectLater(result, throwsA(matcher));
      await expectLater(effect.result, throwsA(matcher));
    },
  );

  test(
    'emitSideEffect also fails an awaitable result without a listener',
    () async {
      final effect = BoolEffect();
      controller.emitSideEffect(effect);
      await expectLater(effect.result, throwsStateError);
    },
  );

  test('fire-and-forget emission without listener does not throw', () {
    expect(
      () => controller.emitSideEffect(NotificationEffect()),
      returnsNormally,
    );
  });

  test('explicitly awaiting fire-and-forget without listener fails', () async {
    await expectLater(
      controller.emitAndWaitSideEffect(NotificationEffect()),
      throwsStateError,
    );
  });

  test('explicitly awaited fire-and-forget is settled on disposal', () async {
    final subscription = controller.sideEffects.listen((_) {});
    addTearDown(subscription.cancel);
    final result = controller.emitAndWaitSideEffect(NotificationEffect());
    final assertion = expectLater(result, throwsStateError);
    controller.dispose();
    await assertion;
  });

  test('rejected effects are not reported as emitted', () async {
    final previous = JObserver.onEffectEmitted;
    addTearDown(() => JObserver.onEffectEmitted = previous);
    var emitted = 0;
    JObserver.onEffectEmitted = (_) => emitted++;
    await expectLater(
      controller.emitAndWaitSideEffect(BoolEffect()),
      throwsStateError,
    );
    expect(emitted, 0);
  });

  test('new listener receives subsequent effects but no replay', () async {
    final missing = BoolEffect();
    await expectLater(
      controller.emitAndWaitSideEffect(missing),
      throwsStateError,
    );
    final received = <JEffect>[];
    final subscription = controller.sideEffects.listen((effect) {
      received.add(effect);
      (effect as BoolEffect).complete(true);
    });
    addTearDown(subscription.cancel);
    final delivered = BoolEffect();
    expect(await controller.emitAndWaitSideEffect(delivered), isTrue);
    expect(received, [delivered]);
  });

  test(
    'disposal fails every pending result, including directly emitted effects',
    () async {
      final subscription = controller.sideEffects.listen((_) {});
      addTearDown(subscription.cancel);
      final first = BoolEffect();
      final second = BoolEffect();
      final result = controller.emitAndWaitSideEffect(first);
      controller.emitSideEffect(second);
      final firstAssertion = expectLater(result, throwsStateError);
      final secondAssertion = expectLater(second.result, throwsStateError);
      controller.dispose();
      await firstAssertion;
      await secondAssertion;
      first.complete(true);
      second.complete(false);
      await expectLater(first.result, throwsStateError);
      await expectLater(second.result, throwsStateError);
    },
  );

  test('disposal preserves results completed before cleanup runs', () async {
    final subscription = controller.sideEffects.listen((_) {});
    addTearDown(subscription.cancel);
    final effect = BoolEffect();
    final result = controller.emitAndWaitSideEffect(effect);
    effect.complete(true);
    controller.dispose();
    expect(await result, isTrue);
  });

  test('disposal preserves a previously completed error', () async {
    final subscription = controller.sideEffects.listen((_) {});
    addTearDown(subscription.cancel);
    final effect = BoolEffect();
    final result = controller.emitAndWaitSideEffect(effect);
    final error = ArgumentError('handler error');
    final assertion = expectLater(result, throwsA(same(error)));
    effect.completeError(error);
    controller.dispose();
    await assertion;
  });

  test(
    'emitSideEffect after disposal throws and settles effect result',
    () async {
      controller.dispose();
      final effect = BoolEffect();
      expect(() => controller.emitSideEffect(effect), throwsStateError);
      await expectLater(effect.result, throwsStateError);
    },
  );

  test(
    'emitAndWaitSideEffect after disposal fails through its future',
    () async {
      controller.dispose();
      final effect = BoolEffect();
      await expectLater(
        controller.emitAndWaitSideEffect(effect),
        throwsStateError,
      );
      await expectLater(effect.result, throwsStateError);
    },
  );

  testWidgets('disposal settles timed effect without waiting for timeout', (
    tester,
  ) async {
    final subscription = controller.sideEffects.listen((_) {});
    addTearDown(subscription.cancel);
    final effect = BoolEffect();
    final result = controller.emitAndWaitSideEffect(
      effect,
      timeout: const Duration(hours: 1),
    );
    final assertion = expectLater(result, throwsStateError);
    controller.dispose();
    await tester.pump();
    await assertion;
    await tester.pump(const Duration(hours: 1));
    await expectLater(effect.result, throwsStateError);
  });

  test(
    'cancelling a subscription before delivery drops the event but timeout settles result',
    () async {
      var delivered = false;
      final subscription = controller.sideEffects.listen(
        (_) => delivered = true,
      );
      final effect = BoolEffect();
      // A zero-duration timer runs on the next event turn, after cancellation.
      final result = controller.emitAndWaitSideEffect(
        effect,
        timeout: Duration.zero,
      );
      final assertion = expectLater(result, throwsA(isA<TimeoutException>()));
      await subscription.cancel();
      expect(effect.isCompleted, isFalse);
      await assertion;
      expect(delivered, isFalse);
    },
  );
}
