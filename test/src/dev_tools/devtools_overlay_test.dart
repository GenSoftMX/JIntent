import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/devtools.dart';

import '../core/core_test_support.dart';

class _MetaIntent extends JIntent<CounterState> with JMetaData<CounterState> {
  @override
  String get type => 'counter';

  @override
  Map<String, dynamic> get metadata => {'source': 'test'};

  @override
  Future<void> onInvoke() async {}
}

class _PlainEffect extends JFireAndForgetEffect {}

void main() {
  late void Function(JIntent)? previousIntent;
  late void Function(JState, JState, JIntent?)? previousState;
  late void Function(JEffect)? previousEffect;

  setUp(() {
    previousIntent = JObserver.onIntentDispatched;
    previousState = JObserver.onStateChanged;
    previousEffect = JObserver.onEffectEmitted;
  });

  tearDown(() {
    JObserver.onIntentDispatched = previousIntent;
    JObserver.onStateChanged = previousState;
    JObserver.onEffectEmitted = previousEffect;
  });

  Future<void> pumpOverlay(
    WidgetTester tester, {
    bool enabled = true,
    Duration maxEventAge = const Duration(seconds: 30),
    int maxEvents = 50,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: JDevToolsOverlay(
          enabled: enabled,
          maxEventAge: maxEventAge,
          maxEvents: maxEvents,
          child: const Scaffold(body: Text('app')),
        ),
      ),
    );
  }

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.developer_mode));
    await tester.pump();
  }

  String? chipCount(WidgetTester tester, String label) {
    final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
    final texts = tester.widgetList<Text>(
      find.descendant(of: row.first, matching: find.byType(Text)),
    );
    return texts.last.data;
  }

  testWidgets('disabled overlay renders only the child and no observers', (
    tester,
  ) async {
    JObserver.onIntentDispatched = null;
    await pumpOverlay(tester, enabled: false);
    expect(find.text('app'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(JObserver.onIntentDispatched, isNull);
  });

  testWidgets('toggle button opens and closes the panel', (tester) async {
    await pumpOverlay(tester);
    expect(find.text('JIntent DevTools'), findsNothing);

    await openPanel(tester);
    expect(find.text('JIntent DevTools'), findsOneWidget);
    expect(find.textContaining('No events yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('JIntent DevTools'), findsNothing);
  });

  testWidgets('records intent, state and effect events with counters', (
    tester,
  ) async {
    await pumpOverlay(tester);
    await openPanel(tester);

    JObserver.notifyIntentDispatched(_MetaIntent());
    JObserver.notifyStateChanged(
      const CounterState(),
      const CounterState(1),
      _MetaIntent(),
    );
    JObserver.notifyStateChanged(const CounterState(1), const CounterState(2));
    final effect = _PlainEffect();
    JObserver.notifyEffectEmitted(effect);
    await tester.pump();

    expect(find.text('_MetaIntent'), findsOneWidget);
    expect(find.text('_PlainEffect'), findsOneWidget);
    expect(find.text('CounterState → CounterState'), findsNWidgets(2));
    expect(chipCount(tester, 'Intents'), '1');
    expect(chipCount(tester, 'States'), '2');
    expect(chipCount(tester, 'Effects'), '1');
    expect(find.text('INTENT'), findsOneWidget);
    expect(find.text('STATE'), findsNWidgets(2));
    expect(find.text('EFFECT'), findsOneWidget);
  });

  testWidgets('expanding an event shows its metadata', (tester) async {
    await pumpOverlay(tester);
    await openPanel(tester);

    JObserver.notifyIntentDispatched(_MetaIntent());
    JObserver.notifyStateChanged(const CounterState(), const CounterState(1));
    await tester.pump();

    await tester.tap(find.text('_MetaIntent'));
    await tester.pumpAndSettle();
    expect(find.text('Metadata:'), findsOneWidget);
    expect(find.text('type: counter'), findsOneWidget);
    expect(find.text('metadata: {source: test}'), findsOneWidget);

    await tester.tap(find.text('CounterState → CounterState'));
    await tester.pumpAndSettle();
    expect(find.text('origin: unknown'), findsOneWidget);
  });

  testWidgets('header actions collapse the metrics and clear events', (
    tester,
  ) async {
    await pumpOverlay(tester);
    await openPanel(tester);
    JObserver.notifyEffectEmitted(_PlainEffect());
    await tester.pump();
    expect(find.text('Effects'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pump();
    expect(find.text('Effects'), findsNothing);
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump();
    expect(find.text('Effects'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(find.textContaining('No events yet'), findsOneWidget);
  });

  testWidgets('keeps at most maxEvents, newest first', (tester) async {
    await pumpOverlay(tester, maxEvents: 2);
    await openPanel(tester);

    JObserver.notifyIntentDispatched(_MetaIntent());
    JObserver.notifyEffectEmitted(_PlainEffect());
    JObserver.notifyStateChanged(const CounterState(), const CounterState(1));
    await tester.pump();

    expect(find.text('_MetaIntent'), findsNothing);
    expect(find.text('_PlainEffect'), findsOneWidget);
    expect(find.text('CounterState → CounterState'), findsOneWidget);
  });

  testWidgets('drops events older than maxEventAge', (tester) async {
    // A negative age makes every recorded event already expired.
    await pumpOverlay(tester, maxEventAge: const Duration(microseconds: -1));
    await openPanel(tester);

    JObserver.notifyIntentDispatched(_MetaIntent());
    JObserver.notifyEffectEmitted(_PlainEffect());
    await tester.pump();

    expect(find.text('_MetaIntent'), findsNothing);
    expect(find.text('_PlainEffect'), findsNothing);
    expect(find.textContaining('No events yet'), findsOneWidget);
  });

  testWidgets('records failed, cancelled and dropped intents', (tester) async {
    await pumpOverlay(tester);
    await openPanel(tester);

    JObserver.notifyIntentFailed(_MetaIntent(), 'boom', StackTrace.empty);
    JObserver.notifyIntentCancelled(_MetaIntent());
    JObserver.notifyIntentDropped(_MetaIntent());
    await tester.pump();

    expect(find.text('_MetaIntent (failed)'), findsOneWidget);
    expect(find.text('_MetaIntent (cancelled)'), findsOneWidget);
    expect(find.text('_MetaIntent (dropped)'), findsOneWidget);
    expect(chipCount(tester, 'Intents'), '3');

    await tester.tap(find.text('_MetaIntent (failed)'));
    await tester.pump();
    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.textContaining('failed'), findsWidgets);
  });

  testWidgets('disposing detaches only its own observer', (tester) async {
    final seen = <JIntent>[];
    JObserver.onIntentDispatched = seen.add;
    var delegateCalls = 0;
    final other = _CountingObserver(() => delegateCalls++);
    JObserver.addObserver(other);
    addTearDown(() => JObserver.removeObserver(other));

    await pumpOverlay(tester);
    await openPanel(tester);
    JObserver.notifyIntentDispatched(_MetaIntent());
    await tester.pump();
    expect(find.text('_MetaIntent'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    JObserver.notifyIntentDispatched(_MetaIntent());

    // Other consumers keep receiving notifications after the overlay is gone.
    expect(seen, hasLength(2));
    expect(delegateCalls, 2);
    expect(JObserver.onIntentDispatched, isNotNull);
  });

  testWidgets('does not replace callbacks assigned before it', (tester) async {
    var calls = 0;
    JObserver.onIntentDispatched = (_) => calls++;

    await pumpOverlay(tester);
    JObserver.notifyIntentDispatched(_MetaIntent());
    await tester.pump();

    expect(calls, 1);
  });
}

class _CountingObserver extends JObserverDelegate {
  _CountingObserver(this.onCall);
  final void Function() onCall;

  @override
  void onIntentDispatched(JIntent intent) => onCall();
}
