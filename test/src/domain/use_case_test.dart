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
  });
}