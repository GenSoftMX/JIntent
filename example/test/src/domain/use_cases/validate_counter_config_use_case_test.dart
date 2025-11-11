import 'package:flutter_test/flutter_test.dart';
import 'package:counter/src/domain/models/counter_config.dart';
import 'package:counter/src/domain/use_cases/validate_counter_config_use_case.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('ValidateCounterConfigUseCase', () {
    late ValidateCounterConfigUseCase useCase;

    setUp(() {
      useCase = ValidateCounterConfigUseCase();
    });

    group('successful validation', () {
      test('accepts valid configuration', () {
        final config = const CounterConfig(
          initialValue: 5,
          minValue: 0,
          maxValue: 10,
          step: 1,
        );

        final result = useCase(config);

        expect(result.isRight, true);
        expect(result.right, true);
      });

      test('accepts configuration with negative range', () {
        final config = const CounterConfig(
          initialValue: -5,
          minValue: -10,
          maxValue: 0,
          step: 1,
        );

        final result = useCase(config);

        expect(result.isRight, true);
      });

      test('accepts configuration with large step', () {
        final config = const CounterConfig(
          initialValue: 50,
          minValue: 0,
          maxValue: 100,
          step: 10,
        );

        final result = useCase(config);

        expect(result.isRight, true);
      });
    });

    group('fail-fast validation chain', () {
      test('fails at step validation when step is zero', () {
        final config = const CounterConfig(
          initialValue: 5,
          minValue: 0,
          maxValue: 10,
          step: 0, // Invalid - will fail first
        );

        final result = useCase(config);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Step must be positive'));
        expect(result.left.toString(), contains('0'));
      });

      test('fails at step validation when step is negative', () {
        final config = const CounterConfig(
          initialValue: 5,
          minValue: 0,
          maxValue: 10,
          step: -1, // Invalid - will fail first
        );

        final result = useCase(config);

        expect(result.isLeft, true);
        expect(result.left.toString(), contains('Step must be positive'));
      });

      test('fails at min/max validation when min >= max', () {
        final config = const CounterConfig(
          initialValue: 5,
          minValue: 10,
          maxValue: 5, // Invalid - min >= max
          step: 1, // Valid - passes first validator
        );

        final result = useCase(config);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('Min value must be less than max value'),
        );
        expect(result.left.toString(), contains('min: 10'));
        expect(result.left.toString(), contains('max: 5'));
      });

      test('fails at min/max validation when min equals max', () {
        final config = const CounterConfig(
          initialValue: 5,
          minValue: 5,
          maxValue: 5, // Invalid - min == max
          step: 1,
        );

        final result = useCase(config);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('Min value must be less than max value'),
        );
      });

      test('fails at initial range validation when initial is below min', () {
        final config = const CounterConfig(
          initialValue: -5, // Invalid - below min
          minValue: 0, // Valid - passes first validator
          maxValue: 10, // Valid - passes second validator
          step: 1,
        );

        final result = useCase(config);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('Initial value must be between 0 and 10'),
        );
        expect(result.left.toString(), contains('-5'));
      });

      test('fails at initial range validation when initial is above max', () {
        final config = const CounterConfig(
          initialValue: 15, // Invalid - above max
          minValue: 0,
          maxValue: 10,
          step: 1,
        );

        final result = useCase(config);

        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('Initial value must be between 0 and 10'),
        );
        expect(result.left.toString(), contains('15'));
      });
    });

    group('fail-fast demonstration', () {
      test(
        'stops at first failure (step), does not check min/max or initial',
        () {
          final config = const CounterConfig(
            initialValue: 15, // Also invalid
            minValue: 10, // Also invalid (min >= max)
            maxValue: 5, // Also invalid
            step: -1, // Invalid - checked first
          );

          final result = useCase(config);

          // Should fail on step validation only
          expect(result.isLeft, true);
          expect(result.left.toString(), contains('Step must be positive'));
          // Should NOT contain errors from other validators
          expect(result.left.toString(), isNot(contains('min')));
          expect(result.left.toString(), isNot(contains('Initial')));
        },
      );

      test('stops at second failure (min/max), does not check initial', () {
        final config = const CounterConfig(
          initialValue: 15, // Also invalid
          minValue: 10, // Invalid with max
          maxValue: 5, // Invalid with min
          step: 1, // Valid - passes first check
        );

        final result = useCase(config);

        // Should fail on min/max validation
        expect(result.isLeft, true);
        expect(
          result.left.toString(),
          contains('Min value must be less than max value'),
        );
        // Should NOT contain error from initial value validator
        expect(result.left.toString(), isNot(contains('Initial')));
      });
    });

    group('boundary values', () {
      test('accepts initial at minimum boundary', () {
        final config = const CounterConfig(
          initialValue: 0,
          minValue: 0,
          maxValue: 10,
          step: 1,
        );

        final result = useCase(config);

        expect(result.isRight, true);
      });

      test('accepts initial at maximum boundary', () {
        final config = const CounterConfig(
          initialValue: 10,
          minValue: 0,
          maxValue: 10,
          step: 1,
        );

        final result = useCase(config);

        expect(result.isRight, true);
      });
    });
  });
}
