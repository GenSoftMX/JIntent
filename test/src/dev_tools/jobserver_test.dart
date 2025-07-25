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
}

class FakeEffect extends JEffect<void> {}

void main() {
  group('JObserver', () {
    test('calls onIntentDispatched callback', () {
      bool called = false;
      JIntent? receivedIntent;

      JObserver.onIntentDispatched = (intent) {
        called = true;
        receivedIntent = intent;
      };

      final intent = FakeIntent();
      JObserver.notifyIntentDispatched(intent);

      expect(called, true);
      expect(receivedIntent, intent);
    });

    test('calls onStateChanged callback', () {
      bool called = false;
      JState? prevState;
      JState? nextState;
      JIntent? origin;

      JObserver.onStateChanged = (prev, next, originIntent) {
        called = true;
        prevState = prev;
        nextState = next;
        origin = originIntent;
      };

      final prev = FakeState();
      final next = FakeState();
      final intent = FakeIntent();

      JObserver.notifyStateChanged(prev, next, intent);

      expect(called, true);
      expect(prevState, prev);
      expect(nextState, next);
      expect(origin, intent);
    });

    test('calls onEffectEmitted callback', () {
      bool called = false;
      JEffect? receivedEffect;

      JObserver.onEffectEmitted = (effect) {
        called = true;
        receivedEffect = effect;
      };

      final effect = FakeEffect();
      JObserver.notifyEffectEmitted(effect);

      expect(called, true);
      expect(receivedEffect, effect);
    });

    tearDown(() {
      // Clean callbacks after each test
      JObserver.onIntentDispatched = null;
      JObserver.onStateChanged = null;
      JObserver.onEffectEmitted = null;
    });
  });
}
