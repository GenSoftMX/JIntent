import 'package:flutter/foundation.dart';
import 'package:jintent/src/core/core.dart';
import 'package:jintent/src/devtools/jobserver.dart';

/// Interface for dispatching intents.
///
/// Defines a contract for classes that handle dispatching `JIntent` instances
/// to a `JController`. This abstraction allows different dispatching strategies
/// such as default execution or logging.
abstract class JIntentDispatcher {
  /// Dispatches the given [intent] to the provided [controller].
  ///
  /// The intent represents an action or event that can modify the
  /// controller's state. The implementation should ensure the intent
  /// is invoked appropriately.
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  );
}

/// Default dispatcher implementation that simply invokes the intent.
///
/// This class dispatches intents by directly calling their `run` method.
/// It also notifies the `JObserver` about dispatched intents for monitoring
/// or debugging purposes.
class JDefaultIntentDispatcher implements JIntentDispatcher {
  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    if (kDebugMode) {
      debugPrint('🚀 [JIntent] Dispatching ${intent.runtimeType}');
    }

    await intent.run(controller);

    JObserver.notifyIntentDispatched(intent);
  }
}

/// Dispatcher decorator that logs intent dispatching lifecycle events.
///
/// Wraps another [JIntentDispatcher] and adds logging before and after
/// dispatching an intent, including metadata if available.
///
/// This allows transparent logging of all intent dispatches without
/// modifying the underlying dispatcher behavior.
class LoggingDispatcher implements JIntentDispatcher {
  final JIntentDispatcher inner;

  /// Creates a logging decorator around the given [inner] dispatcher.
  LoggingDispatcher(this.inner);

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    final name =
        (intent is JMetaData)
            ? (intent as JMetaData).name
            : intent.runtimeType.toString();
    final type = (intent is JMetaData) ? (intent as JMetaData).type : 'default';
    final meta = (intent is JMetaData) ? (intent as JMetaData).metadata : {};

    if (kDebugMode) {
      debugPrint('[JIntent][$type] Dispatching: $name → metadata:$meta');
    }

    await inner.dispatch(intent, controller);

    if (kDebugMode) {
      debugPrint('✅ [JIntent][$type] Completed: $name');
    }
  }
}
