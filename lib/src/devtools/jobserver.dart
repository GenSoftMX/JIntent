import 'package:jintent/src/core/core.dart';

/// JObserver is a centralized observability utility to track
/// lifecycle events in the JIntent architecture.
///
/// It exposes static callbacks that can be assigned by the UI or devtools
/// to listen for intents dispatched, state changes, and side effects emitted.
class JObserver {
  /// Callback triggered when an intent is dispatched.
  static void Function(JIntent intent)? onIntentDispatched;

  /// Callback triggered when state changes from [prev] to [next].
  /// Optionally includes the originating intent.
  static void Function(JState prev, JState next, JIntent? origin)?
  onStateChanged;

  /// Callback triggered when a side effect is emitted.
  static void Function(JEffect effect)? onEffectEmitted;

  /// Called by JController (or dispatcher) to notify that an intent was dispatched.
  static void notifyIntentDispatched(JIntent intent) {
    onIntentDispatched?.call(intent);
  }

  /// Called by JController when the state changes.
  static void notifyStateChanged(JState prev, JState next, [JIntent? origin]) {
    onStateChanged?.call(prev, next, origin);
  }

  /// Called by JController when a side effect is emitted.
  static void notifyEffectEmitted(JEffect effect) {
    onEffectEmitted?.call(effect);
  }
}
