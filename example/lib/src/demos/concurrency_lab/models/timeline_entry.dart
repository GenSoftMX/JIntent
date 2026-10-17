import 'package:flutter/foundation.dart';

enum TimelineKind { started, finished, cancelled, dropped, failed }

@immutable
class TimelineEntry {
  const TimelineEntry(this.taskId, this.kind, this.at);

  final int taskId;
  final TimelineKind kind;

  /// Time since the recorder was created or reset.
  final Duration at;
}
