import 'package:counter/src/domain/use_cases/validated_decrement_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidatedDecrementUseCase', () {
    late ValidatedDecrementUseCase useCase;

    setUp(() {
      useCase = ValidatedDecrementUseCase();
    });

    group('successful decrement', () {
      test('decrements value within valid range', () {
        final result = useCase.call(5);
        expect(result.isRight, true);
        expect(result.right, 4);
      });

      test('decrements from maximum value', () {
        final result = useCase.call(10);
        expect(result.isRight, true);
        expect(result.right, 9);
      });

      test('decrements to minimum value', () {
        final result = useCase.call(-9);
        expect(result.isRight, true);
        expect(result.right, -10);
      });

      test('decrements zero', () {
        final result = useCase.call(0);
        expect(result.isRight, true);
        expect(result.right, -1);
      });

      test('decrements positive value', () {
        final result = useCase.call(5);
        expect(result.isRight, true);
        expect(result.right, 4);
      });
    });

    group('validation failures', () {
      test('rejects decrement when value is at minimum', () {
        final result = useCase.call(-10);
        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('would go below minimum value of -10'),
        );
      });

      test('rejects decrement when value is below minimum', () {
        final result = useCase.call(-11);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
      });

      test('rejects decrement when value is above maximum', () {
        final result = useCase.call(11);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
      });
    });

    group('fail-fast behavior', () {
      test('fails at first validator (range check) before decrement check', () {
        // Value -15 is out of range, so it should fail at the first validator
        final result = useCase.call(-15);

        expect(result.isLeft, true);
        // Should fail at range check, not decrement check
        expect(result.left.toString(), contains('between -10 and 10'));
        expect(
          result.left.toString().contains('go below minimum'),
          false,
        );
      });

      test('fails at second validator (decrement check) when range is valid', () {
        // Value -10 is within range but can't be decremented
        final result = useCase.call(-10);

        expect(result.isLeft, true);
        // Should fail at decrement check, not range check
        expect(result.left.toString(), contains('would go below minimum'));
      });
    });

    group('edge cases', () {
      test('handles minimum integer edge case', () {
        // Test with extreme values within the valid range
        final minInRange = ValidatedDecrementUseCase.minValue + 1;
        final result = useCase.call(minInRange);
        expect(result.isRight, true);
        expect(result.right, ValidatedDecrementUseCase.minValue);
      });

      test('handles maximum integer edge case', () {
        final maxInRange = ValidatedDecrementUseCase.maxValue;
        final result = useCase.call(maxInRange);
        expect(result.isRight, true);
        expect(result.right, ValidatedDecrementUseCase.maxValue - 1);
      });
    });
  });
}
