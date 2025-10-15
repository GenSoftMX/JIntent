import 'package:counter/src/domain/use_cases/validated_increment_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidatedIncrementUseCase', () {
    late ValidatedIncrementUseCase useCase;

    setUp(() {
      useCase = ValidatedIncrementUseCase();
    });

    group('successful increment', () {
      test('increments value within valid range', () {
        final result = useCase.call(5);
        expect(result.isRight, true);
        expect(result.right, 6);
      });

      test('increments from minimum value', () {
        final result = useCase.call(-10);
        expect(result.isRight, true);
        expect(result.right, -9);
      });

      test('increments to maximum value', () {
        final result = useCase.call(9);
        expect(result.isRight, true);
        expect(result.right, 10);
      });

      test('increments zero', () {
        final result = useCase.call(0);
        expect(result.isRight, true);
        expect(result.right, 1);
      });

      test('increments negative value', () {
        final result = useCase.call(-5);
        expect(result.isRight, true);
        expect(result.right, -4);
      });
    });

    group('validation failures', () {
      test('rejects increment when value is at maximum', () {
        final result = useCase.call(10);
        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('would exceed maximum value of 10'),
        );
      });

      test('rejects increment when value is above maximum', () {
        final result = useCase.call(11);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
      });

      test('rejects increment when value is below minimum', () {
        final result = useCase.call(-11);
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
      });
    });

    group('fail-fast behavior', () {
      test('fails at first validator (range check) before increment check', () {
        // Value 15 is out of range, so it should fail at the first validator
        final result = useCase.call(15);

        expect(result.isLeft, true);
        // Should fail at range check, not increment check
        expect(result.left.toString(), contains('between -10 and 10'));
        expect(
          result.left.toString().contains('exceed maximum'),
          false,
        );
      });

      test('fails at second validator (increment check) when range is valid', () {
        // Value 10 is within range but can't be incremented
        final result = useCase.call(10);

        expect(result.isLeft, true);
        // Should fail at increment check, not range check
        expect(result.left.toString(), contains('would exceed maximum'));
      });
    });

    group('edge cases', () {
      test('handles maximum integer edge case', () {
        // Test with extreme values within the valid range
        final maxInRange = ValidatedIncrementUseCase.maxValue - 1;
        final result = useCase.call(maxInRange);
        expect(result.isRight, true);
        expect(result.right, ValidatedIncrementUseCase.maxValue);
      });

      test('handles minimum integer edge case', () {
        final minInRange = ValidatedIncrementUseCase.minValue;
        final result = useCase.call(minInRange);
        expect(result.isRight, true);
        expect(result.right, ValidatedIncrementUseCase.minValue + 1);
      });
    });
  });
}
