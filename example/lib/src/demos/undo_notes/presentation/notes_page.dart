import 'dart:async';

import 'package:counter/src/demos/undo_notes/controller/notes_controller.dart';
import 'package:counter/src/demos/undo_notes/state/notes_state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/widgets.dart';
import 'package:jintent/undo_redo.dart';

class UndoNotesPage extends StatefulWidget {
  const UndoNotesPage({super.key});

  @override
  State<UndoNotesPage> createState() => _UndoNotesPageState();
}

class _UndoNotesPageState extends State<UndoNotesPage> {
  final _controller = NotesController();
  final _field = TextEditingController();
  final _focus = FocusNode();

  void _add() {
    final text = _field.text.trim();
    if (text.isEmpty) return;
    _field.clear();
    // Submitting with Enter unfocuses a text field; keep typing possible.
    _focus.requestFocus();
    unawaited(_controller.add(text).catchError((_) {}));
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Undo Notes')),
      body: JControllerBuilder<NotesState>(
        controller: _controller,
        builder:
            (context, state) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UndoRedoMixin records local state changes. Each '
                    'add or remove is recorded and can be undone and redone.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('note-field'),
                          controller: _field,
                          focusNode: _focus,
                          decoration: const InputDecoration(labelText: 'Note'),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      IconButton(
                        key: const Key('add-note'),
                        tooltip: 'Add',
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  ValueListenableBuilder<JUndoHistoryState>(
                    valueListenable: _controller.history,
                    builder:
                        (context, history, child) => Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              key: const Key('undo'),
                              tooltip: 'Undo',
                              onPressed:
                                  history.canUndo
                                      ? () => _controller.undo()
                                      : null,
                              icon: const Icon(Icons.undo),
                            ),
                            IconButton(
                              key: const Key('redo'),
                              tooltip: 'Redo',
                              onPressed:
                                  history.canRedo
                                      ? () => _controller.redo()
                                      : null,
                              icon: const Icon(Icons.redo),
                            ),
                            TextButton(
                              onPressed:
                                  () => unawaited(
                                    _controller.removeLast().catchError((_) {}),
                                  ),
                              child: const Text('Remove last'),
                            ),
                            TextButton(
                              key: const Key('clear-history'),
                              onPressed:
                                  history.canUndo || history.canRedo
                                      ? _controller.clearHistory
                                      : null,
                              child: const Text('Clear history'),
                            ),
                          ],
                        ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        if (state.notes.isEmpty) const Text('No notes yet'),
                        for (final note in state.notes)
                          ListTile(title: Text(note)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
