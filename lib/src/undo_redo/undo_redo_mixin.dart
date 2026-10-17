import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

import 'undo_history_state.dart';

/// Bounded snapshot history for immutable controller states.
///
/// Only [updateWithUndo] records snapshots. Ordinary updates leave history
/// intact; call [clearHistory] when replacing a document or loading remote data.
/// [undo] and [redo] are synchronous. To order them with asynchronous intents,
/// invoke them inside an intent using a sequential dispatcher.
///
/// Domain state and [history] are separate observables. History notifications
/// follow the state update, including when only metadata changes. Snapshots
/// retain state references: all state values and nested collections must be
/// immutable. History does not reverse network, persistence or other effects.
mixin UndoRedoMixin<T extends JState> on JController<T> {
  final List<T> _undoStack = [];
  final List<T> _redoStack = [];
  final _history = ValueNotifier(const JUndoHistoryState());
  int _maxHistorySize = 50;
  bool _undoRedoEnabled = false;
  bool _isUndoRedoOperation = false;

  /// Read-only history metadata. The controller owns and disposes its notifier.
  ValueListenable<JUndoHistoryState> get history => _history;

  bool get canUndo => _undoRedoEnabled && _undoStack.isNotEmpty;
  bool get canRedo => _undoRedoEnabled && _redoStack.isNotEmpty;
  int get undoStackSize => _undoStack.length;
  int get redoStackSize => _redoStack.length;
  List<T> get undoHistory => List.unmodifiable(_undoStack);
  List<T> get redoHistory => List.unmodifiable(_redoStack);

  bool get _canChangeHistory {
    if (!mounted) return false;
    final current = JIntent.current;
    return current == null ||
        !identical(current.controller, this) ||
        !current.isCancelled;
  }

  void _publishHistory() {
    if (!mounted) return;
    _history.value = JUndoHistoryState(
      enabled: _undoRedoEnabled,
      undoCount: _undoStack.length,
      redoCount: _redoStack.length,
    );
  }

  /// Enables recording. A smaller positive limit trims the oldest snapshots
  /// from both stacks. Invalid limits throw without changing history.
  void enableUndoRedo({int maxHistorySize = 50}) {
    if (!_canChangeHistory) return;
    if (maxHistorySize <= 0) {
      throw ArgumentError.value(
        maxHistorySize,
        'maxHistorySize',
        'Must be positive',
      );
    }
    _maxHistorySize = maxHistorySize;
    _undoRedoEnabled = true;
    for (final stack in [_undoStack, _redoStack]) {
      if (stack.length > _maxHistorySize) {
        stack.removeRange(0, stack.length - _maxHistorySize);
      }
    }
    _publishHistory();
  }

  /// Disables recording, clears both stacks and notifies [history].
  void disableUndoRedo() {
    if (!_canChangeHistory) return;
    _undoRedoEnabled = false;
    clearHistory();
  }

  /// Applies a reducer and records the previous state only for a real change.
  /// Equal states, throwing reducers, cancellation and disposal leave history
  /// untouched. When recording is disabled this behaves like [update].
  void updateWithUndo(T Function(T state) reducer, {JIntent? origin}) {
    if (!_canChangeHistory) return;
    if (!_undoRedoEnabled || _isUndoRedoOperation) {
      update(reducer, origin: origin);
      return;
    }
    try {
      update((previous) {
        final next = reducer(previous);
        if (mounted && previous != next) {
          _undoStack.add(previous);
          if (_undoStack.length > _maxHistorySize) _undoStack.removeAt(0);
          _redoStack.clear();
        }
        return next;
      }, origin: origin);
    } finally {
      _publishHistory();
    }
  }

  /// Restores the previous snapshot. Returns false when unavailable, disposed
  /// or called from a cancelled intent. Real changes notify [JObserver].
  bool undo() => _restore(_undoStack, _redoStack);

  /// Restores the next snapshot under the same contract as [undo].
  bool redo() => _restore(_redoStack, _undoStack);

  bool _restore(List<T> source, List<T> destination) {
    if (!_canChangeHistory ||
        !_undoRedoEnabled ||
        source.isEmpty ||
        _isUndoRedoOperation) {
      return false;
    }
    _isUndoRedoOperation = true;
    try {
      update((previous) {
        final next = source.removeLast();
        destination.add(previous);
        if (destination.length > _maxHistorySize) destination.removeAt(0);
        return next;
      });
      return true;
    } finally {
      _isUndoRedoOperation = false;
      _publishHistory();
    }
  }

  /// Clears snapshots without changing domain state. Notifies [history] when
  /// its metadata changes. Recording stays enabled if it was enabled.
  void clearHistory() {
    if (!_canChangeHistory) return;
    _undoStack.clear();
    _redoStack.clear();
    _publishHistory();
  }

  @override
  void dispose() {
    if (!mounted) return;
    _undoStack.clear();
    _redoStack.clear();
    _history.dispose();
    super.dispose();
  }
}
