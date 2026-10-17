import 'package:flutter/foundation.dart';
import 'package:jintent/src/core/core.dart';

/// Composable observer for the JIntent lifecycle.
///
/// Extend it and override only the notifications you need, then register it
/// with [JObserver.addObserver]. Unlike the static [JObserver] callbacks, any
/// number of observers can coexist and each one can be removed independently.
abstract class JObserverDelegate {
  const JObserverDelegate();

  /// An intent started executing [JIntent.onInvoke].
  void onIntentStarted(JIntent intent) {}

  /// An intent was dispatched and completed successfully.
  void onIntentDispatched(JIntent intent) {}

  /// An intent finished after cancellation was requested ([JIntent.cancel]).
  /// It is reported here instead of [onIntentDispatched]; its work may have
  /// been partly skipped and its state updates were ignored.
  void onIntentCancelled(JIntent intent) {}

  /// A dispatcher discarded an intent without running it, for example
  /// [JDroppableIntentDispatcher] while an intent with the same key runs.
  void onIntentDropped(JIntent intent) {}

  /// An intent failed while executing [JIntent.onInvoke].
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) {}

  /// State changed from [prev] to [next], optionally via [origin].
  void onStateChanged(JState prev, JState next, JIntent? origin) {}

  /// A side effect was emitted by a controller.
  void onEffectEmitted(JEffect effect) {}
}

/// JObserver is a centralized observability utility to track
/// lifecycle events in the JIntent architecture.
///
/// There are two ways to listen:
/// - [addObserver] registers a [JObserverDelegate]. Several observers can be
///   registered at once and each registration can be removed on its own.
/// - The static `on...` callbacks hold a single slot each; assigning one
///   replaces the previous value. They keep working and are invoked before the
///   registered observers.
///
/// Observer failures never reach the code being observed: they are reported
/// through [FlutterError.reportError] and the remaining observers still run.
/// Notifications are global; call [reset] in tests that register observers.
class JObserver {
  static final List<JObserverDelegate> _delegates = [];

  /// Callback triggered when an intent is dispatched and completed. Cancelled
  /// and dropped intents are reported only to observers
  /// ([JObserverDelegate.onIntentCancelled], [JObserverDelegate.onIntentDropped]).
  static void Function(JIntent intent)? onIntentDispatched;

  /// Callback triggered when an intent fails while executing.
  static void Function(JIntent intent, Object error, StackTrace stackTrace)?
  onIntentFailed;

  /// Callback triggered when state changes from [prev] to [next].
  /// Optionally includes the originating intent.
  static void Function(JState prev, JState next, JIntent? origin)?
  onStateChanged;

  /// Callback triggered when a side effect is emitted.
  static void Function(JEffect effect)? onEffectEmitted;

  /// Registers [observer] and returns a function that removes it.
  ///
  /// Registering the same instance twice has no effect; the returned function
  /// is idempotent.
  static void Function() addObserver(JObserverDelegate observer) {
    if (!_delegates.any((registered) => identical(registered, observer))) {
      _delegates.add(observer);
    }
    return () => removeObserver(observer);
  }

  /// Removes [observer]; returns whether it was registered.
  static bool removeObserver(JObserverDelegate observer) {
    final before = _delegates.length;
    _delegates.removeWhere((registered) => identical(registered, observer));
    return _delegates.length != before;
  }

  /// Clears every registered observer and static callback.
  static void reset() {
    _delegates.clear();
    onIntentDispatched = null;
    onIntentFailed = null;
    onStateChanged = null;
    onEffectEmitted = null;
  }

  /// Called by the intent when its execution starts.
  static void notifyIntentStarted(JIntent intent) {
    if (_delegates.isEmpty) return;
    _notify('intent started', (d) => d.onIntentStarted(intent));
  }

  /// Called by dispatchers to notify that an intent was dispatched.
  static void notifyIntentDispatched(JIntent intent) {
    final callback = onIntentDispatched;
    if (callback == null && _delegates.isEmpty) return;
    _notify(
      'intent dispatched',
      (d) => d.onIntentDispatched(intent),
      callback == null ? null : () => callback(intent),
    );
  }

  /// Called by dispatchers when an intent finished without failing: reports
  /// [notifyIntentCancelled] if cancellation was requested, otherwise
  /// [notifyIntentDispatched].
  static void notifyIntentCompleted(JIntent intent) {
    if (intent.isCancelled) {
      notifyIntentCancelled(intent);
    } else {
      notifyIntentDispatched(intent);
    }
  }

  /// Called by dispatchers when a cancelled intent finishes.
  static void notifyIntentCancelled(JIntent intent) {
    if (_delegates.isEmpty) return;
    _notify('intent cancelled', (d) => d.onIntentCancelled(intent));
  }

  /// Called by dispatchers when an intent is discarded without running.
  static void notifyIntentDropped(JIntent intent) {
    if (_delegates.isEmpty) return;
    _notify('intent dropped', (d) => d.onIntentDropped(intent));
  }

  /// Called by the intent when its execution fails.
  static void notifyIntentFailed(
    JIntent intent,
    Object error,
    StackTrace stackTrace,
  ) {
    final callback = onIntentFailed;
    if (callback == null && _delegates.isEmpty) return;
    _notify(
      'intent failed',
      (d) => d.onIntentFailed(intent, error, stackTrace),
      callback == null ? null : () => callback(intent, error, stackTrace),
    );
  }

  /// Called by JController when the state changes.
  static void notifyStateChanged(JState prev, JState next, [JIntent? origin]) {
    final callback = onStateChanged;
    if (callback == null && _delegates.isEmpty) return;
    _notify(
      'state changed',
      (d) => d.onStateChanged(prev, next, origin),
      callback == null ? null : () => callback(prev, next, origin),
    );
  }

  /// Called by JController when a side effect is emitted.
  static void notifyEffectEmitted(JEffect effect) {
    final callback = onEffectEmitted;
    if (callback == null && _delegates.isEmpty) return;
    _notify(
      'effect emitted',
      (d) => d.onEffectEmitted(effect),
      callback == null ? null : () => callback(effect),
    );
  }

  // Callers return early when nothing observes, so the closures and the list
  // copy below are only built when there is something to notify.
  static void _notify(
    String event,
    void Function(JObserverDelegate delegate) notifyDelegate, [
    void Function()? callback,
  ]) {
    if (callback != null) _guard(event, callback);
    if (_delegates.isEmpty) return;
    // Iterate a copy so observers can unregister themselves while notified.
    for (final delegate in List.of(_delegates)) {
      _guard(event, () => notifyDelegate(delegate));
    }
  }

  static void _guard(String event, void Function() action) {
    try {
      action();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'jintent',
          context: ErrorDescription('while notifying observers of $event'),
        ),
      );
    }
  }
}
