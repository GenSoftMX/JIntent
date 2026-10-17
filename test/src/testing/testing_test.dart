import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/devtools.dart';
import 'package:jintent/testing.dart';

import '../core/core_test_support.dart';

class _Increment extends CallbackIntent {
  _Increment()
    : super((intent) async {
        intent.controller.update(
          (s) => s.copyWith(value: s.value + 1),
          origin: intent,
        );
      });
}

class _Confirm extends JDialogEffect<bool> {}

class _Toast extends JFireAndForgetEffect {}

void main() {
  group('JStateRecorder', () {
    late CounterController controller;
    late JStateRecorder<CounterState> recorder;

    setUp(() {
      controller = CounterController();
      recorder = JStateRecorder(controller);
    });

    tearDown(() {
      recorder.dispose();
      controller.dispose();
    });

    test('records only the changes after it is attached, in order', () async {
      expect(recorder.states, isEmpty);
      expect(recorder.lastState, isNull);

      await controller.intent(_Increment());
      await controller.intent(_Increment());

      expect(recorder.states, [const CounterState(1), const CounterState(2)]);
      expect(recorder.lastState, const CounterState(2));
    });

    test('ignores equal updates, clears and stops on dispose', () async {
      controller.update((s) => s);
      expect(recorder.states, isEmpty);

      await controller.intent(_Increment());
      recorder.clear();
      expect(recorder.states, isEmpty);

      recorder.dispose();
      await controller.intent(_Increment());
      expect(recorder.states, isEmpty);
    });

    test('exposes an unmodifiable snapshot', () async {
      await controller.intent(_Increment());
      expect(
        () => recorder.states.add(const CounterState()),
        throwsUnsupportedError,
      );
    });
  });

  group('JEffectRecorder', () {
    late CounterController controller;
    late JEffectRecorder ui;

    setUp(() {
      controller = CounterController();
    });

    tearDown(() async {
      await ui.dispose();
      controller.dispose();
    });

    test('completes awaitable effects with scripted responses', () async {
      ui = JEffectRecorder(controller)..respondTo<_Confirm, bool>((_) => true);

      final answer = await controller.emitAndWaitSideEffect(_Confirm());

      expect(answer, isTrue);
      expect(ui.effects.single, isA<_Confirm>());
      expect(ui.effectsOfType<_Confirm>(), hasLength(1));
      expect(ui.effectsOfType<_Toast>(), isEmpty);
    });

    test('responders receive the effect and can fail it', () async {
      ui = JEffectRecorder(controller)
        ..respondTo<_Confirm, bool>((_) => throw StateError('denied'));

      await expectLater(
        controller.emitAndWaitSideEffect(_Confirm()),
        throwsStateError,
      );
    });

    test('unanswered awaitable effects stay pending by default', () async {
      ui = JEffectRecorder(controller);
      final effect = _Confirm();
      final result = controller.emitAndWaitSideEffect(
        effect,
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(result, throwsA(isA<TimeoutException>()));
      expect(ui.effects.single, same(effect));
    });

    test('failUnhandled completes unanswered awaitable effects', () async {
      ui = JEffectRecorder(controller, failUnhandled: true);

      await expectLater(
        controller.emitAndWaitSideEffect(_Confirm()),
        throwsStateError,
      );
    });

    test('records fire-and-forget effects without completing them', () async {
      ui = JEffectRecorder(controller, failUnhandled: true);
      final toast = _Toast();

      controller.emitSideEffect(toast);
      await Future<void>(() {});

      expect(ui.effects.single, same(toast));
      expect(toast.isCompleted, isFalse);
      ui.clear();
      expect(ui.effects, isEmpty);
    });
  });

  group('resetJIntentGlobals', () {
    test('restores observers, effect config, metrics and Either logger', () {
      JObserver.onIntentDispatched = (_) {};
      JObserver.addObserver(const _NoopObserver());
      JEffectsConfig().defaultTimeout = const Duration(seconds: 1);
      JEffectsConfig().unhandledStrategy = UnhandledEffectStrategy.warnOnly;
      JEffectsConfig().idGenerator = () => 'fixed';
      JEffectsConfig().categoryResolver = (_) => 'cat';
      JMetrics.enable();
      JMetrics.incrementCounter('x');
      JMetrics.maxMetrics = 5;
      EitherConfig.configureLogger((_) {});

      resetJIntentGlobals();

      expect(JObserver.onIntentDispatched, isNull);
      expect(JEffectsConfig().defaultTimeout, isNull);
      expect(
        JEffectsConfig().unhandledStrategy,
        UnhandledEffectStrategy.warnAndCompleteError,
      );
      expect(JEffectsConfig().idGenerator, isNull);
      expect(JEffectsConfig().categoryResolver, isNull);
      JMetrics.incrementCounter('after-reset');
      expect(JMetrics.getMetrics(), isEmpty);
      expect(JMetrics.maxMetrics, 1000);
      expect(EitherConfig.errorLogger, isNull);
    });
  });
}

class _NoopObserver extends JObserverDelegate {
  const _NoopObserver();
}
