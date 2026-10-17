import 'package:jintent/devtools.dart';

/// How many times each outcome has been counted by `JMetrics`.
Map<String, int> outcomeCounts() => {
  for (final name in const [
    'intent.dispatched',
    'intent.failed',
    'intent.cancelled',
    'intent.dropped',
  ])
    name: JMetrics.getMetricsByName(name).length,
};
