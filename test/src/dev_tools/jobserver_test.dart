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

    test('calls onIntentFailed callback', () {
      Object? receivedError;
      JObserver.onIntentFailed = (intent, error, stackTrace) {
        receivedError = error;
      };

      JObserver.notifyIntentFailed(FakeIntent(), 'boom', StackTrace.empty);

      expect(receivedError, 'boom');
    });

    tearDown(JObserver.reset);
  });

  group('JObserver observers', () {
    tearDown(JObserver.reset);

    test('several observers coexist with the static callbacks', () {
      final calls = <String>[];
      JObserver.onIntentDispatched = (_) => calls.add('static');
      JObserver.addObserver(_RecordingObserver('a', calls));
      JObserver.addObserver(_RecordingObserver('b', calls));

      JObserver.notifyIntentDispatched(FakeIntent());

      expect(calls, ['static', 'a', 'b']);
    });

    test('every notification reaches observers', () {
      final calls = <String>[];
      JObserver.addObserver(_RecordingObserver('o', calls));
      final intent = FakeIntent();

      JObserver.notifyIntentStarted(intent);
      JObserver.notifyIntentFailed(intent, 'e', StackTrace.empty);
      JObserver.notifyStateChanged(FakeState(), FakeState());
      JObserver.notifyEffectEmitted(FakeEffect());

      expect(calls, ['o:started', 'o:failed', 'o:state', 'o:effect']);
    });

    test('the returned function removes only that observer, idempotently', () {
      final calls = <String>[];
      final removeA = JObserver.addObserver(_RecordingObserver('a', calls));
      JObserver.addObserver(_RecordingObserver('b', calls));

      removeA();
      removeA();
      JObserver.notifyIntentDispatched(FakeIntent());

      expect(calls, ['b']);
    });

    test('registering the same instance twice notifies it once', () {
      final calls = <String>[];
      final observer = _RecordingObserver('a', calls);
      JObserver.addObserver(observer);
      JObserver.addObserver(observer);

      JObserver.notifyIntentDispatched(FakeIntent());

      expect(calls, ['a']);
      expect(JObserver.removeObserver(observer), isTrue);
      expect(JObserver.removeObserver(observer), isFalse);
    });

    test('an observer can unregister itself while being notified', () {
      final calls = <String>[];
      late void Function() remove;
      remove = JObserver.addObserver(
        _RecordingObserver('a', calls, onCall: () => remove()),
      );
      JObserver.addObserver(_RecordingObserver('b', calls));

      JObserver.notifyIntentDispatched(FakeIntent());
      JObserver.notifyIntentDispatched(FakeIntent());

      expect(calls, ['a', 'b', 'b']);
    });

    test('failing observers are reported and do not stop the others', () {
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);
      final calls = <String>[];
      JObserver.onIntentDispatched = (_) => throw StateError('static');
      JObserver.addObserver(
        _RecordingObserver('a', calls, onCall: () => throw StateError('a')),
      );
      JObserver.addObserver(_RecordingObserver('b', calls));

      expect(
        () => JObserver.notifyIntentDispatched(FakeIntent()),
        returnsNormally,
      );

      expect(calls, ['a', 'b']);
      expect(reported, hasLength(2));
      expect(reported.first.library, 'jintent');
    });

    test('reset clears observers and callbacks', () {
      final calls = <String>[];
      JObserver.onIntentDispatched = (_) => calls.add('static');
      JObserver.addObserver(_RecordingObserver('a', calls));

      JObserver.reset();
      JObserver.notifyIntentDispatched(FakeIntent());

      expect(calls, isEmpty);
    });
  });
}

class _RecordingObserver extends JObserverDelegate {
  _RecordingObserver(this.name, this.calls, {this.onCall});
  final String name;
  final List<String> calls;
  final void Function()? onCall;

  void _record(String event) {
    final label = event.isEmpty ? name : '$name:$event';
    calls.add(label);
    onCall?.call();
  }

  @override
  void onIntentStarted(JIntent intent) => _record('started');

  @override
  void onIntentDispatched(JIntent intent) => _record('');

  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) =>
      _record('failed');

  @override
  void onStateChanged(JState prev, JState next, JIntent? origin) =>
      _record('state');

  @override
  void onEffectEmitted(JEffect effect) => _record('effect');
}
