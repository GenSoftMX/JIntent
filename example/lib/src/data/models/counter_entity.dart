/// Domain entity representing counter state
class CounterEntity {
  final int value;
  final DateTime lastUpdated;

  CounterEntity({
    required this.value,
    required this.lastUpdated,
  });

  @override
  String toString() =>
      'CounterEntity(value: $value, lastUpdated: $lastUpdated)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterEntity &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => value.hashCode ^ lastUpdated.hashCode;
}
