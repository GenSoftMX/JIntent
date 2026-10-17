import 'dart:async';

import 'package:counter/src/demos/observability_lab/observers/lab_log_observer.dart';
import 'package:counter/src/demos/observability_lab/models/lab_outcome.dart';
import 'package:counter/src/demos/observability_lab/controller/observability_controller.dart';
import 'package:counter/src/demos/observability_lab/state/observability_state.dart';
import 'package:counter/src/demos/observability_lab/observers/outcome_counts.dart';
import 'package:flutter/material.dart';
import 'package:jintent/devtools.dart';
import 'package:jintent/widgets.dart';

class ObservabilityLabPage extends StatefulWidget {
  const ObservabilityLabPage({super.key});

  @override
  State<ObservabilityLabPage> createState() => _ObservabilityLabPageState();
}

class _ObservabilityLabPageState extends State<ObservabilityLabPage> {
  final _controller = ObservabilityController();
  late final LabLogObserver _log;
  late final void Function() _removeLog;

  @override
  void initState() {
    super.initState();
    // Metrics first, so counters are updated before the log refreshes the UI.
    JMetrics.attachToObserver();
    _log = LabLogObserver(
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    _removeLog = JObserver.addObserver(_log);
  }

  /// Metrics are global: they also count the other demos. Clearing starts the
  /// comparison from zero.
  void _clear() {
    JMetrics.clear();
    setState(_log.lines.clear);
  }

  void _run(Future<void> operation) {
    unawaited(operation.catchError((_) {}));
  }

  @override
  void dispose() {
    _removeLog();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = outcomeCounts();
    return JDevToolsOverlay(
      enabled: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Observability Lab')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Every button runs an intent through a droppable dispatcher. '
              'Several observers watch it at once: JMetrics, the log below '
              'and the debug overlay (bottom-right button).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run(_controller.run(LabOutcome.succeed)),
                  child: const Text('Succeed'),
                ),
                FilledButton(
                  onPressed: () => _run(_controller.run(LabOutcome.fail)),
                  child: const Text('Fail'),
                ),
                FilledButton(
                  onPressed: () => _run(_controller.run(LabOutcome.cancel)),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => _run(_controller.runTwiceToDrop()),
                  child: const Text('Drop one'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Metrics (JMetrics, app-wide since launch)',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  key: const Key('clear-metrics'),
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            for (final entry in counts.entries)
              Text('${entry.key}: ${entry.value}', key: Key(entry.key)),
            const SizedBox(height: 16),
            JControllerBuilder<ObservabilityState>(
              controller: _controller,
              builder:
                  (context, state) => Text(
                    'Completed runs: ${state.completedRuns}\n'
                    'Last correlation id: ${state.lastCorrelationId ?? '-'}',
                    key: const Key('obs-state'),
                  ),
            ),
            const SizedBox(height: 16),
            Text('Event log (observer)', style: theme.textTheme.titleSmall),
            if (_log.lines.isEmpty) const Text('Nothing recorded yet'),
            for (final line in _log.lines) Text(line.text),
          ],
        ),
      ),
    );
  }
}
