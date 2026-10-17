import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/src/domain/either.dart';

void main() {
  group('Either', () {
    test('Left holds failure', () {
      final left = Left<Exception, int>(Exception('fail'));
      expect(left.isLeft, true);
      expect(left.isRight, false);
      expect(left.left, isA<Exception>());
      expect(left.right, null);
    });

    test('Right holds success', () {
      final right = Right<Exception, int>(42);
      expect(right.isRight, true);
      expect(right.isLeft, false);
      expect(right.right, 42);
      expect(right.left, null);
    });

    test('fold behaves correctly', () {
      final left = Left<String, int>('error');
      final right = Right<String, int>(100);

      final leftResult = left.fold((l) => 'Left: $l', (r) => 'Right: $r');
      final rightResult = right.fold((l) => 'Left: $l', (r) => 'Right: $r');

      expect(leftResult, 'Left: error');
      expect(rightResult, 'Right: 100');
    });

    test('value exposes the held value on each side', () {
      expect(Left<String, int>('e').value, 'e');
      expect(const Right<String, int>(3).value, 3);
    });

    test('switch destructures and is exhaustive', () {
      String describe(Either<String, int> e) => switch (e) {
        Left(:final value) => 'left $value',
        Right(:final value) => 'right $value',
      };

      expect(describe(Left('x')), 'left x');
      expect(describe(const Right(1)), 'right 1');
    });

    test('equality compares side, value and type arguments', () {
      expect(Left<String, int>('a'), Left<String, int>('a'));
      expect(Left<String, int>('a').hashCode, Left<String, int>('a').hashCode);
      expect(Left<String, int>('a'), isNot(Left<String, int>('b')));
      expect(const Right<String, int>(1), const Right<String, int>(1));
      expect(const Right<String, int>(1), isNot(const Right<String, int>(2)));
      expect(Left<int, int>(1), isNot(const Right<int, int>(1)));
      expect(Left<String, int>('a'), isNot(Left<String, String>('a')));
    });

    test('equality is symmetric across related type arguments', () {
      final narrowLeft = Left<String, int>('x');
      final wideLeft = Left<String, num>('x');
      expect(narrowLeft == wideLeft, isFalse);
      expect(wideLeft == narrowLeft, isFalse);

      const narrowRight = Right<Exception, int>(1);
      const wideRight = Right<Object, num>(1);
      expect(narrowRight == wideRight, isFalse);
      expect(wideRight == narrowRight, isFalse);
    });

    test('toString shows side and value', () {
      expect(Left<String, int>('e').toString(), 'Left(e)');
      expect(const Right<String, int>(2).toString(), 'Right(2)');
    });

    group('EitherConfig', () {
      tearDown(() => EitherConfig.errorLogger = null);

      test('logs a Left value in debug mode', () {
        final logged = <Object>[];
        EitherConfig.configureLogger(logged.add);

        Left<String, int>('boom');

        expect(logged, ['boom']);
      });

      test('does not fail for a null Left value', () {
        final logged = <Object>[];
        EitherConfig.configureLogger(logged.add);

        expect(() => Left<String?, int>(null), returnsNormally);
        expect(logged, isEmpty);
      });
    });
  });
}
