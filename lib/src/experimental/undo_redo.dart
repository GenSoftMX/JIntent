import 'package:jintent/jintent.dart';

/// Experimental undo/redo support for JIntent.
///
/// **WARNING: This is experimental API and may change in future versions.**
///
/// This provides basic undo/redo functionality by maintaining a history
/// of state changes. Not all state changes are undoable - only those
/// explicitly marked.
///
/// Usage:
/// ```dart
/// class MyController extends JController<MyState>
///     with UndoRedoMixin<MyState> {
///   MyController() : super(MyState.initial());
///
///   @override
///   void onInit() {
///     enableUndoRedo(maxHistorySize: 50);
///   }
/// }
///
/// // In your intent
/// @override
/// Future<void> onInvoke() async {
///   updateWithUndo((state) => state.copyWith(value: newValue));
/// }
///
/// // Undo/redo
/// controller.undo();
/// controller.redo();
/// ```
mixin UndoRedoMixin<T extends JState> on JController<T> {
  final List<T> _undoStack = [];
  final List<T> _redoStack = [];

  int _maxHistorySize = 50;
  bool _undoRedoEnabled = false;
  bool _isUndoRedoOperation = false;

  /// Enables undo/redo functionality with optional history size limit.
  void enableUndoRedo({int maxHistorySize = 50}) {
    _maxHistorySize = maxHistorySize;
    _undoRedoEnabled = true;
  }

  /// Disables undo/redo functionality.
  void disableUndoRedo() {
    _undoRedoEnabled = false;
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Returns true if there are states to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Returns true if there are states to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Returns the number of states in the undo stack.
  int get undoStackSize => _undoStack.length;

  /// Returns the number of states in the redo stack.
  int get redoStackSize => _redoStack.length;

  /// Updates state and adds current state to undo history.
  ///
  /// Use this instead of [update] when you want the change to be undoable.
  void updateWithUndo(T Function(T state) reducer, {JIntent? origin}) {
    if (!_undoRedoEnabled || _isUndoRedoOperation) {
      // If undo/redo is disabled or we're in an undo/redo operation,
      // just do a normal update
      update(reducer, origin: origin);
      return;
    }

    // Save current state to undo stack
    _undoStack.add(currentState);

    // Limit history size
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }

    // Clear redo stack when making a new change
    _redoStack.clear();

    // Apply the update
    update(reducer, origin: origin);
  }

  /// Undoes the last state change.
  ///
  /// Returns true if undo was successful, false if nothing to undo.
  bool undo() {
    if (!canUndo) return false;

    _isUndoRedoOperation = true;

    // Move current state to redo stack
    _redoStack.add(currentState);

    // Restore previous state
    final previousState = _undoStack.removeLast();
    state = previousState;

    _isUndoRedoOperation = false;
    return true;
  }

  /// Redoes the last undone state change.
  ///
  /// Returns true if redo was successful, false if nothing to redo.
  bool redo() {
    if (!canRedo) return false;

    _isUndoRedoOperation = true;

    // Move current state to undo stack
    _undoStack.add(currentState);

    // Restore next state
    final nextState = _redoStack.removeLast();
    state = nextState;

    _isUndoRedoOperation = false;
    return true;
  }

  /// Clears all undo/redo history.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Gets a snapshot of the current undo stack (for debugging).
  List<T> get undoHistory => List.unmodifiable(_undoStack);

  /// Gets a snapshot of the current redo stack (for debugging).
  List<T> get redoHistory => List.unmodifiable(_redoStack);
}

/// Intent that supports undo/redo operations.
///
/// Use this as a base for intents that should be undoable.
///
/// Example:
/// ```dart
/// class IncrementIntent extends UndoableIntent<CounterState> {
///   @override
///   Future<void> onInvoke() async {
///     performUndoableUpdate((state) => state.copyWith(
///       counter: state.counter + 1,
///     ));
///   }
/// }
/// ```
abstract class UndoableIntent<T extends JState> extends JIntent<T>
    with JIntentHelpers<T> {
  /// Performs an undoable state update.
  ///
  /// This will add the current state to the undo history before applying
  /// the update.
  void performUndoableUpdate(T Function(T state) reducer) {
    if (controller is UndoRedoMixin<T>) {
      (controller as UndoRedoMixin<T>).updateWithUndo(reducer, origin: this);
    } else {
      // Fallback to regular update if controller doesn't support undo/redo
      update(reducer);
    }
  }
}

/// Command pattern implementation for undo/redo.
///
/// This is an alternative approach to the mixin-based undo/redo.
/// Use this when you need more control over what gets undone/redone.
///
/// Example:
/// ```dart
/// class IncrementCommand extends UndoableCommand<CounterState> {
///   final int amount;
///
///   IncrementCommand(this.amount);
///
///   @override
///   CounterState execute(CounterState state) {
///     return state.copyWith(counter: state.counter + amount);
///   }
///
///   @override
///   CounterState undo(CounterState state) {
///     return state.copyWith(counter: state.counter - amount);
///   }
/// }
///
/// // Usage in intent
/// final command = IncrementCommand(1);
/// final newState = command.execute(state);
/// update((_) => newState);
/// commandHistory.push(command);
/// ```
abstract class UndoableCommand<T extends JState> {
  /// Executes the command and returns the new state.
  T execute(T state);

  /// Undoes the command and returns the previous state.
  T undo(T state);

  /// Optional: Redo the command (by default, calls execute again).
  T redo(T state) => execute(state);
}

/// Manages a stack of undoable commands.
///
/// This is a more flexible alternative to [UndoRedoMixin] for cases
/// where you need custom undo/redo logic per command.
class CommandHistory<T extends JState> {
  final List<UndoableCommand<T>> _undoStack = [];
  final List<UndoableCommand<T>> _redoStack = [];
  final int maxSize;

  CommandHistory({this.maxSize = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoStackSize => _undoStack.length;
  int get redoStackSize => _redoStack.length;

  /// Executes a command and adds it to history.
  T execute(T currentState, UndoableCommand<T> command) {
    _undoStack.add(command);

    if (_undoStack.length > maxSize) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();

    return command.execute(currentState);
  }

  /// Undoes the last command.
  T? undo(T currentState) {
    if (!canUndo) return null;

    final command = _undoStack.removeLast();
    _redoStack.add(command);

    return command.undo(currentState);
  }

  /// Redoes the last undone command.
  T? redo(T currentState) {
    if (!canRedo) return null;

    final command = _redoStack.removeLast();
    _undoStack.add(command);

    return command.redo(currentState);
  }

  /// Clears all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
