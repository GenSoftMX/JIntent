import 'package:counter/src/demos/undo_notes/intents/add_note_intent.dart';
import 'package:counter/src/demos/undo_notes/state/notes_state.dart';
import 'package:counter/src/demos/undo_notes/intents/remove_last_note_intent.dart';
import 'package:jintent/undo_redo.dart';
import 'package:jintent/jintent.dart';

/// Undo and redo come from [UndoRedoMixin]: only changes made
/// with `updateWithUndo` (here through [UndoableIntent]) are recorded.
class NotesController extends JController<NotesState>
    with UndoRedoMixin<NotesState> {
  NotesController() : super(NotesState());

  Future<void> add(String note) => intent(AddNoteIntent(note));

  Future<void> removeLast() => intent(RemoveLastNoteIntent());

  @override
  void onInit() => enableUndoRedo(maxHistorySize: 20);
}
