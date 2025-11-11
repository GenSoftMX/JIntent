import 'package:flutter_test/flutter_test.dart';
import 'package:counter/src/domain/use_cases/add_to_counter_use_case.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('AddToCounterUseCase', () {
    late AddToCounterUseCase useCase;

    setUp(() {
      useCase = AddToCounterUseCase();
    });

    group('successful validation and execution', () {
      test('adds valid amount to counter', () {
        final input = const AddToCounterInput(currentValue: 5, amountToAdd: 3);

        final result = useCase(input);

        expect(result.isRight, true);
        expect(result.right, 8);
      });

      test('accepts zero amount', () {
        final input = const AddToCounterInput(currentValue: 5, amountToAdd: 0);

        final result = useCase(input);

        expect(result.isRight, true);
        expect(result.right, 5);
      });

      test('adds to reach maximum value', () {
        final input = const AddToCounterInput(currentValue: 8, amountToAdd: 2);

        final result = useCase(input);

        expect(result.isRight, true);
        expect(result.right, 10); // Max value
      });
    });

    group('fail-fast validation chain', () {
      test('fails at validator 1 (non-negative check)', () {
        final input = const AddToCounterInput(
          currentValue: 5,
          amountToAdd: -3, // Invalid - negative
        );

        final result = useCase(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be negative'));
        expect(result.left.toString(), contains('-3'));
        // Should not mention other validators
        expect(result.left.toString(), isNot(contains('exceed')));
        expect(result.left.toString(), isNot(contains('Result')));
      });

      test('fails at validator 2 (reasonable amount check)', () {
        final input = const AddToCounterInput(
          currentValue: 5,
          amountToAdd: 150, // Invalid - exceeds max add amount
        );

        final result = useCase(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot exceed 100'));
        expect(result.left.toString(), contains('150'));
        // Should not mention overflow validator
        expect(result.left.toString(), isNot(contains('Result would')));
      });

      test('fails at validator 3 (overflow check)', () {
        final input = const AddToCounterInput(
          currentValue: 9,
          amountToAdd: 5, // Valid amount, but result exceeds max
        );

        final result = useCase(input);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('Result would exceed maximum value'),
        );
        expect(result.left.toString(), contains('Current: 9'));
        expect(result.left.toString(), contains('Adding: 5'));
        expect(result.left.toString(), contains('Result: 14'));
      });
    });

    group('fail-fast demonstration with multiple invalid values', () {
      test('stops at first failure even when all validators would fail', () {
        final input = const AddToCounterInput(
          currentValue: 10,
          amountToAdd: -200, // Invalid for all 3 validators
        );

        final result = useCase(input);

        // Should only fail on first validator (non-negative)
        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be negative'));
        // Should NOT mention later validators
        expect(result.left.toString(), isNot(contains('exceed 100')));
        expect(result.left.toString(), isNot(contains('Result would')));
      });

      test(
        'stops at second failure when first passes but second and third fail',
        () {
          final input = const AddToCounterInput(
            currentValue: 5,
            amountToAdd: 101, // Passes validator 1, fails validator 2 and 3
          );

          final result = useCase(input);

          // Should fail on second validator (reasonable amount)
          expect(result.isLeft, true);
          expect(result.left.toString(), contains('cannot exceed 100'));
          // Should NOT mention third validator
          expect(result.left.toString(), isNot(contains('Result would')));
        },
      );
    });

    group('boundary values', () {
      test('accepts amount at maximum allowed', () {
        final input = const AddToCounterInput(
          currentValue: 0,
          amountToAdd: 10, // Exactly at max counter value
        );

        final result = useCase(input);

        expect(result.isRight, true);
        expect(result.right, 10);
      });

      test('rejects amount one over maximum result', () {
        final input = const AddToCounterInput(
          currentValue: 5,
          amountToAdd: 6, // Result would be 11, over max of 10
        );

        final result = useCase(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Result would exceed'));
      });

      test('accepts maximum add amount if result is valid', () {
        final input = const AddToCounterInput(
          currentValue: -90,
          amountToAdd: 100, // Max add amount, result is 10
        );

        final result = useCase(input);

        expect(result.isRight, true);
        expect(result.right, 10);
      });

      test('rejects maximum add amount if result exceeds max', () {
        final input = const AddToCounterInput(
          currentValue: 0,
          amountToAdd: 100, // Max add amount, but result is 100 > 10
        );

        final result = useCase(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Result would exceed'));
      });
    });

    group('validator order verification', () {
      test('negative amount fails before checking overflow', () {
        // This would also overflow, but should fail on negative check first
        final input = const AddToCounterInput(
          currentValue: 10,
          amountToAdd: -1,
        );

        final result = useCase(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot be negative'));
      });

      test('unreasonable amount fails before checking overflow', () {
        // This would also overflow, but should fail on reasonable check first
        final input = const AddToCounterInput(
          currentValue: 10,
          amountToAdd: 200,
        );

        final result = useCase(input);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('cannot exceed 100'));
      });
    });
  });
}
