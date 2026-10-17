import 'package:jintent/jintent.dart';
import 'undo_redo_mixin.dart';

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
