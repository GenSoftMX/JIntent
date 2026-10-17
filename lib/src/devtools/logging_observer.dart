import 'package:flutter/foundation.dart';
import 'package:jintent/src/core/core.dart';
import 'package:jintent/src/devtools/jobserver.dart';

class _LoggingObserver extends JObserverDelegate {
  const _LoggingObserver();

  @override
  void onIntentDispatched(JIntent intent) {
    debugPrint('[Observer] Intent dispatched: ${intent.runtimeType}');
  }

  @override
  void onIntentCancelled(JIntent intent) {
    debugPrint('[Observer] Intent cancelled: ${intent.runtimeType}');
  }

  @override
  void onIntentDropped(JIntent intent) {
    debugPrint('[Observer] Intent dropped: ${intent.runtimeType}');
  }

  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) {
    debugPrint('[Observer] Intent failed: ${intent.runtimeType}: $error');
  }

  @override
  void onStateChanged(JState prev, JState next, JIntent? origin) {
    debugPrint(
      '[Observer] State changed: $prev → $next (via ${origin?.runtimeType})',
    );
  }

  @override
  void onEffectEmitted(JEffect effect) {
    debugPrint('[Observer] Effect emitted: ${effect.runtimeType}');
  }
}

const _loggingObserver = _LoggingObserver();

/// Enables a simple logging observer for debugging purposes.
///
/// This registers a [JObserverDelegate] on [JObserver] to log:
/// - When a [JIntent] is dispatched, fails, is cancelled or is dropped.
/// - When the state changes (from → to), including the triggering intent (if provided).
/// - When a [JEffect] is emitted by a controller.
///
/// It coexists with other observers and static callbacks, and calling it again
/// has no additional effect. It does nothing outside [kDebugMode]. The returned
/// function unregisters the observer.
///
/// Example:
/// ```dart
/// void main() {
///   enableLoggingObserver();
///   runApp(MyApp());
/// }
/// ```
void Function() enableLoggingObserver() {
  if (!kDebugMode) return () {};
  return JObserver.addObserver(_loggingObserver);
}
