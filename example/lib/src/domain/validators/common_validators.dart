import 'package:jintent/jintent.dart';

/// Common reusable validators for use cases.
///
/// These validators demonstrate various validation patterns:
/// - Range validation
/// - Non-null validation
/// - String format validation
/// - Business rule validation
///
/// Each validator follows the fail-fast pattern: returning Left on failure
/// and Right on success.
class CommonValidators {
  /// Validates that an integer is within a specified range (inclusive).
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.intInRange(input, 0, 100));
  /// ```
  static Either<Exception, int> intInRange(int value, int min, int max) {
    if (value < min || value > max) {
      return Left(
        Exception('Value must be between $min and $max, got: $value'),
      );
    }
    return Right(value);
  }

  /// Validates that a string is not empty or null.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.notEmpty(input.name));
  /// ```
  static Either<Exception, String> notEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Left(Exception('Value cannot be empty'));
    }
    return Right(value);
  }

  /// Validates that a string length is within specified bounds.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.lengthInRange(input.name, 3, 50));
  /// ```
  static Either<Exception, String> lengthInRange(
    String value,
    int min,
    int max,
  ) {
    if (value.length < min || value.length > max) {
      return Left(
        Exception(
          'Length must be between $min and $max characters, got: ${value.length}',
        ),
      );
    }
    return Right(value);
  }

  /// Validates that a list is not empty.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.listNotEmpty(input.items));
  /// ```
  static Either<Exception, List<T>> listNotEmpty<T>(List<T> value) {
    if (value.isEmpty) {
      return Left(Exception('List cannot be empty'));
    }
    return Right(value);
  }

  /// Validates that a value is not null.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.notNull(input.userId));
  /// ```
  static Either<Exception, T> notNull<T>(T? value) {
    if (value == null) {
      return Left(Exception('Value cannot be null'));
    }
    return Right(value);
  }

  /// Validates that a double is positive (> 0).
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.positive(input.amount));
  /// ```
  static Either<Exception, double> positive(double value) {
    if (value <= 0) {
      return Left(Exception('Value must be positive, got: $value'));
    }
    return Right(value);
  }

  /// Validates that an integer is non-negative (>= 0).
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.nonNegative(input.count));
  /// ```
  static Either<Exception, int> nonNegative(int value) {
    if (value < 0) {
      return Left(Exception('Value cannot be negative, got: $value'));
    }
    return Right(value);
  }

  /// Validates email format using a basic regex pattern.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.isEmail(input.email));
  /// ```
  static Either<Exception, String> isEmail(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return Left(Exception('Invalid email format: $value'));
    }
    return Right(value);
  }

  /// Validates that a string contains only alphanumeric characters.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.alphanumeric(input.username));
  /// ```
  static Either<Exception, String> alphanumeric(String value) {
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return Left(
        Exception('Value must contain only letters and numbers: $value'),
      );
    }
    return Right(value);
  }

  /// Validates minimum string length.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.minLength(input.password, 8));
  /// ```
  static Either<Exception, String> minLength(String value, int min) {
    if (value.length < min) {
      return Left(
        Exception('Minimum length is $min characters, got: ${value.length}'),
      );
    }
    return Right(value);
  }

  /// Validates maximum string length.
  ///
  /// Example:
  /// ```dart
  /// addValidator((input) => CommonValidators.maxLength(input.bio, 500));
  /// ```
  static Either<Exception, String> maxLength(String value, int max) {
    if (value.length > max) {
      return Left(
        Exception('Maximum length is $max characters, got: ${value.length}'),
      );
    }
    return Right(value);
  }
}
