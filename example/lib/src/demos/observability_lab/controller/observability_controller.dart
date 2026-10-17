import 'dart:async';

import 'package:counter/src/demos/observability_lab/models/lab_outcome.dart';
import 'package:counter/src/demos/observability_lab/state/observability_state.dart';
import 'package:counter/src/demos/observability_lab/intents/outcome_intent.dart';
import 'package:jintent/devtools.dart';
import 'package:jintent/jintent.dart';

class ObservabilityController extends JController<ObservabilityState> {
  /// The droppable dispatcher lets the lab show `onIntentDropped` too: one
  /// intent at a time, others are ignored.
  ObservabilityController()
    : super(
        const ObservabilityState(),
        dispatcher: JDroppableIntentDispatcher(keyOf: (_) => 'lab'),
      );

  /// Runs [outcome] under a fresh correlation id.
  Future<void> run(LabOutcome outcome) => CorrelationContext.runWithCorrelation(
    () => intent(OutcomeIntent(outcome)),
  );

  /// Fires two intents back to back: the second is dropped.
  Future<void> runTwiceToDrop() =>
      Future.wait([run(LabOutcome.succeed), run(LabOutcome.succeed)]);

  @override
  void onInit() {}
}
