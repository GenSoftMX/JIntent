import 'package:jintent/jintent.dart';
import 'package:counter/src/domain/validators/common_validators.dart';

/// Use case that sets the counter to a specific value with validation.
///
/// This demonstrates the fail-fast validation chain pattern:
/// 1. First validates the value is in valid range (-10 to 10)
/// 2. Only proceeds if validation passes
///
/// Example of fail-fast behavior:
/// - Input: -11 → Fails at range validation, returns Left immediately
/// - Input: 5 → Passes validation, sets value, returns Right
class SetCounterValueUseCase extends JSyncUseCase<int, int> {
  SetCounterValueUseCase() {
    // Fail-fast validation chain
    // This validator checks range constraints
    addValidator((input) => CommonValidators.intInRange(input, -10, 10));
  }

  @override
  Either<Exception, int> run(int newValue) {
    // Business logic only executes if validation passes
    // The input is guaranteed to be in the valid range
    return Right(newValue);
  }
}
