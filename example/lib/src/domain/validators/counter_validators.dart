import 'package:jintent/jintent.dart';

/// Counter-specific validators for the example app.
///
/// These validators demonstrate fail-fast validation chains
/// in a simple, practical context.
class CounterValidators {
  /// Validates that the counter value is within the allowed range.
  static UseCaseInputValidator<int> withinRange(int min, int max) {
    return (input) {
      if (input < min || input > max) {
        return Left(
          Exception('Value must be between $min and $max'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that the counter is not at the maximum value.
  static UseCaseInputValidator<int> notAtMax(int max) {
    return (input) {
      if (input >= max) {
        return Left(
          Exception('Cannot increment: value is already at maximum ($max)'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that the counter is not at the minimum value.
  static UseCaseInputValidator<int> notAtMin(int min) {
    return (input) {
      if (input <= min) {
        return Left(
          Exception('Cannot decrement: value is already at minimum ($min)'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that the increment will not exceed the maximum.
  static UseCaseInputValidator<int> canIncrement(int max) {
    return (input) {
      if (input + 1 > max) {
        return Left(
          Exception('Cannot increment: would exceed maximum value of $max'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that the decrement will not go below the minimum.
  static UseCaseInputValidator<int> canDecrement(int min) {
    return (input) {
      if (input - 1 < min) {
        return Left(
          Exception('Cannot decrement: would go below minimum value of $min'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that the value is even.
  static UseCaseInputValidator<int> isEven = (input) {
    if (input % 2 != 0) {
      return Left(Exception('Value must be even'));
    }
    return Right(input);
  };

  /// Validates that the value is odd.
  static UseCaseInputValidator<int> isOdd = (input) {
    if (input % 2 == 0) {
      return Left(Exception('Value must be odd'));
    }
    return Right(input);
  };

  /// Validates that the value is divisible by a specific number.
  static UseCaseInputValidator<int> divisibleBy(int divisor) {
    return (input) {
      if (input % divisor != 0) {
        return Left(Exception('Value must be divisible by $divisor'));
      }
      return Right(input);
    };
  }

  /// Example validation chain for increment operations.
  ///
  /// This demonstrates fail-fast behavior:
  /// 1. First check if value is within valid range
  /// 2. Then check if increment is possible
  /// 3. Only if both pass, the use case logic executes
  static List<UseCaseInputValidator<int>> incrementChain({
    required int min,
    required int max,
  }) {
    return [
      withinRange(min, max),
      canIncrement(max),
    ];
  }

  /// Example validation chain for decrement operations.
  static List<UseCaseInputValidator<int>> decrementChain({
    required int min,
    required int max,
  }) {
    return [
      withinRange(min, max),
      canDecrement(min),
    ];
  }
}
