import 'dart:convert';

import 'package:counter/src/@core/observability/observability_setup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/devtools.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/testing.dart';

class _State extends JState {
  const _State();

  @override
  JState copyWith() => this;

  @override
  List<Object?> get props => [];
}

class _Controller extends JController<_State> {
  _Controller({super.dispatcher}) : super(const _State());

  @override
  void onInit() {}
}

class _FailingIntent extends JIntent<_State> {
  @override
  Future<void> onInvoke() async => throw StateError('boom');
}

class _NoopIntent extends JIntent<_State> {
  @override
  Future<void> onInvoke() async {}
}

void main() {
  late List<Map<String, dynamic>> logs;
  late DebugPrintCallback previousDebugPrint;

  setUp(() {
    logs = [];
    previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null && message.startsWith('{')) {
        logs.add(jsonDecode(message) as Map<String, dynamic>);
      }
    };
    JObserver.addObserver(
      IntentOutcomeObserver(JStructuredLogger(serviceName: 'test')),
    );
  });

  tearDown(() {
    debugPrint = previousDebugPrint;
    resetJIntentGlobals();
  });

  test('logs a failed intent as an error with its type and cause', () async {
    final controller = _Controller();
    addTearDown(controller.dispose);

    await expectLater(controller.intent(_FailingIntent()), throwsStateError);

    final entry = logs.single;
    expect(entry['level'], 'ERROR');
    expect(entry['message'], 'Intent failed');
    expect(entry['context']['intent'], '_FailingIntent');
    expect(entry['error'], contains('boom'));
  });

  test('logs dropped and cancelled intents at info level', () async {
    final controller = _Controller(dispatcher: JDefaultIntentDispatcher());
    addTearDown(controller.dispose);

    JObserver.notifyIntentDropped(_NoopIntent());
    await controller.intent(_CancellingIntent());

    expect(logs.map((l) => l['message']), [
      'Intent dropped',
      'Intent cancelled',
    ]);
    expect(logs.every((l) => l['level'] == 'INFO'), isTrue);
  });

  test('succeeding intents are not logged', () async {
    final controller = _Controller();
    addTearDown(controller.dispose);

    await controller.intent(_NoopIntent());

    expect(logs, isEmpty);
  });
}

class _CancellingIntent extends JIntent<_State> {
  @override
  Future<void> onInvoke() async => cancel();
}
