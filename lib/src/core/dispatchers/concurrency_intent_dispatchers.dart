import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/src/core/jintent.dart' show isIntentRunning;

/// Computes the group an intent belongs to for concurrency decisions.
///
/// Intents with equal keys (by `==`) compete with each other; intents with
/// different keys never affect each other.
typedef JIntentKey = Object Function(JIntent intent);

Object _byRuntimeType(JIntent intent) => intent.runtimeType;

/// Dispatcher that drops an intent while another one with the same key is
/// still running for the same controller.
///
/// Useful for actions that must not overlap, such as submit or refresh. The
/// dropped intent is neither queued nor executed, and its returned future
/// completes normally; observers receive `onIntentDropped`. By default the key
/// is the intent's `runtimeType`.
/// Intents with different keys run concurrently. Disposal does not interrupt
/// running intents; the controller rejects new ones.
class JDroppableIntentDispatcher implements JIntentDispatcher {
  JDroppableIntentDispatcher({JIntentKey? keyOf})
    : _keyOf = keyOf ?? _byRuntimeType;

  final JIntentKey _keyOf;
  final _running = <(Object, Object)>{};

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    if (!controller.mounted) {
      throw StateError('JController has been disposed.');
    }
    final slot = (controller, _keyOf(intent));
    if (!_running.add(slot)) {
      if (kDebugMode) {
        debugPrint('⏭️ [JIntent][DROP] Dropped ${intent.runtimeType}');
      }
      JObserver.notifyIntentDropped(intent);
      return;
    }
    try {
      await intent.run(controller);
      JObserver.notifyIntentCompleted(intent);
    } finally {
      _running.remove(slot);
    }
  }
}

/// Dispatcher that cancels the running intent with the same key when a new one
/// arrives for the same controller, then starts the new intent immediately.
///
/// Useful for search-as-you-type or any "latest wins" flow. Cancellation is
/// cooperative (see [JIntent.cancel]): the superseded intent keeps running
/// until it returns, but [JController.update] ignores its state updates and it
/// can stop early by checking [JIntent.isCancelled]. Its future still reports
/// its own result or error, and observers receive `onIntentCancelled` instead
/// of `onIntentDispatched` when it finishes. By default the key is the intent's `runtimeType`.
/// Intents with different keys run concurrently.
class JRestartableIntentDispatcher implements JIntentDispatcher {
  JRestartableIntentDispatcher({JIntentKey? keyOf})
    : _keyOf = keyOf ?? _byRuntimeType;

  final JIntentKey _keyOf;
  final _running = <(Object, Object), JIntent>{};

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    if (!controller.mounted) {
      throw StateError('JController has been disposed.');
    }
    final slot = (controller, _keyOf(intent));
    // An instance that is still executing cannot be started again, even when
    // a newer intent already replaced it in the slot: reject the overlap
    // before cancelling or replacing anything.
    if (isIntentRunning(intent)) {
      throw StateError('${intent.runtimeType} is already running.');
    }
    _running[slot]?.cancel();
    _running[slot] = intent;
    try {
      await intent.run(controller);
      JObserver.notifyIntentCompleted(intent);
    } finally {
      // A newer intent may already own the slot; only release our own.
      if (identical(_running[slot], intent)) _running.remove(slot);
    }
  }
}
