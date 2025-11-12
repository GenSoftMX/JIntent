import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

/// Dispatcher for handling intents sequentially, ensuring that each intent
/// is processed one at a time in the order they are received.
class JSequentialIntentDispatcher implements JIntentDispatcher {
  final _queue = Queue<_QueuedIntent>();
  bool _processing = false;

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) {
    final completer = Completer<void>();
    _queue.add(_QueuedIntent<T>(intent, controller, completer));
    _drain();
    return completer.future;
  }

  /// Processes the intent queue sequentially.
  /// * Each intent is executed in the order it was added, ensuring that
  /// side effects and state changes are handled in a predictable manner.
  /// * If an intent fails, it does not stop the processing of subsequent intents.
  void _drain() {
    if (_processing) return;
    _processing = true;

    Future<void>(() async {
      while (_queue.isNotEmpty) {
        final task = _queue.removeFirst();
        try {
          if (kDebugMode) {
            debugPrint(
              '🚀 [JIntent][SEQ] Dispatching ${task.intent.runtimeType}',
            );
          }

          await task.intent.run(task.controller);
          JObserver.notifyIntentDispatched(task.intent);

          if (kDebugMode) {
            debugPrint('✅ [JIntent][SEQ] Completed ${task.intent.runtimeType}');
          }

          task.completer.complete();
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              '❌ [JIntent][SEQ] Error in ${task.intent.runtimeType}: $e',
            );
          }
          // Notify the observer (you could add an onIntentError hook if you want)
          task.completer.completeError(e, st);
          // Continue with the rest; do not break the queue
        }
      }
      _processing = false;
    });
  }
}

class _QueuedIntent<T extends JState> {
  final JIntent<T> intent;
  final JController<T> controller;
  final Completer<void> completer;
  _QueuedIntent(this.intent, this.controller, this.completer);
}
