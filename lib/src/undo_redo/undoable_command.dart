import 'package:jintent/jintent.dart';

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
/// final newState = commandHistory.execute(state, command);
/// update((_) => newState);
/// ```
abstract class UndoableCommand<T extends JState> {
  /// Executes the command and returns the new state.
  T execute(T state);

  /// Undoes the command and returns the previous state.
  T undo(T state);

  /// Optional: Redo the command (by default, calls execute again).
  T redo(T state) => execute(state);
}
