import 'package:jintent/jintent.dart';

class DecrementUseCase extends JSyncUseCase<int, int> {
  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue - 1;

    if (newValue < -10) {
      return Left(Exception('Value cannot be less than -10'));
    }
    return Right(newValue);
  }
}
