/// Data Transfer Object for counter data from storage/API
class CounterDto {
  final int value;
  final String? lastUpdated;

  CounterDto({
    required this.value,
    this.lastUpdated,
  });

  /// Create DTO from JSON
  factory CounterDto.fromJson(Map<String, dynamic> json) {
    return CounterDto(
      value: json['value'] as int,
      lastUpdated: json['lastUpdated'] as String?,
    );
  }

  /// Convert DTO to JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'lastUpdated': lastUpdated,
    };
  }

  @override
  String toString() => 'CounterDto(value: $value, lastUpdated: $lastUpdated)';
}
