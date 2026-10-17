import 'package:counter/src/demos/undo_notes/state/notes_state.dart';
import 'package:counter/src/demos/undo_notes/controller/notes_controller.dart';
import 'package:counter/src/demos/undo_notes/presentation/notes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/testing.dart';

void main() {
  group('NotesController', () {
    late NotesController controller;

    setUp(() => controller = NotesController());
    tearDown(() => controller.dispose());

    test('snapshots cannot be changed through an input list', () {
      final source = ['original'];
      final state = NotesState(notes: source);
      source.add('external');
      expect(state.notes, ['original']);
      expect(() => state.notes.add('mutation'), throwsUnsupportedError);
    });

    test('starts empty with nothing to undo', () {
      expect(controller.currentState.notes, isEmpty);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });

    test('undo and redo walk through the recorded changes', () async {
      final states = JStateRecorder(controller);
      addTearDown(states.dispose);

      await controller.add('one');
      await controller.add('two');
      expect(controller.currentState.notes, ['one', 'two']);

      expect(controller.undo(), isTrue);
      expect(controller.currentState.notes, ['one']);
      expect(controller.canRedo, isTrue);

      expect(controller.redo(), isTrue);
      expect(controller.currentState.notes, ['one', 'two']);
      expect(states.states, hasLength(4));
    });

    test('a new change clears the redo history', () async {
      await controller.add('one');
      controller.undo();

      await controller.add('other');

      expect(controller.canRedo, isFalse);
      expect(controller.currentState.notes, ['other']);
    });

    test('removing the last note is undoable', () async {
      await controller.add('one');
      await controller.removeLast();
      expect(controller.currentState.notes, isEmpty);

      controller.undo();

      expect(controller.currentState.notes, ['one']);
    });

    test('removing from an empty list records no history', () async {
      await controller.add('one');
      controller.undo();
      expect(controller.currentState.notes, isEmpty);

      await controller.removeLast();

      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue, reason: 'the redo history survives');
    });

    test('undo and redo report false when there is nothing to do', () {
      expect(controller.undo(), isFalse);
      expect(controller.redo(), isFalse);
    });
  });

  group('UndoNotesPage', () {
    testWidgets('clearing history disables buttons without changing notes', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: UndoNotesPage()));
      await tester.enterText(find.byKey(const Key('note-field')), 'Keep me');
      await tester.tap(find.byKey(const Key('add-note')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(find.byKey(const Key('undo'))).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('clear-history')));
      await tester.pump();
      expect(find.text('Keep me'), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byKey(const Key('undo'))).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(find.byKey(const Key('redo'))).onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets('adds a note and undoes and redoes it', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UndoNotesPage()));
      expect(find.text('No notes yet'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('note-field')), 'Buy milk');
      await tester.tap(find.byKey(const Key('add-note')));
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('Buy milk'), findsOneWidget);

      await tester.tap(find.byKey(const Key('undo')));
      await tester.pump();
      expect(find.text('Buy milk'), findsNothing);

      await tester.tap(find.byKey(const Key('redo')));
      await tester.pump();
      expect(find.text('Buy milk'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the note field keeps focus after submitting', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UndoNotesPage()));

      await tester.enterText(find.byKey(const Key('note-field')), 'one');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 10));

      final field = tester.widget<TextField>(
        find.byKey(const Key('note-field')),
      );
      expect(field.focusNode!.hasFocus, isTrue);
      expect(find.text('one'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('undo and redo are disabled until there is history', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: UndoNotesPage()));

      expect(
        tester.widget<IconButton>(find.byKey(const Key('undo'))).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(find.byKey(const Key('redo'))).onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });
}
