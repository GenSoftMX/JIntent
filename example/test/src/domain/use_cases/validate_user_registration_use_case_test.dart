import 'package:counter/src/domain/use_cases/validate_user_registration_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidateUserRegistrationUseCase', () {
    late ValidateUserRegistrationUseCase useCase;

    setUp(() {
      useCase = ValidateUserRegistrationUseCase();
    });

    UserRegistrationInput validInput() => const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 18,
        );

    group('successful registration', () {
      test('accepts valid input', () async {
        final input = validInput();
        final result = await useCase.call(input);

        expect(result.isRight, true);
        expect(result.right?.email, input.email);
        expect(result.right?.username, input.username);
      });

      test('accepts input with older age', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 65,
        );
        final result = await useCase.call(input);

        expect(result.isRight, true);
      });

      test('accepts username with underscores', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'john_doe_123',
          age: 25,
        );
        final result = await useCase.call(input);

        expect(result.isRight, true);
      });
    });

    group('email validation failures', () {
      test('rejects empty email', () async {
        final input = const UserRegistrationInput(
          email: '',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });

      test('rejects invalid email format', () async {
        final input = const UserRegistrationInput(
          email: 'invalid-email',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Invalid email format'));
      });

      test('rejects email that is too long', () async {
        final longEmail = 'a' * 91 + '@example.com'; // 105 characters
        final input = UserRegistrationInput(
          email: longEmail,
          password: 'SecurePass123',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('too long'));
      });
    });

    group('password validation failures', () {
      test('rejects empty password', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: '',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });

      test('rejects password shorter than 8 characters', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'Pass1',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('at least 8 characters'));
      });

      test('rejects password without uppercase letter', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'password123',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('uppercase letter'));
      });

      test('rejects password without lowercase letter', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'PASSWORD123',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('lowercase letter'));
      });

      test('rejects password without number', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'PasswordSecure',
          username: 'johndoe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('one number'));
      });
    });

    group('username validation failures', () {
      test('rejects empty username', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: '',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });

      test('rejects username shorter than 3 characters', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'ab',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('at least 3 characters'));
      });

      test('rejects username longer than 20 characters', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'a' * 21,
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('at most 20 characters'));
      });

      test('rejects username with special characters', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'john-doe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('letters, numbers, and underscores'),
        );
      });

      test('rejects username with spaces', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'john doe',
          age: 18,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('letters, numbers, and underscores'),
        );
      });
    });

    group('age validation failures', () {
      test('rejects age below 13', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 12,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('at least 13 years old'),
        );
      });

      test('accepts age exactly 13', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 13,
        );
        final result = await useCase.call(input);

        expect(result.isRight, true);
      });

      test('rejects unrealistic age', () async {
        final input = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 150,
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Invalid age'));
      });
    });

    group('fail-fast behavior', () {
      test('stops at first validation error (email)', () async {
        // Multiple validation errors, but should return the first one
        final input = const UserRegistrationInput(
          email: '', // First error
          password: 'pass', // Would also fail
          username: 'a', // Would also fail
          age: 5, // Would also fail
        );
        final result = await useCase.call(input);

        expect(result.isLeft, true);
        // Should fail at email validation, not password or other fields
        expect(result.left.toString(), contains('cannot be empty'));
      });

      test('validates in order: email -> password -> username -> age', () async {
        // Valid email, invalid password
        final input1 = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'pass', // Too short
          username: 'a', // Would fail
          age: 5, // Would fail
        );
        final result1 = await useCase.call(input1);
        expect(result1.isLeft, true);
        expect(result1.left.toString(), contains('at least 8 characters'));

        // Valid email and password, invalid username
        final input2 = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'a', // Too short
          age: 5, // Would fail
        );
        final result2 = await useCase.call(input2);
        expect(result2.isLeft, true);
        expect(result2.left.toString(), contains('at least 3 characters'));

        // Valid email, password, and username, invalid age
        final input3 = const UserRegistrationInput(
          email: 'user@example.com',
          password: 'SecurePass123',
          username: 'johndoe',
          age: 5, // Too young
        );
        final result3 = await useCase.call(input3);
        expect(result3.isLeft, true);
        expect(result3.left.toString(), contains('at least 13 years old'));
      });
    });
  });
}
