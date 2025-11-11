/// Configuration input for counter operations.
///
/// This model demonstrates validation of complex inputs with multiple fields.
class CounterConfig {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final int step;

  const CounterConfig({
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.step,
  });

  @override
  String toString() {
    return 'CounterConfig(initial: $initialValue, min: $minValue, max: $maxValue, step: $step)';
  }
}
