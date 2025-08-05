import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/src/core/effects/side_effect_handler.dart';
import 'package:mocktail/mocktail.dart';

import 'package:jintent/src/core/jcontroller.dart';
import 'package:jintent/src/core/jstate.dart';
import 'package:jintent/src/core/effects/jeffect.dart';

class MockController extends Mock implements JController<JState> {}

class TestEffect extends JEffect<int> {}

class TestHandler extends JSideEffectHandler<JState> {
  TestHandler(JController<JState> controller) : super(controller);
}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late final MockController controller;
  late final TestHandler handler;
  late final BuildContext context;

  setUp(() {
    controller = MockController();
    context = MockBuildContext();
    handler = TestHandler(controller);
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
}
