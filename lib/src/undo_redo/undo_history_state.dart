import 'package:jintent/jintent.dart';

/// Immutable metadata for a controller's history, separate from domain state.
class JUndoHistoryState extends JState {
  const JUndoHistoryState({
    this.enabled = false,
    this.undoCount = 0,
    this.redoCount = 0,
  });

  final bool enabled;
  final int undoCount;
  final int redoCount;

  bool get canUndo => enabled && undoCount > 0;
  bool get canRedo => enabled && redoCount > 0;

  @override
  JUndoHistoryState copyWith({bool? enabled, int? undoCount, int? redoCount}) =>
      JUndoHistoryState(
        enabled: enabled ?? this.enabled,
        undoCount: undoCount ?? this.undoCount,
        redoCount: redoCount ?? this.redoCount,
      );

  @override
  List<Object?> get props => [enabled, undoCount, redoCount];
}
