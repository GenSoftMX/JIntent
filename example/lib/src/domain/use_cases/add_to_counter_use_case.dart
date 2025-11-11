import 'package:jintent/jintent.dart';

/// Input for adding a value to the counter.
class AddToCounterInput {
  final int currentValue;
  final int amountToAdd;

  const AddToCounterInput({
    required this.currentValue,
    required this.amountToAdd,
  });

  @override
  String toString() {
    return 'AddToCounterInput(current: $currentValue, toAdd: $amountToAdd)';
  }
}

/// Use case that adds a value to the counter with comprehensive validation.
///
/// This demonstrates multiple validation patterns in a fail-fast chain:
/// 1. Non-negative amount validation
/// 2. Reasonable amount validation (business rule)
/// 3. Result overflow validation (cross-field)
///
/// Fail-fast behavior example:
/// - Input: AddToCounterInput(current: 5, toAdd: -3)
///   → Fails at validator 1 (non-negative check)
///   → Validators 2 and 3 are never executed
///   → Returns: Left(Exception('Amount to add cannot be negative'))
///
/// - Input: AddToCounterInput(current: 5, toAdd: 1000)
///   → Passes validator 1 (is non-negative)
///   → Fails at validator 2 (exceeds reasonable limit)
///   → Validator 3 is never executed
///   → Returns: Left(Exception('Amount to add cannot exceed 100'))
///
/// - Input: AddToCounterInput(current: 9, toAdd: 5)
///   → Passes validator 1 (is non-negative)
///   → Passes validator 2 (within reasonable limit)
///   → Fails at validator 3 (result would exceed limit)
///   → Returns: Left(Exception('Result would exceed maximum value'))
///
/// - Input: AddToCounterInput(current: 5, toAdd: 3)
///   → Passes all validators
///   → Business logic executes
///   → Returns: Right(8)
class AddToCounterUseCase extends JSyncUseCase<AddToCounterInput, int> {
  static const int maxCounterValue = 10;
  static const int maxAddAmount = 100;

  AddToCounterUseCase() {
    // Validator 1: Basic constraint - amount must be non-negative
    // This is the cheapest check, so it goes first
    addValidator(_validateNonNegative);

    // Validator 2: Business rule - amount must be reasonable
    // Prevents abuse and ensures sensible operations
    addValidator(_validateReasonableAmount);

    // Validator 3: Cross-field validation - result must not overflow
    // This check depends on both fields, so it goes last
    addValidator(_validateNoOverflow);
  }

  /// Validates that the amount to add is non-negative.
  Either<Exception, AddToCounterInput> _validateNonNegative(
    AddToCounterInput input,
  ) {
    if (input.amountToAdd < 0) {
      return Left(
        Exception('Amount to add cannot be negative, got: ${input.amountToAdd}'),
      );
    }
    return Right(input);
  }

  /// Validates that the amount is within a reasonable limit.
  Either<Exception, AddToCounterInput> _validateReasonableAmount(
    AddToCounterInput input,
  ) {
    if (input.amountToAdd > maxAddAmount) {
      return Left(
        Exception(
          'Amount to add cannot exceed $maxAddAmount, got: ${input.amountToAdd}',
        ),
      );
    }
    return Right(input);
  }

  /// Validates that the result won't exceed the maximum counter value.
  Either<Exception, AddToCounterInput> _validateNoOverflow(
    AddToCounterInput input,
  ) {
    final result = input.currentValue + input.amountToAdd;
    if (result > maxCounterValue) {
      return Left(
        Exception(
          'Result would exceed maximum value of $maxCounterValue. Current: ${input.currentValue}, Adding: ${input.amountToAdd}, Result: $result',
        ),
      );
    }
    return Right(input);
  }

  @override
  Either<Exception, int> run(AddToCounterInput input) {
    // All validations passed - perform the addition
    final result = input.currentValue + input.amountToAdd;
    return Right(result);
  }
}
