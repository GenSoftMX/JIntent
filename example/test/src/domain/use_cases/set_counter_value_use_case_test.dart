import 'package:flutter_test/flutter_test.dart';
import 'package:counter/src/domain/use_cases/set_counter_value_use_case.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('SetCounterValueUseCase', () {
    late SetCounterValueUseCase useCase;

    setUp(() {
      useCase = SetCounterValueUseCase();
    });

    group('validation', () {
      test('accepts value within valid range', () {
        final result = useCase(5);

        expect(result.isRight, true);
        expect(result.right, 5);
      });

      test('accepts minimum value', () {
        final result = useCase(-10);

        expect(result.isRight, true);
        expect(result.right, -10);
      });

      test('accepts maximum value', () {
        final result = useCase(10);

        expect(result.isRight, true);
        expect(result.right, 10);
      });

      test('rejects value below minimum', () {
        final result = useCase(-11);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
        expect(result.left.toString(), contains('-11'));
      });

      test('rejects value above maximum', () {
        final result = useCase(11);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('between -10 and 10'));
        expect(result.left.toString(), contains('11'));
      });
    });

    group('boundary values', () {
      test('accepts zero', () {
        final result = useCase(0);

        expect(result.isRight, true);
        expect(result.right, 0);
      });

      test('accepts -9', () {
        final result = useCase(-9);

        expect(result.isRight, true);
        expect(result.right, -9);
      });

      test('accepts 9', () {
        final result = useCase(9);

        expect(result.isRight, true);
        expect(result.right, 9);
      });
    });
  });
}
