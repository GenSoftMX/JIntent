import 'package:jintent/jintent.dart';
import 'undoable_command.dart';
import 'undo_redo_mixin.dart';

/// Manages a stack of undoable commands.
///
/// This is a more flexible alternative to [UndoRedoMixin] for cases
/// where you need custom undo/redo logic per command.
class CommandHistory<T extends JState> {
  final List<UndoableCommand<T>> _undoStack = [];
  final List<UndoableCommand<T>> _redoStack = [];
  final int maxSize;

  CommandHistory({this.maxSize = 50}) {
    if (maxSize <= 0) {
      throw ArgumentError.value(maxSize, 'maxSize', 'Must be positive');
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoStackSize => _undoStack.length;
  int get redoStackSize => _redoStack.length;

  /// Executes a command and adds it to history only if its state changes.
  /// A throwing command leaves both stacks untouched. Commands must return new
  /// immutable states; external side effects cannot be rolled back here.
  T execute(T currentState, UndoableCommand<T> command) {
    final next = command.execute(currentState);
    if (next == currentState) return next;
    _undoStack.add(command);

    if (_undoStack.length > maxSize) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();

    return next;
  }

  /// Undoes the last command.
  T? undo(T currentState) {
    if (!canUndo) return null;

    final command = _undoStack.last;
    final previous = command.undo(currentState);
    _undoStack.removeLast();
    _redoStack.add(command);
    return previous;
  }

  /// Redoes the last undone command.
  T? redo(T currentState) {
    if (!canRedo) return null;

    final command = _redoStack.last;
    final next = command.redo(currentState);
    _redoStack.removeLast();
    _undoStack.add(command);
    return next;
  }

  /// Clears all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
