import 'package:counter/src/domain/validators/email_validators.dart';
import 'package:counter/src/domain/validators/password_validators.dart';
import 'package:jintent/jintent.dart';

/// Input model for user registration.
class UserRegistrationInput {
  final String email;
  final String password;
  final String username;
  final int age;

  const UserRegistrationInput({
    required this.email,
    required this.password,
    required this.username,
    required this.age,
  });
}

/// Mock user model for demonstration.
class User {
  final String email;
  final String username;

  const User({
    required this.email,
    required this.username,
  });
}

/// Demonstrates fail-fast validation chains with complex input.
///
/// This use case shows how validators can be chained to validate
/// different fields of a complex input object. Each validator
/// focuses on a specific aspect, and validation stops at the
/// first failure (fail-fast behavior).
///
/// Validation order:
/// 1. Email validation (empty, format, length)
/// 2. Password validation (length, complexity)
/// 3. Username validation (length, format)
/// 4. Age validation (minimum age requirement)
///
/// Example usage:
/// ```dart
/// final useCase = ValidateUserRegistrationUseCase();
/// final input = UserRegistrationInput(
///   email: 'user@example.com',
///   password: 'SecurePass123!',
///   username: 'johndoe',
///   age: 18,
/// );
/// final result = await useCase.call(input);
/// ```
class ValidateUserRegistrationUseCase
    extends JUseCase<UserRegistrationInput, User> {
  ValidateUserRegistrationUseCase() {
    // Email validation chain
    addValidator(_validateEmail);

    // Password validation chain
    addValidator(_validatePassword);

    // Username validation chain
    addValidator(_validateUsername);

    // Age validation
    addValidator(_validateAge);
  }

  /// Validates the email field using EmailValidators.
  ///
  /// This demonstrates using pre-built validators for common fields.
  UseCaseInputValidator<UserRegistrationInput> _validateEmail = (input) {
    // Check if empty
    final notEmptyResult = EmailValidators.notEmpty(input.email);
    if (notEmptyResult.isLeft) {
      return Left(notEmptyResult.left!);
    }

    // Check length
    final lengthResult = EmailValidators.length(input.email);
    if (lengthResult.isLeft) {
      return Left(lengthResult.left!);
    }

    // Check format
    final formatResult = EmailValidators.format(input.email);
    if (formatResult.isLeft) {
      return Left(formatResult.left!);
    }

    return Right(input);
  };

  /// Validates the password field using PasswordValidators.
  ///
  /// This demonstrates composing multiple password requirements.
  UseCaseInputValidator<UserRegistrationInput> _validatePassword = (input) {
    // Check if empty
    final notEmptyResult = PasswordValidators.notEmpty(input.password);
    if (notEmptyResult.isLeft) {
      return Left(notEmptyResult.left!);
    }

    // Check minimum length
    final minLengthResult = PasswordValidators.minLength(8)(input.password);
    if (minLengthResult.isLeft) {
      return Left(minLengthResult.left!);
    }

    // Check for uppercase letter
    final uppercaseResult = PasswordValidators.hasUppercase(input.password);
    if (uppercaseResult.isLeft) {
      return Left(uppercaseResult.left!);
    }

    // Check for lowercase letter
    final lowercaseResult = PasswordValidators.hasLowercase(input.password);
    if (lowercaseResult.isLeft) {
      return Left(lowercaseResult.left!);
    }

    // Check for number
    final numberResult = PasswordValidators.hasNumber(input.password);
    if (numberResult.isLeft) {
      return Left(numberResult.left!);
    }

    return Right(input);
  };

  /// Validates the username field.
  ///
  /// This demonstrates custom validation logic specific to this use case.
  UseCaseInputValidator<UserRegistrationInput> _validateUsername = (input) {
    if (input.username.isEmpty) {
      return Left(Exception('Username cannot be empty'));
    }

    if (input.username.length < 3) {
      return Left(Exception('Username must be at least 3 characters'));
    }

    if (input.username.length > 20) {
      return Left(Exception('Username must be at most 20 characters'));
    }

    // Username can only contain letters, numbers, and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(input.username)) {
      return Left(
        Exception(
          'Username can only contain letters, numbers, and underscores',
        ),
      );
    }

    return Right(input);
  };

  /// Validates the age field.
  ///
  /// This demonstrates business rule validation.
  UseCaseInputValidator<UserRegistrationInput> _validateAge = (input) {
    if (input.age < 13) {
      return Left(
        Exception('You must be at least 13 years old to register'),
      );
    }

    if (input.age > 120) {
      return Left(Exception('Invalid age'));
    }

    return Right(input);
  };

  @override
  Future<Either<Exception, User>> run(UserRegistrationInput input) async {
    // All validations passed, create the user
    // In a real app, this would call a repository to save the user
    return Right(
      User(
        email: input.email,
        username: input.username,
      ),
    );
  }
}
