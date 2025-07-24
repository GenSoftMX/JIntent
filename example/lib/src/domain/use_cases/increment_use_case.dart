import 'package:jintent/jintent.dart';

class IncrementUseCase extends JSyncUseCase<int, int> {
  int intents = 0;

  IncrementUseCase() {
    addValidator((input) {
      intents++;

      if (intents % 2 == 0) {
        if (input == 10) {
          return Left(
            Exception(
              'Value cannot be greater than 10 from: use case validator',
            ),
          );
        }
      }

      return Right(input);
    });
  }
  @override
  Either<Exception, int> run(int currentValue) {
    final newValue = currentValue + 1;

    if (newValue > 10) {
      return Left(Exception('Value cannot be greater than 10'));
    }
    return Right(newValue);
  }
}
