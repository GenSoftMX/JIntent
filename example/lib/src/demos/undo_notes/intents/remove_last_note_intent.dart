import 'package:counter/src/demos/undo_notes/state/notes_state.dart';
import 'package:jintent/undo_redo.dart';

class RemoveLastNoteIntent extends UndoableIntent<NotesState> {
  @override
  Future<void> onInvoke() async {
    // There is no note to remove from an empty list.
    if (controller.currentState.notes.isEmpty) return;
    performUndoableUpdate(
      (state) =>
          state.copyWith(notes: state.notes.sublist(0, state.notes.length - 1)),
    );
  }
}
