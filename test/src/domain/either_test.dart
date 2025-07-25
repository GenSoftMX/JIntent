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
  });
}
