import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

class TestUseCase extends JUseCase<int, String> {
  @override
  Future<Either<Exception, String>> run(int input) async {
    return Right(input.toString());
  }
}

void main() {
  group('JUseCase', () {
    late TestUseCase useCase;

    setUp(() {
      useCase = TestUseCase();
    });

    test('returns Left if validator fails', () async {
      useCase.addValidator((input) {
        if (input < 0) return Left(Exception('Negative input'));
        return Right(input);
      });

      final result = await useCase.call(-1);

      expect(result.isLeft, true);
      expect(result.left!.toString(), contains('Negative input'));
    });

    test('returns Right if validator passes and run succeeds', () async {
      useCase.addValidator((input) => Right(input));

      final result = await useCase.call(42);

      expect(result.isRight, true);
      expect(result.right, '42');
    });

    test('stops at the first failing validator', () async {
      var secondCalled = false;
      useCase.addValidator((_) => Left(Exception('first')));
      useCase.addValidator((input) {
        secondCalled = true;
        return Right(input);
      });

      final result = await useCase.call(1);

      expect(result.left.toString(), contains('first'));
      expect(secondCalled, isFalse);
    });
  });

  group('JSyncUseCase', () {
    late _DoubleUseCase useCase;

    setUp(() => useCase = _DoubleUseCase());

    test('runs when there are no validators', () {
      expect(useCase(4).right, 8);
    });

    test('returns the first validator failure without running', () {
      useCase.addValidator((i) => i < 0 ? Left(Exception('neg')) : Right(i));

      final result = useCase(-1);

      expect(result.isLeft, isTrue);
      expect(result.left.toString(), contains('neg'));
      expect(useCase.runs, 0);
    });

    test('runs after all validators pass', () {
      useCase.addValidator((i) => Right(i));

      expect(useCase(2).right, 4);
      expect(useCase.runs, 1);
    });
  });

  test('JNoParams can be const-constructed', () {
    expect(const JNoParams(), same(const JNoParams()));
  });
}

class _DoubleUseCase extends JSyncUseCase<int, int> {
  int runs = 0;

  @override
  Either<Exception, int> run(int input) {
    runs++;
    return Right(input * 2);
  }
}
