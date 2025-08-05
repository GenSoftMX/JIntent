import 'package:jintent/jintent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetCurrentValueUseCase extends JUseCase<JNoParams, int> {
  final SharedPreferences _preferences;

  GetCurrentValueUseCase({required SharedPreferences preferences})
    : _preferences = preferences;

  @override
  Future<Either<Exception, int>> run(JNoParams params) async {
    try {
      final int? value = _preferences.getInt('currentValue');

      if (value != null) {
        return Right(value);
      } else {
        return Left(Exception("No value saved for 'currentValue'"));
      }
    } catch (e) {
      return Left(Exception('Exception reading currentValue: $e'));
    }
  }
}
