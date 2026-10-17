/// Undo/redo for immutable controller states and synchronous commands.
///
/// See `doc/undo-redo.md` for history observation and lifecycle contracts.
library;

export 'src/undo_redo/undo_history_state.dart';
export 'src/undo_redo/undo_redo_mixin.dart';
export 'src/undo_redo/undoable_intent.dart';
export 'src/undo_redo/undoable_command.dart';
export 'src/undo_redo/command_history.dart';
