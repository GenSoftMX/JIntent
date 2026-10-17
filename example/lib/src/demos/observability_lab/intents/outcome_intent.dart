import 'dart:async';

import 'package:counter/src/demos/observability_lab/models/lab_outcome.dart';
import 'package:counter/src/demos/observability_lab/state/observability_state.dart';
import 'package:jintent/devtools.dart';
import 'package:jintent/jintent.dart';

class OutcomeIntent extends JIntent<ObservabilityState>
    with JIntentHelpers<ObservabilityState> {
  OutcomeIntent(this.outcome, {this.delay = const Duration(milliseconds: 40)});

  final LabOutcome outcome;
  final Duration delay;

  @override
  Future<void> onInvoke() async {
    await Future<void>.delayed(delay);
    switch (outcome) {
      case LabOutcome.succeed:
        // The zone carries the correlation id from the call site, through the
        // dispatcher and into this intent.
        update(
          (s) => s.copyWith(
            completedRuns: s.completedRuns + 1,
            lastCorrelationId: CorrelationContext.current,
          ),
        );
      case LabOutcome.fail:
        throw StateError('Simulated failure');
      case LabOutcome.cancel:
        cancel();
    }
  }
}
