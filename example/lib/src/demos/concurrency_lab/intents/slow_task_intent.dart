import 'dart:async';

import 'package:counter/src/demos/concurrency_lab/state/lab_state.dart';
import 'package:jintent/jintent.dart';

/// A task that takes [duration] and then records that it finished.
class SlowTaskIntent extends JIntent<LabState> with JIntentHelpers<LabState> {
  SlowTaskIntent(this.id, this.duration);

  final int id;
  final Duration duration;

  @override
  Future<void> onInvoke() async {
    await Future<void>.delayed(duration);
    // Cooperative cancellation: a superseded task can stop early. Even
    // without this check, `update` ignores the writes of a cancelled intent.
    if (isCancelled) return;
    update((state) => state.copyWith(finished: [...state.finished, id]));
  }
}
