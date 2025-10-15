import 'package:counter/src/domain/validators/counter_validators.dart';
import 'package:jintent/jintent.dart';

/// Demonstrates fail-fast validation chains in a practical example.
///
/// This use case increments a counter value, but first validates:
/// 1. The current value is within valid range (-10 to 10)
/// 2. Incrementing won't exceed the maximum value
///
/// If either validation fails, the increment operation is not performed
/// and an error is returned immediately (fail-fast behavior).
///
/// Example usage:
/// ```dart
/// final useCase = ValidatedIncrementUseCase();
///
/// // Success case
/// final result1 = useCase.call(5); // Returns Right(6)
///
/// // Failure case - at maximum
/// final result2 = useCase.call(10); // Returns Left(Exception('Cannot increment...'))
///
/// // Failure case - out of range
/// final result3 = useCase.call(15); // Returns Left(Exception('Value must be between...'))
/// ```
class ValidatedIncrementUseCase extends JSyncUseCase<int, int> {
  static const int minValue = -10;
  static const int maxValue = 10;

  ValidatedIncrementUseCase() {
    // Add validators in order - they execute sequentially
    // and stop at the first failure (fail-fast)

    // First, check if value is within valid range
    addValidator(CounterValidators.withinRange(minValue, maxValue));

    // Then, check if we can increment without exceeding max
    addValidator(CounterValidators.canIncrement(maxValue));
  }

  @override
  Either<Exception, int> run(int currentValue) {
    // If we reach here, all validators passed
    // Perform the increment operation
    return Right(currentValue + 1);
  }
}
