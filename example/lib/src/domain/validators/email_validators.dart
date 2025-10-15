import 'package:jintent/jintent.dart';

/// Email-specific validators demonstrating domain-specific validation logic.
///
/// These validators can be chained together in a use case to create
/// a comprehensive email validation pipeline.
class EmailValidators {
  // Cached regex pattern for performance
  static final _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  /// Validates that the email has a valid format.
  ///
  /// Example valid emails:
  /// - user@example.com
  /// - john.doe@company.co.uk
  /// - test_123@test-domain.com
  static UseCaseInputValidator<String> format = (input) {
    if (!_emailRegex.hasMatch(input)) {
      return Left(Exception('Invalid email format'));
    }
    return Right(input);
  };

  /// Validates that the email is not too long.
  ///
  /// RFC 5321 specifies a maximum of 254 characters for email addresses,
  /// but we use 100 as a practical limit.
  static UseCaseInputValidator<String> length = (input) {
    if (input.length > 100) {
      return Left(Exception('Email is too long (max 100 characters)'));
    }
    return Right(input);
  };

  /// Validates that the email is not empty.
  static UseCaseInputValidator<String> notEmpty = (input) {
    if (input.isEmpty) {
      return Left(Exception('Email cannot be empty'));
    }
    return Right(input);
  };

  /// Validates that the email does not use a disposable domain.
  ///
  /// This is useful for preventing spam or temporary registrations.
  static UseCaseInputValidator<String> notDisposable = (input) {
    final disposableDomains = [
      'tempmail.com',
      'throwaway.email',
      '10minutemail.com',
      'guerrillamail.com',
    ];

    final domain = input.split('@').last.toLowerCase();
    if (disposableDomains.contains(domain)) {
      return Left(Exception('Disposable email addresses are not allowed'));
    }
    return Right(input);
  };

  /// Validates that the email has a valid domain part.
  static UseCaseInputValidator<String> validDomain = (input) {
    final parts = input.split('@');
    if (parts.length != 2) {
      return Left(Exception('Invalid email format'));
    }

    final domain = parts[1];
    if (domain.isEmpty || !domain.contains('.')) {
      return Left(Exception('Invalid email domain'));
    }

    return Right(input);
  };

  /// Example of a complete email validation chain that can be used in a use case.
  static List<UseCaseInputValidator<String>> get completeChain => [
        notEmpty,
        length,
        format,
        validDomain,
        // notDisposable, // Optional - uncomment if needed
      ];
}
