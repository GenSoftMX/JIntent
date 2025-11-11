import 'package:jintent/jintent.dart';

/// Use case that decrements the counter value by 1.
///
/// This demonstrates validation within the business logic (run method)
/// rather than using input validators.
///
/// Business Logic:
/// - Decrements the value by 1
/// - Ensures result doesn't go below minimum value of -10
///
/// Note: This use case doesn't use input validators, showing that
/// validation can also be done in the run method. However, using
/// input validators is preferred for reusability and fail-fast behavior.
class DecrementUseCase extends JSyncUseCase<int, int> {
  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue - 1;

    // Validation in business logic
    if (newValue < -10) {
      return Left(Exception('Value cannot be less than -10'));
    }
    return Right(newValue);
  }
}
