import 'package:flutter/foundation.dart';
import 'package:jintent/src/devtools/jobserver.dart';

/// Enables a simple logging observer for debugging purposes.
///
/// This registers global callbacks on the [JObserver] singleton to log:
/// - When a [JIntent] is dispatched.
/// - When the state changes (from → to), including the triggering intent (if provided).
/// - When a [JEffect] is emitted by a controller.
///
/// This should typically be enabled only in development environments
/// using [kDebugMode].
///
/// Example:
/// ```dart
/// void main() {
///   enableLoggingObserver();
///   runApp(MyApp());
/// }
/// ```
void enableLoggingObserver() {
  if (kDebugMode) {
    JObserver.onIntentDispatched = (intent) {
      debugPrint('[Observer] Intent dispatched: ${intent.runtimeType}');
    };

    JObserver.onStateChanged = (prev, next, origin) {
      debugPrint(
        '[Observer] State changed: $prev → $next (via ${origin?.runtimeType})',
      );
    };

    JObserver.onEffectEmitted = (effect) {
      debugPrint('[Observer] Effect emitted: ${effect.runtimeType}');
    };
  }
}
