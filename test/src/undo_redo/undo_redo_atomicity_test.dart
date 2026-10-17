import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/undo_redo.dart';
import 'package:jintent/jintent.dart';
import '../core/core_test_support.dart';

class HistoryController extends JController<CounterState>
    with UndoRedoMixin<CounterState> {
  HistoryController() : super(const CounterState());
  @override
  void onInit() => enableUndoRedo();
}

class CancelledUpdate extends UndoableIntent<CounterState> {
  @override
  Future<void> onInvoke() async {
    cancel();
    performUndoableUpdate((s) => s.copyWith(value: 5));
  }
}

class HistoryCommand extends UndoableCommand<CounterState> {
  bool failExecute = false;
  bool failUndo = false;
  bool failRedo = false;
  @override
  CounterState execute(CounterState state) {
    if (failExecute) throw StateError('execute');
    return state.copyWith(value: state.value + 1);
  }

  @override
  CounterState undo(CounterState state) {
    if (failUndo) throw StateError('undo');
    return state.copyWith(value: state.value - 1);
  }

  @override
  CounterState redo(CounterState state) {
    if (failRedo) throw StateError('redo');
    return execute(state);
  }
}

void main() {
  test('equal or throwing reducer preserves redo and history', () {
    final c = HistoryController();
    addTearDown(c.dispose);
    c.updateWithUndo((s) => s.copyWith(value: 1));
    c.undo();
    c.updateWithUndo((s) => s.copyWith(value: s.value));
    expect(c.undoStackSize, 0);
    expect(c.canRedo, isTrue);
    expect(
      () => c.updateWithUndo((s) => throw StateError('reducer')),
      throwsStateError,
    );
    expect(c.undoStackSize, 0);
    expect(c.canRedo, isTrue);
  });

  test('disposed controller never evaluates reducer or records history', () {
    final c = HistoryController();
    c.dispose();
    c.updateWithUndo((s) => throw StateError('must not run'));
    expect(c.undoStackSize, 0);
  });

  test('cancelled intent cannot create a history entry', () async {
    final c = HistoryController();
    addTearDown(c.dispose);
    await c.intent(CancelledUpdate());
    expect(c.currentState.value, 0);
    expect(c.canUndo, isFalse);
  });

  test('failed command preserves an existing redo branch', () {
    final h = CommandHistory<CounterState>();
    final state = h.execute(const CounterState(), HistoryCommand());
    final previous = h.undo(state)!;
    expect(
      () => h.execute(previous, HistoryCommand()..failExecute = true),
      throwsStateError,
    );
    expect(h.undoStackSize, 0);
    expect(h.redoStackSize, 1);
    expect(h.redo(previous)!.value, 1);
  });

  test('failed execute, undo and redo leave command stacks unchanged', () {
    final h = CommandHistory<CounterState>();
    final command = HistoryCommand()..failExecute = true;
    expect(() => h.execute(const CounterState(), command), throwsStateError);
    expect(h.canUndo, isFalse);
    command.failExecute = false;
    var state = h.execute(const CounterState(), command);
    command.failUndo = true;
    expect(() => h.undo(state), throwsStateError);
    expect(h.undoStackSize, 1);
    expect(h.redoStackSize, 0);
    command.failUndo = false;
    state = h.undo(state)!;
    command.failRedo = true;
    expect(() => h.redo(state), throwsStateError);
    expect(h.undoStackSize, 0);
    expect(h.redoStackSize, 1);
    command.failRedo = false;
    expect(h.redo(state)!.value, 1);
  });
}
