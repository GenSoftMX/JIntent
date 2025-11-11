import 'package:flutter_test/flutter_test.dart';
import 'package:counter/src/domain/validators/common_validators.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('CommonValidators', () {
    group('intInRange', () {
      test('accepts value within range', () {
        final result = CommonValidators.intInRange(5, 0, 10);

        expect(result.isRight, true);
        expect(result.right, 5);
      });

      test('accepts minimum value', () {
        final result = CommonValidators.intInRange(0, 0, 10);

        expect(result.isRight, true);
        expect(result.right, 0);
      });

      test('accepts maximum value', () {
        final result = CommonValidators.intInRange(10, 0, 10);

        expect(result.isRight, true);
        expect(result.right, 10);
      });

      test('rejects value below range', () {
        final result = CommonValidators.intInRange(-1, 0, 10);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between 0 and 10'));
        expect(result.left.toString(), contains('-1'));
      });

      test('rejects value above range', () {
        final result = CommonValidators.intInRange(11, 0, 10);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between 0 and 10'));
        expect(result.left.toString(), contains('11'));
      });
    });

    group('notEmpty', () {
      test('accepts non-empty string', () {
        final result = CommonValidators.notEmpty('hello');

        expect(result.isRight, true);
        expect(result.right, 'hello');
      });

      test('rejects empty string', () {
        final result = CommonValidators.notEmpty('');

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });

      test('rejects whitespace-only string', () {
        final result = CommonValidators.notEmpty('   ');

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });

      test('rejects null string', () {
        final result = CommonValidators.notEmpty(null);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });
    });

    group('lengthInRange', () {
      test('accepts string within range', () {
        final result = CommonValidators.lengthInRange('hello', 3, 10);

        expect(result.isRight, true);
        expect(result.right, 'hello');
      });

      test('accepts minimum length', () {
        final result = CommonValidators.lengthInRange('abc', 3, 10);

        expect(result.isRight, true);
      });

      test('accepts maximum length', () {
        final result = CommonValidators.lengthInRange('1234567890', 3, 10);

        expect(result.isRight, true);
      });

      test('rejects string too short', () {
        final result = CommonValidators.lengthInRange('ab', 3, 10);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between 3 and 10'));
        expect(result.left.toString(), contains('2'));
      });

      test('rejects string too long', () {
        final result = CommonValidators.lengthInRange('12345678901', 3, 10);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between 3 and 10'));
        expect(result.left.toString(), contains('11'));
      });
    });

    group('listNotEmpty', () {
      test('accepts non-empty list', () {
        final result = CommonValidators.listNotEmpty([1, 2, 3]);

        expect(result.isRight, true);
        expect(result.right, [1, 2, 3]);
      });

      test('rejects empty list', () {
        final result = CommonValidators.listNotEmpty([]);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be empty'));
      });
    });

    group('notNull', () {
      test('accepts non-null value', () {
        final result = CommonValidators.notNull(42);

        expect(result.isRight, true);
        expect(result.right, 42);
      });

      test('rejects null value', () {
        final result = CommonValidators.notNull(null);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be null'));
      });
    });

    group('positive', () {
      test('accepts positive value', () {
        final result = CommonValidators.positive(5.5);

        expect(result.isRight, true);
        expect(result.right, 5.5);
      });

      test('rejects zero', () {
        final result = CommonValidators.positive(0.0);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('must be positive'));
      });

      test('rejects negative value', () {
        final result = CommonValidators.positive(-5.5);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('must be positive'));
      });
    });

    group('nonNegative', () {
      test('accepts positive value', () {
        final result = CommonValidators.nonNegative(5);

        expect(result.isRight, true);
        expect(result.right, 5);
      });

      test('accepts zero', () {
        final result = CommonValidators.nonNegative(0);

        expect(result.isRight, true);
        expect(result.right, 0);
      });

      test('rejects negative value', () {
        final result = CommonValidators.nonNegative(-5);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be negative'));
      });
    });

    group('isEmail', () {
      test('accepts valid email', () {
        final result = CommonValidators.isEmail('user@example.com');

        expect(result.isRight, true);
        expect(result.right, 'user@example.com');
      });

      test('accepts email with subdomain', () {
        final result = CommonValidators.isEmail('user@mail.example.com');

        expect(result.isRight, true);
      });

      test('rejects email without @', () {
        final result = CommonValidators.isEmail('userexample.com');

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Invalid email format'));
      });

      test('rejects email without domain', () {
        final result = CommonValidators.isEmail('user@');

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Invalid email format'));
      });
    });

    group('alphanumeric', () {
      test('accepts alphanumeric string', () {
        final result = CommonValidators.alphanumeric('abc123');

        expect(result.isRight, true);
        expect(result.right, 'abc123');
      });

      test('rejects string with spaces', () {
        final result = CommonValidators.alphanumeric('abc 123');

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('letters and numbers'));
      });

      test('rejects string with special characters', () {
        final result = CommonValidators.alphanumeric('abc@123');

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('letters and numbers'));
      });
    });

    group('minLength', () {
      test('accepts string meeting minimum', () {
        final result = CommonValidators.minLength('password', 8);

        expect(result.isRight, true);
        expect(result.right, 'password');
      });

      test('rejects string below minimum', () {
        final result = CommonValidators.minLength('pass', 8);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Minimum length is 8'));
        expect(result.left.toString(), contains('4'));
      });
    });

    group('maxLength', () {
      test('accepts string within maximum', () {
        final result = CommonValidators.maxLength('bio', 500);

        expect(result.isRight, true);
        expect(result.right, 'bio');
      });

      test('rejects string exceeding maximum', () {
        final result = CommonValidators.maxLength('a' * 501, 500);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Maximum length is 500'));
        expect(result.left.toString(), contains('501'));
      });
    });
  });
}
