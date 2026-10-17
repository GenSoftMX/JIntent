import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

import 'core_test_support.dart';

void main() {
  late CounterController controller;
  late Duration? previousTimeout;
  late void Function(JState, JState, JIntent?)? previousObserver;
  late StreamSubscription<JEffect> effectSubscription;

  setUp(() {
    controller = CounterController();
    effectSubscription = controller.sideEffects.listen((_) {});
    previousTimeout = JEffectsConfig().defaultTimeout;
    previousObserver = JObserver.onStateChanged;
    JObserver.onStateChanged = null;
  });

  tearDown(() async {
    await effectSubscription.cancel();
    if (controller.mounted) controller.dispose();
    JEffectsConfig().defaultTimeout = previousTimeout;
    JObserver.onStateChanged = previousObserver;
  });

  for (final useDeprecatedSetter in [false, true]) {
    final method = useDeprecatedSetter ? 'setState' : 'update';

    void apply(CounterState next, {JIntent? origin}) {
      if (useDeprecatedSetter) {
        // ignore: deprecated_member_use_from_same_package
        controller.setState(next, origin: origin);
      } else {
        controller.update((_) => next, origin: origin);
      }
    }

    test('$method skips equal states and preserves original identity', () {
      final original = controller.currentState;
      var listenerCalls = 0;
      var observerCalls = 0;
      final remove = controller.addListener(
        (_) => listenerCalls++,
        fireImmediately: false,
      );
      addTearDown(remove);
      JObserver.onStateChanged = (_, _, _) => observerCalls++;

      apply(CounterState(original.value));

      expect(controller.currentState, same(original));
      expect(listenerCalls, 0);
      expect(observerCalls, 0);
    });

    test(
      '$method notifies once with previous state, next state and origin',
      () {
        final original = controller.currentState;
        const next = CounterState(2);
        final origin = CallbackIntent((_) async {});
        final states = <CounterState>[];
        final remove = controller.addListener(
          states.add,
          fireImmediately: false,
        );
        addTearDown(remove);
        var observerCalls = 0;
        JObserver.onStateChanged = (previous, current, source) {
          observerCalls++;
          expect(previous, same(original));
          expect(current, same(next));
          expect(source, same(origin));
        };

        apply(next, origin: origin);

        expect(controller.currentState, same(next));
        expect(states, [next]);
        expect(observerCalls, 1);
      },
    );
  }

  test('reducer failure leaves state and observers unchanged', () {
    final original = controller.currentState;
    var notifications = 0;
    JObserver.onStateChanged = (_, _, _) => notifications++;
    expect(
      () => controller.update((_) => throw ArgumentError('bad reducer')),
      throwsArgumentError,
    );
    expect(controller.currentState, same(original));
    expect(notifications, 0);
  });

  test('disposal prevents reducers and observer notifications', () {
    controller.dispose();
    var reducerCalled = false;
    var notifications = 0;
    JObserver.onStateChanged = (_, _, _) => notifications++;
    controller.update((state) {
      reducerCalled = true;
      return state;
    });
    // ignore: deprecated_member_use_from_same_package
    controller.setState(const CounterState(1));
    expect(reducerCalled, isFalse);
    expect(notifications, 0);
  });

  test('intent after disposal fails asynchronously without running', () async {
    controller.dispose();
    var invoked = false;
    final intent = CallbackIntent((_) async => invoked = true);
    await expectLater(controller.intent(intent), throwsStateError);
    expect(invoked, isFalse);
  });

  test('effect returns a non-nullable result', () async {
    final effect = BoolEffect();
    final subscription = controller.sideEffects.listen(
      (event) => effect.complete(true),
    );
    addTearDown(subscription.cancel);
    expect(await controller.emitAndWaitSideEffect(effect), isTrue);
  });

  test('effect propagates handler result errors', () async {
    final effect = BoolEffect();
    final error = StateError('handler failed');
    final result = controller.emitAndWaitSideEffect(effect);
    final assertion = expectLater(result, throwsA(same(error)));
    effect.completeError(error);
    await assertion;
  });

  testWidgets('explicit timeout fails both futures with TimeoutException', (
    tester,
  ) async {
    final effect = BoolEffect();
    const timeout = Duration(seconds: 1);
    JEffectsConfig().defaultTimeout = const Duration(seconds: 10);
    final result = controller.emitAndWaitSideEffect(effect, timeout: timeout);
    final matcher = isA<TimeoutException>().having(
      (error) => error.duration,
      'duration',
      timeout,
    );
    final assertion = expectLater(result, throwsA(matcher));
    final effectAssertion = expectLater(effect.result, throwsA(matcher));
    await tester.pump(timeout);
    await assertion;
    await effectAssertion;
    expect(effect.isCompleted, isTrue);
    effect.complete(true);
    await expectLater(effect.result, throwsA(matcher));
  });

  testWidgets('configured timeout is used when none is passed', (tester) async {
    const timeout = Duration(seconds: 2);
    JEffectsConfig().defaultTimeout = timeout;
    final effect = BoolEffect();
    final result = controller.emitAndWaitSideEffect(effect);
    final assertion = expectLater(result, throwsA(isA<TimeoutException>()));
    await tester.pump(timeout);
    await assertion;
    expect(effect.isCompleted, isTrue);
  });

  testWidgets('completion before timeout preserves the result', (tester) async {
    final effect = BoolEffect();
    final result = controller.emitAndWaitSideEffect(
      effect,
      timeout: const Duration(seconds: 1),
    );
    effect.complete(false);
    expect(await result, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(await effect.result, isFalse);
  });
}
