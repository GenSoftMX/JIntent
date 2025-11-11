import 'package:jintent/jintent.dart';
import 'package:counter/src/domain/models/counter_config.dart';

/// Use case that validates counter configuration.
///
/// This demonstrates a fail-fast validation chain with multiple validators:
/// 1. Validates step is positive
/// 2. Validates min is less than max
/// 3. Validates initial value is within range
///
/// The chain stops at the FIRST failure, demonstrating fail-fast behavior.
///
/// Examples:
/// - Config(initial: 5, min: 0, max: 10, step: 1) → Success ✓
/// - Config(initial: 5, min: 0, max: 10, step: 0) → Fails at step validation ✗
/// - Config(initial: 5, min: 10, max: 0, step: 1) → Fails at min/max validation ✗
/// - Config(initial: 15, min: 0, max: 10, step: 1) → Fails at range validation ✗
class ValidateCounterConfigUseCase extends JSyncUseCase<CounterConfig, bool> {
  ValidateCounterConfigUseCase() {
    // Validator 1: Check step is positive
    // This is checked first as it's a simple, cheap validation
    addValidator(_validateStepIsPositive);

    // Validator 2: Check min < max
    // Business rule validation
    addValidator(_validateMinLessThanMax);

    // Validator 3: Check initial value is within bounds
    // Cross-field validation
    addValidator(_validateInitialInRange);
  }

  /// Validates that the step value is positive.
  Either<Exception, CounterConfig> _validateStepIsPositive(
    CounterConfig input,
  ) {
    if (input.step <= 0) {
      return Left(Exception('Step must be positive, got: ${input.step}'));
    }
    return Right(input);
  }

  /// Validates that minValue is less than maxValue.
  Either<Exception, CounterConfig> _validateMinLessThanMax(
    CounterConfig input,
  ) {
    if (input.minValue >= input.maxValue) {
      return Left(
        Exception(
          'Min value must be less than max value. Got min: ${input.minValue}, max: ${input.maxValue}',
        ),
      );
    }
    return Right(input);
  }

  /// Validates that initial value is within the min/max range.
  Either<Exception, CounterConfig> _validateInitialInRange(
    CounterConfig input,
  ) {
    if (input.initialValue < input.minValue ||
        input.initialValue > input.maxValue) {
      return Left(
        Exception(
          'Initial value must be between ${input.minValue} and ${input.maxValue}, got: ${input.initialValue}',
        ),
      );
    }
    return Right(input);
  }

  @override
  Either<Exception, bool> run(CounterConfig input) {
    // If we reach here, all validations passed
    return Right(true);
  }
}
