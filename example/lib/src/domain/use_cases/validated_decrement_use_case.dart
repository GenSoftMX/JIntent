import 'package:counter/src/domain/validators/counter_validators.dart';
import 'package:jintent/jintent.dart';

/// Demonstrates fail-fast validation chains for decrement operations.
///
/// This use case decrements a counter value, but first validates:
/// 1. The current value is within valid range (-10 to 10)
/// 2. Decrementing won't go below the minimum value
///
/// If either validation fails, the decrement operation is not performed
/// and an error is returned immediately (fail-fast behavior).
///
/// Example usage:
/// ```dart
/// final useCase = ValidatedDecrementUseCase();
///
/// // Success case
/// final result1 = useCase.call(5); // Returns Right(4)
///
/// // Failure case - at minimum
/// final result2 = useCase.call(-10); // Returns Left(Exception('Cannot decrement...'))
///
/// // Failure case - out of range
/// final result3 = useCase.call(-15); // Returns Left(Exception('Value must be between...'))
/// ```
class ValidatedDecrementUseCase extends JSyncUseCase<int, int> {
  static const int minValue = -10;
  static const int maxValue = 10;

  ValidatedDecrementUseCase() {
    // Add validators in order - they execute sequentially
    // and stop at the first failure (fail-fast)

    // First, check if value is within valid range
    addValidator(CounterValidators.withinRange(minValue, maxValue));

    // Then, check if we can decrement without going below min
    addValidator(CounterValidators.canDecrement(minValue));
  }

  @override
  Either<Exception, int> run(int currentValue) {
    // If we reach here, all validators passed
    // Perform the decrement operation
    return Right(currentValue - 1);
  }
}
