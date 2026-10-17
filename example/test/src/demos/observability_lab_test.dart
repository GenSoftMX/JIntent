import 'package:counter/src/demos/observability_lab/observers/lab_log_observer.dart';
import 'package:counter/src/demos/observability_lab/models/lab_outcome.dart';
import 'package:counter/src/demos/observability_lab/controller/observability_controller.dart';
import 'package:counter/src/demos/observability_lab/presentation/observability_page.dart';
import 'package:counter/src/demos/observability_lab/state/observability_state.dart';
import 'package:counter/src/demos/observability_lab/observers/outcome_counts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/devtools.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/testing.dart';

void main() {
  setUp(() {
    resetJIntentGlobals();
    JMetrics.attachToObserver();
  });
  tearDown(resetJIntentGlobals);

  group('ObservabilityController', () {
    late ObservabilityController controller;
    late LabLogObserver log;

    setUp(() {
      controller = ObservabilityController();
      log = LabLogObserver();
      JObserver.addObserver(log);
    });

    tearDown(() => controller.dispose());

    test(
      'a succeeding intent is counted and sees the correlation id',
      () async {
        await controller.run(LabOutcome.succeed);

        expect(outcomeCounts()['intent.dispatched'], 1);
        expect(controller.currentState.completedRuns, 1);
        expect(controller.currentState.lastCorrelationId, isNotNull);
        expect(log.lines.map((l) => l.text), [
          'completed OutcomeIntent',
          'started OutcomeIntent',
        ]);
      },
    );

    test('each run gets its own correlation id', () async {
      await controller.run(LabOutcome.succeed);
      final first = controller.currentState.lastCorrelationId;
      await controller.run(LabOutcome.succeed);

      expect(controller.currentState.lastCorrelationId, isNot(first));
    });

    test('a failing intent is counted and reaches the caller', () async {
      await expectLater(controller.run(LabOutcome.fail), throwsStateError);

      expect(outcomeCounts()['intent.failed'], 1);
      expect(outcomeCounts()['intent.dispatched'], 0);
      expect(log.lines.first.text, contains('failed OutcomeIntent'));
    });

    test(
      'a cancelled intent is counted as cancelled, not dispatched',
      () async {
        await controller.run(LabOutcome.cancel);

        expect(outcomeCounts()['intent.cancelled'], 1);
        expect(outcomeCounts()['intent.dispatched'], 0);
        expect(log.lines.first.text, 'cancelled OutcomeIntent');
      },
    );

    test('the second of two overlapping intents is dropped', () async {
      await controller.runTwiceToDrop();

      expect(outcomeCounts()['intent.dropped'], 1);
      expect(outcomeCounts()['intent.dispatched'], 1);
      expect(controller.currentState.completedRuns, 1);
      expect(log.lines.map((l) => l.text), contains('dropped OutcomeIntent'));
    });

    test('the log keeps only the latest lines', () async {
      final short = LabLogObserver(maxLines: 2);
      JObserver.addObserver(short);

      await controller.run(LabOutcome.succeed);
      await controller.run(LabOutcome.succeed);

      expect(short.lines, hasLength(2));
    });
  });

  group('ObservabilityLabPage', () {
    Future<void> pumpPage(WidgetTester tester) =>
        tester.pumpWidget(const MaterialApp(home: ObservabilityLabPage()));

    Future<void> tapAndSettle(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('buttons update the metrics and the event log', (tester) async {
      await pumpPage(tester);
      expect(find.text('intent.failed: 0'), findsOneWidget);

      await tapAndSettle(tester, 'Fail');
      await tapAndSettle(tester, 'Succeed');
      await tapAndSettle(tester, 'Cancel');
      await tapAndSettle(tester, 'Drop one');

      expect(find.text('intent.failed: 1'), findsOneWidget);
      expect(find.text('intent.cancelled: 1'), findsOneWidget);
      expect(find.text('intent.dropped: 1'), findsOneWidget);
      expect(find.text('intent.dispatched: 2'), findsOneWidget);
      expect(find.text('dropped OutcomeIntent'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('clear resets the app-wide metrics and the log', (
      tester,
    ) async {
      await pumpPage(tester);
      await tapAndSettle(tester, 'Succeed');
      expect(find.text('intent.dispatched: 1'), findsOneWidget);
      expect(find.text('completed OutcomeIntent'), findsOneWidget);

      await tester.tap(find.byKey(const Key('clear-metrics')));
      await tester.pump();

      expect(find.text('intent.dispatched: 0'), findsOneWidget);
      expect(find.text('Nothing recorded yet'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows the debug overlay and removes only its observers', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(find.byIcon(Icons.developer_mode), findsOneWidget);

      await tapAndSettle(tester, 'Succeed');
      await tester.tap(find.byIcon(Icons.developer_mode));
      await tester.pump();
      expect(find.text('JIntent DevTools'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      // The metrics observer registered outside the page keeps working.
      JObserver.notifyIntentDispatched(_StubIntent());
      expect(outcomeCounts()['intent.dispatched'], 2);
    });
  });
}

class _StubIntent extends JIntent<ObservabilityState> {
  @override
  Future<void> onInvoke() async {}
}
