import 'package:counter/di/di.dart';
import 'package:counter/src/presentation/splash/presentation/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jnavigator_service.dart';

/// Main application class for the Flutter project.
///
/// The `MyApp` class represents the root of the Flutter application. It is a
/// `StatelessWidget`, indicating that it does not maintain any mutable state
/// itself. The class sets up the overall application structure, including the
/// theme, navigator key, and initial route.
///
/// This class is typically instantiated once and provided to `runApp()` to start
/// the Flutter application.
///
/// **Key Features**:
/// - **Stateless**: As a `StatelessWidget`, `MyApp` does not change once
///   instantiated.
/// - **MaterialApp Setup**: Configures the `MaterialApp` with a theme, a navigator
///   key, and a home widget.
/// - **Dependency Injection**: Uses `Di` to get the `JNavigatorService` for navigation.
/// - **Riverpod Integration**: Wrapped in `ProviderScope` to enable Riverpod-based
///   state management across the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

// Initialization of GetIt and inject dependences
  await Di().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Di.sl<JNavigatorService>().key,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashView(),
    );
  }
}
