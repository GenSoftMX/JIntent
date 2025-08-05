import 'package:jintent/jintent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaveCurrentValueUseCase implements JUseCaseVoid<int> {
  final SharedPreferences _preferences;

  SaveCurrentValueUseCase({required SharedPreferences preferences})
    : _preferences = preferences;

  @override
  Future<void> run(int currentValue) async {
    await _preferences.setInt('currentValue', currentValue);
  }
}
