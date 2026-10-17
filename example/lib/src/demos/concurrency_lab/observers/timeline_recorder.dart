import 'package:counter/src/demos/concurrency_lab/intents/slow_task_intent.dart';
import 'package:counter/src/demos/concurrency_lab/models/timeline_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

/// Records what the dispatchers report about [SlowTaskIntent]s.
///
/// This is a [JObserverDelegate]: it is the same hook an analytics or logging
/// integration would use, and it coexists with any other observer.
class TimelineRecorder extends JObserverDelegate {
  TimelineRecorder() {
    _clock.start();
  }

  final _clock = Stopwatch();
  final entries = ValueNotifier<List<TimelineEntry>>(const []);

  void reset() {
    _clock
      ..reset()
      ..start();
    entries.value = const [];
  }

  void _add(JIntent intent, TimelineKind kind) {
    if (intent is! SlowTaskIntent) return;
    entries.value = [
      ...entries.value,
      TimelineEntry(intent.id, kind, _clock.elapsed),
    ];
  }

  @override
  void onIntentStarted(JIntent intent) => _add(intent, TimelineKind.started);

  @override
  void onIntentDispatched(JIntent intent) =>
      _add(intent, TimelineKind.finished);

  @override
  void onIntentCancelled(JIntent intent) =>
      _add(intent, TimelineKind.cancelled);

  @override
  void onIntentDropped(JIntent intent) => _add(intent, TimelineKind.dropped);

  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) =>
      _add(intent, TimelineKind.failed);
}
