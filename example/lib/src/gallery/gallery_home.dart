import 'package:flutter/material.dart';

/// One entry of the gallery: what the demo is called, what it shows and which
/// library features it exercises.
class DemoEntry {
  const DemoEntry({
    required this.title,
    required this.description,
    required this.route,
    required this.features,
  });

  final String title;
  final String description;
  final String route;
  final List<String> features;
}

const galleryDemos = <DemoEntry>[
  DemoEntry(
    title: 'Counter',
    description:
        'The full architecture: use cases, mappers, repositories, Riverpod, '
        'a service locator, effect handlers and error handling.',
    route: '/counter',
    features: [
      'JState',
      'JIntent',
      'JController',
      'Effects',
      'Either',
      'Use cases',
      'Mappers',
      'JNavigator',
      'JThrottler',
    ],
  ),
  DemoEntry(
    title: 'Concurrency Lab',
    description:
        'The same five tasks under every dispatcher, with the timeline the '
        'observer reports.',
    route: '/demos/concurrency',
    features: [
      'Sequential',
      'Default (concurrent)',
      'Droppable',
      'Restartable',
      'Cooperative cancellation',
      'JObserverDelegate',
    ],
  ),
  DemoEntry(
    title: 'Startup & Effects',
    description:
        'Effects emitted before the UI attaches, dialogs with results, '
        'timeouts and unhandled effects.',
    route: '/demos/startup',
    features: [
      'effectBufferSize',
      'JEffectListener',
      'JDialogEffect',
      'Timeouts',
      'Unhandled effects',
      'JValidationUtils',
    ],
  ),
  DemoEntry(
    title: 'Observability Lab',
    description:
        'Metrics, correlation ids, a custom observer and the debug overlay '
        'watching succeeding, failing, cancelled and dropped intents.',
    route: '/demos/observability',
    features: [
      'JMetrics',
      'JObserver',
      'CorrelationContext',
      'JDevToolsOverlay',
      'Several observers',
    ],
  ),
  DemoEntry(
    title: 'Undo Notes',
    description: 'Undo, redo and observable history over a list of notes.',
    route: '/demos/undo',
    features: ['UndoRedoMixin', 'UndoableIntent', 'Observable history'],
  ),
];

/// The gallery's landing page. [onOpen] receives the route of the chosen demo,
/// so the page does not depend on a particular router.
class GalleryHome extends StatelessWidget {
  const GalleryHome({
    super.key,
    required this.onOpen,
    this.demos = galleryDemos,
  });

  final void Function(String route) onOpen;
  final List<DemoEntry> demos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('JIntent gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Each demo is small and focused. Together they exercise the '
            'library: core contracts, effects, concurrency, observability, '
            'testing and undo/redo.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final demo in demos)
            Card(
              child: InkWell(
                key: Key('demo-${demo.route}'),
                onTap: () => onOpen(demo.route),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(demo.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(demo.description),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final feature in demo.features)
                            Chip(
                              label: Text(feature),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
