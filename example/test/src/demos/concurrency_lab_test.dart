import 'package:counter/src/demos/concurrency_lab/controller/lab_controller.dart';
import 'package:counter/src/demos/concurrency_lab/presentation/lab_page.dart';
import 'package:counter/src/demos/concurrency_lab/configuration/lab_scenario.dart';
import 'package:counter/src/demos/concurrency_lab/state/lab_state.dart';
import 'package:counter/src/demos/concurrency_lab/configuration/lab_strategy.dart';
import 'package:counter/src/demos/concurrency_lab/intents/slow_task_intent.dart';
import 'package:counter/src/demos/concurrency_lab/models/timeline_entry.dart';
import 'package:counter/src/demos/concurrency_lab/observers/timeline_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/testing.dart';

Duration _taskDuration(int id) => Duration(milliseconds: (6 - id) * 20);

/// Fires the five tasks at once and waits until the strategy settles.
Future<(LabController, TimelineRecorder)> _run(LabStrategy strategy) async {
  final controller = LabController(strategy);
  final recorder = TimelineRecorder();
  JObserver.addObserver(recorder);
  final futures = [
    for (var id = 1; id <= labTaskCount; id++)
      controller.run(id, _taskDuration(id)),
  ];
  await Future.wait(futures);
  return (controller, recorder);
}

List<TimelineKind> _kindsOf(TimelineRecorder recorder, int id) => [
  for (final entry in recorder.entries.value)
    if (entry.taskId == id) entry.kind,
];

void main() {
  setUp(resetJIntentGlobals);
  tearDown(resetJIntentGlobals);

  group('LabController strategies', () {
    test('sequential keeps order and loses nothing', () async {
      final (controller, recorder) = await _run(LabStrategy.sequential);
      addTearDown(controller.dispose);

      expect(controller.currentState.finished, [1, 2, 3, 4, 5]);
      for (var id = 1; id <= labTaskCount; id++) {
        expect(_kindsOf(recorder, id), [
          TimelineKind.started,
          TimelineKind.finished,
        ]);
      }
      // One at a time: task n starts only after task n - 1 finished.
      final kinds = recorder.entries.value.map((e) => e.kind).toList();
      expect(kinds, [
        for (var i = 0; i < labTaskCount; i++) ...[
          TimelineKind.started,
          TimelineKind.finished,
        ],
      ]);
    });

    test('concurrent starts everything and finishes by duration', () async {
      final (controller, recorder) = await _run(LabStrategy.concurrent);
      addTearDown(controller.dispose);

      expect(controller.currentState.finished, [5, 4, 3, 2, 1]);
      final firstFive = recorder.entries.value
          .take(labTaskCount)
          .map((e) => e.kind);
      expect(firstFive, everyElement(TimelineKind.started));
    });

    test('droppable runs the first task and drops the rest', () async {
      final (controller, recorder) = await _run(LabStrategy.droppable);
      addTearDown(controller.dispose);

      expect(controller.currentState.finished, [1]);
      expect(_kindsOf(recorder, 1), [
        TimelineKind.started,
        TimelineKind.finished,
      ]);
      for (var id = 2; id <= labTaskCount; id++) {
        expect(_kindsOf(recorder, id), [TimelineKind.dropped]);
      }
    });

    test('restartable cancels superseded tasks and keeps the latest', () async {
      final (controller, recorder) = await _run(LabStrategy.restartable);
      addTearDown(controller.dispose);

      expect(controller.currentState.finished, [5]);
      for (var id = 1; id < labTaskCount; id++) {
        expect(_kindsOf(recorder, id), [
          TimelineKind.started,
          TimelineKind.cancelled,
        ]);
      }
      expect(_kindsOf(recorder, 5), [
        TimelineKind.started,
        TimelineKind.finished,
      ]);
    });
  });

  test('the recorder ignores intents that are not lab tasks', () async {
    final recorder = TimelineRecorder();
    final controller = LabController(LabStrategy.sequential);
    addTearDown(controller.dispose);

    recorder.onIntentDispatched(_OtherIntent());

    expect(recorder.entries.value, isEmpty);
  });

  test('reset clears the recorded timeline', () {
    final recorder = TimelineRecorder();
    recorder.onIntentDropped(SlowTaskIntent(1, Duration.zero));
    expect(recorder.entries.value, hasLength(1));

    recorder.reset();

    expect(recorder.entries.value, isEmpty);
  });

  group('ConcurrencyLabPage', () {
    Future<void> pumpPage(WidgetTester tester) =>
        tester.pumpWidget(const MaterialApp(home: ConcurrencyLabPage()));

    Future<void> fireAndSettle(
      WidgetTester tester,
      LabStrategy strategy,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.text(strategy.label));
      await tester.pump();
      await tester.tap(find.text('Fire 5 tasks'));
      // Tasks are fired 80 ms apart and the longest lasts 750 ms.
      await tester.pump(const Duration(seconds: 4));
    }

    testWidgets('every strategy stays readable on a narrow phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      for (final strategy in LabStrategy.values) {
        expect(find.text(strategy.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sequential finishes in order', (tester) async {
      await fireAndSettle(tester, LabStrategy.sequential);

      expect(find.text('Finished order: 1, 2, 3, 4, 5'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('concurrent finishes in reverse order', (tester) async {
      await fireAndSettle(tester, LabStrategy.concurrent);

      expect(find.text('Finished order: 5, 4, 3, 2, 1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('droppable shows dropped tasks in the timeline', (
      tester,
    ) async {
      await fireAndSettle(tester, LabStrategy.droppable);

      expect(find.text('Finished order: 1'), findsOneWidget);
      expect(find.text('Task 2 dropped'), findsOneWidget);
      expect(find.text('Task 5 dropped'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('restartable shows cancelled tasks in the timeline', (
      tester,
    ) async {
      await fireAndSettle(tester, LabStrategy.restartable);

      expect(find.text('Finished order: 5'), findsOneWidget);
      expect(find.text('Task 1 cancelled'), findsOneWidget);
      expect(find.text('Task 5 finished'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reset clears the result and the timeline', (tester) async {
      await fireAndSettle(tester, LabStrategy.sequential);

      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(find.text('No task has finished yet'), findsOneWidget);
      expect(find.text('Nothing recorded yet'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('changing strategy while tasks run leaves no pending work', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.text('Fire 5 tasks'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Droppable'));
      await tester.pump(const Duration(seconds: 4));

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _OtherIntent extends JIntent<LabState> {
  @override
  Future<void> onInvoke() async {}
}
