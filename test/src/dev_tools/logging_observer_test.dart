import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/devtools.dart';

class FakeIntent extends JIntent<JState> {
  @override
  Future<void> onInvoke() async {}
}

class FakeState extends JState {
  @override
  JState copyWith() => this;

  @override
  List<Object?> get props => [];
  @override
  String toString() => 'FakeState';
}

class FakeEffect extends JEffect<void> {}

void main() {
  group('enableLoggingObserver', () {
    test('registers an observer without taking the static callbacks', () {
      var staticCalls = 0;
      JObserver.onIntentDispatched = (_) => staticCalls++;
      final prints = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) prints.add(message);
      };
      addTearDown(() => debugPrint = previous);

      final remove = enableLoggingObserver();
      JObserver.notifyIntentDispatched(FakeIntent());

      expect(staticCalls, 1);
      expect(prints, ['[Observer] Intent dispatched: FakeIntent']);

      remove();
      prints.clear();
      JObserver.notifyIntentDispatched(FakeIntent());
      expect(prints, isEmpty);
    });

    test('logs cancelled and dropped intents', () {
      final prints = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) prints.add(message);
      };
      addTearDown(() => debugPrint = previous);

      enableLoggingObserver();
      JObserver.notifyIntentCancelled(FakeIntent());
      JObserver.notifyIntentDropped(FakeIntent());

      expect(prints, [
        '[Observer] Intent cancelled: FakeIntent',
        '[Observer] Intent dropped: FakeIntent',
      ]);
    });

    test('is idempotent and logs failures', () {
      final prints = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) prints.add(message);
      };
      addTearDown(() => debugPrint = previous);

      enableLoggingObserver();
      enableLoggingObserver();
      JObserver.notifyIntentFailed(FakeIntent(), 'boom', StackTrace.empty);

      expect(prints, ['[Observer] Intent failed: FakeIntent: boom']);
    });

    test('logging callbacks print debug messages', () {
      enableLoggingObserver();

      final intent = FakeIntent();
      final prevState = FakeState();
      final nextState = FakeState();
      final effect = FakeEffect();

      final prints = <String>[];

      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          prints.add(message);
        }
      };

      JObserver.notifyIntentDispatched(intent);
      JObserver.notifyStateChanged(prevState, nextState, intent);
      JObserver.notifyEffectEmitted(effect);

      expect(
        prints,
        containsAll([
          '[Observer] Intent dispatched: FakeIntent',
          '[Observer] State changed: FakeState → FakeState (via FakeIntent)',
          '[Observer] Effect emitted: FakeEffect',
        ]),
      );

      // Restaurar debugPrint si quieres:
      debugPrint = debugPrintSynchronously;
    });

    tearDown(JObserver.reset);
  });
}
