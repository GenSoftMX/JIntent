import 'package:counter/src/demos/startup_effects/effects/confirm_effect.dart';
import 'package:counter/src/demos/startup_effects/effects/show_welcome_effect.dart';
import 'package:counter/src/demos/startup_effects/controller/startup_controller.dart';
import 'package:counter/src/demos/startup_effects/presentation/startup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/testing.dart';

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(resetJIntentGlobals);
  tearDown(resetJIntentGlobals);

  group('StartupController', () {
    test(
      'buffered: the effect emitted in onInit reaches a later listener',
      () async {
        final controller = StartupController(buffered: true);
        addTearDown(controller.dispose);

        // Attached after the controller was created, like a page building later.
        final ui = JEffectRecorder(controller);
        addTearDown(ui.dispose);
        await _flush();

        expect(ui.effectsOfType<ShowWelcomeEffect>(), hasLength(1));
      },
    );

    test('unbuffered: the effect emitted in onInit is lost', () async {
      final controller = StartupController(buffered: false);
      addTearDown(controller.dispose);

      final ui = JEffectRecorder(controller);
      addTearDown(ui.dispose);
      await _flush();

      expect(ui.effects, isEmpty);
    });

    test('saveName validates the length', () async {
      final controller = StartupController(buffered: false);
      addTearDown(controller.dispose);

      await controller.saveName('ab');
      expect(
        controller.currentState.status,
        'The name needs 3 to 12 characters',
      );
      expect(controller.currentState.name, isNull);

      await controller.saveName('  Ada Lovelace ');
      expect(controller.currentState.name, 'Ada Lovelace');
      expect(controller.currentState.status, 'Saved "Ada Lovelace"');

      await controller.saveName('a name that is far too long');
      expect(controller.currentState.name, 'Ada Lovelace');
    });

    for (final answer in [true, false]) {
      test('confirmation answered ${answer ? 'yes' : 'no'}', () async {
        final controller = StartupController(buffered: false);
        addTearDown(controller.dispose);
        await controller.saveName('Ada');
        final ui = JEffectRecorder(controller)
          ..respondTo<ConfirmEffect, bool>((_) => answer);
        addTearDown(ui.dispose);

        await controller.askConfirmation();

        expect(ui.effectsOfType<ConfirmEffect>().single.question, isNotEmpty);
        expect(
          controller.currentState.status,
          answer ? 'Name reset' : 'Kept the saved name',
        );
        expect(controller.currentState.name, answer ? isNull : 'Ada');
      });
    }

    test('an unanswered confirmation times out', () async {
      final controller = StartupController(
        buffered: false,
        confirmTimeout: const Duration(milliseconds: 20),
      );
      addTearDown(controller.dispose);
      final ui = JEffectRecorder(controller);
      addTearDown(ui.dispose);

      await controller.askConfirmation();

      expect(controller.currentState.status, 'No answer in time');
    });

    test('an effect with no handler fails with a StateError', () async {
      final controller = StartupController(buffered: false);
      addTearDown(controller.dispose);
      final ui = JEffectRecorder(controller, failUnhandled: true);
      addTearDown(ui.dispose);

      await controller.triggerUnhandled();

      expect(controller.currentState.status, startsWith('Failed: '));
    });

    test('with no listener at all an awaitable effect also fails', () async {
      final controller = StartupController(buffered: false);
      addTearDown(controller.dispose);

      await controller.triggerUnhandled();

      expect(controller.currentState.status, contains('No listener attached'));
    });
  });

  group('StartupEffectsPage', () {
    const welcome = 'Welcome! This effect was emitted in onInit.';

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: StartupEffectsPage()));
      await tester.pump();
    }

    testWidgets('shows the buffered welcome effect, then loses it unbuffered', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(welcome), findsOneWidget);

      // Let the snackbar finish entering, time out and leave, then recreate
      // the controller unbuffered.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('buffer-switch')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(welcome), findsNothing);

      // Buffering again recovers it.
      await tester.tap(find.byKey(const Key('buffer-switch')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(welcome), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('confirmation dialog completes the awaiting intent', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.text('Ask confirmation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reset the saved name?'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Status: Name reset'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('saving a short name reports the validation message', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.enterText(find.byKey(const Key('name-field')), 'ab');
      await tester.tap(find.text('Save name'));
      await tester.pump(const Duration(milliseconds: 10));

      expect(
        find.text('Status: The name needs 3 to 12 characters'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an unregistered effect surfaces its failure in the status', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.text('Trigger unhandled effect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('No handler registered'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
