import 'package:jintent/jintent.dart';

/// The dispatchers the lab compares. Each one decides what happens when
/// several intents arrive while earlier ones are still running.
enum LabStrategy {
  sequential(
    'Sequential',
    'One at a time, in order (the default). Nothing is lost, but later tasks '
        'wait for earlier ones.',
  ),
  concurrent(
    'Concurrent',
    'Every task starts immediately. They finish in the order their work ends.',
  ),
  droppable(
    'Droppable',
    'Tasks that arrive while one is running are ignored. Good for submit and '
        'refresh buttons.',
  ),
  restartable(
    'Restartable',
    'A new task cancels the running one (cooperatively). Only the latest wins: '
        'search as you type.',
  );

  const LabStrategy(this.label, this.description);

  final String label;
  final String description;

  JIntentDispatcher createDispatcher() => switch (this) {
    LabStrategy.sequential => JSequentialIntentDispatcher(),
    LabStrategy.concurrent => JDefaultIntentDispatcher(),
    LabStrategy.droppable => JDroppableIntentDispatcher(),
    LabStrategy.restartable => JRestartableIntentDispatcher(),
  };
}
