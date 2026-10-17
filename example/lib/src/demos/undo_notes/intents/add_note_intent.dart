import 'package:counter/src/demos/undo_notes/state/notes_state.dart';
import 'package:jintent/undo_redo.dart';

class AddNoteIntent extends UndoableIntent<NotesState> {
  AddNoteIntent(this.note);

  final String note;

  @override
  Future<void> onInvoke() async {
    performUndoableUpdate(
      (state) => state.copyWith(notes: [...state.notes, note]),
    );
  }
}
