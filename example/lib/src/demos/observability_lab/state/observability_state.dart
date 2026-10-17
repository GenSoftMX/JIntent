import 'package:jintent/jintent.dart';

class ObservabilityState extends JState {
  const ObservabilityState({this.completedRuns = 0, this.lastCorrelationId});

  final int completedRuns;

  /// The correlation id the last successful intent saw while running.
  final String? lastCorrelationId;

  @override
  ObservabilityState copyWith({
    int? completedRuns,
    String? lastCorrelationId,
  }) => ObservabilityState(
    completedRuns: completedRuns ?? this.completedRuns,
    lastCorrelationId: lastCorrelationId ?? this.lastCorrelationId,
  );

  @override
  List<Object?> get props => [completedRuns, lastCorrelationId];
}
