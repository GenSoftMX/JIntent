import 'package:counter/src/domain/validators/email_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailValidators', () {
    group('notEmpty', () {
      test('accepts non-empty email', () {
        final result = EmailValidators.notEmpty('test@example.com');
        expect(result.isRight, true);
        expect(result.right, 'test@example.com');
      });

      test('rejects empty email', () {
        final result = EmailValidators.notEmpty('');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });
    });

    group('format', () {
      test('accepts valid email formats', () {
        final validEmails = [
          'user@example.com',
          'john.doe@company.co.uk',
          'test_123@test-domain.com',
          'user+tag@example.com',
          'a@b.co',
        ];

        for (final email in validEmails) {
          final result = EmailValidators.format(email);
          expect(
            result.isRight,
            true,
            reason: '$email should be valid',
          );
        }
      });

      test('rejects invalid email formats', () {
        final invalidEmails = [
          'invalid-email',
          '@example.com',
          'user@',
          'user@.com',
          'user@domain',
          'user domain@example.com',
          'user@domain..com',
        ];

        for (final email in invalidEmails) {
          final result = EmailValidators.format(email);
          expect(
            result.isLeft,
            true,
            reason: '$email should be invalid',
          );
          expect(result.left.toString(), contains('Invalid email format'));
        }
      });
    });

    group('length', () {
      test('accepts email within length limit', () {
        final result = EmailValidators.length('user@example.com');
        expect(result.isRight, true);
      });

      test('rejects email exceeding length limit', () {
        final longEmail = 'a' * 91 + '@example.com'; // 105 characters total
        final result = EmailValidators.length(longEmail);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('too long'));
      });

      test('accepts email at exact length limit', () {
        final maxLengthEmail = 'a' * 88 + '@example.com'; // Exactly 100 chars
        final result = EmailValidators.length(maxLengthEmail);
        expect(result.isRight, true);
      });
    });

    group('validDomain', () {
      test('accepts email with valid domain', () {
        final result = EmailValidators.validDomain('user@example.com');
        expect(result.isRight, true);
      });

      test('rejects email without @ symbol', () {
        final result = EmailValidators.validDomain('userexample.com');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Invalid email format'));
      });

      test('rejects email with empty domain', () {
        final result = EmailValidators.validDomain('user@');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Invalid email domain'));
      });

      test('rejects email without dot in domain', () {
        final result = EmailValidators.validDomain('user@domain');
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Invalid email domain'));
      });
    });

    group('notDisposable', () {
      test('accepts non-disposable email', () {
        final result = EmailValidators.notDisposable('user@gmail.com');
        expect(result.isRight, true);
      });

      test('rejects disposable email domains', () {
        final disposableEmails = [
          'user@tempmail.com',
          'user@throwaway.email',
          'user@10minutemail.com',
          'user@guerrillamail.com',
        ];

        for (final email in disposableEmails) {
          final result = EmailValidators.notDisposable(email);
          expect(
            result.isLeft,
            true,
            reason: '$email should be rejected as disposable',
          );
          expect(
            result.left.toString(),
            contains('Disposable email addresses are not allowed'),
          );
        }
      });

      test('is case-insensitive for domains', () {
        final result = EmailValidators.notDisposable('user@TEMPMAIL.COM');
        expect(result.isLeft, true);
      });
    });

    group('completeChain', () {
      test('applies all validators in order', () {
        final chain = EmailValidators.completeChain;

        // Should have multiple validators
        expect(chain.length, greaterThanOrEqualTo(3));

        // Valid email should pass all validators
        String email = 'user@example.com';
        for (final validator in chain) {
          final result = validator(email);
          if (result.isLeft) {
            fail('Valid email should pass all validators: ${result.left}');
          }
        }
      });

      test('fails at first invalid validator (fail-fast)', () {
        final chain = EmailValidators.completeChain;

        // Empty email should fail at notEmpty validator (first)
        String email = '';
        var failedAtIndex = -1;

        for (var i = 0; i < chain.length; i++) {
          final result = chain[i](email);
          if (result.isLeft) {
            failedAtIndex = i;
            break;
          }
        }

        // Should fail at the first validator
        expect(failedAtIndex, 0);
      });
    });
  });
}
