import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/devtools.dart';

class _LoggedEffect extends JFireAndForgetEffect with JCategorizableEffect {
  @override
  String get category => 'test';
}

void main() {
  late DebugPrintCallback previousDebugPrint;
  late void Function(JEffect)? previousObserver;
  late List<String> lines;

  setUp(() {
    previousDebugPrint = debugPrint;
    previousObserver = JObserver.onEffectEmitted;
    lines = [];
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
  });

  tearDown(() {
    debugPrint = previousDebugPrint;
    JObserver.reset();
    JObserver.onEffectEmitted = previousObserver;
  });

  test('logEmitted prints id, type and category', () {
    final effect = _LoggedEffect();
    JEffectsLogger.logEmitted(effect);
    expect(lines, hasLength(1));
    expect(lines.single, contains('[Effect][emit]'));
    expect(lines.single, contains(effect.id));
    expect(lines.single, contains('_LoggedEffect'));
    expect(lines.single, contains('category=test'));
  });

  test('logCompleted prints id and type', () {
    final effect = _LoggedEffect();
    JEffectsLogger.logCompleted(effect);
    expect(lines.single, contains('[Effect][done]'));
    expect(lines.single, contains(effect.id));
  });

  test('attach logs every emitted effect through the observer', () {
    JEffectsLogger.attach();
    final effect = _LoggedEffect();
    JObserver.notifyEffectEmitted(effect);
    expect(lines.single, contains(effect.id));
  });

  test('attach is idempotent, composable and removable', () {
    var otherCalls = 0;
    JObserver.onEffectEmitted = (_) => otherCalls++;
    JEffectsLogger.attach();
    final remove = JEffectsLogger.attach();

    JObserver.notifyEffectEmitted(_LoggedEffect());
    expect(lines, hasLength(1));
    expect(otherCalls, 1);

    remove();
    JObserver.notifyEffectEmitted(_LoggedEffect());
    expect(lines, hasLength(1));
    expect(otherCalls, 2);
  });
}
