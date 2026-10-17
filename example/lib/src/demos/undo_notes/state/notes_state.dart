import 'package:jintent/jintent.dart';

class NotesState extends JState {
  NotesState({List<String> notes = const []})
    : notes = List.unmodifiable(notes);

  final List<String> notes;

  @override
  NotesState copyWith({List<String>? notes}) =>
      NotesState(notes: notes ?? this.notes);

  @override
  List<Object?> get props => [notes];
}
