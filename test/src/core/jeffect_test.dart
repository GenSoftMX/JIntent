import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/src/core/effects/side_effect_handler.dart';
import 'package:mocktail/mocktail.dart';

import 'package:jintent/src/core/jcontroller.dart';
import 'package:jintent/src/core/jstate.dart';
import 'package:jintent/src/core/effects/jeffect.dart';
import 'package:jintent/src/core/effects/jeffect_config.dart';

class MockController extends Mock implements JController<JState> {}

class TestEffect extends JEffect<int> {}

class NullableEffect extends JResultEffect<bool?> {}

class NotificationEffect extends JFireAndForgetEffect {}

class DerivedEffect extends TestEffect {}

class TestHandler extends JSideEffectHandler<JState> {
  TestHandler(super.controller);
}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late MockController controller;
  late TestHandler handler;
  late BuildContext context;
  late UnhandledEffectStrategy previousStrategy;

  setUp(() {
    controller = MockController();
    context = MockBuildContext();
    handler = TestHandler(controller);
    previousStrategy = JEffectsConfig().unhandledStrategy;
    JEffectsConfig().unhandledStrategy =
        UnhandledEffectStrategy.warnAndCompleteError;
  });

  tearDown(() {
    JEffectsConfig().unhandledStrategy = previousStrategy;
  });

  test('handle calls registered handler and completes effect', () async {
    final effect = TestEffect();

    var called = false;
    handler.register<TestEffect>((eff, ctrl, context) async {
      called = true;
      eff.complete(42);
    });

    await handler.handle(effect, controller, context);

    expect(called, isTrue);
    expect(effect.isCompleted, isTrue);
    expect(await effect.result, 42);
  });

  test(
    'missing handler completes non-nullable result with descriptive error',
    () async {
      final effect = TestEffect();
      final assertion = expectLater(
        effect.result,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('TestEffect'), contains(effect.id)),
          ),
        ),
      );
      await handler.handle(effect, controller, context);
      await assertion;
      expect(effect.isCompleted, isTrue);
    },
  );

  test(
    'missing nullable handler also completes with error instead of null',
    () async {
      final effect = NullableEffect();
      final assertion = expectLater(effect.result, throwsStateError);
      await handler.handle(effect, controller, context);
      await assertion;
    },
  );

  test('legacy auto-complete strategy completes with error', () async {
    JEffectsConfig().unhandledStrategy =
        // ignore: deprecated_member_use_from_same_package
        UnhandledEffectStrategy.warnAndAutoComplete;
    final effect = TestEffect();
    final assertion = expectLater(effect.result, throwsStateError);
    await handler.handle(effect, controller, context);
    await assertion;
  });

  test('throwError fails handler and effect with the same error', () async {
    JEffectsConfig().unhandledStrategy = UnhandledEffectStrategy.throwError;
    final effect = TestEffect();
    Object? resultError;
    final observed = effect.result.then<void>(
      (_) => fail('Expected error'),
      onError: (Object error) {
        resultError = error;
      },
    );
    Object? handlerError;
    try {
      await handler.handle(effect, controller, context);
    } catch (error) {
      handlerError = error;
    }
    await observed;
    expect(handlerError, isA<StateError>());
    expect(resultError, same(handlerError));
  });

  test('warnOnly explicitly leaves result pending', () async {
    JEffectsConfig().unhandledStrategy = UnhandledEffectStrategy.warnOnly;
    final effect = TestEffect();
    await handler.handle(effect, controller, context);
    expect(effect.isCompleted, isFalse);
  });

  test('absent fire-and-forget handler does not fail', () async {
    JEffectsConfig().unhandledStrategy = UnhandledEffectStrategy.throwError;
    final effect = NotificationEffect();
    await handler.handle(effect, controller, context);
    expect(effect.isCompleted, isFalse);
  });

  test('base handler does not silently claim derived effect support', () async {
    var called = false;
    handler.register<TestEffect>((effect, controller, context) async {
      called = true;
      effect.complete(42);
    });
    final effect = DerivedEffect();
    final assertion = expectLater(effect.result, throwsStateError);
    await handler.handle(effect, controller, context);
    await assertion;
    expect(called, isFalse);
  });

  test('concrete derived handler is resolved normally', () async {
    handler.register<DerivedEffect>((effect, controller, context) async {
      effect.complete(7);
    });
    final effect = DerivedEffect();
    await handler.handle(effect, controller, context);
    expect(await effect.result, 7);
  });

  test(
    'direct handler failure completes result and preserves error and stack',
    () async {
      final error = ArgumentError('failure');
      final stack = StackTrace.current;
      handler.register<TestEffect>(
        (effect, controller, context) => Future<void>.error(error, stack),
      );
      final effect = TestEffect();
      final assertion = expectLater(effect.result, throwsA(same(error)));
      try {
        await handler.handle(effect, controller, context);
        fail('Expected handler failure');
      } catch (caught, trace) {
        expect(caught, same(error));
        expect(trace.toString(), stack.toString());
      }
      await assertion;
    },
  );

  test('a later failure does not overwrite a completed result', () async {
    handler.register<TestEffect>((effect, controller, context) async {
      effect.complete(42);
      throw StateError('late failure');
    });
    final effect = TestEffect();
    await expectLater(
      handler.handle(effect, controller, context),
      throwsStateError,
    );
    expect(await effect.result, 42);
  });

  test('completion is idempotent for values and errors', () async {
    final effect = TestEffect();
    effect.complete(1);
    effect.complete(2);
    effect.completeError(StateError('late failure'));
    expect(await effect.result, 1);
    final failed = TestEffect();
    final error = StateError('first failure');
    final assertion = expectLater(failed.result, throwsA(same(error)));
    failed.completeError(error);
    failed.complete(3);
    failed.completeError(StateError('second failure'));
    await assertion;
  });
}
