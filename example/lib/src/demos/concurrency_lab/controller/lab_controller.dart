import 'dart:async';

import 'package:counter/src/demos/concurrency_lab/state/lab_state.dart';
import 'package:counter/src/demos/concurrency_lab/configuration/lab_strategy.dart';
import 'package:counter/src/demos/concurrency_lab/intents/slow_task_intent.dart';
import 'package:jintent/jintent.dart';

class LabController extends JController<LabState> {
  LabController(LabStrategy strategy)
    : super(const LabState(), dispatcher: strategy.createDispatcher());

  Future<void> run(int id, Duration duration) =>
      intent(SlowTaskIntent(id, duration));

  @override
  void onInit() {}
}
