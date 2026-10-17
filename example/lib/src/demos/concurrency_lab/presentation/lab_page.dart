import 'dart:async';

import 'package:counter/src/demos/concurrency_lab/controller/lab_controller.dart';
import 'package:counter/src/demos/concurrency_lab/configuration/lab_scenario.dart';
import 'package:counter/src/demos/concurrency_lab/state/lab_state.dart';
import 'package:counter/src/demos/concurrency_lab/configuration/lab_strategy.dart';
import 'package:counter/src/demos/concurrency_lab/models/timeline_entry.dart';
import 'package:counter/src/demos/concurrency_lab/observers/timeline_recorder.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/widgets.dart';

class ConcurrencyLabPage extends StatefulWidget {
  const ConcurrencyLabPage({super.key});

  @override
  State<ConcurrencyLabPage> createState() => _ConcurrencyLabPageState();
}

class _ConcurrencyLabPageState extends State<ConcurrencyLabPage> {
  LabStrategy _strategy = LabStrategy.sequential;
  late LabController _controller;
  late TimelineRecorder _recorder;
  late void Function() _removeObserver;
  bool _firing = false;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _controller = LabController(_strategy);
    _recorder = TimelineRecorder();
    _removeObserver = JObserver.addObserver(_recorder);
  }

  void _release() {
    _removeObserver();
    _controller.dispose();
  }

  void _select(LabStrategy strategy) {
    if (strategy == _strategy) return;
    setState(() {
      _release();
      _strategy = strategy;
      _firing = false;
      _create();
    });
  }

  Future<void> _fire() async {
    final controller = _controller;
    setState(() => _firing = true);
    for (var id = 1; id <= labTaskCount; id++) {
      if (!mounted || !identical(controller, _controller)) return;
      // Dispatch futures can fail (for example after disposal); the lab only
      // watches outcomes through the observer, so errors end here.
      unawaited(controller.run(id, labTaskDuration(id)).catchError((_) {}));
      await Future<void>.delayed(labTaskSpacing);
    }
    if (mounted && identical(controller, _controller)) {
      setState(() => _firing = false);
    }
  }

  void _reset() {
    setState(() {
      _release();
      _firing = false;
      _create();
    });
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Concurrency Lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Five tasks are fired 80 ms apart. Each takes a little less than '
            'the previous one. Pick a dispatcher and compare what happens.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          // Chips wrap onto several lines, so every label stays readable on a
          // narrow phone (a SegmentedButton would split words).
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final strategy in LabStrategy.values)
                ChoiceChip(
                  label: Text(strategy.label),
                  selected: strategy == _strategy,
                  onSelected: (_) => _select(strategy),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_strategy.description, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _firing ? null : _fire,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Fire 5 tasks'),
              ),
              OutlinedButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Result written to state', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          JControllerBuilder<LabState>(
            controller: _controller,
            builder:
                (context, state) => Text(
                  state.finished.isEmpty
                      ? 'No task has finished yet'
                      : 'Finished order: ${state.finished.join(', ')}',
                  key: const Key('lab-result'),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Timeline reported by the observer',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<List<TimelineEntry>>(
            valueListenable: _recorder.entries,
            builder: (context, entries, _) {
              if (entries.isEmpty) return const Text('Nothing recorded yet');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final entry in entries) _EntryRow(entry)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow(this.entry);

  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color, verb) = switch (entry.kind) {
      TimelineKind.started => (
        Icons.play_circle_outline,
        Colors.blue,
        'started',
      ),
      TimelineKind.finished => (Icons.check_circle, Colors.green, 'finished'),
      TimelineKind.cancelled => (Icons.cancel, Colors.orange, 'cancelled'),
      TimelineKind.dropped => (Icons.block, Colors.grey, 'dropped'),
      TimelineKind.failed => (Icons.error, Colors.red, 'failed'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              '${entry.at.inMilliseconds} ms',
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text('Task ${entry.taskId} $verb'),
        ],
      ),
    );
  }
}
