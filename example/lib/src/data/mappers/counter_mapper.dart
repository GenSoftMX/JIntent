import 'package:jintent/jintent.dart';
import '../models/counter_dto.dart';
import '../models/counter_entity.dart';

/// Bidirectional mapper for Counter DTO ↔ Entity
/// 
/// Demonstrates:
/// - Bidirectional transformation using IBiMapper
/// - Date parsing and formatting
/// - Validation during mapping
/// - ArgumentError handling
class CounterBiMapper implements IBiMapper<CounterEntity, CounterDto> {
  @override
  CounterDto to(CounterEntity entity) {
    return CounterDto(
      value: entity.value,
      lastUpdated: entity.lastUpdated.toIso8601String(),
    );
  }

  @override
  CounterEntity from(CounterDto dto) {
    // Validate DTO before transformation
    if (dto.value < -10 || dto.value > 10) {
      throw ArgumentError(
        'Counter value out of bounds: ${dto.value}. '
        'Expected value between -10 and 10.',
      );
    }

    // Parse date with fallback to current time
    DateTime lastUpdated;
    try {
      lastUpdated = dto.lastUpdated != null
          ? DateTime.parse(dto.lastUpdated!)
          : DateTime.now();
    } on FormatException {
      throw ArgumentError(
        'Invalid date format: ${dto.lastUpdated}. '
        'Expected ISO 8601 format.',
      );
    }

    return CounterEntity(
      value: dto.value,
      lastUpdated: lastUpdated,
    );
  }
}

/// One-way mapper from DTO to Entity using JMapper
/// 
/// Demonstrates:
/// - JMapper for one-way transformation
/// - Safe transformation with validation
/// - Error handling in map() method
class CounterMapper extends JMapper<CounterDto, CounterEntity> {
  @override
  CounterEntity map(CounterDto dto) {
    // Validate value range
    if (dto.value < -10 || dto.value > 10) {
      throw ArgumentError(
        'Counter value ${dto.value} is out of valid range [-10, 10]',
      );
    }

    // Parse date with fallback
    DateTime lastUpdated;
    if (dto.lastUpdated != null) {
      try {
        lastUpdated = DateTime.parse(dto.lastUpdated!);
      } on FormatException {
        throw ArgumentError('Invalid date format: ${dto.lastUpdated}');
      }
    } else {
      lastUpdated = DateTime.now();
    }

    return CounterEntity(
      value: dto.value,
      lastUpdated: lastUpdated,
    );
  }
}
