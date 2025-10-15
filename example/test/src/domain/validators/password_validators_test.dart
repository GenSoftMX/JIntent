import 'package:counter/src/domain/validators/password_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordValidators', () {
    group('notEmpty', () {
      test('accepts non-empty password', () {
        final result = PasswordValidators.notEmpty('password123');
        expect(result.isRight, true);
      });

      test('rejects empty password', () {
        final result = PasswordValidators.notEmpty('');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });
    });

    group('minLength', () {
      test('accepts password meeting minimum length', () {
        final validator = PasswordValidators.minLength(8);
        final result = validator('password123');
        expect(result.isRight, true);
      });

      test('rejects password below minimum length', () {
        final validator = PasswordValidators.minLength(8);
        final result = validator('pass');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('at least 8 characters'));
      });

      test('accepts password at exact minimum length', () {
        final validator = PasswordValidators.minLength(8);
        final result = validator('12345678');
        expect(result.isRight, true);
      });
    });

    group('maxLength', () {
      test('accepts password below maximum length', () {
        final validator = PasswordValidators.maxLength(20);
        final result = validator('password123');
        expect(result.isRight, true);
      });

      test('rejects password exceeding maximum length', () {
        final validator = PasswordValidators.maxLength(20);
        final result = validator('a' * 21);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('at most 20 characters'));
      });
    });

    group('hasUppercase', () {
      test('accepts password with uppercase letter', () {
        final result = PasswordValidators.hasUppercase('Password123');
        expect(result.isRight, true);
      });

      test('rejects password without uppercase letter', () {
        final result = PasswordValidators.hasUppercase('password123');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('uppercase letter'));
      });
    });

    group('hasLowercase', () {
      test('accepts password with lowercase letter', () {
        final result = PasswordValidators.hasLowercase('Password123');
        expect(result.isRight, true);
      });

      test('rejects password without lowercase letter', () {
        final result = PasswordValidators.hasLowercase('PASSWORD123');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('lowercase letter'));
      });
    });

    group('hasNumber', () {
      test('accepts password with number', () {
        final result = PasswordValidators.hasNumber('Password123');
        expect(result.isRight, true);
      });

      test('rejects password without number', () {
        final result = PasswordValidators.hasNumber('Password');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('one number'));
      });
    });

    group('hasSpecialChar', () {
      test('accepts password with special character', () {
        final specialChars = ['!', '@', '#', '\$', '%', '^', '&', '*'];
        for (final char in specialChars) {
          final result = PasswordValidators.hasSpecialChar('Password1$char');
          expect(
            result.isRight,
            true,
            reason: 'Should accept password with $char',
          );
        }
      });

      test('rejects password without special character', () {
        final result = PasswordValidators.hasSpecialChar('Password123');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('special character'));
      });
    });

    group('noSpaces', () {
      test('accepts password without spaces', () {
        final result = PasswordValidators.noSpaces('Password123!');
        expect(result.isRight, true);
      });

      test('rejects password with spaces', () {
        final result = PasswordValidators.noSpaces('Pass word 123');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot contain spaces'));
      });
    });

    group('notCommon', () {
      test('accepts strong password', () {
        final result = PasswordValidators.notCommon('MyStr0ng!Pass');
        expect(result.isRight, true);
      });

      test('rejects common passwords', () {
        final commonPasswords = [
          'password',
          'Password',
          'PASSWORD',
          '123456',
          'qwerty',
          'admin',
        ];

        for (final password in commonPasswords) {
          final result = PasswordValidators.notCommon(password);
          expect(
            result.isLeft,
            true,
            reason: '$password should be rejected as common',
          );
          expect(result.left.toString(), contains('too common'));
        }
      });
    });

    group('standardChain', () {
      test('accepts password meeting all standard requirements', () {
        final password = 'MyP@ssw0rd123';
        final chain = PasswordValidators.standardChain;

        for (final validator in chain) {
          final result = validator(password);
          if (result.isLeft) {
            fail('Strong password should pass all validators: ${result.left}');
          }
        }
      });

      test('rejects weak passwords at appropriate validator', () {
        final testCases = [
          ('', 'notEmpty'),
          ('Pass1!', 'minLength'),
          ('password123!', 'hasUppercase'),
          ('PASSWORD123!', 'hasLowercase'),
          ('Password!', 'hasNumber'),
          ('Password123', 'hasSpecialChar'),
          ('password', 'notCommon'),
        ];

        for (final testCase in testCases) {
          final password = testCase.$1;
          final expectedFailure = testCase.$2;

          final chain = PasswordValidators.standardChain;
          var failed = false;

          for (final validator in chain) {
            final result = validator(password);
            if (result.isLeft) {
              failed = true;
              break;
            }
          }

          expect(
            failed,
            true,
            reason: 'Password "$password" should fail $expectedFailure check',
          );
        }
      });
    });

    group('basicChain', () {
      test('accepts password meeting basic requirements', () {
        final password = 'Pass123';
        final chain = PasswordValidators.basicChain;

        for (final validator in chain) {
          final result = validator(password);
          if (result.isLeft) {
            fail('Basic password should pass all validators: ${result.left}');
          }
        }
      });

      test('rejects password without number', () {
        final password = 'Password';
        final chain = PasswordValidators.basicChain;
        var failed = false;

        for (final validator in chain) {
          final result = validator(password);
          if (result.isLeft) {
            failed = true;
            expect(result.left.toString(), contains('number'));
            break;
          }
        }

        expect(failed, true);
      });
    });
  });
}
