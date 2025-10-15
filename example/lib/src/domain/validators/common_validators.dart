import 'package:jintent/jintent.dart';

/// Common reusable validators for various data types.
///
/// These validators demonstrate best practices for creating
/// composable, reusable validation logic.
class CommonValidators {
  // String Validators

  /// Validates that a string is not empty.
  static UseCaseInputValidator<String> notEmpty(String fieldName) {
    return (input) {
      if (input.isEmpty) {
        return Left(Exception('$fieldName cannot be empty'));
      }
      return Right(input);
    };
  }

  /// Validates that a string has a minimum length.
  static UseCaseInputValidator<String> minLength(int min, String fieldName) {
    return (input) {
      if (input.length < min) {
        return Left(
          Exception('$fieldName must be at least $min characters'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that a string has a maximum length.
  static UseCaseInputValidator<String> maxLength(int max, String fieldName) {
    return (input) {
      if (input.length > max) {
        return Left(
          Exception('$fieldName must be at most $max characters'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that a string matches a specific pattern.
  static UseCaseInputValidator<String> matchesPattern(
    RegExp pattern,
    String fieldName,
    String errorMessage,
  ) {
    return (input) {
      if (!pattern.hasMatch(input)) {
        return Left(Exception(errorMessage));
      }
      return Right(input);
    };
  }

  // Numeric Validators

  /// Validates that a number is within a range.
  static UseCaseInputValidator<int> inRange(
    int min,
    int max,
    String fieldName,
  ) {
    return (input) {
      if (input < min || input > max) {
        return Left(
          Exception('$fieldName must be between $min and $max'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that a number is positive.
  static UseCaseInputValidator<int> positive(String fieldName) {
    return (input) {
      if (input <= 0) {
        return Left(Exception('$fieldName must be positive'));
      }
      return Right(input);
    };
  }

  /// Validates that a number is non-negative.
  static UseCaseInputValidator<int> nonNegative(String fieldName) {
    return (input) {
      if (input < 0) {
        return Left(Exception('$fieldName must be non-negative'));
      }
      return Right(input);
    };
  }

  /// Validates that a double is within a range.
  static UseCaseInputValidator<double> doubleInRange(
    double min,
    double max,
    String fieldName,
  ) {
    return (input) {
      if (input < min || input > max) {
        return Left(
          Exception('$fieldName must be between $min and $max'),
        );
      }
      return Right(input);
    };
  }

  // Collection Validators

  /// Validates that a list is not empty.
  static UseCaseInputValidator<List<T>> listNotEmpty<T>(String fieldName) {
    return (input) {
      if (input.isEmpty) {
        return Left(Exception('$fieldName cannot be empty'));
      }
      return Right(input);
    };
  }

  /// Validates that a list has a minimum size.
  static UseCaseInputValidator<List<T>> listMinSize<T>(
    int minSize,
    String fieldName,
  ) {
    return (input) {
      if (input.length < minSize) {
        return Left(
          Exception('$fieldName must contain at least $minSize items'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that a list has a maximum size.
  static UseCaseInputValidator<List<T>> listMaxSize<T>(
    int maxSize,
    String fieldName,
  ) {
    return (input) {
      if (input.length > maxSize) {
        return Left(
          Exception('$fieldName must contain at most $maxSize items'),
        );
      }
      return Right(input);
    };
  }
}
