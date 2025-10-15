import 'package:counter/src/domain/validators/counter_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterValidators', () {
    group('withinRange', () {
      test('accepts value within range', () {
        final validator = CounterValidators.withinRange(-10, 10);
        final result = validator(5);
        expect(result.isRight, true);
        expect(result.right, 5);
      });

      test('accepts value at minimum', () {
        final validator = CounterValidators.withinRange(-10, 10);
        final result = validator(-10);
        expect(result.isRight, true);
      });

      test('accepts value at maximum', () {
        final validator = CounterValidators.withinRange(-10, 10);
        final result = validator(10);
        expect(result.isRight, true);
      });

      test('rejects value below minimum', () {
        final validator = CounterValidators.withinRange(-10, 10);
        final result = validator(-11);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
      });

      test('rejects value above maximum', () {
        final validator = CounterValidators.withinRange(-10, 10);
        final result = validator(11);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
      });
    });

    group('notAtMax', () {
      test('accepts value below maximum', () {
        final validator = CounterValidators.notAtMax(10);
        final result = validator(9);
        expect(result.isRight, true);
      });

      test('rejects value at maximum', () {
        final validator = CounterValidators.notAtMax(10);
        final result = validator(10);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('already at maximum'));
      });

      test('rejects value above maximum', () {
        final validator = CounterValidators.notAtMax(10);
        final result = validator(11);
        expect(result.isLeft, true);
      });
    });

    group('notAtMin', () {
      test('accepts value above minimum', () {
        final validator = CounterValidators.notAtMin(-10);
        final result = validator(-9);
        expect(result.isRight, true);
      });

      test('rejects value at minimum', () {
        final validator = CounterValidators.notAtMin(-10);
        final result = validator(-10);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('already at minimum'));
      });

      test('rejects value below minimum', () {
        final validator = CounterValidators.notAtMin(-10);
        final result = validator(-11);
        expect(result.isLeft, true);
      });
    });

    group('canIncrement', () {
      test('accepts value that can be incremented', () {
        final validator = CounterValidators.canIncrement(10);
        final result = validator(9);
        expect(result.isRight, true);
      });

      test('rejects value at maximum', () {
        final validator = CounterValidators.canIncrement(10);
        final result = validator(10);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('would exceed maximum'));
      });

      test('accepts value at maximum - 1', () {
        final validator = CounterValidators.canIncrement(10);
        final result = validator(9);
        expect(result.isRight, true);
      });
    });

    group('canDecrement', () {
      test('accepts value that can be decremented', () {
        final validator = CounterValidators.canDecrement(-10);
        final result = validator(-9);
        expect(result.isRight, true);
      });

      test('rejects value at minimum', () {
        final validator = CounterValidators.canDecrement(-10);
        final result = validator(-10);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('would go below minimum'));
      });

      test('accepts value at minimum + 1', () {
        final validator = CounterValidators.canDecrement(-10);
        final result = validator(-9);
        expect(result.isRight, true);
      });
    });

    group('isEven', () {
      test('accepts even numbers', () {
        final evenNumbers = [0, 2, -2, 4, -4, 100];
        for (final num in evenNumbers) {
          final result = CounterValidators.isEven(num);
          expect(
            result.isRight,
            true,
            reason: '$num should be accepted as even',
          );
        }
      });

      test('rejects odd numbers', () {
        final oddNumbers = [1, -1, 3, -3, 99];
        for (final num in oddNumbers) {
          final result = CounterValidators.isEven(num);
          expect(
            result.isLeft,
            true,
            reason: '$num should be rejected as not even',
          );
          expect(result.left.toString(), contains('must be even'));
        }
      });
    });

    group('isOdd', () {
      test('accepts odd numbers', () {
        final oddNumbers = [1, -1, 3, -3, 99];
        for (final num in oddNumbers) {
          final result = CounterValidators.isOdd(num);
          expect(
            result.isRight,
            true,
            reason: '$num should be accepted as odd',
          );
        }
      });

      test('rejects even numbers', () {
        final evenNumbers = [0, 2, -2, 4, -4, 100];
        for (final num in evenNumbers) {
          final result = CounterValidators.isOdd(num);
          expect(
            result.isLeft,
            true,
            reason: '$num should be rejected as not odd',
          );
          expect(result.left.toString(), contains('must be odd'));
        }
      });
    });

    group('divisibleBy', () {
      test('accepts numbers divisible by divisor', () {
        final validator = CounterValidators.divisibleBy(5);
        final divisibleNumbers = [0, 5, -5, 10, -10, 100];

        for (final num in divisibleNumbers) {
          final result = validator(num);
          expect(
            result.isRight,
            true,
            reason: '$num should be divisible by 5',
          );
        }
      });

      test('rejects numbers not divisible by divisor', () {
        final validator = CounterValidators.divisibleBy(5);
        final notDivisibleNumbers = [1, 2, 3, 4, 6, 7, 8, 9];

        for (final num in notDivisibleNumbers) {
          final result = validator(num);
          expect(
            result.isLeft,
            true,
            reason: '$num should not be divisible by 5',
          );
          expect(result.left.toString(), contains('divisible by 5'));
        }
      });
    });

    group('incrementChain', () {
      test('accepts valid increment operation', () {
        final chain = CounterValidators.incrementChain(min: -10, max: 10);
        final value = 5;

        for (final validator in chain) {
          final result = validator(value);
          if (result.isLeft) {
            fail('Valid increment should pass all validators: ${result.left}');
          }
        }
      });

      test('rejects increment at maximum', () {
        final chain = CounterValidators.incrementChain(min: -10, max: 10);
        final value = 10;
        var failed = false;

        for (final validator in chain) {
          final result = validator(value);
          if (result.isLeft) {
            failed = true;
            break;
          }
        }

        expect(failed, true);
      });

      test('rejects increment out of range', () {
        final chain = CounterValidators.incrementChain(min: -10, max: 10);
        final value = 15;
        var failed = false;

        for (final validator in chain) {
          final result = validator(value);
          if (result.isLeft) {
            failed = true;
            expect(result.left.toString(), contains('between'));
            break;
          }
        }

        expect(failed, true);
      });
    });

    group('decrementChain', () {
      test('accepts valid decrement operation', () {
        final chain = CounterValidators.decrementChain(min: -10, max: 10);
        final value = 5;

        for (final validator in chain) {
          final result = validator(value);
          if (result.isLeft) {
            fail('Valid decrement should pass all validators: ${result.left}');
          }
        }
      });

      test('rejects decrement at minimum', () {
        final chain = CounterValidators.decrementChain(min: -10, max: 10);
        final value = -10;
        var failed = false;

        for (final validator in chain) {
          final result = validator(value);
          if (result.isLeft) {
            failed = true;
            break;
          }
        }

        expect(failed, true);
      });

      test('rejects decrement out of range', () {
        final chain = CounterValidators.decrementChain(min: -10, max: 10);
        final value = -15;
        var failed = false;

        for (final validator in chain) {
          final result = validator(value);
          if (result.isLeft) {
            failed = true;
            expect(result.left.toString(), contains('between'));
            break;
          }
        }

        expect(failed, true);
      });
    });
  });
}
