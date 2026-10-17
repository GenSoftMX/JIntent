import 'package:counter/di/di.dart';
import 'package:counter/navigation/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jintent/testing.dart';

/// Gives each test a fresh counter app.
///
/// Integration tests run on a device with real preferences and share the
/// service locator and the global router, so without this each test would see
/// the previous one's saved value, fail to register the dependencies again, or
/// start on the gallery that follows the splash screen.
Future<void> prepareCounterApp() async {
  resetJIntentGlobals();
  await Di.sl.reset();
  final preferences = await SharedPreferences.getInstance();
  await preferences.clear();
  await Di().init();
  appRouter.go('/counter');
}
