import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/undo_redo.dart';

import '../core/core_test_support.dart';

class UndoController extends JController<CounterState>
    with UndoRedoMixin<CounterState> {
  UndoController() : super(const CounterState());

  @override
  void onInit() => enableUndoRedo(maxHistorySize: 3);
}

class PlainController extends JController<CounterState> {
  PlainController() : super(const CounterState());

  @override
  void onInit() {}
}

class AddUndoable extends UndoableIntent<CounterState> {
  final int amount;
  AddUndoable(this.amount);

  @override
  Future<void> onInvoke() async => performUndoableUpdate(
    (state) => state.copyWith(value: state.value + amount),
  );
}

class AddCommand extends UndoableCommand<CounterState> {
  final int amount;
  AddCommand(this.amount);

  @override
  CounterState execute(CounterState state) =>
      state.copyWith(value: state.value + amount);

  @override
  CounterState undo(CounterState state) =>
      state.copyWith(value: state.value - amount);
}

void main() {
  group('UndoRedoMixin', () {
    late UndoController controller;

    setUp(() => controller = UndoController());
    tearDown(() => controller.dispose());

    CounterState add(CounterState s) => s.copyWith(value: s.value + 1);

    test('records history, undoes and redoes changes', () {
      controller.updateWithUndo(add);
      controller.updateWithUndo(add);
      expect(controller.currentState.value, 2);
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);
      expect(controller.undoStackSize, 2);

      expect(controller.undo(), isTrue);
      expect(controller.currentState.value, 1);
      expect(controller.redoStackSize, 1);
      expect(controller.canRedo, isTrue);

      expect(controller.redo(), isTrue);
      expect(controller.currentState.value, 2);
      expect(controller.redoStackSize, 0);
    });

    test('undo and redo report false when there is nothing to do', () {
      expect(controller.undo(), isFalse);
      expect(controller.redo(), isFalse);
      expect(controller.currentState.value, 0);
    });

    test('a new change clears the redo history', () {
      controller.updateWithUndo(add);
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.updateWithUndo(add);
      expect(controller.canRedo, isFalse);
    });

    test('history is capped at maxHistorySize dropping the oldest state', () {
      for (var i = 0; i < 5; i++) {
        controller.updateWithUndo(add);
      }
      expect(controller.undoStackSize, 3);
      expect(controller.undoHistory.map((s) => s.value), [2, 3, 4]);
    });

    test('history snapshots are unmodifiable', () {
      controller.updateWithUndo(add);
      controller.undo();
      expect(
        () => controller.undoHistory.add(const CounterState()),
        throwsUnsupportedError,
      );
      expect(
        () => controller.redoHistory.add(const CounterState()),
        throwsUnsupportedError,
      );
    });

    test('clearHistory empties both stacks', () {
      controller.updateWithUndo(add);
      controller.updateWithUndo(add);
      controller.undo();
      controller.clearHistory();
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });

    test('disableUndoRedo clears history and makes updates plain', () {
      controller.updateWithUndo(add);
      controller.disableUndoRedo();
      expect(controller.canUndo, isFalse);

      controller.updateWithUndo(add);
      expect(controller.currentState.value, 2);
      expect(controller.canUndo, isFalse);
    });

    test('updates are plain until undo/redo is enabled', () {
      final plain = _LateEnabled();
      addTearDown(plain.dispose);
      plain.updateWithUndo(add);
      expect(plain.currentState.value, 1);
      expect(plain.canUndo, isFalse);

      plain.enableUndoRedo();
      plain.updateWithUndo(add);
      expect(plain.undoStackSize, 1);
    });
  });

  group('UndoableIntent', () {
    test('records history when the controller supports undo', () async {
      final controller = UndoController();
      addTearDown(controller.dispose);
      await controller.intent(AddUndoable(5));
      expect(controller.currentState.value, 5);
      expect(controller.undo(), isTrue);
      expect(controller.currentState.value, 0);
    });

    test('falls back to a plain update otherwise', () async {
      final controller = PlainController();
      addTearDown(controller.dispose);
      await controller.intent(AddUndoable(5));
      expect(controller.currentState.value, 5);
    });
  });

  group('CommandHistory', () {
    late CommandHistory<CounterState> history;

    setUp(() => history = CommandHistory<CounterState>(maxSize: 2));

    test('executes, undoes and redoes commands', () {
      var state = history.execute(const CounterState(), AddCommand(2));
      expect(state.value, 2);
      expect(history.canUndo, isTrue);

      state = history.undo(state)!;
      expect(state.value, 0);
      expect(history.canRedo, isTrue);
      expect(history.redoStackSize, 1);

      state = history.redo(state)!;
      expect(state.value, 2);
      expect(history.undoStackSize, 1);
    });

    test('returns null when there is nothing to undo or redo', () {
      expect(history.undo(const CounterState()), isNull);
      expect(history.redo(const CounterState()), isNull);
    });

    test('executing clears redo and respects maxSize', () {
      var state = history.execute(const CounterState(), AddCommand(1));
      state = history.execute(state, AddCommand(1));
      state = history.execute(state, AddCommand(1));
      expect(history.undoStackSize, 2);

      history.undo(state);
      expect(history.canRedo, isTrue);
      history.execute(state, AddCommand(1));
      expect(history.canRedo, isFalse);
    });

    test('clear empties both stacks', () {
      final state = history.execute(const CounterState(), AddCommand(1));
      history.undo(state);
      history.clear();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });
  });
}

class _LateEnabled extends JController<CounterState>
    with UndoRedoMixin<CounterState> {
  _LateEnabled() : super(const CounterState());

  @override
  void onInit() {}
}
