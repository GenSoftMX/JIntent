import 'dart:async';

import 'package:jintent/devtools.dart';
import 'package:jintent/jintent.dart';

/// Restores JIntent's process-wide state to its defaults.
///
/// Resets [JObserver] (registered observers and static callbacks),
/// [JEffectsConfig], [JMetrics] and [EitherConfig]. Call it from `setUp` or
/// `tearDown` so global configuration cannot leak between tests.
void resetJIntentGlobals() {
  JObserver.reset();
  JEffectsConfig().reset();
  JMetrics.reset();
  EitherConfig.errorLogger = null;
}

/// Records every state a [JController] emits, in order.
///
/// The state present when the recorder is attached is not recorded, so
/// [states] contains only the changes that follow. Equal consecutive states
/// never appear, because controllers skip them.
///
/// ```dart
/// final recorder = JStateRecorder(controller);
/// await controller.intent(IncrementIntent());
/// expect(recorder.states, [const CounterState(count: 1)]);
/// recorder.dispose();
/// ```
class JStateRecorder<T extends JState> {
  JStateRecorder(JController<T> controller) {
    _removeListener = controller.addListener(
      _states.add,
      fireImmediately: false,
    );
  }

  final _states = <T>[];
  late final void Function() _removeListener;

  /// The states emitted since this recorder was attached.
  List<T> get states => List.unmodifiable(_states);

  /// The most recent recorded state, or `null` if none changed yet.
  T? get lastState => _states.isEmpty ? null : _states.last;

  /// Forgets everything recorded so far.
  void clear() => _states.clear();

  /// Stops recording. Recorded states remain readable.
  void dispose() => _removeListener();
}

/// Plays the role of the UI for a [JController] in tests: it records emitted
/// effects and completes the awaitable ones with scripted responses.
///
/// Responses are registered per concrete effect type. An awaitable effect with
/// no registered response is left pending, so tests can assert on timeouts or
/// complete it manually; use [failUnhandled] to fail it instead.
///
/// ```dart
/// final ui = JEffectRecorder(controller)
///   ..respondTo<ConfirmDelete, bool>((effect) => true);
/// await controller.intent(DeleteIntent());
/// expect(ui.effects.single, isA<ConfirmDelete>());
/// ui.dispose();
/// ```
class JEffectRecorder {
  JEffectRecorder(JController controller, {this.failUnhandled = false}) {
    _subscription = controller.sideEffects.listen(_onEffect);
  }

  /// Whether awaitable effects without a registered response complete with a
  /// [StateError] instead of staying pending.
  final bool failUnhandled;

  final _effects = <JEffect>[];
  final _responders = <Type, Object? Function(JEffect effect)>{};
  late final StreamSubscription<JEffect> _subscription;

  /// Every effect received, in emission order.
  List<JEffect> get effects => List.unmodifiable(_effects);

  /// The received effects of type [E].
  List<E> effectsOfType<E extends JEffect>() =>
      _effects.whereType<E>().toList();

  /// Completes effects of exactly type [E] with the value [response] returns.
  ///
  /// If [response] throws, the effect completes with that error.
  void respondTo<E extends JEffect<V>, V>(V Function(E effect) response) {
    _responders[E] = (effect) => response(effect as E);
  }

  /// Forgets the recorded effects; registered responses are kept.
  void clear() => _effects.clear();

  /// Stops listening. Pending effects are left untouched.
  Future<void> dispose() => _subscription.cancel();

  void _onEffect(JEffect effect) {
    _effects.add(effect);
    final responder = _responders[effect.runtimeType];
    if (responder != null) {
      try {
        (effect as JEffect<Object?>).complete(responder(effect));
      } catch (error, stackTrace) {
        effect.completeError(error, stackTrace);
      }
    } else if (failUnhandled && effect is! JFireAndForgetEffect) {
      effect.completeError(
        StateError('No test response registered for ${effect.runtimeType}.'),
      );
    }
  }
}
