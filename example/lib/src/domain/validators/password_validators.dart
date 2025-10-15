import 'package:jintent/jintent.dart';

/// Password-specific validators demonstrating security validation patterns.
///
/// These validators enforce common password security requirements.
class PasswordValidators {
  /// Validates that the password meets minimum length requirement.
  static UseCaseInputValidator<String> minLength(int min) {
    return (input) {
      if (input.length < min) {
        return Left(
          Exception('Password must be at least $min characters'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that the password does not exceed maximum length.
  static UseCaseInputValidator<String> maxLength(int max) {
    return (input) {
      if (input.length > max) {
        return Left(
          Exception('Password must be at most $max characters'),
        );
      }
      return Right(input);
    };
  }

  /// Validates that the password contains at least one uppercase letter.
  static UseCaseInputValidator<String> hasUppercase = (input) {
    if (!RegExp(r'[A-Z]').hasMatch(input)) {
      return Left(
        Exception('Password must contain at least one uppercase letter'),
      );
    }
    return Right(input);
  };

  /// Validates that the password contains at least one lowercase letter.
  static UseCaseInputValidator<String> hasLowercase = (input) {
    if (!RegExp(r'[a-z]').hasMatch(input)) {
      return Left(
        Exception('Password must contain at least one lowercase letter'),
      );
    }
    return Right(input);
  };

  /// Validates that the password contains at least one number.
  static UseCaseInputValidator<String> hasNumber = (input) {
    if (!RegExp(r'[0-9]').hasMatch(input)) {
      return Left(
        Exception('Password must contain at least one number'),
      );
    }
    return Right(input);
  };

  /// Validates that the password contains at least one special character.
  static UseCaseInputValidator<String> hasSpecialChar = (input) {
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(input)) {
      return Left(
        Exception('Password must contain at least one special character'),
      );
    }
    return Right(input);
  };

  /// Validates that the password is not empty.
  static UseCaseInputValidator<String> notEmpty = (input) {
    if (input.isEmpty) {
      return Left(Exception('Password cannot be empty'));
    }
    return Right(input);
  };

  /// Validates that the password does not contain spaces.
  static UseCaseInputValidator<String> noSpaces = (input) {
    if (input.contains(' ')) {
      return Left(Exception('Password cannot contain spaces'));
    }
    return Right(input);
  };

  /// Validates that the password is not a common weak password.
  static UseCaseInputValidator<String> notCommon = (input) {
    final commonPasswords = [
      'password',
      '123456',
      '12345678',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
    ];

    if (commonPasswords.contains(input.toLowerCase())) {
      return Left(Exception('Password is too common, please choose a stronger password'));
    }
    return Right(input);
  };

  /// Example of a standard password validation chain.
  ///
  /// This chain enforces:
  /// - Not empty
  /// - Between 8 and 128 characters
  /// - Contains uppercase, lowercase, number, and special character
  /// - No spaces
  /// - Not a common password
  static List<UseCaseInputValidator<String>> get standardChain => [
        notEmpty,
        minLength(8),
        maxLength(128),
        noSpaces,
        hasUppercase,
        hasLowercase,
        hasNumber,
        hasSpecialChar,
        notCommon,
      ];

  /// Example of a basic password validation chain (less strict).
  ///
  /// This chain enforces:
  /// - Not empty
  /// - At least 6 characters
  /// - Contains at least one letter and one number
  static List<UseCaseInputValidator<String>> get basicChain => [
        notEmpty,
        minLength(6),
        maxLength(128),
        (input) {
          if (!RegExp(r'[a-zA-Z]').hasMatch(input)) {
            return Left(Exception('Password must contain at least one letter'));
          }
          return Right(input);
        },
        hasNumber,
      ];
}
