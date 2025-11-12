import 'package:jintent/jintent.dart';

/// Use case that increments the counter value by 1.
///
/// This demonstrates input validation with a stateful validator
/// that enforces business rules based on usage patterns.
///
/// Validation:
/// - On every second call, validates that input is not at maximum (10)
///
/// Business Logic:
/// - Increments the value by 1
/// - Ensures result doesn't exceed maximum value of 10
class IncrementUseCase extends JSyncUseCase<int, int> {
  int intents = 0;

  IncrementUseCase() {
    // Validator that demonstrates conditional validation based on state
    // This is a more advanced pattern showing validators can maintain state
    addValidator((input) {
      intents++;

      // Every second call, enforce stricter validation
      if (intents % 2 == 0) {
        if (input == 10) {
          return Left(
            Exception(
              'Value cannot be greater than 10 from: use case validator',
            ),
          );
        }
      }

      return Right(input);
    });
  }

  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue + 1;

    // Business logic validation - ensures result is within bounds
    if (newValue > 10) {
      return Left(Exception('Value cannot be greater than 10'));
    }
    return Right(newValue);
  }
}
