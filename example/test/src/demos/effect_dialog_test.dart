import 'dart:async';

import 'package:counter/src/demos/startup_effects/controller/startup_controller.dart';
import 'package:counter/src/demos/startup_effects/presentation/startup_effect_handler.dart';
import 'package:counter/src/demos/startup_effects/state/startup_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/testing.dart';

void main() {
  setUp(resetJIntentGlobals);
  tearDown(resetJIntentGlobals);

  Future<void> mount(
    WidgetTester tester,
    StartupController controller, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: JEffectListener<StartupState>(
          controller: controller,
          handler: StartupEffectHandler(controller),
          child: const Scaffold(body: Text('Demo')),
        ),
      ),
    );
  }

  testWidgets('timeout dismisses dialog and a fresh confirmation still works', (
    tester,
  ) async {
    final c = StartupController(
      buffered: false,
      confirmTimeout: const Duration(seconds: 2),
    );
    addTearDown(c.dispose);
    await mount(tester, c);
    final first = c.askConfirmation();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await first;
    expect(find.byType(AlertDialog), findsNothing);
    expect(c.currentState.status, 'No answer in time');

    final second = c.askConfirmation();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    await second;
    expect(c.currentState.status, 'Name reset');
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeout removes only its owned route below a newer route', (
    tester,
  ) async {
    final c = StartupController(
      buffered: false,
      confirmTimeout: const Duration(seconds: 2),
    );
    addTearDown(c.dispose);
    final navigatorKey = GlobalKey<NavigatorState>();
    await mount(tester, c, navigatorKey: navigatorKey);
    final operation = c.askConfirmation();
    await tester.pumpAndSettle();
    unawaited(
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await operation;
    expect(find.text('Other route'), findsOneWidget);
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Demo'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'controller disposal closes pending dialog without handler error',
    (tester) async {
      final c = StartupController(buffered: false);
      await mount(tester, c);
      Object? failure;
      final operation = c.askConfirmation().catchError((Object error) {
        failure = error;
      });
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      c.dispose();
      await tester.pumpAndSettle();
      await operation;
      expect(failure, isA<StateError>());
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
