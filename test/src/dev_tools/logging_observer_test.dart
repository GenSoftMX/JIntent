
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

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
    test('registers logging callbacks when in debug mode', () {

      enableLoggingObserver();

      expect(JObserver.onIntentDispatched, isNotNull);
      expect(JObserver.onStateChanged, isNotNull);
      expect(JObserver.onEffectEmitted, isNotNull);
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

      JObserver.onIntentDispatched?.call(intent);
      JObserver.onStateChanged?.call(prevState, nextState, intent);
      JObserver.onEffectEmitted?.call(effect);

      expect(
          prints,
          containsAll([
            '[Observer] Intent dispatched: FakeIntent',
            '[Observer] State changed: FakeState → FakeState (via FakeIntent)',
            '[Observer] Effect emitted: FakeEffect',
          ]));

      // Restaurar debugPrint si quieres:
      debugPrint = debugPrintSynchronously;
    });

    tearDown(() {
      // Limpia los callbacks para evitar efecto en otros tests
      JObserver.onIntentDispatched = null;
      JObserver.onStateChanged = null;
      JObserver.onEffectEmitted = null;
    });
  });
}
